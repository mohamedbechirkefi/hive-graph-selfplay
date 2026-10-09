# Frozen constants, hyperparameters, seeds and configurations {#sec:app-c}

Every value in this appendix is the one the campaigns actually ran; the configuration and manifest files kept with each run are authoritative, and nothing here is a recommendation. Dates are those of the author's approval or of the mechanical computation that fixed a value; `@sec:app-e`{=typst} indexes the corresponding records, and `@sec:protocol`{=typst} explains why each value was fixed when it was.

## Frozen constants {#sec:app-c-constants}

| Constant | Value | Fixed on (2026) | Approved by |
| --- | --- | --- | --- |
| Game variant | base game (queen, spider, beetle, grasshopper, ant), tournament opening rule; expansions outside the perimeter | 9 Sep (scope); frozen in the protocol 10 Sep | the author |
| Move cap and truncation | 300 plies; a truncated game is its own outcome, never a draw; rate reported separately | 9 Sep (convention and measured value); frozen 10 Sep | the author |
| Self-play search budget | 128 full / 32 cheap simulations per decision; full fraction 0.25 | 10 Sep (protocol) | the author |
| Self-play exploration | temperature sampling for 12 plies; Dirichlet root noise ε = 0.25; resignation at −0.92 with a 10% no-resign audit | 10 Sep (pre-registered matrix) | the author |
| Evaluation search | 400 simulations per decision; no root noise; deterministic argmax | 9 Sep | the author |
| Evaluation volume | 100 paired games per opponent at final and cutoff checkpoints; 20 per opponent at generations 4 and 7 | 10 Sep; confirmed unchanged 16 Sep | the author |
| Opponent population | B-RND (legal-random), B-HEU (heuristic, weights hash-pinned), B-MCTS (search, 6,400 simulations); prior checkpoint excluded | 9 Sep | the author |
| Openings | 250 unique legal 4-ply openings; generator seed 20260910; pair *i* plays line *i* with both colours | 10 Sep | the author |
| Equal-time cutoff | 18.77 h = median total wall-clock of the three original grid runs; rule in the matrix | rule 10 Sep; value 16 Sep | rule: the author; value: computed mechanically |
| Training seeds | 1–3 per arm; 4–5 added under three written pre-commitments | 10 Sep; extension 26 Sep | the author |
| Protocol document | version 1.0; any later change is a new study | 10 Sep | the author |

