#!/usr/bin/env python3
"""Run the hand-annotated critical position corpus against the UHP engine.

Cases live in tests/critical_positions/cases/*.toml (see the README there).
This script drives the engine over UHP (newgame/play/validmoves) and compares
expectations. MoveStrings are resolved to (piece, destination cell) with a
pure-geometry notation parser, so the reference piece chosen by the annotator
need not match the engine's canonical choice. No game rules are implemented
here — expectations come from the TOML files only.

Usage: python3 scripts/run_critical_corpus.py [--engine PATH] [--cases DIR]
Exit code: 0 iff all cases PASS.
"""

import argparse
import subprocess
import sys
import tomllib
from pathlib import Path

# Axial hex coordinates. Suffix markers: "R-" = E, "R/" = NE, "R\" = SE.
# Prefix markers: "-R" = W, "/R" = SW, "\R" = NW. (crates/hive-core notation.rs)
DIRS = {
    "E": (1, 0), "W": (-1, 0),
    "NE": (1, -1), "SW": (-1, 1),
    "NW": (0, -1), "SE": (0, 1),
}
SUFFIX = {"-": "E", "/": "NE", "\\": "SE"}
PREFIX = {"-": "W", "/": "SW", "\\": "NW"}


class Board:
    """Tracks piece -> cell from a sequence of MoveStrings. Geometry only."""

    def __init__(self):
        self.pos = {}  # piece name -> (q, r)

    def resolve(self, movestr):
        """Return (piece, destination cell) for a MoveString, or None for pass."""
        s = movestr.strip()
        if s == "pass":
            return None
        parts = s.split()
        piece = parts[0]
        if len(parts) == 1:
            return piece, (0, 0)  # first placement of the game
        ref = parts[1]
        if ref[0] in PREFIX and ref[1:] in self.pos:
            d = DIRS[PREFIX[ref[0]]]
            rq, rr = self.pos[ref[1:]]
        elif ref[-1] in SUFFIX and ref[:-1] in self.pos:
            d = DIRS[SUFFIX[ref[-1]]]
            rq, rr = self.pos[ref[:-1]]
        elif ref in self.pos:
            return piece, self.pos[ref]  # land on top of ref's stack
        else:
            raise ValueError(f"unresolvable reference {ref!r} in {movestr!r}")
        return piece, (rq + d[0], rr + d[1])

    def apply(self, movestr):
        r = self.resolve(movestr)
        if r is not None:
            piece, cell = r
            self.pos[piece] = cell


class Engine:
    def __init__(self, path):
        self.p = subprocess.Popen(
            [path], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True
        )
        self._read()  # banner

    def _read(self):
        lines = []
        while True:
            line = self.p.stdout.readline()
            if not line:
                raise RuntimeError("engine closed stdout")
            line = line.rstrip("\n")
            if line == "ok":
                return lines
            lines.append(line)

    def cmd(self, text):
        self.p.stdin.write(text + "\n")
        self.p.stdin.flush()
        return self._read()

    def close(self):
        try:
            self.p.stdin.write("exit\n")
            self.p.stdin.flush()
        except Exception:
            pass
        self.p.wait(timeout=10)


def fmt_cells(items):
    return ", ".join(f"{p}->({q},{r})" for p, (q, r) in sorted(items)) or "(none)"


def run_case(engine_path, case):
    eng = Engine(engine_path)
    try:
        board = Board()
        resp = eng.cmd(f"newgame {case.get('game_type', 'Base')}")
        if resp and resp[0].startswith("err"):
            return "SETUP-ERROR", f"newgame: {resp[0]}"
        last_state = resp[0] if resp else ""
        for mv in case.get("setup", []):
            resp = eng.cmd(f"play {mv}")
            if resp and (resp[0].startswith("invalidmove") or resp[0].startswith("err")):
                return "SETUP-ERROR", f"setup move {mv!r}: {resp[0]}"
            last_state = resp[0] if resp else last_state
            board.apply(mv)

        exp = case["expect"]
        kind = exp["kind"]

        if kind == "game_over":
            state = last_state.split(";")[1] if ";" in last_state else "?"
            if state == exp["state"]:
                return "PASS", ""
            return "FAIL", f"expected state {exp['state']}, engine says {state}"

        if kind in ("move_legal", "move_illegal"):
            resp = eng.cmd(f"play {exp['move']}")
            rejected = bool(resp) and (
                resp[0].startswith("invalidmove") or resp[0].startswith("err")
            )
            if kind == "move_legal" and not rejected:
                return "PASS", ""
            if kind == "move_illegal" and rejected:
                return "PASS", ""
            detail = resp[0] if resp else "(no response)"
            return "FAIL", f"play {exp['move']!r} -> {detail}"

        resp = eng.cmd("validmoves")
        raw = resp[0] if resp else ""
        engine_moves = [m for m in raw.split(";") if m] if raw else []

        if kind == "must_pass":
            if engine_moves == ["pass"] or engine_moves == []:
                return "PASS", ""
            return "FAIL", f"expected only pass, engine offers: {raw}"

        if kind == "all_moves_place":
            piece = exp["piece"]
            bad = [m for m in engine_moves
                   if m == "pass" or m.split()[0] != piece or m.split()[0] in board.pos]
            if not bad:
                return "PASS", ""
            return "FAIL", f"non-{piece}-placement moves offered: {bad}"

        if kind == "all_moves_are_placements":
            bad = [m for m in engine_moves if m != "pass" and m.split()[0] in board.pos]
            if not bad:
                return "PASS", ""
            return "FAIL", f"movement moves offered before queen placed: {bad}"

        if kind == "moves_for_piece":
            piece = exp["piece"]
            got = {board.resolve(m) for m in engine_moves
                   if m != "pass" and m.split()[0] == piece}
            want = {board.resolve(m) for m in exp.get("moves", [])}
            if got == want:
                return "PASS", ""
            return "FAIL", (
                f"for {piece}: expected {{{fmt_cells(want)}}}, "
                f"engine has {{{fmt_cells(got)}}}; "
                f"missing={fmt_cells(want - got)}; extra={fmt_cells(got - want)}"
            )

        return "SETUP-ERROR", f"unknown expectation kind {kind!r}"
    finally:
        eng.close()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--engine", default="./target/release/hive-engine")
    ap.add_argument("--cases", default="tests/critical_positions/cases")
    ap.add_argument("--only", help="run a single case id")
    args = ap.parse_args()

    files = sorted(Path(args.cases).glob("*.toml"))
    if not files:
        print(f"no cases found under {args.cases}", file=sys.stderr)
        return 2

    counts = {"PASS": 0, "FAIL": 0, "SETUP-ERROR": 0}
    for f in files:
        with open(f, "rb") as fh:
            case = tomllib.load(fh)
        if args.only and case.get("id") != args.only:
            continue
        status, detail = run_case(args.engine, case)
        counts[status] += 1
        line = f"[{status}] {case.get('id', f.name)} — {case.get('title', '')}"
        if detail:
            line += f"\n    {detail}"
        print(line)

    total = sum(counts.values())
    print(f"\n{total} cases: {counts['PASS']} pass, {counts['FAIL']} fail, "
          f"{counts['SETUP-ERROR']} setup errors")
    return 0 if counts["FAIL"] == 0 and counts["SETUP-ERROR"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
