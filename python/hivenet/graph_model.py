"""HiveGraphNet: the study's graph arm (docs/representations/graph.md).

Relational message passing over the cell graph with direction-typed
edges, global-pooling bias, masked global pooling for the value head,
and per-candidate (slot, dest, src) policy scoring through the shared
decoder contract (D-015): logits attach to legal moves only; softmax
over the legal set happens in the loss/inference, exactly as the grid
arm's masked softmax.

All shapes are static (NODE_CAP/MOVE_CAP) for ONNX/CoreML export.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F

from .graph_dataset import GLOBAL_F, MOVE_CAP, NODE_CAP, NODE_F, PASS_SLOT


class RelLayer(nn.Module):
    """h_i' = ReLU(W_self h_i + sum_d W_d h_{n_i(d)} + b), masked."""

    def __init__(self, hidden: int, global_pool: bool = False):
        super().__init__()
        self.self_lin = nn.Linear(hidden, hidden)
        self.dir_lin = nn.ModuleList(nn.Linear(hidden, hidden, bias=False) for _ in range(6))
        self.gpool = nn.Linear(2 * hidden, hidden) if global_pool else None

    def forward(self, h, nbrs, nmask):
        # h: (B, N+1, H) with a zero pad row at index NODE_CAP.
        y = self.self_lin(h[:, :-1])
        for d in range(6):
            nb = h.gather(1, nbrs[:, :, d : d + 1].expand(-1, -1, h.size(-1)))
            y = y + self.dir_lin[d](nb)
        if self.gpool is not None:
            m = nmask.unsqueeze(-1)
            mean = (h[:, :-1] * m).sum(1) / m.sum(1).clamp_min(1.0)
            mx = (h[:, :-1] + (~nmask.unsqueeze(-1)) * -1e9).amax(1)
            y = y + self.gpool(torch.cat([mean, mx], dim=1)).unsqueeze(1)
        y = F.relu(h[:, :-1] + y) * nmask.unsqueeze(-1)
        return torch.cat([y, torch.zeros_like(y[:, :1])], dim=1)


class HiveGraphNet(nn.Module):
    def __init__(self, hidden: int = 152, layers: int = 8, slot_dim: int = 32):
        super().__init__()
        self.hidden = hidden
        self.inp = nn.Linear(NODE_F + GLOBAL_F, hidden)
        self.layers = nn.ModuleList(
            RelLayer(hidden, global_pool=(i % 3 == 2)) for i in range(layers)
        )
        self.slot_emb = nn.Embedding(PASS_SLOT + 1, slot_dim)
        self.reserve_vec = nn.Parameter(torch.zeros(hidden))
        self.policy_mlp = nn.Sequential(
            nn.Linear(2 * hidden + slot_dim, 128), nn.ReLU(inplace=True), nn.Linear(128, 1)
        )
        self.value_mlp = nn.Sequential(
            nn.Linear(2 * hidden + GLOBAL_F, 64), nn.ReLU(inplace=True), nn.Linear(64, 3)
        )

    def forward(self, nodes, nbrs, nmask, glob, moves, mmask):
        # nodes (B,N,F), nbrs (B,N,6), nmask (B,N), glob (B,G),
        # moves (B,M,3), mmask (B,M) -> (move logits (B,M), value (B,3))
        x = torch.cat([nodes, glob.unsqueeze(1).expand(-1, nodes.size(1), -1)], dim=2)
        h = self.inp(x) * nmask.unsqueeze(-1)
        h = torch.cat([h, torch.zeros_like(h[:, :1])], dim=1)  # pad row = NODE_CAP
        for layer in self.layers:
            h = layer(h, nbrs, nmask)

        m = nmask.unsqueeze(-1)
        mean = (h[:, :-1] * m).sum(1) / m.sum(1).clamp_min(1.0)
        mx = (h[:, :-1] + (~m) * -1e9).amax(1)
        value = self.value_mlp(torch.cat([mean, mx, glob], dim=1))

        hd = h.size(-1)
        dest_e = h.gather(1, moves[:, :, 1:2].expand(-1, -1, hd))
        src_e = h.gather(1, moves[:, :, 2:3].expand(-1, -1, hd))
        # Placements/pass have src = NODE_CAP (zero row): substitute the
        # learned reserve vector there.
        is_reserve = (moves[:, :, 2] == NODE_CAP).unsqueeze(-1)
        src_e = torch.where(is_reserve, self.reserve_vec.expand_as(src_e), src_e)
        slot_e = self.slot_emb(moves[:, :, 0].clamp(max=PASS_SLOT))
        logits = self.policy_mlp(torch.cat([dest_e, src_e, slot_e], dim=2)).squeeze(-1)
        logits = logits.masked_fill(~mmask, -1e9)
        return logits, value


def count_params(model: nn.Module) -> int:
    return sum(p.numel() for p in model.parameters())


if __name__ == "__main__":
    net = HiveGraphNet()
    B = 2
    nodes = torch.zeros(B, NODE_CAP, NODE_F)
    nbrs = torch.full((B, NODE_CAP, 6), NODE_CAP, dtype=torch.long)
    nmask = torch.zeros(B, NODE_CAP, dtype=torch.bool)
    nmask[:, :5] = True
    glob = torch.zeros(B, GLOBAL_F)
    moves = torch.full((B, MOVE_CAP, 3), NODE_CAP, dtype=torch.long)
    moves[:, :4, 0] = 3
    moves[:, :4, 1] = 2
    mmask = torch.zeros(B, MOVE_CAP, dtype=torch.bool)
    mmask[:, :4] = True
    p, v = net(nodes, nbrs, nmask, glob, moves, mmask)
    assert p.shape == (B, MOVE_CAP) and v.shape == (B, 3)
    print(f"HiveGraphNet OK: {count_params(net)/1e6:.2f}M params, policy {p.shape}, value {v.shape}")
