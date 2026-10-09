# Annex C — Hyperparameters, seeds, commands: full reproduction sheet

*Every value below is the one the campaigns actually ran (per-run
`train-config.json` and `*-manifest.json` files are authoritative);
nothing here is a recommendation.*

## C.1 Frozen experimental constants

| Constant | Value | Frozen by |
| --- | --- | --- |
| Variant | base game, tournament opening rule | D-007 / protocol v1.0 |
| Move cap | 300 plies; truncation = own outcome | D-008/D-011 / protocol §3 |
| Self-play sims (full/cheap) | 128 / 32, full-frac 0.25 | protocol §5 |
| Temperature plies / resign / audit | 12 / −0.92 / 10% | matrix (pre-registered) |
| Eval sims / noise / volume | 400 / none / 100 games/opponent | D-019, D-027 |
| Opponent population | B-RND, B-HEU (weights sha256 d0602f18…0b97a), B-MCTS@6400 | D-017 |
| Openings | 250 × 4-ply, content sha256 63b318d0…5af7b | D-025 |
| T\* (same-wall-clock cutoff) | 18.77 h (median of grid s1–s3 totals) | pre-registered rule, computed 2026-09-16 |
| Seeds | 1–5 per arm (4–5 added under pre-commitment) | D-026 / D-031 |

## C.2 Training hyperparameters (identical both arms)

SGD, lr 0.02 cosine-annealed to lr/100 over the run, momentum 0.9,
weight decay 1e-4, batch 256, 2 epochs per generation, value-loss
weight 0.6, legal-masked policy cross-entropy against MCTS visit
distributions, truncated records excluded from the value loss.
Grid: channels 96 × blocks 8. Graph: hidden 152 × layers 8, slot
embedding 32. No hyperparameter search was performed for either arm
(same zero tuning budget, plan ch. 6); the only post-hoc optimizer
change in the whole study is the gradient clip of the explicitly
two-component A1′ supplement.

## C.3 Seed derivation

Training run (arm, seed): base_seed = 100,000 × seed; generation g uses
base_seed + g for self-play and training; the gen-0 network is a
seeded random initialisation exported to ONNX (torch.manual_seed =
base_seed). Evaluation: network seed 9000+gen (finals) / 9500 (T\*
sets), opponent seeds 9101 (B-RND) and 9201 (B-MCTS), arena seeds as
logged; with fixed openings the schedule is seed-independent (proven by
schedule-hash test).

## C.4 Commands

```sh
# one training run of the matrix (resumable per generation)
python3 scripts/run_comparison.py --arm grid  --seed 1 --gens 10 --games 500
python3 scripts/run_comparison.py --arm graph --seed 1 --gens 10 --games 500
# ablations: --arm graph-untyped | graph-nogpool | graph-untyped-clip

# regenerate every table and figure from raw per-game records
python3 scripts/make_results.py
python/.venv/bin/python scripts/make_figures.py

# pre-training check battery on any shard set
bash scripts/run_h4_checks.sh '<abs>/gen000-*.bin' '<abs>/gen000-manifest.json'

# fresh-environment minimal reproduction (clone, build, replay, compare)
bash scripts/reproduce_minimal.sh /tmp/repro

# booklet (assembly -> HTML -> PDF)
python3 scripts/assemble_booklet.py && bash scripts/make_booklet_pdf.sh

# French/English numeric-identity check
python3 scripts/check_fr_numbers.py
```

## C.5 Measured machine profile (all wall-clock figures)

Apple M1 Pro (10 cores, 16 GB, macOS 15.3.1); 4 worker threads per run,
runs sequential under `caffeinate`. Inference: grid CoreML 2.62
ms/eval, graph CPU 3.67 ms/eval (CoreML slower for the gather-heavy
graph net — measured, reported, charged). Training throughput
benchmark on MPS (batch 128, forward+backward): 274 (grid) / 138
(graph) pos/s. Training wall-clock per 10 × 500-game run (self-play
generation + training, evaluation excluded): grid 16.7–19.1 h, graph
26.6–49.9 h; evaluation ≈23–32 s/game at 400 sims.

## C.6 Journal and decision index for this study

Protocol and freezes: D-007/008/011/012/017/019/020/025. Campaigns:
D-026 (main), D-029 (ablations), D-030 (A1′), D-031 (5-seed extension
with pre-commitments). Analysis journals: H6-2026-09-19-comparison-01
(3-seed), H6-2026-10-09-5seed-final-01 (final), H7-2026-09-23 /
10-02 / 10-09 (A1, A2, A1′). Engine validation: H2-2026-09-09 set.
Every table cell in this booklet is reachable from one of these.
