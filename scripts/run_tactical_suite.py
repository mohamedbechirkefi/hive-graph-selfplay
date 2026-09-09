#!/usr/bin/env python3
"""Run the hand-annotated tactical set against the MCTS baseline (H3 task 4).

Cases in tests/tactical_positions/cases/*.toml. For each case the engine
(`hive-engine --mcts --sims N --seed S`) is asked for `bestmove depth 1`
(= exactly N simulations); the reply is resolved to a destination cell and
compared to the expectation:
  - bestmove_to_cell:    the move must land on the target cell
  - bestmove_avoid_cell: the move must NOT land on the target cell

The target is written as the reference part of a MoveString (e.g. "bQ\\" =
SE of bQ) and resolved with the corpus notation parser — geometry only, no
game rules. Exit code 0 iff all cases pass.
"""

import argparse
import sys
import tomllib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from run_critical_corpus import Board, Engine  # noqa: E402


def resolve_target(board, target):
    """Resolve a reference-only string like 'bQ\\' or '-wQ' to a cell."""
    piece, cell = board.resolve(f"?? {target}")
    return cell


def run_case(engine_cmd, case):
    eng = Engine(engine_cmd)
    try:
        board = Board()
        resp = eng.cmd(f"newgame {case.get('game_type', 'Base')}")
        if resp and resp[0].startswith("err"):
            return "SETUP-ERROR", f"newgame: {resp[0]}"
        for mv in case.get("setup", []):
            resp = eng.cmd(f"play {mv}")
            if resp and (resp[0].startswith("invalidmove") or resp[0].startswith("err")):
                return "SETUP-ERROR", f"setup move {mv!r}: {resp[0]}"
            board.apply(mv)

        exp = case["expect"]
        target = resolve_target(board, exp["target"])
        resp = eng.cmd("bestmove depth 1")
        reply = resp[0] if resp else ""
        if reply.startswith("err"):
            return "FAIL", f"bestmove: {reply}"
        try:
            _, dest = board.resolve(reply)
        except (ValueError, TypeError):
            return "FAIL", f"unresolvable bestmove reply {reply!r}"

        kind = exp["kind"]
        if kind == "bestmove_to_cell":
            if dest == target:
                return "PASS", f"played {reply}"
            return "FAIL", f"expected a move to {target}, engine played {reply!r} -> {dest}"
        if kind == "bestmove_avoid_cell":
            if dest != target:
                return "PASS", f"played {reply}"
            return "FAIL", f"engine played into the forbidden cell {target}: {reply!r}"
        return "SETUP-ERROR", f"unknown expectation kind {kind!r}"
    finally:
        eng.close()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--engine", default="./target/release/hive-engine")
    ap.add_argument("--sims", type=int, default=6400)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--cases", default="tests/tactical_positions/cases")
    args = ap.parse_args()

    files = sorted(Path(args.cases).glob("*.toml"))
    if not files:
        print(f"no cases found under {args.cases}", file=sys.stderr)
        return 2

    counts = {"PASS": 0, "FAIL": 0, "SETUP-ERROR": 0}
    for f in files:
        with open(f, "rb") as fh:
            case = tomllib.load(fh)
        status, detail = run_case(
            f"{args.engine} --mcts --sims {args.sims} --seed {args.seed}", case
        )
        counts[status] += 1
        print(f"[{status}] {case.get('id', f.name)} — {case.get('title', '')}")
        if detail:
            print(f"    {detail}")

    total = sum(counts.values())
    print(f"\n{total} cases at {args.sims} sims: {counts['PASS']} pass, "
          f"{counts['FAIL']} fail, {counts['SETUP-ERROR']} setup errors")
    return 0 if counts["FAIL"] == 0 and counts["SETUP-ERROR"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
