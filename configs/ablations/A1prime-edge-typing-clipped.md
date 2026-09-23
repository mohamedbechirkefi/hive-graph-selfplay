# Supplementary A1' (D-030): naive adjacency + gradient clipping
# EXPLICITLY A TWO-COMPONENT DIFF vs the H6 graph full method:
#   (1) untyped edges (as A1); (2) global grad-norm clip 1.0 — added
#   ONLY because A1 proved the variant untrainable at parity (NaN gen-0,
#   3/3 seeds; journal H7-2026-09-23-a1-divergence-01).
# QUESTION: what does a TRAINED naive-adjacency net score? Per plan
# ch. 6, NO effect measured here is ever attributed to edge typing
# alone — the clip is confounded by construction; the write-up must say
# so wherever A1' numbers appear.
# Capacity: 0.54M (inherent to the untyped component, as A1).
arm: graph-untyped-clip
reference: descriptive only (two-component); parity reference remains A1's divergence
driver: scripts/run_comparison.py --arm graph-untyped-clip --seed {1,2,3}
budget: 10 gens x 500 games, frozen budgets; QUEUED after the A2 runs
