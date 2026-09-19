# Score / cost table (H6 task 7; fig2)

| Metric | Grid arm | Graph arm |
| --- | --- | --- |
| Parameters | 1.44 M | 1.47 M (+2.1%) |
| Best-provider inference (b1) | 2.62 ms (CoreML) | 3.67 ms (CPU) |
| Mean run wall-clock (10 gens × 500 games) | 18.2 h | 35.7 h (2.0×) |
| Mean self-play cost | 13.1 s/game | 25.7 s/game |
| Training throughput (MPS) | ≈770 pos/s | ≈195 pos/s |
| Population score, same-examples | 0.412 | 0.327 |
| Population score, same-wall-clock (T*=18.77 h) | 0.402 | 0.321 |

Population score = mean over the three frozen opponents of the seed-mean score (truncations excluded, reported separately in the results tables). Sources: results-*.csv, wallclock.json per run, comparison-controls.md measurements; journal H6-2026-09-19-comparison-01.
