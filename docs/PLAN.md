# Ultra-Strong Hive AI Engine — Implementation Plan

## Context

Greenfield project in the empty directory `/Users/bechirkefi/Documents/hive_thegame`. Goal: an AI bot for the board game **Hive** strong enough to beat other engines and professional-level humans.

Decisions locked in with the user:
- **Rules**: base game + all expansions (Mosquito, Ladybug, Pillbug) — all 8 UHP game types (`Base` … `Base+MLP`).
- **Engine**: staged. **Phase A** = alpha-beta/PVS with handcrafted eval (strong classical engine, sparring partner, test oracle). **Phase B** = AlphaZero-style MCTS + neural net trained by self-play (the "ultra" tier).
- **Language**: Rust engine core; Python/PyTorch (MPS) for training; in-engine inference via **`ort`** (ONNX Runtime, CoreML EP, fixed-shape exports) with candle-Metal as feature-flagged fallback.
- **Interface**: UHP (Universal Hive Protocol) so it plays automated gauntlets vs **Mzinga** (reference C# engine) and **nokamute** (fast Rust engine).
- **Hardware**: single Apple M4 Pro, 14 cores, 24 GB unified memory. Self-play sized accordingly (prior art: ~35k AZ games reached strong-human level in Hive, so this is feasible).

Key verified external facts (sources: Mzinga wiki UHP + Perft pages, nokamute repo, World Hive Tournaments rules FAQ):
- UHP: stdin/stdout, every response ends with `ok`; commands `info`, `newgame`, `play`, `pass`, `validmoves`, `bestmove depth|time`, `undo [N]`, `options`; relative MoveString notation (`wB1 wS1-`, prefix/suffix `-` `/` `\`); pillbug throws use ordinary notation naming the thrown piece.
- Perft ground truth for all 8 game types on the Mzinga Perft wiki (Base: d1=4, d2=96, d3=1440, d4=21600, d5=516240, d6=12219480…). Conventions: no queen placement on turn 1, identical in-hand bugs counted once, forced pass = 1 move.
- Rules algorithmics: one-hive = articulation points (Tarjan lowlink DFS, O(n)); slide freedom = exactly-one-occupied common neighbor; beetle/height gate: step A→B blocked iff both common neighbors n satisfy `h(n) > max(hA−1, hB)` (also applies to ladybug and both legs of pillbug throws); pillbug stun rule (piece moved last turn can't move/be moved); mosquito copies adjacent bug types (pure beetle while on hive); ladybug exactly 2 steps on top + 1 down; draws by simultaneous surround and 3-fold repetition.
- nokamute provides `uhp-debug` (UHP conformance tester) and a built-in match runner — reuse both.

## Repository Layout

```
hive_thegame/
├── Cargo.toml                  # Rust workspace
├── crates/
│   ├── hive-core/      # rules kernel, zero-alloc, no I/O
│   │   └── src/: hex.rs, bug.rs, board.rs, state.rs, onehive.rs,
│   │            movegen/{mod,slide,climb,hopper,ladybug,pillbug,mosquito}.rs,
│   │            zobrist.rs, canonical.rs, notation.rs, perft.rs
│   ├── hive-uhp/       # UHP server (our engine) + client (drive opponents)
│   ├── hive-eval/      # handcrafted eval + SPSA tuner
│   ├── hive-search/    # PVS/alpha-beta (Phase A)
│   ├── hive-mcts/      # batched PUCT MCTS + ort inference (Phase B)
│   ├── hive-selfplay/  # self-play actors, replay shard writer (memmap2)
│   ├── hive-arena/     # UHP-vs-UHP match runner, opening book, SPRT/Elo
│   └── hive-engine/    # shipped binary: UHP front, backend = AlphaBeta|MCTS
├── python/hivenet/     # model.py, dataset.py (12× symmetry aug), train.py,
│                       # export_onnx.py (fixed shapes b=1, b=128), gate.py
├── tests/              # perft_fixtures.json, tactical_suite/, edge_cases/
└── scripts/            # fetch_opponents.sh, gauntlet.sh
```

Crates: rayon, crossbeam-channel, smallvec, ahash, clap, serde, rand_chacha, memmap2, criterion, proptest, ort (feature `coreml`).

## Milestones (each independently testable)

### M0 — Scaffolding (~0.5 wk)
Workspace compiles; clippy/fmt/test in CI; `fetch_opponents.sh` gets a macOS Mzinga release binary + `cargo install`s nokamute.
**Accept:** both opponents answer `info` over UHP locally.

### M1 — Rules core + movegen + perft (~2–3 wk) — the foundation
- Board: nokamute-style flat wrapping byte grid (64×64) with {color, bug, height} per cell; stacks in a side table. Absolute coordinates never renormalize mid-game → Zobrist stays fully incremental (translation symmetry NOT needed for the TT; canonicalization only at NN/book boundary in `canonical.rs`).
- Full movegen incl. all expansion interactions; `last_moved` field implements pillbug stun; forced-pass and game-over conventions per Mzinga.
**Accept:** exact match to all Mzinga wiki perft tables (8 game types; deep depths nightly) + differential fuzzing: 100k random games/type where our `validmoves` set equals Mzinga's AND nokamute's after every ply. Every divergence frozen as a regression fixture.

### M2 — UHP I/O (~0.5–1 wk)
Full command set, capabilities `Mosquito;Ladybug;Pillbug`, `err`/`invalidmove` semantics, GameString round-trip.
**Accept:** passes `nokamute uhp-debug ./hive-engine`; full manual game via MzingaViewer.

### M3 — Alpha-beta engine (~3–4 wk)
- PVS + iterative deepening; TT (Zobrist, 1–4 GB, two-tier); ordering: TT move → queen-surround moves → killers → history (piece×destination); LMR + futility on quiet moves (no null-move — Hive has zugzwang-like pass states); quiescence = extend moves changing a queen's liberty count or landing adjacent to a queen; extension when a queen ≤ 2 liberties; 3-fold repetition detection; lazy SMP (10–12 threads).
- Eval (tapered by pieces placed): queen-liberties differential (dominant, convex), attackers/defenders around queens, pinned-piece counts (free from movegen's articulation bitset), per-bug mobility, beetle on/near enemy queen, grasshopper alignment, pillbug-near-own-queen rescue latent, stun tempo, reserve/placement tempo, own-queen crowding penalty. Hand-set weights → SPSA self-play tuning.
**Accept:** ≥ 95% vs 1-ply self; ≥ 90% on 100-position tactical suite at 5 s/move; make/unmake hash property tests pass.

### M4 — Arena + gauntlet (~1 wk, then continuous)
`hive-arena`: paired color-swapped games from a balanced random opening book, time control enforcement, adjudication (GameStateString, 300-ply draw), SPRT (elo0=0, elo1=10, α=β=0.05) + Elo error bars; Mzinga & nokamute anchors; all 8 game types.
**Accept (Phase A exit):** ≥ 65% vs both anchors at 5 s/move over ≥ 500 paired games on Base and Base+MLP.

### M5 — NN design + supervised bootstrap (~2–3 wk)
- **Input** (76, 32, 32) fp16: canonicalized (translation + best of 12 hex symmetries) axial coords in a 32×32 frame; hex adjacency ⊂ 3×3 so plain convs work. Planes: 8 bugs × 2 colors × 4 stack levels (64) + pinned + stunned + legal-placement×2 + side-to-move + queen-liberties×2 + move-number + game-type M/L/P one-hot + reserve summary.
- **Policy head**: (piece, destination-hex) spatial map — 28 piece channels × 32×32 + pass = 28,673 logits. (piece, dest) uniquely identifies a Hive move (pillbug-throw/walk collisions produce identical states — harmless). Bijective move↔index codec in hive-core, exhaustively tested. Fallback specced: relative UHP-style encoding.
- **Value head**: WDL 3-way softmax. **Net**: 8-block × 96-filter ResNet (~1.6 M params) with global pooling in 2 blocks.
- **Bootstrap**: log 200k+ Phase A fast-TC games → supervised pretrain (sidesteps AZ cold start on limited hardware).
**Accept:** ONNX runs under ort CoreML EP at fixed shapes; **≥ 2,000 evals/s @ b=128 benchmark = Phase B go/no-go**; bootstrapped policy top-1 ≥ 40% vs searcher.

### M6 — AZ self-play loop (~4–8 wk wall-clock, mostly compute)
- Batched PUCT (virtual loss, batch 64–128, 8–12 game actors → 1 inference thread); Dirichlet root noise (α≈0.15, ε=0.25); temp 1.0 for 12 plies → 0; KataGo economies: playout-cap randomization (25% @ 600 sims / 75% @ 100), forced playouts + policy-target pruning, resignation with audit games.
- Throughput plan: 6–10k games/day realistic on the M4 Pro. Replay buffer ~1 M positions in memmapped shards; train on MPS (batch 256, SGD momentum, lr 0.02 cosine→2e-4) interleaved with generation; gate each generation: ≥ 55% over 300 paired games vs best + fixed alpha-beta anchor match. Game-type curriculum: Base 30%, Base+MLP 40%, others 30% (one conditional net).
**Accept (Phase B exit):** MCTS+NN ≥ 60% vs Phase A engine at equal wall-clock (5 s/move) on Base and Base+MLP; ≥ 80% vs Mzinga/nokamute.

### M7 — Time management + integration (~1 wk)
`hive-engine` binary with backend option, soft/hard time budgets from `bestmove time`, early-stop (visit dominance / stable-best-move), optional pondering. README + reproducible gauntlet + published Elo table.

## Key Risks → Mitigations
- **Policy move-space** (hardest NN decision): chosen (piece,dest) map with uniqueness argument; exhaustive round-trip tests; relative-encoding fallback specced.
- **Rule edge cases** (beetle gates, stun chains, mosquito→pillbug, gated throws): perft tables ×8 game types + differential fuzzing vs two independent engines; divergences become permanent fixtures.
- **Limited compute for AZ**: supervised bootstrap, small conditional net, KataGo efficiency tricks, M5 inference benchmark as go/no-go; fallback = NNUE-style small net inside the PVS engine.
- **Zobrist vs floating board**: absolute-coordinate incremental hashing is sound (no mid-game renormalization); canonicalization isolated to NN/book; property-tested.
- **CoreML dynamic-shape pitfalls**: fixed-shape exports only; candle-Metal fallback; CPU EP as correctness oracle.
- **Draw death-spirals**: 3-fold + 300-ply adjudication everywhere; WDL head; slight contempt in gating.
- **24 GB memory**: TT caps (4 GB match / 1 GB self-play), disk-backed replay.

## Verification
1. Unit tests per movegen rule file (gates, stun, copies) + notation round-trip on every fuzzed move.
2. Perft vs Mzinga wiki tables (fast in CI, deep nightly).
3. Cross-engine `validmoves` differential fuzzing vs Mzinga + nokamute, all 8 game types.
4. Search invariants: hash(make;unmake)==hash (proptest); TT on/off same bestmove at fixed depth.
5. Tactical regression suite (surround-in-N, pillbug rescues) must never regress.
6. Every search/eval change passes SPRT in hive-arena before landing.
7. End-to-end: `scripts/gauntlet.sh` reproduces the Elo table vs Mzinga/nokamute.

---

# Status addendum (2026-07-12, end of first build session)

- M0–M4 COMPLETE. Perft d≤7 matches Mzinga for all 8 game types; differential
  fuzz 27k/66k positions vs Mzinga/nokamute PASS; uhp-debug 21/21.
- Strength v0.2 @1s/move: 100% vs Mzinga, 79.2% vs nokamute (+232 Elo).
  v0.3 added adaptive time management + aspiration windows after v0.2
  underperformed at 5s/move; v0.3 gauntlet results land in logs/ overnight.
- M5 pipeline COMPLETE: hive-nn (frame/policy/records), selfplay datagen,
  Python training (HiveNet 1.44M params), ONNX export. Inference go/no-go
  PASSED: 2,246 evals/s @b128 via onnxruntime CoreML EP.
- M6 STARTED: hive-mcts (batched PUCT, Evaluator trait, EvalNet fallback)
  tested; `hive-engine --mcts` works.

## Codebase status: FEATURE-COMPLETE for training (2026-07-12, session 1 end)

Everything through the M6 loop is now implemented and smoke-tested:
- ort/CoreML evaluator (`hive-mcts/src/ort_eval.rs`); `hive-engine --mcts
  --net model.onnx` plays over UHP.
- Record v2 (MCTS visit-distribution policy targets, HIVEREC2 shards);
  Python dataset/training handle v1+v2, soft-CE loss, `--init` warm starts.
- `selfplay-mcts`: NN self-play with Dirichlet noise, temperature,
  playout-cap randomization, resignation + audit fraction.
- `scripts/rl_loop.sh`: generation loop self-play → train → export → gate
  (promote at ≥55%), training window over recent generations.

## Remaining work, in order
1. TRAINING (compute, not code): run scripts/overnight.sh to completion
   (bootstrap net), then scripts/rl_loop.sh for days/weeks. Monitor gate
   logs; anchor-check vs alpha-beta and nokamute every few generations:
     ./target/release/hive-arena --games 40 --movetime 5 --threads 2 \
       -- ./target/release/hive-engine --mcts --net models/best-b1.onnx \
       -- ./opponents/nokamute uhp
2. Read v0.3 gauntlet results (logs/gauntlet_*.log): confirm ≥65% vs
   nokamute at 5s (Phase A exit).
3. Perf when it becomes the bottleneck: b32 exports for self-play batching,
   CoreML-friendly ops (9/64 nodes currently fall back to CPU), tree reuse
   between moves, cross-thread inference batching.
4. M7 polish: pondering, `SearchBackend` UHP option, README Elo table.
5. Ongoing: SPSA eval tuning, tactical suite growth, opening book,
   Base+MLP game-type curriculum in the RL loop (GAMETYPE env).
