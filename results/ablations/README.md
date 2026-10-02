# H7 ablation results (feeds booklet table H-T3)

Reference: H6 graph full method (journal H6-2026-09-19-comparison-01).

| Ablation | Component removed | Outcome |
| --- | --- | --- |
| A1 naive adjacency (`graph-untyped`) | direction-typed edge matrices → one shared matrix | **Training diverged (NaN, generation 0, 3/3 seeds)** — untrainable at parity settings; eval tables are artifacts of a NaN policy and are excluded as scores (journal H7-2026-09-23-a1-divergence-01). Attribution: typed edges contribute at minimum optimization stability. |
| A2 no global pooling (`graph-nogpool`) | global-pooling bias in all layers | **NULL effect**: diff vs full graph −0.001 [−0.170, +0.165] (B-RND), −0.007 [−0.043, +0.030] (B-HEU), −0.013 [−0.043, +0.013] (B-MCTS); seed variance dominates; failure modes unchanged (journal H7-2026-10-02-a2-nogpool-01). Pooling is dispensable at this scale. |

| A1' supplement (`graph-untyped-clip`, two-component, D-030) | untyped edges + grad-clip 1.0 | QUEUED (after the D-031 extension; ≈Oct 5-6) |
