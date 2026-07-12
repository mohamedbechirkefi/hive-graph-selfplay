#!/usr/bin/env python
"""Cross-language golden test: Rust plane encoder vs Python decoder.

Run: ./target/release/dump_planes /tmp/hive_planes.bin
     python/.venv/bin/python scripts/crosscheck_planes.py /tmp/hive_planes.bin
"""

import sys

import numpy as np

sys.path.insert(0, "python")
from hivenet.dataset import FRAME, PLANES, RECORD_SIZE, decode_planes  # noqa: E402

PLANES_BYTES = PLANES * FRAME * FRAME * 4
PAIR = RECORD_SIZE + PLANES_BYTES

path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/hive_planes.bin"
blob = open(path, "rb").read()
assert len(blob) % PAIR == 0, f"file size {len(blob)} not a multiple of {PAIR}"
n = len(blob) // PAIR

bad = 0
for i in range(n):
    chunk = blob[i * PAIR : (i + 1) * PAIR]
    rec = np.frombuffer(chunk[:RECORD_SIZE], dtype=np.uint8)
    rust = np.frombuffer(chunk[RECORD_SIZE:], dtype=np.float32).reshape(PLANES, FRAME, FRAME)
    py = decode_planes(rec)
    if not np.array_equal(rust, py):
        bad += 1
        diff = np.argwhere(rust != py)
        print(f"MISMATCH at position {i}: {len(diff)} cells, first {diff[0]} "
              f"(rust {rust[tuple(diff[0])]}, py {py[tuple(diff[0])]})")
        if bad > 3:
            break

if bad:
    sys.exit(f"FAIL: {bad}+ mismatching positions out of {n}")
print(f"PASS: {n} positions, Rust and Python plane encoders agree exactly")
