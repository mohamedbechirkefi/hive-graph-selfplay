# van der Pol, Worrall, van Hoof, Oliehoek & Welling (2020) — MDP Homomorphic Networks

```yaml
citation:        "Elise van der Pol, Daniel E. Worrall, Herke van Hoof, Frans A. Oliehoek, Max Welling. MDP Homomorphic Networks: Group Symmetries in Reinforcement Learning."
venue_year:      "NeurIPS 2020 (peer-reviewed). arXiv:2006.16908."
question:        "Can building equivariance to the symmetries of an MDP's joint state-action space directly into policy/value networks shrink the solution space and speed up RL, and can such equivariant layers be constructed automatically."
game_task:       "CartPole (reflection symmetry), a grid world (rotations), and Pong (reflection) — control/Atari-style RL, not board games."
representation:  "Standard state inputs (vectors / image frames) processed by equivariant MLPs and CNNs; the policy output transforms consistently with the state under the group action (state flips => action distribution permutes accordingly)."
search_method:   "Model-free deep RL (policy-gradient/A2C-style and DQN-style training in rlpyt); no tree search."
compute_budget:  "Not reported as a formal budget; small standard benchmarks, comparisons via learning curves at equal environment steps."
metrics:         "Sample efficiency / convergence speed of learning curves vs non-equivariant baselines of comparable size (equivariant nets converge faster on all three environments); also vs data augmentation."
code_available:  yes (https://github.com/ElisevanderPol/mdp-homomorphic-networks — official, PyTorch/rlpyt; separate 'symmetrizer' package for layer construction)
limits:          "Requires the symmetry group to be known and exact, and discrete/small (reflections, 90-degree rotations); the symmetrizer solves for weight-space bases numerically, adding construction overhead; demonstrated only on small environments; approximate or state-dependent symmetries not handled."
difference_from_our_study:  "We do NOT build equivariant layers. Our GNN gets translation invariance for free (a Hive board graph has no coordinates, so the D6/translation symmetry of the hex plane largely disappears from the input), while the grid/CNN arm sees a bbox-centered 32x32 BFS-unwrapped frame whose representation is only approximately translation-stable and not rotation-aware. This paper supplies the theory for why that asymmetry could matter at small compute (equivariance = smaller hypothesis space = faster convergence) and gives the baseline alternative we deliberately skip (constructing hex-D6-equivariant layers). Our strictly time-permitting secondary question is the cheap empirical version: probe both trained encoders for policy robustness under board translations/rotations/reflections, and optionally compare against symmetry data augmentation, which this paper also benchmarks against."
relevance:       "RQ-H1 secondary axis (symmetry/translation robustness, time-permitting); explains a possible mechanism behind any GNN advantage found in the main RQ-H1 comparison."
date_read:       2026-09-09
version_doi:     "arXiv:2006.16908 (v2, 2021-01-20), https://arxiv.org/abs/2006.16908; NeurIPS 2020 proceedings https://papers.nips.cc/paper/2020/hash/2be5f9c2e3620eb73c2972d7552b6cb5-Abstract.html. Code: github.com/ElisevanderPol/mdp-homomorphic-networks (no release pinned)."
classification:  bibliography
purpose:         lit-review
```

## Notes

- Core idea: an MDP homomorphism maps equivalent state-action pairs onto each other; a network is "MDP homomorphic" if pi(g·s) = g·pi(s) for group elements g acting jointly on states and actions. For board games the relevant group action permutes *moves* when the board is transformed — in Hive, rotating the hive by 60 degrees permutes the (piece, destination) move set. A pointer-style decoder over candidates composes naturally with this: if node embeddings are equivariant (or invariant) under the transformation, per-candidate scores transform correctly by construction. That is a one-paragraph theoretical argument for our architecture worth making explicitly.
- Their key practical contribution — the numerical "symmetrizer" that builds equivariant weight bases from a specification of the group — is what we'd use if the secondary question were promoted to a full arm (hex D6 = 12 elements, well within its discrete-group scope). Under limited compute we instead (a) measure robustness post hoc and (b) at most compare with augmentation; the paper's own baseline comparison (equivariance beats augmentation in sample efficiency) predicts what we'd find.
- Evidence class: convergence-speed gains on CartPole / grid world / Pong at equal environment steps — small-scale, model-free, no search. No board-game or MCTS evidence, so we cite it for mechanism, not for magnitude in AlphaZero-style settings.
- Relation to the other cluster works: Cohen & Welling (2016) G-CNNs give equivariance in the *state encoder* only; this paper extends it through the *policy output*, which is the part that matters for a (piece,destination) action space. That is why it was chosen over G-CNNs for this slot.
- Caveat for Hive specifically: exact global symmetry is broken by nothing in base Hive (no board edge!), so the symmetry group is genuinely large (translations x D6) — the CNN arm's bbox-centering handles translation only, crudely; rotations/reflections remain. A graph input quotient s out translations entirely and reduces D6 to relabeling edge-direction attributes. Good framing sentence for the paper.
- Peer-reviewed (NeurIPS 2020), official code available.