Table: Frozen experimental constants with the date each was fixed and the approval under which it was fixed. No constant was changed after its date. {#tbl:app-c-frozen}
<!-- src: paper/annex-reproduction.md:7-19; configs/comparison-matrix.yaml:27-59; configs/eval-settings.toml:10-17; paper/annex-architectures.md:87-92; ../state/decisions.md:499-521, 572-591, 605-618, 763-771, 795-806, 823-849, 946-956; journal/2026-09-16-h6-progress-01.md:36-37 -->

Frozen artifacts are identified by content hash (`@tbl:app-c-hashes`{=typst}). The protocol file carried its hash at the freeze and carries it unchanged; the openings hash covers the 250 opening lines independently of the file header; the heuristic weights are additionally pinned by an automated test that fails if any weight changes.

| Artifact | SHA-256 |
| --- | --- |
| Protocol, version 1.0 | f340a6b64db0f5f0bf126ffb251c3de339450bde192fd54b719036a8a3aefeb5 |
| Openings, content (250 lines) | 63b318d071dfc3ecfae3585636c8e6f7327ddc08e7aed86a466f915f8005af7b |
| Heuristic weights (B-HEU) | d0602f1895fbed70b6f84ac2a3eb87bd68e811e53acf24d4d7814a1495b0b97a |
| B-RND configuration | f2fc4a06441d3c1a7922838a6693dbb48ec54543bc34fd814d41c9a742514cd7 |
| B-HEU configuration | 7210a0a349c5bad5dcd2df099cc6865ee3cb5d8a2c30e106ce58137804818999 |
| B-MCTS configuration | 3fc8f75cf2b4f21012dd61e9924408fbfc32c8ea561aa96eb44f1091ba07364e |

Table: Content hashes of the frozen artifacts; these are the scientific identifiers of the protocol, the openings and the opponent population. {#tbl:app-c-hashes}
<!-- src: ../state/decisions.md:606-607, 766-769; results/comparison/opponents-manifest.md:10-17, 34-35; docs/baselines.md:27-30 -->

## Training hyperparameters {#sec:app-c-hyper}

The training loop and every hyperparameter are identical for both arms and for all ablation variants, with the single exception noted in the last row.

| Hyperparameter | Value (both arms) |
| --- | --- |
| Optimizer | SGD, momentum 0.9, weight decay 1e-4 |
| Learning rate | 0.02, cosine-annealed to lr/100 over each generation's steps |
| Batch size | 256 |
| Epochs per generation | 2 |
| Policy loss | cross-entropy against the MCTS visit distribution, softmax over exactly the legal move set |
| Value loss | win/draw/loss from the side to move, weight 0.6; truncated records excluded |
| Training data per generation | the generation's 500 self-play games; only full-budget (128-simulation) decisions are recorded |
| Gradient clipping | none, except in the A1′ supplement (global norm 1.0) |
| Hyperparameter search | none, for either arm |

Table: Training hyperparameters, identical for the grid arm, the graph arm and the ablation variants; the gradient clip of the A1′ supplement is the only optimizer change in the study. {#tbl:app-c-hyper}
<!-- src: paper/annex-reproduction.md:21-31; configs/comparison-matrix.yaml:36-40; paper/annex-architectures.md:87-92 -->

## Seed derivation {#sec:app-c-seeds}

Every random choice in the study descends from a recorded seed, so that a run, an evaluation set or a bootstrap interval regenerates identically.

| Quantity | Seed |
| --- | --- |
| Training run (arm, seed *s*) | base seed = 100,000 × *s*; seed spaces disjoint across runs |
| Generation *g* (0–9) | self-play seed = base + *g*; training seed = base + *g* |
| Generation-0 network | seeded random initialisation with the base seed, exported before any self-play |
| Network under evaluation | 9000 + *g* for in-run evaluations (generations 4, 7 and 9); 9500 for cutoff-checkpoint sets |
| Opponents | B-RND 9101; B-MCTS 9201; B-HEU deterministic (no seed) |
| Match runner | 777,000 + *g* for in-run evaluations; 888,000 for cutoff sets; with fixed openings the opening/colour schedule is seed-independent (schedule hash 8cd84b6564440666 reproduced across runs with different agents and match seeds) |
| Opening generator | 20260910 |
| Bootstrap | fixed resampling seed; 10,000 resamples |

Table: Derivation of every seed used in training, evaluation and analysis. {#tbl:app-c-seeds}
<!-- src: paper/annex-reproduction.md:33-41; ../state/decisions.md:948; results/comparison/opponents-manifest.md:39-44; journal/2026-09-19-h6-comparison-01.md:39; scripts/run_comparison.py:86, 148, 155; scripts/tstar_evals.sh:24-26 -->

## Configuration of each arm and variant {#sec:app-c-configs}

All five configurations share the frozen constants of `@tbl:app-c-frozen`{=typst} and the hyperparameters of `@tbl:app-c-hyper`{=typst}; they differ only as stated in the table. Parameter counts are exact counts from the instantiated models; the +1.5% capacity difference between the arms is the exact ratio. Capacity differences in the ablation variants are inherent to the removed component and are reported rather than equalised.
<!-- src: results/comparison/parameter-counts.md:1-12 -->

| Variant | Body | Parameters | Difference from the full graph arm | Seeds | Inference provider |
| --- | --- | ---: | --- | --- | --- |
| Grid arm | residual CNN, 96 channels × 8 blocks, over 77 planes × 32 × 32 | 1,443,168 | not applicable (the other arm) | 1–5 | CoreML |
| Graph arm (full method) | relational message passing, 152 hidden × 8 layers, slot embedding 32, node capacity 224, six direction-typed relations, global-pooling bias | 1,465,452 (+1.5%) | reference | 1–5 | CPU |
| A1 (naive adjacency) | one shared edge matrix in place of the six direction-typed matrices | 541,292 (−62.5%) | edge typing removed | 1–3 | CPU |
| A2 (no global pooling) | global-pooling bias removed from every layer | 1,372,732 (−4.9%) | pooling removed | 1–3 | CPU |
| A1′ (supplement) | as A1 plus global gradient-norm clip 1.0 | as A1 | two components: edge typing removed and clip added | 1–3 | CPU |

Table: Configuration of the two arms and the three ablation variants, with exact parameter counts and the difference relative to the grid arm in parentheses. Everything not listed is identical across the five rows. The inference provider is the measured best available per arm on the study machine. {#tbl:app-c-configs}
<!-- src: results/comparison/parameter-counts.md:5-10; configs/comparison-matrix.yaml:13-25; paper/annex-architectures.md:8-10, 28-33, 54-56; configs/ablations/A1-edge-typing.md:10-13; configs/ablations/A2-global-pooling.md:9-10; configs/ablations/A1prime-edge-typing-clipped.md:1-11 -->

## Measured machine profile {#sec:app-c-machine}

All wall-clock figures in this report were measured on one Apple M1 Pro (10 cores, 16 GB, macOS 15.3.1), with 4 worker threads per run, runs executed sequentially and the machine kept awake. The inference provider used for each arm's self-play and evaluation is the measured best available on this machine; the graph network's gather-heavy operations are only partly supported by the accelerator (147 of 287 nodes, 15 partitions), which is why its CPU path wins.
<!-- src: docs/representations/comparison-controls.md:1-10, 19-27 -->

| Path (batch 1, per decision-evaluation) | Grid | Graph |
| --- | ---: | ---: |
| PyTorch, CPU | 11.03 ms | 10.51 ms |
| ONNX, CPU provider | 23.5 ms | 3.67 ms |
| ONNX, CoreML provider | 2.62 ms | 9.84 ms |
| Best available (used) | 2.62 ms (CoreML) | 3.67 ms (CPU) |

Table: Inference cost per network evaluation on the study machine, measured on 10 September 2026; the best available path per arm is the one used in self-play and evaluation. {#tbl:app-c-inference}
<!-- src: docs/representations/comparison-controls.md:19-27 -->

Training throughput was benchmarked on 10 September 2026 at batch 128, forward and backward, on the machine's GPU backend: 274 positions/s for the grid network and 138 positions/s for the graph network (forward-only on the CPU: 138 and 478 positions/s; the graph network is faster per position on the CPU and slower on the GPU). The campaign runs loaded their data in-process and trained at or below these figures; generation, not training, dominates a generation's wall-clock in either arm. Per-run training wall-clock (self-play, training and export over 10 generations × 500 games, evaluation games excluded) was 16.7–19.1 h for grid runs and 26.6–49.9 h for graph runs, with means of 18.0 h and 36.7 h (per-seed values in `@tbl:d-wallclock`{=typst}). An evaluation game at 400 simulations took ≈23–32 s; the search opponent at 6,400 simulations decides in ≈27 ms single-threaded; a subprocess round-trip to the engine costs 21.7 µs. Disk use was estimated at ≈3–5 GB per three-seed campaign against a 20 GB free-space guard.
<!-- src: docs/representations/comparison-controls.md:34-44; results/comparison/wallclock-per-run.md:3-8; scripts/run_comparison.py:126-129; paper/annex-reproduction.md:70-75; docs/baselines.md:54-56; journal/2026-09-09-throughput-profile-01.md:72-73; journal/2026-09-10-h6-matrix-01.md:50-55; configs/comparison-matrix.yaml:62 -->
