"""Graph-arm dataset: v3 records -> fixed-capacity cell-graph tensors.

Spec: docs/representations/graph.md (D-022). Nodes are the candidate-set
cells (occupied + 1-ring) in the record's 32x32 frame coordinates; edges
are the six hex directions as a neighbour-index tensor; pieces enter via
slot embeddings + their standing node. Fixed capacities keep ONNX shapes
static (CoreML); overflow fails loudly, never truncates.

Per item:
  nodes    (NODE_CAP, NODE_F) float32   node features (zero-padded)
  nbrs     (NODE_CAP, 6)      int64     neighbour node index, NODE_CAP = none
  nmask    (NODE_CAP,)        bool      real-node mask
  glob     (GLOBAL_F,)        float32   global features
  moves    (MOVE_CAP, 3)      int64     [rel_piece slot, dest node, src node]
                                        src = NODE_CAP for placements/pass;
                                        pass rows use slot PASS_SLOT
  mmask    (MOVE_CAP,)        bool      legal-move mask
  target   (MOVE_CAP,)        float32   visit distribution over legal moves
  wdl      ()                 int64     0 L / 1 D / 2 W / 3 truncated
"""

import numpy as np
import torch
from torch.utils.data import Dataset

from .dataset import (
    HEX_DELTAS,
    PIECES_PER_COLOR,
    RECORD_SIZE,
    RECORD_V2_TOPK,
    ROSTER_BUG,
    HiveRecordDataset,
    legal_mask as _legal_mask,  # noqa: F401  (re-export convenience)
)

NODE_CAP = 224
MOVE_CAP = 321          # 320 legal (record cap) + 1 pass row
PASS_SLOT = 28          # slot ids 0..27 are pieces; 28 = pass
POLICY_PASS = 28 * 32 * 32
NODE_F = 56             # 5 levels x (present, own, bug one-hot 8) + 6 flags
GLOBAL_F = 23


