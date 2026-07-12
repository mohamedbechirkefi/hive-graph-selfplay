"""HiveNet: KataGo-lite ResNet for Hive.

Input:  (B, 77, 32, 32) planes — see crates/hive-nn/src/lib.rs and dataset.py.
Policy: (B, 28673) logits — 28 piece slots x 32x32 destinations + pass.
Value:  (B, 3) WDL logits from the side-to-move perspective.

Hex adjacency on axial coordinates is a 7-cell subset of the 3x3
neighborhood, so ordinary 3x3 convolutions cover it (the two non-neighbor
corners become learnable dead weights).
"""

import torch
import torch.nn as nn
import torch.nn.functional as F

PLANES = 77
FRAME = 32
PIECE_SLOTS = 28
POLICY_SIZE = PIECE_SLOTS * FRAME * FRAME + 1  # + pass


class GlobalPoolBias(nn.Module):
    """KataGo-style global pooling bias: pooled stats modulate channels."""

    def __init__(self, channels: int):
        super().__init__()
        self.fc = nn.Linear(2 * channels, channels)

    def forward(self, x):
        mean = x.mean(dim=(2, 3))
        mx = x.amax(dim=(2, 3))
        bias = self.fc(torch.cat([mean, mx], dim=1))
        return x + bias[:, :, None, None]


class ResBlock(nn.Module):
    def __init__(self, channels: int, global_pool: bool = False):
        super().__init__()
        self.conv1 = nn.Conv2d(channels, channels, 3, padding=1, bias=False)
        self.bn1 = nn.BatchNorm2d(channels)
        self.conv2 = nn.Conv2d(channels, channels, 3, padding=1, bias=False)
        self.bn2 = nn.BatchNorm2d(channels)
        self.gpool = GlobalPoolBias(channels) if global_pool else None

    def forward(self, x):
        y = F.relu(self.bn1(self.conv1(x)))
        y = self.bn2(self.conv2(y))
        if self.gpool is not None:
            y = self.gpool(y)
        return F.relu(x + y)


class HiveNet(nn.Module):
    def __init__(self, channels: int = 96, blocks: int = 8):
        super().__init__()
        self.stem = nn.Sequential(
            nn.Conv2d(PLANES, channels, 3, padding=1, bias=False),
            nn.BatchNorm2d(channels),
            nn.ReLU(inplace=True),
        )
        # Global pooling in two middle blocks (queen safety is global).
        self.blocks = nn.ModuleList(
            ResBlock(channels, global_pool=(i in (blocks // 3, 2 * blocks // 3)))
            for i in range(blocks)
        )
        self.policy_conv = nn.Conv2d(channels, PIECE_SLOTS, 1)
        self.policy_pass = nn.Linear(channels, 1)
        self.value_head = nn.Sequential(
            nn.Linear(channels, 64),
            nn.ReLU(inplace=True),
            nn.Linear(64, 3),
        )

    def forward(self, x):
        h = self.stem(x)
        for b in self.blocks:
            h = b(h)
        pooled = h.mean(dim=(2, 3))
        spatial = self.policy_conv(h).flatten(1)  # (B, 28*32*32)
        pass_logit = self.policy_pass(pooled)  # (B, 1)
        policy = torch.cat([spatial, pass_logit], dim=1)
        value = self.value_head(pooled)
        return policy, value


def count_params(model: nn.Module) -> int:
    return sum(p.numel() for p in model.parameters())


if __name__ == "__main__":
    net = HiveNet()
    x = torch.zeros(2, PLANES, FRAME, FRAME)
    p, v = net(x)
    assert p.shape == (2, POLICY_SIZE) and v.shape == (2, 3)
    print(f"HiveNet OK: {count_params(net)/1e6:.2f}M params, policy {p.shape}, value {v.shape}")
