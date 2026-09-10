# Comparability controls — grid vs graph arms (H5 task 7)

Measured 2026-09-10 on the study machine (Apple M1 Pro, 10 cores, 16 GB,
macOS 15.3.1; torch/MPS, onnxruntime with CPU and CoreML providers).
Journal: H5-2026-09-10-encoders-01. Both arms feed the identical D-015
decoder and identical rules/search; the numbers below are the *only*
intended differences plus their measured costs (plan ch. 6 binding
table: capacity close or difference reported; wall-clock, hardware,
states and simulations reported; throughput per-example AND per-second
for H6's two budget readings).

## Capacity

| Arm | Architecture | Parameters |
| --- | --- | --- |
| Grid | HiveNet c96×b8 (ResNet, 28,673-way flat head) | 1.44 M |
| Graph | HiveGraphNet h152×L8 (6-relation MP, per-candidate head) | 1.47 M (+2.1%) |

## Inference (per decision-eval, batch 1)

| Path | Grid | Graph |
| --- | --- | --- |
| torch CPU | 11.03 ms | 10.51 ms |
| ONNX ORT CPU | 23.5 ms | **3.67 ms** |
| ONNX ORT CoreML | **2.62 ms** | 9.84 ms (147/287 nodes supported, 15 partitions — gather-heavy graph ops fall back) |
| **Best available** | **2.62 ms (CoreML)** | **3.67 ms (CPU)** |

The self-play/eval cost ratio at best-provider settings is ≈1.4× against
the graph arm per evaluation. This is a real hardware-interaction
difference and is REPORTED, not equalised away: the same-wall-clock
budget reading (protocol §5) will charge each arm its true cost on this
machine; the same-examples reading is unaffected.

## Training throughput (batch 128, fwd+bwd, matched conditions)

| Path | Grid | Graph |
| --- | --- | --- |
| torch CPU (fwd only) | 138 pos/s | 478 pos/s |
| torch MPS (fwd+bwd) | 274 pos/s | 138 pos/s |

Cross-pattern: the graph arm is ~3.5× faster per position on CPU and ~2×
slower on MPS (gather/scatter cost). Training runs on MPS; generation
dominates wall-clock either way (H4 pilot: training ≈3.5 min vs
generation ≈60 min per gen-0 generation).

## Identity of everything else

Rules and search: same engine, same MCTS, same pinned eval settings
(D-019). Data protocol: same v3 records, same targets, same
truncation-exclusion value rule, same legal-masked normalisation (the
grid arm masks a flat tensor; the graph arm scores only legal rows —
identical distributions over identical legal sets). Hyperparameter
budget: neither arm has had any tuning beyond capacity matching; any
future search applies the same budget to both (plan ch. 6). Opponents
and eval settings: frozen (D-017, D-019).

## Known open items before H6

Rust-side graph builder + `dump_graph` golden crosscheck (D-022c) and
graph-arm wiring into the Rust MCTS evaluator; graph-arm training-loop
integration mirroring `train.py`. Until those land, the graph arm
trains/checks in Python only and cannot be evaluated in the arena.
