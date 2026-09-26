# janpfeifer/hiveGo (2018–2026) — Hive in Go with AlphaZero-style AI (FNN + tiny GNN)

```yaml
citation:        Jan Pfeifer (GitHub user janpfeifer). "hiveGo — Go Implementation of Hive Game." GitHub repository.
venue_year:      GitHub repository, 2018–2026 (created 2018-08-24, originally TensorFlow; refreshed 2025 onto GoMLX; last push 2026-08-20)
question:        Hobby/educational, no formal research question — can AlphaZero-style self-play (and an alpha-beta engine) learn to play Hive, as a platform for game algorithms and a demo of the GoMLX framework?
game_task:       Hive (base game); web (Go->WebAssembly), command-line, and Gnome UIs (Gnome currently broken)
representation:  Hand-crafted "basic set of features for the board" (README's own words; no plane/frame spec published) feeding two model families — a feedforward network (FNN) used by the alpha-beta searcher, and a "tiny GNN (Graph Neural Network)" used by the AlphaZero/MCTS path. A hexagonal-convolution full-board model (odd/even-column kernels, residual connections) exists but is flagged "currently broken".
search_method:   Alpha-beta pruning (FNN evaluation) and MCTS, AlphaZero-style (GNN policy/value); two trainer programs (ab-trainer, a0-trainer) with self-play, game rescoring, and model distillation
compute_budget:  not reported (README only recommends a GPU via GoMLX "during training with larger models"; no run lengths, game counts, or hardware given)
metrics:         None controlled — anecdotal only: the AI "beats me every time", and against "some commercially available Hive game, both AIs won every time". The trainers have a "Compare AIs" mode, but no comparison results, no fixed opponents, no Elo, no seeds, no uncertainty are published anywhere in the repo.
code_available:  yes (https://github.com/janpfeifer/hiveGo, main branch; consulted at commit d6ff95418d2b, 2026-08-20)
limits:          No controlled evaluation of any kind, and in particular NO grid-vs-graph comparison — the GNN, FNN and hex-CNN are attached to different searchers/pipelines and never compared like-for-like; hex-CNN and Gnome UI broken; no LICENSE file detected via the GitHub API (rights unclear — any code reuse would be a G-RIGHTS gate, but none is planned); descended from an earlier Python project (makatony/hiveAI).
difference_from_our_study:  hiveGo is an existence proof that GNN + AlphaZero-style training for Hive is buildable, and the closest public precedent for a graph encoder on Hive — but it makes and supports no representation claim. We reuse nothing from it (our engine is independent, UHP-validated); we supply exactly what it lacks: capacity-matched grid CNN vs relational message-passing GNN (1.44M vs 1.47M params), a shared action decoder, frozen opponents/openings/protocol, two budget readings (same-examples and same-wall-clock), 3 seeds/arm. Cited as webographie context: graph encodings for Hive exist in the wild with no controlled evidence either way — our H1 rejection is, to our knowledge, the first controlled reading.
relevance:       RQ-H1
date_read:       2026-09-26
version_doi:     main branch, commit d6ff95418d2b (2026-08-20, "Updated main.wasm version."); https://github.com/janpfeifer/hiveGo; consulted 2026-09-26
classification:  webographie
purpose:         lit-review
```

## Notes
- Repository facts verified via the GitHub API on 2026-09-26: janpfeifer/hiveGo, "Go Implementation of Hive Game", created 2018-08-24, last push 2026-08-20 (HEAD d6ff95418d2b), primary language Go, 18 stars, no licence detected. README states the project "was originally a 2018 project using TensorFlow, refreshed in 2025 to use GoMLX" and calls itself "an experimental / educative project to learn the AlphaZero algorithm and RL in general".
- Working today per README: CLI play, alpha-beta + FNN, AlphaZero/MCTS + "a tiny GNN" (internal/ai/gomlx/), a0-trainer and ab-trainer with self-play, rescoring and distillation. Broken: hexagonal-convolution board model and the Gnome UI. So all three representation families (features->FNN, graph->GNN, hex-grid->CNN) appear in one codebase, yet no two of them are ever evaluated under matched conditions — a neat miniature of the field-wide gap H1 targets.
- Evaluation is entirely anecdotal ("beats me every time"; both AIs beat a commercial Hive app every time). No opponents pinned, no game counts, no seeds, no intervals. For the report this is the webographie citation showing GNN-for-Hive prior art exists but reports no controlled comparison.
- Rights note: no LICENSE file at the consulted commit. We consume nothing from this repo, so no G-RIGHTS action needed; flag only if that ever changes.
