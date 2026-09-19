# Ablation A2 (H7 task 1, ablation a SUBSTITUTION per D-028): global pooling
# QUESTION (single): does the global-pooling bias drive the graph arm's
# (relatively strong) value learning / overall behaviour? Substituted for
# the plan's augmentation-removal ablation, which has nothing to remove
# because D-023 excluded augmentation from the full method.
# ONE-COMPONENT DIFF vs the H6 graph full method:
#   RelLayer global-pooling bias removed from all layers
#   (graph_model.py no_gpool=True). Everything else byte-identical.
# Capacity consequence (reported): 1.37M vs 1.47M params.
arm: graph-nogpool
reference: H6 graph full method (cmp-graph-s{1,2,3})
driver: scripts/run_comparison.py --arm graph-nogpool --seed {1,2,3}
budget: identical to A1
status: PROPOSED — runs only if the human includes it at G-SPEND
