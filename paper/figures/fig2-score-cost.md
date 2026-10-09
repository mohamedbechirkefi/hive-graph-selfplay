# Score / cost table (H6 task 7; fig2)

| Metric | Grid arm | Graph arm |
| --- | --- | --- |
| Parameters | 1.44 M | 1.47 M (+2.1%) |
| Best-provider inference (b1) | 2.62 ms (CoreML) | 3.67 ms (CPU) |
| Mean run wall-clock (10 gens × 500 games) | 30.0 h | 61.2 h (2.0×) |
| Mean self-play cost | 21.6 s/game | 44.0 s/game |
| Training throughput (MPS) | ≈770 pos/s | ≈195 pos/s |
| Population score, same-examples | 0.411 | 0.331 |
| Population score, same-wall-clock (T*=18.77 h) | 0.405 | 0.326 |

Population score = mean over the three frozen opponents of the seed-mean score (truncations excluded, reported separately in the results tables). Sources: results-*.csv, wallclock.json per run, comparison-controls.md measurements; journal H6-2026-09-19-comparison-01.
