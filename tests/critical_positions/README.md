# Critical position corpus (H2 task 2 — plan ch. 4)

Hand-annotated edge positions with expected legal moves or expected
properties. **Every expectation in this corpus was written by hand from the
publisher's rules — never generated from, or corrected against, the engine.**
The corpus is committed before any run against the engine; disagreements
found by the runner are investigated against the rules text (the corpus may
be wrong, not only the engine) and each resolution is journaled with its rule
citation (pipeline H2 task 3).

## Ruleset and conventions

- **Base game** (D-007), with the **tournament opening rule**: the Queen Bee
  may not be placed on either player's first turn. The Gen42 base rulesheet
  (© 2010) permits a first-turn queen; the tournament variant forbids it and
  is the convention adopted by UHP and both reference engines (Mzinga,
  nokamute) and by this engine. Corpus cases assume the tournament rule and
  cite it as such (webographie sources below).
- A few cases are tagged `game_type = "Base+P"`: they guard the shared
  kernel's Pillbug stun logic (H2 task 2 allows this) and are **not** study
  variants (protocol §2).
- Positions are expressed as UHP move sequences from the empty board, so
  every position is reachable and its legality is independently checkable.
  Expected moves are UHP MoveStrings; the runner compares **(piece,
  destination cell)** sets — reference-piece choice in a MoveString does not
  matter.

## Case format (`cases/*.toml`)

```toml
id = "C001"                      # stable id, cited by journal entries
title = "..."
game_type = "Base"               # or "Base+P" (kernel-guard cases)
setup = ["wS1", "bG1 wS1-", ...] # UHP MoveStrings from the empty board
[expect]
kind = "moves_for_piece"         # see kinds below
piece = "wA1"                    # focal piece (kind-dependent)
moves = ["wA1 -wS1", ...]        # exact expected set (kind-dependent)
[annotation]
rule = "Freedom to Move"         # rule name as in the rulesheet
source = "Gen42 Hive rulesheet p. 10"
justification = """hand-written reasoning citing the rule"""
```

Expectation kinds:

| kind | meaning |
| --- | --- |
| `moves_for_piece` | exact set of legal moves for `piece` (empty list = piece cannot move) |
| `move_legal` / `move_illegal` | the single MoveString in `move` is legal / illegal in the position |
| `all_moves_place` | every legal move is a placement of `piece` (forced queen) |
| `all_moves_are_placements` | no movement moves exist (queen not yet placed) |
| `must_pass` | the side to move has no legal placement or move (validmoves = pass) |
| `game_over` | after `setup`, the GameString state equals `state` (WhiteWins/BlackWins/Draw) |

## Rules sources (webographie; consulted 2026-09-09)

1. **Gen42 Hive rulesheet** — John Yianni, © 2010 Gen42 Games,
   https://www.gen42.com/wp-content/uploads/Hive-rules.pdf. Cited by page:
   p. 2 Placing; p. 3 Placing your Queen Bee / Moving (incl. the One Hive
   NB); pp. 4–5 Beetle (stack immobility, stack colour, no direct placement
   on hive); p. 6 Grasshopper; p. 7 Spider; p. 8 Soldier Ant; p. 9 One Hive
   rule (incl. "unlinked while in transit"); p. 10 Freedom to Move (incl.
   placement-into-surrounded-space NB); p. 11 Unable to move or place / The
   End of the Game. (PDF not committed — publisher's copyright.)
2. **Gen42 Pillbug rulesheet** ("The Pillbug — Additional Hive Pieces",
   John Yianni), https://www.gen42.com/wp-content/uploads/Pillbug_Rules.pdf,
   English section: movement, special ability, the four exceptions, and the
   next-turn immobility of the moved piece.
3. **World Hive Tournaments — Rules FAQ**,
   https://www.worldhivetournaments.com/rules-of-hive/: gates and *beetle
   gates* above ground level ("If two stacks form a gate above the ground
   level, pieces won't be able to slide through"); stun clarifications
   ("any piece that just moved … is unable to: move, be moved or use the
   pillbug's ability"); draw by threefold repetition.
4. **Tournament opening rule** (queen not on the first turn): tournament
   variant of the official rules (not in the 2010 base rulesheet), adopted
   by UHP engines; see e.g. Wikipedia "Hive (game)", Tournament rules
   section, and the UHP convention (Mzinga wiki).

## Review status

**Unreviewed — declared limit (H2 task 4).** No Hive-literate external
reader has reviewed these annotations yet. Until one does, this is an
explicit limitation to be carried into the report's limits section. Sending
the corpus to an external reader requires G-PUBLIC. Each case nevertheless
cites the exact rule passage its expectation derives from.

## Running

```sh
python3 scripts/run_critical_corpus.py            # uses ./target/release/hive-engine
python3 scripts/run_critical_corpus.py --engine <path-to-uhp-engine>
```

The runner drives the engine over UHP (`newgame`/`play`/`validmoves`),
resolves MoveStrings to destination cells with its own notation parser (pure
geometry — no game rules), and reports PASS/FAIL per case with set diffs.
A setup move the engine rejects is reported as SETUP-ERROR (also a finding).
