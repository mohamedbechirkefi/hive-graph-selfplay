# Tactical position set (H3 task 4 — plan ch. 5)

Hand-annotated tactical positions with a known good outcome, used to verify
the **search** (MCTS-without-network baseline, and any later searcher) finds
correct tactical moves at reasonable budget. Discipline is identical to the
H2 critical corpus: **expectations derive from the rules by hand — never
from the searcher under test** (positions reuse ring geometries verified in
`tests/critical_positions/`; the win/loss reasoning cites the Gen42
rulesheet's end-of-game rule, p. 11).

Because several pieces can often reach the winning cell, expectations are
**destination-based**: the searcher's move must (or must not) land on a
named cell — any piece completing the surround wins (rulesheet p. 1:
surrounding pieces may be any mixture of colours).

## Case format (`cases/*.toml`)

```toml
id = "T001"
title = "..."
game_type = "Base"
setup = ["wS1", ...]        # UHP MoveStrings from the empty board
[expect]
kind = "bestmove_to_cell"   # or "bestmove_avoid_cell"
target = "bQ\\"            # cell named relative to a piece on the board
[annotation]
...rule + hand-written justification...
```

## Running

```sh
python3 scripts/run_tactical_suite.py                # default --sims 6400 --seed 1
python3 scripts/run_tactical_suite.py --sims 1600    # budget sweep
```

The runner drives `hive-engine --mcts --sims N --seed S` over UHP,
requests `bestmove depth 1` (= exactly N simulations), resolves the reply
to a destination cell with the corpus notation parser, and compares.

## Value-sign / alternation checks (task 4b)

The plan ch. 5 requirement "verify the sign of values under player
alternation" is covered by automated Rust tests, not by this set:
`hive-eval` (negamax identity: same board, flipped side-to-move ⇒ negated
eval), `hive-search` (mate-in-1 scores positive for the *mover*, both
colours), `hive-mcts` (root value strongly positive for the winning mover,
both colours). See `crates/*/tests/` — wired into `cargo test`.

## Review status

Unreviewed by an external Hive-literate reader — same declared limit as the
H2 corpus (carried into the report's limits).
