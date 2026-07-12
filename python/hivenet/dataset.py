"""Dataset over compact self-play records written by crates/hive-selfplay.

Record layout (112 bytes, little-endian) — MUST stay in sync with
crates/hive-nn/src/lib.rs:

  0..84   28 x (x u8, y u8, level u8), absolute PieceId order; x=255 in hand
  84      side to move (0 white, 1 black)
  85      last-moved piece (absolute PieceId, 255 = none)
  86      ply (clamped 255)
  87      game type bits (1=M, 2=L, 4=P)
  88,89   queen liberties (stm, opponent); 255 = queen not placed
  90,91   reserve counts (stm, opponent)
  92..96  pinned bitmask u32 (bit = absolute PieceId)
  96,97   policy target u16
  98      WDL from stm perspective (0 L, 1 D, 2 W)

Plane layout (77 x 32 x 32), all float32 in [0,1]:
  0..63   piece planes: (own=0/opp=32) + bug*4 + min(level,3)
  64      pinned top pieces
  65      last-moved (stunned-relevant) piece cell
  66      stm legal placement cells
  67      opponent legal placement cells
  68      side-to-move-is-white (constant plane)
  69,70   queen liberties (stm, opp) / 6 (constant planes; 0 if unplaced)
  71      ply / 100 (constant plane)
  72..74  game type M, L, P (constant planes)
  75,76   reserve (stm, opp) / 14 (constant planes)
"""

import numpy as np
import torch
from torch.utils.data import Dataset

RECORD_SIZE = 112
FRAME = 32
PLANES = 77
PIECES_PER_COLOR = 14
# Bug type by roster index: Q S S B B G G G A A A M L P
ROSTER_BUG = np.array([0, 1, 1, 2, 2, 3, 3, 3, 4, 4, 4, 5, 6, 7], dtype=np.int64)

# Axial hex neighbor deltas (pointy-top): E, NE, NW, W, SW, SE
HEX_DELTAS = [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)]


class HiveRecordDataset(Dataset):
    def __init__(self, shard_paths: list[str]):
        self.records = np.concatenate(
            [
                np.fromfile(p, dtype=np.uint8).reshape(-1, RECORD_SIZE)
                for p in sorted(shard_paths)
            ]
        )

    def __len__(self) -> int:
        return len(self.records)

    def __getitem__(self, idx: int):
        rec = self.records[idx]
        planes = decode_planes(rec)
        policy = int(rec[96]) | (int(rec[97]) << 8)
        wdl = int(rec[98])
        return (
            torch.from_numpy(planes),
            torch.tensor(policy, dtype=torch.long),
            torch.tensor(wdl, dtype=torch.long),
        )


def decode_planes(rec: np.ndarray) -> np.ndarray:
    planes = np.zeros((PLANES, FRAME, FRAME), dtype=np.float32)
    stm = int(rec[84])  # 0 white, 1 black

    pieces = rec[:84].reshape(28, 3)  # (x, y, level)
    on_board = pieces[:, 0] != 255
    pinned = int.from_bytes(bytes(rec[92:96]), "little")

    # Occupancy / stack tops for placement computation.
    height = np.zeros((FRAME, FRAME), dtype=np.int8)
    top_color = -np.ones((FRAME, FRAME), dtype=np.int8)
    top_level = -np.ones((FRAME, FRAME), dtype=np.int8)

    for pid in range(28):
        if not on_board[pid]:
            continue
        x, y, lvl = int(pieces[pid, 0]), int(pieces[pid, 1]), int(pieces[pid, 2])
        color = 0 if pid < PIECES_PER_COLOR else 1
        own = 0 if color == stm else 1
        bug = int(ROSTER_BUG[pid % PIECES_PER_COLOR])
        planes[own * 32 + bug * 4 + min(lvl, 3), y, x] = 1.0
        if pinned >> pid & 1:
            planes[64, y, x] = 1.0
        height[y, x] += 1
        if lvl > top_level[y, x]:
            top_level[y, x] = lvl
            top_color[y, x] = color

    last_moved = int(rec[85])
    if last_moved != 255 and on_board[last_moved]:
        x, y = int(pieces[last_moved, 0]), int(pieces[last_moved, 1])
        planes[65, y, x] = 1.0

    # Legal placement cells per color: empty, adjacent to >=1 own top,
    # adjacent to 0 enemy tops. (Early-game special cases ignored: with <2
    # pieces on board these planes are approximate, which is harmless.)
    occupied = height > 0
    adj = {0: np.zeros_like(occupied), 1: np.zeros_like(occupied)}
    for color in (0, 1):
        mask = (top_color == color) & occupied
        for dx, dy in HEX_DELTAS:
            adj[color] |= np.roll(np.roll(mask, dy, axis=0), dx, axis=1)
    for own_slot, color in ((66, stm), (67, 1 - stm)):
        placeable = adj[color] & ~adj[1 - color] & ~occupied
        planes[own_slot] = placeable.astype(np.float32)

    planes[68] = 1.0 if stm == 0 else 0.0
    for slot, byte in ((69, 88), (70, 89)):
        libs = int(rec[byte])
        planes[slot] = 0.0 if libs == 255 else libs / 6.0
    planes[71] = int(rec[86]) / 100.0
    gt = int(rec[87])
    planes[72] = float(gt & 1)
    planes[73] = float(gt >> 1 & 1)
    planes[74] = float(gt >> 2 & 1)
    planes[75] = int(rec[90]) / 14.0
    planes[76] = int(rec[91]) / 14.0
    return planes


if __name__ == "__main__":
    import glob
    import sys

    paths = glob.glob(sys.argv[1] if len(sys.argv) > 1 else "/tmp/hive_smoke/run-*.bin")
    ds = HiveRecordDataset(paths)
    planes, policy, wdl = ds[0]
    print(f"{len(ds)} records; planes {tuple(planes.shape)}, policy {policy}, wdl {wdl}")
    assert planes.shape == (PLANES, FRAME, FRAME)
    # Sanity: some piece planes are set, policy in range.
    assert planes[:64].sum() > 0
    assert 0 <= int(policy) <= 28 * FRAME * FRAME
    print("dataset OK")
