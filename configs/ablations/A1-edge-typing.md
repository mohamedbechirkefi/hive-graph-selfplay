# Ablation A1 (H7 task 1, ablation b): naive adjacency
# QUESTION (single): do the geometric (direction-typed) edge attributes
# drive the graph arm's behaviour, beyond naive adjacency? (plan ch. 3:
# "a naive adjacency graph may not suffice" — H1 was rejected WITH typed
# edges; this measures what typing was contributing at all.)
# ONE-COMPONENT DIFF vs the H6 graph full method:
#   RelLayer: six direction-specific weight matrices -> ONE shared matrix
#   (graph_model.py untyped_edges=True). Everything else byte-identical:
#   encoder, decoder, training, budgets, eval, opponents, openings.
# Capacity consequence (inherent to the component, reported per plan
# ch. 6): 0.54M params vs full 1.47M — the typed matrices ARE the
# ablated component; equalising width would change a second component.
arm: graph-untyped
reference: H6 graph full method (cmp-graph-s{1,2,3})
driver: scripts/run_comparison.py --arm graph-untyped --seed {1,2,3}
budget: identical (10 gens x 500 games, 128/32; eval D-019 on D-025
        openings vs D-017 population)
