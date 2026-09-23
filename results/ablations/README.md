# H7 ablation results (feeds booklet table H-T3)

Reference: H6 graph full method (journal H6-2026-09-19-comparison-01).

| Ablation | Component removed | Outcome |
| --- | --- | --- |
| A1 naive adjacency (`graph-untyped`) | direction-typed edge matrices → one shared matrix | **Training diverged (NaN, generation 0, 3/3 seeds)** — untrainable at parity settings; eval tables are artifacts of a NaN policy and are excluded as scores (journal H7-2026-09-23-a1-divergence-01). Attribution: typed edges contribute at minimum optimization stability. |
| A2 no global pooling (`graph-nogpool`) | global-pooling bias in all layers | RUNNING (s1 healthy/finite at gen007; completes ≈2026-09-26) |
