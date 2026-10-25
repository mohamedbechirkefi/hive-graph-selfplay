## The second study: frozen constants, regime and seeds {#sec:app-c-study2}

The second study (`@sec:study2`{=typst}) reuses every constant of `@tbl:app-c-frozen`{=typst} except where `@tbl:app-c-study2`{=typst} states otherwise, and every hyperparameter of `@tbl:app-c-hyper`{=typst} except the training data per generation. Its protocol was frozen as version 2.0 on 13 October 2026 under the content hash given in `@tbl:app-c-study2-hash`{=typst}; the two arms are the configurations of the first two rows of `@tbl:app-c-configs`{=typst}, run with seeds 11 to 15, and no ablation variant was run.
<!-- src: docs/protocol-v2.md:3-12, 88-101 -->

| Constant | Value | Fixed on (2026) | Approved by |
| --- | --- | --- | --- |
| Training regime | warm start: the network of generation $g$ is initialised from the final checkpoint of generation $g-1$ (model weights only; optimizer and cosine schedule restart every generation); generation 0 starts from the seeded random initialisation | 13 Oct (protocol v2) | the author |
| Replay window | 3 generations: generation $g$ trains on the records of generations $\max(0, g-2)$ to $g$, that is 500, 1,000, then 1,500 games from generation 2 onward; 2 epochs per generation | 13 Oct | the author |
| Hyperparameter policy | option A: the first study's settings in both arms, no tuning; option B (three learning rates on one seed per arm) considered and rejected | 13 Oct | the author |
| Training seeds | 11–15 per arm; base seed 100,000 × seed; no random stream shared with seeds 1–5 | 13 Oct | the author |
| Equal-time cutoff of the second study | 17.63 h = median of the total training wall-clock of the five grid runs of the second study (17.46, 17.95, 17.63, 17.46, 18.52 h; sum of the ten per-generation clocks, evaluations excluded), computed once from the clock files on 25 October 2026 before any cross-arm number, never recomputed | rule 13 Oct; value 25 Oct | rule: the author; value: computed mechanically |
| Evaluation schedule | generations 5 and 8 at 20 paired games per opponent (descriptive only); final checkpoint at 100; cutoff checkpoints at 100 with network seed 9500 and match seed 888,000 | 13 Oct (as in the first study) | the author |
| Reused frozen assets | opponent population, 250 openings, pinned evaluation settings, both networks and the shared decoder, untouched | 13 Oct (reuse declared) | the author |
| Execution order | ten runs sequential on the study machine, interleaved grid then graph for seeds 11 to 15; no other heavy process during the campaign | 13 Oct | the author |
| Protocol document | version 2.0; any later change is a new study | 13 Oct | the author |

Table: Frozen constants of the second study, with the date each was fixed and the approval under which it was fixed; everything not listed is the first study's. {#tbl:app-c-study2}
<!-- src: docs/protocol-v2.md:3-12, 53-75, 88-130, 152-166; journal/2026-10-25-h9-tstar-01.md:38-48 -->

| Artifact | SHA-256 |
| --- | --- |
| Protocol, version 2.0 | e296a12e8d1e3dee36c3b210ececced62314e64657aede1cb91b1ea452b461eb |

Table: Content hash of the second study's frozen protocol; the hashes of the reused artifacts are those of `@tbl:app-c-hashes`{=typst}. {#tbl:app-c-study2-hash}
<!-- src: ../state/decisions.md (D-038) -->

The seed derivation of `@tbl:app-c-seeds`{=typst} applies unchanged with $s$ = 11 to 15: the base seed is 100,000 × $s$, generation $g$ uses base + $g$ for self-play and training, the generation-0 network is initialised from the base seed, and the evaluation seeds (9000 + $g$ in-run, 9500 for cutoff sets; match runner 777,000 + $g$ in-run, 888,000 for cutoff sets) are the first study's. The campaign driver records the regime of every run (warm start on, window 3) in a configuration file kept with the run, and every generation's training configuration lists the initialisation checkpoint and the shards actually read.
<!-- src: docs/protocol-v2.md:88-101, 105-120; journal/2026-10-09-h9-driver-01.md:30-45 -->
