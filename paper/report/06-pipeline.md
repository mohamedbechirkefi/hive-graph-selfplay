# The self-play learning pipeline {#sec:pipeline}

Both arms of the comparison are trained and evaluated by one pipeline, built in September 2026 on top of the engine of `@sec:engine`{=typst}. It is deliberately ordinary, an AlphaZero-style loop in the sense of Silver et al. (2018) with the compute-saving devices of Wu (2020), since its only requirement is to be identical for the two arms. The search that generates games, the record that stores them, the loss, the export path, the evaluation arena and the automated checks are all shared; only the state encoder and the network body (`@sec:representations`{=typst}) differ between the grid arm and the graph arm. `@fig:pipeline`{=typst} gives the overview; the sections below describe each stage, then the pilot of 10 September 2026 that validated the loop end to end, and the one harness defect it caught.

![The generation loop shared by both arms. Self-play with Monte-Carlo tree search produces training records; the records train a network; the network is exported to ONNX and drives the next generation's self-play; at fixed generations the exported network is evaluated against the frozen opponent population (B-RND, B-HEU, B-MCTS) on frozen openings. The grid arm and the graph arm differ only in the state encoder and the network body inside the boxes marked "network".](figures/fig8-pipeline.png){#fig:pipeline width=90%}

## The generation loop

A training run is identified by an arm and a seed. The generation-0 network is a seeded random initialisation, exported to ONNX before any game is played; the base seed of run $s$ is $100{,}000 \times s$, and generation $g$ uses base seed $+\,g$ for both self-play and training, so no two runs share a random stream. In the configuration under which all study runs executed, a run comprises 10 generations of 500 self-play games each, with four worker threads, on one machine. <!-- src: paper/annex-reproduction.md:33-41 --> <!-- src: configs/comparison-matrix.yaml:42-51 --> <!-- src: paper/annex-reproduction.md:70-71 -->

Each generation proceeds as in the pseudo-code below. The current network plays the generation's games against itself; the positions searched at the full simulation budget become records, stamped with the generation number and a hash of the generating network. A network is trained on those records, exported, and becomes the current network; a checkpoint is kept at every generation so that the same-wall-clock reading (`@sec:protocol`{=typst}) can later select the last checkpoint completed before the equal-time cutoff. Generations are numbered 1 to 10 throughout this report; the run logs and the pseudo-code below count them from 0. After the fifth and the eighth generation, and after the tenth and last, the exported network is evaluated against the frozen opponent population. The driver passes neither a warm-start nor a resume checkpoint to the trainer: the network of generation $g$ is a fresh seeded initialisation trained for two epochs on the records of generation $g$ alone, which were produced by the network of generation $g-1$ (by the random initialisation when $g = 0$). There is no replay window across generations. <!-- src: scripts/run_comparison.py:108-162 --> <!-- src: python/hivenet/train.py:92-123 -->

```
run(arm, seed s):
    θ ← seeded random initialisation (base seed 100,000 × s), exported to ONNX
    for g in 0 … 9:
        D_g ← SELF-PLAY(θ, 500 games; seed base + g)
                 128 / 32 simulations, 25 % of decisions at 128 (recorded)
                 Dirichlet root noise ε = 0.25; visit-proportional sampling for 12 plies
                 resign below −0.92 (10 % of games never resign); truncate at 300 plies
        θ ← TRAIN(fresh seeded initialisation, D_g; seed base + g)
                 2 epochs, batch 256, SGD lr 0.02 (cosine), momentum 0.9, wd 1e-4
                 loss = masked policy cross-entropy + 0.6 × value cross-entropy
                 (truncated records excluded from the value term)
        EXPORT(θ) → ONNX, static shapes; checkpoint kept; wall-clock of g logged
        if g ∈ {4, 7} or g = 9:
            EVALUATE(θ) vs B-RND, B-HEU, B-MCTS on the frozen openings
                 400 simulations, no noise, argmax; 20 games/opponent (g ∈ {4, 7}), 100 (g = 9)
```

The seven-check battery of `@sec:pipeline-checks`{=typst} is a separate command run against real shards. The pilot driver ran it after every generation's self-play; the campaign driver that executed the frozen matrix did not re-run it per generation, relying on the battery having passed on real shards and on the engine-side tests that run with every build. <!-- src: scripts/run_pilot.py:75-76 --> <!-- src: scripts/run_comparison.py:108-139 -->

## Self-play workers and search settings

Self-play runs entirely in the Rust engine; the Python side never sits in a per-move loop and receives its data as binary shard files. The search is PUCT Monte-Carlo tree search with exploration constant $c = 1.4$, batched leaf evaluation and exact back-up of terminal values. Four devices, applied identically to both arms, shape the games into training data. <!-- src: paper/annex-architectures.md:85-92 -->

*Playout-cap randomization* (Wu, 2020). Each decision is searched at the full budget of 128 simulations with probability 0.25 and at the cheap budget of 32 simulations otherwise; only the full-budget decisions are recorded. The device trades policy-target quality on a quarter of the moves for many more games per hour, which is what the value head needs. The 128/32 pair was not taken from the research plan: it was measured on the study machine after the CoreML execution provider was restored on 9 September 2026 and confirmed with a study-scale network in the pilot. <!-- src: paper/annex-architectures.md:88-90 --> <!-- src: docs/protocol.md:112-119 -->

*Exploration.* Dirichlet noise with $\varepsilon = 0.25$ is mixed into the root prior, and for the first 12 plies the move is sampled in proportion to the root visit counts; from ply 12 onward the most-visited move is played. The evaluation path carries $\varepsilon = 0$ as its code default and no sampling, a separation enforced by test (check 6 below). <!-- src: paper/annex-architectures.md:88-90 --> <!-- src: crates/hive-selfplay/src/bin/selfplay_mcts.rs:90-91,216-220 --> <!-- src: configs/eval-settings.toml:7-13 -->

*Resignation with audit.* A side resigns when the root value from its perspective falls below $-0.92$; in 10 % of games, drawn at the start of the game, resignation is disabled so that the threshold can be audited against played-out outcomes. <!-- src: configs/comparison-matrix.yaml:32-33 --> <!-- src: crates/hive-selfplay/src/bin/selfplay_mcts.rs:187-190,210-214 -->

*Truncation.* A game that reaches 300 plies without a result is truncated. Truncation is a distinct outcome (the fourth value of the outcome byte) and is never recorded as a draw; the cap sits beyond the longest search-guided game observed during engine profiling (202 plies). Generation-0 play from a random initialisation truncates often (56.7 % of games in the pilot), which the separate category absorbs by design and the protocol's cap-sensitivity procedure exists to probe. <!-- src: docs/protocol.md:55-66 -->

## The training record

Each recorded position is a fixed-length record of 818 bytes (format version 3), written by the generator and read identically by both arms' data loaders. It stores the position in absolute piece coordinates: 28 pieces × (x, y, level), with a sentinel for pieces in hand. Alongside the position it stores the side to move, the last-moved piece (for the stun rule), the ply, the game-type bits, both sides' queen liberties and reserve counts, and the one-hive-pinned bitmask. Any consumer reconstructs the state, its frame and its candidate set exactly from these bytes, so the grid encoder and the graph encoder derive from the same source. <!-- src: paper/annex-architectures.md:70-83 -->

Three fields were added for this study. A *model stamp* (generation number and network hash) in bytes 100–107 answers, for every shard, which network generated it; the check battery asserts that every record's stamp matches the run manifest. The *legal-move index list* (bytes 178–817, capped at 320 entries; the largest branching measured in real play is 213) enables legal-masked training in both arms without re-running move generation. The *outcome byte* takes four values from the perspective of the side to move: 0 loss, 1 draw, 2 win, 3 truncated. The policy target is the search's root visit distribution over the shared action space, stored as its top-15 entries with the total visit count. <!-- src: paper/annex-architectures.md:70-83 --> <!-- src: python/hivenet/checks.py:104-110 --> <!-- src: docs/action-decoder.md:52-68 -->

Records of the prior demonstration loop (versions 1 and 2) carry no stamp and no legal list, and their cap games were labelled as draws; they are not training inputs for the study. Every run keeps three separate trees, for self-play records (the training inputs), checkpoints and evaluation outputs; an audit asserts that no evaluation file is ever referenced by a training configuration (check 7). <!-- src: docs/action-decoder.md:61-64 --> <!-- src: scripts/audit_run.py:1-13 -->

## The training procedure

Training is identical for both arms down to the optimiser state: stochastic gradient descent with learning rate 0.02 cosine-annealed to one hundredth of its initial value over the generation, momentum 0.9, weight decay $10^{-4}$, batch size 256, two epochs per generation, and a value-loss weight of 0.6. One record in fifty is held out as a validation split, on which policy top-1 (masked as in training) and value accuracy (over non-truncated records) are reported after each epoch. No hyperparameter search was performed for either arm. <!-- src: paper/annex-reproduction.md:21-31 --> <!-- src: python/hivenet/train.py:97-109 -->

The loss is the one written out in `@eq:loss`{=typst} of `@sec:background`{=typst}: the cross-entropy between the recorded visit distribution and the network policy over the legal set, plus 0.6 times the three-way outcome cross-entropy, the value term averaged over the batch's non-truncated records only. The policy distribution $p_\theta(\cdot \mid s)$ is normalised over exactly the legal set: the grid arm fills the illegal entries of its flat logit tensor with $-10^{9}$ before the log-softmax, while the graph arm computes logits only for legal (slot, destination) rows, so the two arms produce the same family of distributions over the same legal sets. The value head is a three-way win/draw/loss classifier; a truncated record contributes to the policy term but is excluded from the value term, never trained as a draw. <!-- src: python/hivenet/train.py:40-51 --> <!-- src: python/hivenet/train_graph.py:1-7,29-30 --> <!-- src: docs/representations/comparison-controls.md:46-52 -->

Checkpoints carry the model, optimiser and scheduler state, the step and epoch counters, the random-number state and the run configuration; the per-epoch shuffle is re-seeded from the run seed and the epoch index, so a run resumed from an epoch boundary replays the identical batch order (check 5). One change was made to the loop after the main campaign: on 23 September 2026, after an ablation run had diverged to a non-finite loss and self-played on it silently for ten generations, a guard was added that halts training on a non-finite loss; it leaves every finite computation unchanged. Training throughput was benchmarked on 10 September 2026 at 274 positions/s for the grid network and 138 positions/s for the graph network (batch 128, forward and backward, on the machine's GPU backend); the campaign runs loaded their data in-process rather than through worker processes, so their training phases ran at or below these figures. Generation rather than training dominates a generation's wall-clock in either arm. <!-- src: python/hivenet/train.py:54-68,129-136,155-161 --> <!-- src: docs/representations/comparison-controls.md:34-44 --> <!-- src: scripts/run_comparison.py:126-129 -->

## Export and inference

After training, the checkpoint is exported to ONNX with static input shapes, one graph per batch size (the campaign exported the batch-1 graph that match play and self-play use). Static shapes are required by the CoreML execution provider; the graph arm obtains them by padding every position to a fixed node capacity and a fixed move capacity with masks. The exported graph then runs inside the Rust search through the same inference path for both arms. <!-- src: python/hivenet/export_onnx.py:1-8,63-87 --> <!-- src: paper/annex-architectures.md:42-45 -->

The execution provider is where the two arms genuinely differ in cost, and the difference is reported rather than equalised away (`@tbl:inference`{=typst}, measured 10 September 2026). The grid arm's convolutional network runs fastest on CoreML; the graph arm's gather-heavy network is split by CoreML into 15 sub-graphs with 147 of 287 nodes supported, and runs fastest on the CPU provider. Each arm therefore used its best available provider: grid on CoreML at 2.62 ms per evaluation, graph on CPU at 3.67 ms, a ratio of ≈1.4× against the graph arm. The same-wall-clock reading of the protocol charges each arm this true cost on this machine; the same-examples reading is unaffected. <!-- src: docs/representations/comparison-controls.md:19-32 -->

| Execution path | Grid arm | Graph arm |
| --- | ---: | ---: |
| PyTorch, CPU | 11.03 | 10.51 |
| ONNX Runtime, CPU | 23.5 | **3.67** |
| ONNX Runtime, CoreML | **2.62** | 9.84 |
| Provider used in the study | 2.62 (CoreML) | 3.67 (CPU) |

Table: Inference latency of the two capacity-matched networks (grid 1.44 M parameters, graph 1.47 M) at batch size 1, in milliseconds per network evaluation, measured on the study machine (Apple M1 Pro, 10 cores, 16 GB) on 10 September 2026 across three execution paths; one measurement series per cell, no interval reported. Bold marks the provider each arm used in self-play and evaluation. {#tbl:inference}

<!-- src: docs/representations/comparison-controls.md:3-4,14-26 -->

The CoreML path itself had to be repaired first: on 9 September 2026 the Rust inference layer crashed under CoreML because it requested the provider's legacy model format; requesting the modern format restored it, and a probe at 128/32 simulations with the prior loop's network as workload ran at ≈3 s per game of wall-clock on four threads. This probe is the origin of the "≈3 s/game with a trained network" estimate quoted in the protocol. <!-- src: journal/2026-09-09-coreml-fix-01.md:18-33 -->

## The evaluation arena

Evaluation is independent of training in data, settings and seeds. The arena plays *paired* games: pair $i$ of every match plays opening line $i$ of a frozen file of 250 unique legal four-ply base-game openings, once with each colour, so that every arm, seed and opponent faces an identical opening-and-colour schedule (verified by a test that hashes the schedules). The openings were generated blind by a seeded random walk over the engine's legal moves and frozen on 10 September 2026, before any comparison run, with their content hash recorded. Final evaluations use 100 games per opponent (openings 0–49), intermediate ones 20. <!-- src: results/comparison/opponents-manifest.md:30-47 --> <!-- src: configs/comparison-matrix.yaml:53-59 -->

The network under evaluation searches 400 simulations per decision with no Dirichlet noise and no temperature: the most-visited move is played, deterministically. These settings were pinned on 9 September 2026 in a versioned configuration and by a unit test asserting that the search's defaults carry $\varepsilon = 0$; the match-play interface exposes no way to enable noise, so the evaluation path cannot explore by accident. The visit count is fixed for a reason: Jones (2021) measures a train-time/test-time compute trade-off under which a floating evaluation budget would let measured strength drift. The opponents are invoked exactly as frozen (`@sec:baselines`{=typst}), with their own fixed seeds; the network side uses seed 9000 plus the generation index (9500 for the evaluations at the equal-time cutoff). Games are capped at 300 plies; truncations are excluded from the score, reported as a separate rate, and scored 0.5 in a sensitivity line. An evaluation game costs ≈23–32 s at this budget. <!-- src: configs/eval-settings.toml:1-19 --> <!-- src: paper/annex-reproduction.md:37-41,74-75 -->

Scores are win = 1, draw = 0.5, loss = 0 over non-truncated games, aggregated to one score per (seed, opponent) cell before any statistics are computed; the seed rather than the game is the resampling unit (`@sec:protocol`{=typst}). <!-- src: docs/protocol.md:77-83,122-132 -->

## Seven automated pre-training checks {#sec:pipeline-checks}

Before any training output was trusted, seven properties of the data path and the training loop were turned into automated assertions and run as one command against real self-play shards (`@tbl:checks`{=typst}). They go beyond unit tests of isolated functions: checks 1–3 run on recorded positions through a real forward pass, check 4 is a short experiment with a stated criterion, and checks 5–7 exercise the resume, evaluation and layout contracts end to end. <!-- src: paper/method-pipeline.md:33-50 -->

| Check | What it asserts | How it is tested |
| --- | --- | --- |
| 1 Legal-set normalisation | The masked policy puts exactly zero probability on illegal actions and sums to one over the legal set | Real forward pass on recorded positions; illegal mass asserted equal to 0 |
| 2 Move-index identity | Encode → index → decode is the identity on all legal moves across game types; every stored target and played index is legal | Rust round-trip test; data-side scan of every record's target entries against its legal list |
| 3 Outcome perspective | The outcome byte is one of four values, correct for the side to move in both colours; truncated records are excluded from the value loss | Rust sign batteries (evaluation, alpha-beta, search root); data-side comparison of the value loss with its truncation-filtered reference |
| 4 Tiny-batch overfit | A fixed small batch reaches near-perfect fit | Policy argmax 15/15, value 15/15, residual KL 0.09 to the soft targets |
| 5 Save and resume | An interrupted run resumed from a checkpoint reproduces bitwise-identical model and optimiser state and keeps the planned learning-rate schedule | Two training legs on CPU; every model tensor and optimiser tensor compared for exact equality |
| 6 No exploration at evaluation | The evaluation path carries ε = 0 and no temperature | Unit test on the search defaults; settings pinned in a versioned configuration |
| 7 Evaluation never feeds training | No evaluation game is a training input | Audit of every training configuration's shard list against the evaluation tree |

Table: The seven automated pre-training checks, run as one command against real self-play shards before training output was trusted. Each row states the property asserted and the mechanism that asserts it; check 4 is an experiment with a numeric criterion, the others are assertions that pass or fail. {#tbl:checks}

<!-- src: paper/method-pipeline.md:33-50 --> <!-- src: python/hivenet/checks.py:57-96 --> <!-- src: scripts/check5_resume.py:1-12,65-77 --> <!-- src: scripts/audit_run.py:1-13 -->

Check 4 deserves a note on its criterion. Visit distributions are soft targets with irreducible entropy, so "loss tends to zero" is the wrong test; the criterion is the Kullback–Leibler divergence to the target-entropy floor. The check's first run was reported as a failure for two reasons unrelated to the network: the loss had been compared against zero rather than the floor, and the validation holdout had been included. The criterion was corrected and the correction recorded. On the pilot shard the corrected check gave KL 0.093, policy argmax 15/15, value 15/15. <!-- src: paper/method-pipeline.md:40-45 --> <!-- src: journal/2026-09-10-h4-pilot.md:50-53 -->

## The pilot of 10 September 2026

The loop was first run end to end at a deliberately small budget: one generation from a seeded random initialisation of the grid network (1.44 M parameters), 300 self-play games at 128/32 simulations with playout-cap randomization, three training epochs (the campaign later used two), batch 256, the masked policy loss, and an independent evaluation against the frozen population under the pinned settings with 30 games per opponent. Self-play started on the evening of 9 September 2026; the evaluation completed on 10 September. <!-- src: journal/2026-09-10-h4-pilot.md:1-36 -->

*Generation.* The 300 games yielded 17,237 recorded positions; 170 of 300 games (56.7 %) were truncated at the 300-ply cap and none ended by resignation, since a random-initialisation value head never crosses the threshold. Generation took ≈60 min on four threads, ≈12 s per game: untrained play runs long, whereas the trained-network probe of the previous day measured ≈3 s per game at the same budget, so per-generation cost falls as play sharpens. <!-- src: journal/2026-09-10-h4-pilot.md:38-44 -->

*Checks.* All seven passed on the real shard: illegal policy mass exactly 0 and legal mass 1; every stored and played index legal; a valid outcome domain with 12,806 truncated records excluded from the value loss; the overfit result above; save and resume bitwise-identical at step 2110; evaluation noise structurally off; evaluation and training trees disjoint. <!-- src: journal/2026-09-10-h4-pilot.md:46-53 -->

*Training.* On 16,893 training and 344 validation records, the losses decreased (policy ≈3.4 nats at the end against ≈4.1 for a uniform distribution over ≈60 legal moves); validation policy top-1 reached 4–5 % against a uniform-legal chance level of ≈1–2 %; validation value accuracy was 42–46 % over the 94 non-truncated validation records; throughput ≈772 positions/s. The value signal is thin at generation 0 because 74 % of records are truncation-masked. <!-- src: journal/2026-09-10-h4-pilot.md:55-59,85-89 -->

*Evaluation.* `@tbl:pilot-eval`{=typst} gives the result. The generation-0 network beat legal-random in every decided game (28 wins, 2 truncations) and scored 3.3 % against both the heuristic and the 6,400-simulation search. <!-- src: journal/2026-09-10-h4-pilot.md:61-68 -->

| Opponent | W/D/L | Score | Truncated |
| --- | ---: | ---: | ---: |
| B-RND (legal-random) | 28/0/0 | 100.0 % | 2/30 |
| B-HEU (heuristic) | 0/2/28 | 3.3 % | 0/30 |
| B-MCTS (search, 6,400 simulations) | 0/2/28 | 3.3 % | 0/30 |

Table: Independent evaluation of the pilot's generation-0 grid network (one training run, 300 self-play games at 128/32 simulations, three epochs) against the three frozen opponents, at 400 simulations per decision without noise, 30 paired colour-swapped games per opponent. Score = wins + ½ draws over non-truncated games, in %; truncations at the 300-ply cap are counted separately. Pilot volume: no interval is reported and this is not a study result. {#tbl:pilot-eval}

<!-- src: journal/2026-09-10-h4-pilot.md:61-68 -->

*What the pilot diagnosed.* The profile (dominance over legal-random, near-total loss to the two mid-band opponents) was interpreted in the mandated order: rules, value signs, search, data. The first three had been validated independently (`@sec:engine`{=typst}, `@sec:baselines`{=typst}), so the gap after one generation reflects data and iteration rather than a defect; the indicated lever is more generations rather than more capacity, and no capacity change was made. The pilot also supplied the two budget confirmations the protocol freeze was waiting for: 128/32 simulations are feasible at study scale (worst case ≈12 s per game at generation 0, improving toward ≈3 s), and the 300-ply cap is workable precisely because truncation is a separately reported outcome. The protocol was frozen with these values the same day. The pilot's limits are those of its size: one seed, 30 games per opponent, generation 0 only, grid arm only. The iteration of the loop was exercised in structure but was not actually run. <!-- src: journal/2026-09-10-h4-pilot.md:85-115 -->

## A harness defect caught during the pilot

The first evaluation pass of the pilot did not produce `@tbl:pilot-eval`{=typst}. It returned 0/2/28 against all three opponents, including legal-random, which a network that had learned anything should not lose to. Following the same investigation order, the game records were inspected: the opponents' replies were identical across the three pairings. The interactive shell loop used for that first pass had passed each opponent's command-line flags as a single argument, so every opponent fell back to the engine's default search backend and all three matches had in fact been played against the heuristic. The pilot driver proper, which builds argument lists explicitly, does not have this defect; rerun with explicit arguments, the evaluation produced the coherent table above. <!-- src: journal/2026-09-10-h4-pilot.md:70-81 -->

The incident was kept as a worked example rather than discarded, because identical results across supposedly different conditions should be treated as a harness alarm before being read as a finding. The rule proved its worth two weeks later, when three "independent" ablation seeds returned game-count-identical evaluations and the alarm led directly to the silent divergence described in `@sec:results-ablations`{=typst}. A second, minor slip of the same pilot, in which the check battery initially invoked a system Python interpreter with a broken deep-learning installation for check 5, was fixed by pinning the project's own environment. <!-- src: journal/2026-09-10-h4-pilot.md:70-83 --> <!-- src: ../docs/methodology-log.md:71-79 -->
