#!/usr/bin/env python
"""Cross-language golden test: Rust graph encoder vs Python builder (D-022c).

Run: ./target/release/dump_graph /tmp/hive_graph.bin
     python/.venv/bin/python scripts/crosscheck_graph.py /tmp/hive_graph.bin
"""

import sys

import numpy as np

sys.path.insert(0, "python")
from hivenet.graph_dataset import (  # noqa: E402
    GLOBAL_F,
    MOVE_CAP,
    NODE_CAP,
    NODE_F,
    build_graph,
)

REC = 818
NODES_B = NODE_CAP * NODE_F * 4
NBRS_B = NODE_CAP * 6 * 8
GLOB_B = GLOBAL_F * 4
MOVES_B = MOVE_CAP * 3 * 8
PAIR = REC + NODES_B + NBRS_B + NODE_CAP + GLOB_B + MOVES_B + MOVE_CAP

path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/hive_graph.bin"
blob = open(path, "rb").read()
assert len(blob) % PAIR == 0, f"file size {len(blob)} not a multiple of {PAIR}"

n = len(blob) // PAIR
for i in range(n):
    off = i * PAIR
    rec = np.frombuffer(blob, np.uint8, REC, off)
    off += REC
    r_nodes = np.frombuffer(blob, "<f4", NODE_CAP * NODE_F, off).reshape(NODE_CAP, NODE_F)
    off += NODES_B
    r_nbrs = np.frombuffer(blob, "<i8", NODE_CAP * 6, off).reshape(NODE_CAP, 6)
    off += NBRS_B
    r_nmask = np.frombuffer(blob, np.uint8, NODE_CAP, off).astype(bool)
    off += NODE_CAP
    r_glob = np.frombuffer(blob, "<f4", GLOBAL_F, off)
    off += GLOB_B
    r_moves = np.frombuffer(blob, "<i8", MOVE_CAP * 3, off).reshape(MOVE_CAP, 3)
    off += MOVES_B
    r_mmask = np.frombuffer(blob, np.uint8, MOVE_CAP, off).astype(bool)

    nodes, nbrs, nmask, glob, moves, mmask, target = build_graph(rec)
    for name, a, b in [
        ("nodes", r_nodes, nodes),
        ("nbrs", r_nbrs, nbrs),
        ("nmask", r_nmask, nmask),
        ("glob", r_glob, glob),
        ("moves", r_moves, moves),
        ("mmask", r_mmask, mmask),
    ]:
        if not np.array_equal(a, b):
            bad = np.argwhere(a != b)[:5]
            sys.exit(
                f"MISMATCH position {i} tensor {name} at {bad.tolist()}: "
                f"rust {a[tuple(bad[0])]} vs python {b[tuple(bad[0])]}"
            )

print(f"PASS: {n} positions, Rust and Python graph encoders agree exactly")