def build_graph(rec: np.ndarray):
    """Build the graph tensors for one v3 record. Pure numpy."""
    stm = int(rec[84])
    pieces = rec[:84].reshape(28, 3).astype(np.int64)  # (x, y, level)
    on_board = pieces[:, 0] != 255
    pinned_bits = int.from_bytes(bytes(rec[92:96]), "little")
    last_moved = int(rec[85])

    # --- cells: occupied + 1-ring, deterministic order (occupied first,
    # then ring, each sorted by (y, x) for reproducibility).
    stacks: dict[tuple[int, int], list[int]] = {}
    for pid in range(28):
        if on_board[pid]:
            stacks.setdefault((int(pieces[pid, 0]), int(pieces[pid, 1])), []).append(pid)
    for cell, pids in stacks.items():
        pids.sort(key=lambda p: pieces[p, 2])  # by level
    occupied = sorted(stacks, key=lambda c: (c[1], c[0]))
    ring = set()
    for (x, y) in occupied:
        for dx, dy in HEX_DELTAS:
            n = (x + dx, y + dy)
            if n not in stacks:
                ring.add(n)
    cells = occupied + sorted(ring, key=lambda c: (c[1], c[0]))
    if not cells:
        cells = [(16, 16)]  # empty board: the canonical first cell (Frame::new)
    if len(cells) > NODE_CAP:
        raise OverflowError(f"candidate set {len(cells)} exceeds NODE_CAP {NODE_CAP}")
    index = {c: i for i, c in enumerate(cells)}

    # --- placement legality per colour (same rule as decode_planes).
    tops = {c: pids[-1] for c, pids in stacks.items()}
    top_color = {c: (0 if pid < PIECES_PER_COLOR else 1) for c, pid in tops.items()}
    placeable = {}
    for color in (0, 1):
        cells_ok = set()
        for c in cells:
            if c in stacks:
                continue
            adj = [top_color.get((c[0] + dx, c[1] + dy)) for dx, dy in HEX_DELTAS]
            if color in adj and (1 - color) not in adj:
                cells_ok.add(c)
        placeable[color] = cells_ok

    nodes = np.zeros((NODE_CAP, NODE_F), dtype=np.float32)
    nbrs = np.full((NODE_CAP, 6), NODE_CAP, dtype=np.int64)
    nmask = np.zeros(NODE_CAP, dtype=bool)
    for c, i in index.items():
        nmask[i] = True
        pids = stacks.get(c, [])
        for lvl, pid in enumerate(pids[:5]):
            base = lvl * 10
            own = 1.0 if (0 if pid < PIECES_PER_COLOR else 1) == stm else 0.0
            nodes[i, base] = 1.0
            nodes[i, base + 1] = own
            nodes[i, base + 2 + int(ROSTER_BUG[pid % PIECES_PER_COLOR])] = 1.0
        nodes[i, 50] = len(pids) / 5.0
        nodes[i, 51] = 0.0 if pids else 1.0  # empty candidate
        if pids and (pinned_bits >> pids[-1]) & 1:
            nodes[i, 52] = 1.0
        if last_moved != 255 and pids and pids[-1] == last_moved:
            nodes[i, 53] = 1.0
        nodes[i, 54] = 1.0 if c in placeable[stm] else 0.0
        nodes[i, 55] = 1.0 if c in placeable[1 - stm] else 0.0
        for d, (dx, dy) in enumerate(HEX_DELTAS):
            n = (c[0] + dx, c[1] + dy)
            if n in index:
                nbrs[i, d] = index[n]

    glob = np.zeros(GLOBAL_F, dtype=np.float32)
    glob[0] = 1.0 if stm == 0 else 0.0
    glob[1] = int(rec[86]) / 100.0
    for slot, byte in ((2, 88), (3, 89)):
        libs = int(rec[byte])
        glob[slot] = 0.0 if libs == 255 else libs / 6.0
    # Per-bug-type reserves, stm-relative.
    for color_rel, off in ((0, 4), (1, 12)):  # 0 = stm, 1 = opponent
        color_abs = stm if color_rel == 0 else 1 - stm
        for ri in range(PIECES_PER_COLOR):
            pid = color_abs * PIECES_PER_COLOR + ri
            if not on_board[pid]:
                glob[off + int(ROSTER_BUG[ri])] += 1.0 / 3.0
    gt = int(rec[87])
    glob[20], glob[21], glob[22] = float(gt & 1), float(gt >> 1 & 1), float(gt >> 2 & 1)

    # --- legal moves -> (slot, dest node, src node) + target distribution.
    count = int(rec[176]) | (int(rec[177]) << 8)
    assert count not in (0, 0xFFFF), "graph arm requires v3 legal lists"
    idxs = rec[178 : 178 + count * 2].view(np.uint16).astype(np.int64)
    moves = np.full((MOVE_CAP, 3), NODE_CAP, dtype=np.int64)
    mmask = np.zeros(MOVE_CAP, dtype=bool)
    pos_of_policy: dict[int, int] = {}
    for k, pidx in enumerate(idxs):
        pidx = int(pidx)
        pos_of_policy[pidx] = k
        mmask[k] = True
        if pidx == POLICY_PASS:
            moves[k] = (PASS_SLOT, NODE_CAP, NODE_CAP)
            continue
        slot = pidx // 1024
        rest = pidx % 1024
        dest = (rest % 32, rest // 32)  # (x, y)
        pid_abs = (stm if slot < PIECES_PER_COLOR else 1 - stm) * PIECES_PER_COLOR + (
            slot % PIECES_PER_COLOR
        )
        src = NODE_CAP
        if on_board[pid_abs]:
            src = index[(int(pieces[pid_abs, 0]), int(pieces[pid_abs, 1]))]
        moves[k] = (slot, index[dest], src)

    target = np.zeros(MOVE_CAP, dtype=np.float32)
    entries = rec[RECORD_SIZE : RECORD_SIZE + RECORD_V2_TOPK * 4].reshape(-1, 2, 2)
    tidx = entries[:, 0, 0].astype(np.int64) | (entries[:, 0, 1].astype(np.int64) << 8)
    tw = entries[:, 1, 0].astype(np.float32) + entries[:, 1, 1].astype(np.float32) * 256.0
    for pidx, w in zip(tidx, tw):
        if w > 0:
            target[pos_of_policy[int(pidx)]] = w
    if target.sum() == 0:  # degenerate: fall back to the played move
        played = int(rec[96]) | (int(rec[97]) << 8)
        target[pos_of_policy[played]] = 1.0
    target /= target.sum()

    return nodes, nbrs, nmask, glob, moves, mmask, target


class HiveGraphDataset(Dataset):
    def __init__(self, shard_paths: list[str]):
        self.base = HiveRecordDataset(shard_paths)
        self.records = self.base.records

    def __len__(self) -> int:
        return len(self.records)

    def __getitem__(self, idx: int):
        rec = self.records[idx]
        nodes, nbrs, nmask, glob, moves, mmask, target = build_graph(rec)
        return (
            torch.from_numpy(nodes),
            torch.from_numpy(nbrs),
            torch.from_numpy(nmask),
            torch.from_numpy(glob),
            torch.from_numpy(moves),
            torch.from_numpy(mmask),
            torch.from_numpy(target),
            torch.tensor(int(rec[98]), dtype=torch.long),
        )
