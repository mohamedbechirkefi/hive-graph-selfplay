# Cazenave et al. (2020) — Polygames: Improved Zero Learning

```yaml
citation:        Tristan Cazenave, Yen-Chi Chen, Guan-Wei Chen, Shi-Yu Chen, Xian-Dong Chiu, Julien Dehos, Maria Elsa, Qucheng Gong, Hengyuan Hu, Vasil Khalidov, Cheng-Ling Li, Hsin-I Lin, Yu-Jin Lin, Xavier Martinet, Vegard Mella, Jeremy Rapin, Baptiste Roziere, Gabriel Synnaeve, Fabien Teytaud, Olivier Teytaud, Shi-Cheng Ye, Yi-Jun Ye, Shi-Jim Yen, Sergey Zagoruyko. "Polygames: Improved Zero Learning."
venue_year:      ICGA Journal 42(4), pp. 244-256, 2020 (issue published Jan 2021); arXiv:2001.09832 (Jan 2020)
question:        How to make AlphaZero-style zero learning more general and robust across many games — in particular, can one network architecture handle arbitrary (and varying) board sizes?
game_task:       Many games in one framework — Hex (up to 19x19), Havannah, Othello, Breakthrough, Connect6, Minishogi and others; Ludii integration added later. Hive is NOT among the supported games.
representation:  Planar/tensor board input to a fully convolutional network with NO fully connected layers, plus global pooling — making the policy/value net independent of board size ("boardsize invariance"); still fundamentally a grid/CNN representation
search_method:   AlphaZero-style self-play: MCTS + policy/value network; training robustness via keeping best checkpoints and training against them
compute_budget:  not reported in comparable per-run units (large distributed Facebook AI infrastructure; varies by game)
metrics:         Tournament/competition results (several first places at TAAI competitions); defeated strong human players at 19x19 Hex, a milestone previously considered intractable for zero learning; Havannah wins
code_available:  yes (https://github.com/facebookincubator/Polygames — MIT license, archived read-only since Mar 2, 2022)
limits:          Boardsize invariance is achieved within the fixed-topology grid paradigm (full convolutions + global pooling), so it handles scaled boards, not board-less/dynamic-topology games like Hive; framework is now archived/unmaintained; per-game compute costs not systematically reported
difference_from_our_study:  We keep the AlphaZero-style self-play loop and adopt their lesson that removing fixed-size fully connected heads (global pooling) is what buys size generality. We differ on the mechanism for handling variable spatial extent: Polygames stays convolutional over a grid that merely varies in size, whereas Hive has no board at all — our GNN handles a dynamically growing, sparse hex-connected structure natively, while our CNN baseline must fix a bounding grid (a la AZ-Hive's 26x26). Polygames is thus the strongest representative of the "grid, done right" side of RQ-H1.
relevance:       RQ-H1 (variable-board-size learning with CNNs; the grid-paradigm ceiling our graph approach is compared against)
date_read:       2026-09-09
version_doi:     DOI 10.3233/ICG-200157; arXiv:2001.09832; code repo archived 2022-03-02 (no pinned release cited)
classification:  bibliography
purpose:         lit-review
```

## Notes
- Central architectural claim: a fully convolutional structure (no FC layers) + global pooling "create[s] bots independent of the board size" — train on one size, play on another. This is the standard grid-world answer to variable board size and the natural steel-man baseline for our CNN arm: if our grid net uses FC heads, a graph-vs-grid win could be confounded by that; adopting fully-conv + global pooling in the CNN baseline removes the confound.
- Headline result: first zero-learning bot to beat strong humans at 19x19 Hex, plus TAAI competition wins — evidence the recipe scales across games without game-specific features.
- Also notable: training-stability tricks (track best checkpoints, train against them) are cheap to adopt under our limited-compute budget.
- What Polygames does not do: any graph/GNN state representation, and any game whose adjacency structure changes during play (Hive's hive is a dynamic graph, pieces stack, there is no fixed lattice extent). Its Ludii bridge covers many board games, but state input remains tensor planes.
- Repo is archived (read-only since 2022-03-02, MIT) — usable for reference implementations of fully-conv value/policy heads, not as a live dependency.
