```yaml
id:            H2-2026-09-09-throughput-profile-01
date:          2026-09-09
hypothesis:    Measure the four metric families of pipeline H2 task 6
               (legal-moves/s, games/s, game length, search time/decision)
               to (a) propose simulation budgets, (b) propose the truncation
               cap, (c) settle PyO3 vs subprocess/UHP. The plan's 64/128
               sims are placeholders to be checked, not assumed.
git_commit:    08459b0
config:        commands inline below (existing binaries; no code changed)
seeds:         AB profiling seed 20260909; distribution seeds 1001-1030;
               MCTS seed 20260909
data_version:  gen-19 checkpoint models/best-b1.onnx / best-b128.onnx (D-003
               prior work, used only as a realistic inference workload)
hardware:      Apple M1 Pro, 10 cores, 16 GB RAM, macOS 15.3.1; release
               builds; python/.venv onnxruntime for EP comparisons
duration:      ~45 min of measurements total
cost:          0
```

## Methods

Short profiling runs on existing binaries (G-SPEND note: short runs in
scope). Alpha-beta workload = the engine's own `bench` fixed positions and
the bootstrap generator at depth 4. NN workload = the preserved gen-19
checkpoint through onnxruntime (Python) and the Rust MCTS generator.
Subprocess overhead = timed UHP round-trips from Python. Phases: `bench`
distinguishes opening/midgame; endgame not separately benchmarked (limit).

## Raw results + uncertainty

**Movegen (perft, release):** Base perft(5) 516,240 nodes in 1.36 ms ≈
380 MN/s; perft(6) 12.2 M nodes in 26.5 ms ≈ 461 MN/s. Legal-move
generation is nowhere near a bottleneck.

**Alpha-beta search (`bench`):** opening-base depth 10: 7.20 Mnps;
midgame-base depth 8: 4.67 Mnps (MLP variants 5.42/4.05 Mnps). Depth-4
decisions in the bootstrap generator cost ~40 ms single-thread (from
single-game timings below).

**Full games, alpha-beta depth 4 (`selfplay`, 6 threads, 100 games, seed
20260909):** 22 s wall → 4.6 games/s; 4,397 recorded positions; result mix
45 W / 13 D / 42 B (NB: this binary counts 300-ply truncations as draws —
see Failures).

**Game-length distribution (30 single-seed games, depth 4, seeds
1001-1030, plies incl. 6 random opening plies):** sorted
27,31,31,31,31,31,32,33,35,35,36,36,36,37,39,39,41,43,44,45,46,46,56,61,
61,63,80,143,180,202. Mean 55.0, median 39, p90 = 80, max 202; **zero
games reached the 300-ply cap**. (Depth-4 self-play; MCTS-with-temperature
games may differ — cross-checked against the MCTS run below.)

**NN inference (gen-19 net, 77×32×32 input):**

| Path | ms/eval | evals/s |
| --- | --- | --- |
| Python onnxruntime, CPU EP, batch 1 | 23.5 | 43 |
| Python onnxruntime, CPU EP, batch 128 | 11.9/pos | 84 |
| Python onnxruntime, **CoreML EP**, batch 1 | **2.62** | **382** |
| Rust `ort` (hive-mcts), CoreML EP | **crashes** (see Failures) | — |

**MCTS end-to-end (Rust generator, CPU EP fallback, 600/150 sims,
full-frac 0.25, resignation on, 4 game threads, seed 20260909):** 8 games
in 638 s wall (~808% CPU incl. ort intra-op threads) → **80 s/game wall ≈
320 thread-seconds/game**; 6/8 games ended by resignation; sample
non-resigned game 96 plies; 104 recorded (full-sim) positions. Anchor: the
old loop with a working CoreML path ran ≈75-78 s/game at 2 threads (≈150
thread-s/game) at the same 600/150 budget — the CPU fallback is ≈2× slower
per thread end-to-end (less than the 9× raw-inference gap thanks to
resignation, the cheap-sim fraction, and intra-op parallelism).

