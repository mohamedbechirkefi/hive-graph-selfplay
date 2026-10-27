# Score / cost table, Study 2 (H9 task 6; fig2, protocol v2)

| Metric | Grid arm | Graph arm |
| --- | --- | --- |
| Parameters | 1.44 M | 1.47 M (+1.5%) |
| Best-provider inference (b1) | 2.62 ms (CoreML) | 3.67 ms (CPU) |
| Mean run wall-clock (10 gens × 500 games) | 17.8 h | 41.6 h (2.3×) |
| Mean self-play cost | 12.8 s/game | 29.9 s/game |
| Training throughput benchmark (MPS, batch 128, fwd+bwd) | 274 pos/s | 138 pos/s |
| Population score, same-examples | 0.399 | 0.393 |
| Population score, same-wall-clock (T*′=17.63 h) | 0.402 | 0.381 |

Population score = mean over the three frozen opponents of the seed-mean score (truncations excluded, reported separately in the results tables). Wall-clock = self-play generation + training per run (evaluation games excluded), mean over the five seeds; self-play cost = that wall-clock / 5,000 games. Sources: results-*.csv, wallclock.json per run, comparison-controls.md measurements (journal H5-2026-09-10-encoders-01); journal H9-2026-10-27-analysis-01 (Study 2: warm start, replay window 3, seeds 11-15; parameters and inference rows unchanged from Study 1).
