# HiveMind — an ultra-strong AI for the board game Hive

A UHP-compatible engine for [Hive](https://en.wikipedia.org/wiki/Hive_(game))
(base game + Mosquito/Ladybug/Pillbug expansions, all 8 UHP game types),
built in two stages:

- **Phase A (classical)** — fast Rust rules kernel, PVS/alpha-beta search
  with a handcrafted evaluation. Serves as sparring partner and test oracle.
- **Phase B (neural)** — AlphaZero-style MCTS + a policy/value network
  trained by self-play (PyTorch/MPS, ONNX inference in-engine).

## Layout

| crate | purpose |
|---|---|
| `hive-core` | rules kernel: board, movegen, UHP notation, Zobrist, perft |
| `hive-uhp` | UHP server loop + subprocess client for other engines |
| `hive-eval` | handcrafted evaluation (tunable weights) |
| `hive-search` | iterative-deepening PVS, TT, killers/history, LMR |
| `hive-arena` | UHP-vs-UHP match runner with Elo reporting |
| `hive-engine` | the shipped binary (also: `perft`, `fuzz` tools) |

## Quick start

Fresh machine (installs toolchain, builds, tests, fetches opponents, sets up
the Python env — add `--overnight` to also launch the unattended
gauntlet→dataset→training pipeline):

```sh
./scripts/setup.sh                    # or: ./scripts/setup.sh --overnight
```

Manual steps, if you prefer:

```sh
cargo build --release
./scripts/fetch_opponents.sh          # Mzinga (release) + nokamute (source)

./target/release/hive-engine          # UHP engine on stdin/stdout
./target/release/perft Base+MLP 6     # parallel perft
./target/release/fuzz ./opponents/MzingaEngine -- 25 42   # differential fuzz

# gauntlet vs nokamute, 20 paired games at 1s/move:
./target/release/hive-arena --games 20 --movetime 1 --threads 5 \
    -- ./target/release/hive-engine -- ./opponents/nokamute uhp
```

## Correctness

The rules kernel is validated three independent ways (see `scripts/nightly.sh`):

1. **Perft**: exact match with [Mzinga's published tables](https://github.com/jonthysell/Mzinga/wiki/Perft)
   for all 8 game types (depth ≤ 6 in CI, depth 7+ nightly).
2. **UHP conformance**: passes all 21 tests of `nokamute uhp-debug`.
3. **Differential fuzzing**: random games where after every ply our
   `validmoves` set must equal Mzinga's and nokamute's exactly, plus
   game-state cross-checks.