**UHP subprocess round-trip (Python ↔ `hive-engine`):** validmoves 21.7
µs/request (46,051 req/s); play+undo pair 21.6 µs. Overhead is ≤0.01% of
any NN-MCTS decision (hundreds of ms) and ~0.05% of a 40 ms depth-4
decision.

## Failures

1. **Rust CoreML EP crash (finding, not fixed):** `selfplay-mcts` with the
   default CoreML EP panics in `ort_eval.rs:76` ("Unable to compute the
   prediction using a neural network model", CoreML error -1) on this
   machine, while Python onnxruntime runs the same model on CoreML at 2.62
   ms/eval (with 55/64 nodes CoreML-supported, 5 partitions). The prior RL
   loop's ~75 s/game at 600/150 sims is consistent with a then-working
   fast path. Suspected `ort`-crate/runtime version drift. Fix belongs to
   H4 (pipeline build); measured stakes: ~9× inference throughput.
2. **Truncation counted as draw in prior generators (invariant 7 / D-008
   violation in prior-work code):** both `selfplay` (main.rs:86-95) and
   `selfplay-mcts` (selfplay_mcts.rs:156,192) cap at 300 plies and map the
   cap to `GameResult::Draw`; internal MCTS rollouts cap at 120
   (hive-mcts/src/lib.rs:459). Recorded as a mandatory H4 fix: the new
   study's generation and evaluation code must carry a distinct truncation
   outcome. Not silently fixed here (prior work, D-003; invariant 2).

## Limits / confounders

- NN numbers use the gen-19 checkpoint as a workload proxy; the new
  study's nets (grid arm, GNN arm) will differ in cost — re-measure at H4.
- Endgame positions not separately benchmarked (bench covers
  opening/midgame); game-length distribution is depth-4 alpha-beta, one
  config, 30 seeds.
- CoreML multi-thread contention (ANE serialization) unmeasured.
- Single machine; wall-clock figures are machine-specific by design (the
  protocol reports hardware with every run).

## Interpretation

(a) **Simulation budgets:** with CoreML restored, 2.62 ms/eval puts a
128-sim decision at ≈0.34 s and a 64-sim decision at ≈0.17 s single-thread
— the plan's 64/128 placeholders are feasible (≈10-20 s/game, tens of
thousands of games per arm within the ch. 16 envelope). CPU-only, the same
budgets cost ≈9× more (1.5-3 s/decision, ≈3-5 min/game/thread), which
would strain the same-wall-clock budget reading badly. Proposal (derived
from measurement — still a proposal until the pilot): fix the CoreML EP in
H4, then adopt full/cheap = 128/32 with playout-cap randomization
(KataGo-style, already implemented); fall back to 64/16 if the pilot's
wall-clock demands it.
(b) **Truncation cap:** measured lengths (median 39, p90 80, max 202 at
depth 4; MCTS addendum below) support a cap of **300 plies** for self-play
— beyond the observed maximum yet bounded — with truncation counted as its
own outcome (D-008), never draw. The H1 freeze consumes this value.
(c) **Binding layer:** subprocess/UHP at 21.7 µs/round-trip is three to
four orders of magnitude below per-decision costs, and the heavy loop
(self-play generation) lives entirely in Rust anyway. PyO3 adds build
complexity for no measured gain → decision D-010.

## Decision

**continue** — decisions D-010 (binding layer) and D-011 (budget + cap
proposals) appended to `state/decisions.md`; protocol draft updated with
the measured values as labeled proposals pending the freeze.

## Artifacts

- Commands inline above (reproducible against commit 08459b0 + fetched
  opponents + `python/.venv`).
- Scratch outputs (regenerable, not kept): profiling shards under the
  session scratchpad.
- Checkpoint used: `models/best-b1.onnx`, `models/best-b128.onnx` (gen 19).
