#!/usr/bin/env python3
"""D-006 consistency pass: every numeric token in each French file must
match its English master exactly (as a multiset). Catches dropped,
reformatted, or altered numbers in translation.

Usage: python3 scripts/check_fr_numbers.py
"""

import re
import sys
from collections import Counter
from pathlib import Path

PAPER = Path(__file__).resolve().parent.parent / "paper"
# A leading -/+ counts as a sign only when not glued to a word
# (English compounds like "generation-10" or "mate-in-1" are values,
# not negatives).
NUM = re.compile(r"(?<![\w])[−\-+]?\d+(?:[.,]\d+)?(?:\s*%)?")


def tokens(path):
    text = path.read_text()
    # Drop the French-copy banner line (contains the version date).
    text = "\n".join(l for l in text.splitlines()
                     if not l.startswith("*Copie française"))
    toks = [t.replace(",", ".").replace("−", "-").replace(" ", "")
            for t in NUM.findall(text)]
    return Counter(toks)


def main():
    base = PAPER
    if len(sys.argv) > 2 and sys.argv[1] == "--dir":
        base = Path(sys.argv[2]).resolve()
    fr_dir = base / "fr"
    if not fr_dir.is_dir():
        sys.exit(f"no {fr_dir} directory")
    failures = 0
    for fr in sorted(fr_dir.glob("*.md")):
        en = base / fr.name
        if not en.exists():
            print(f"  {fr.name}: no English master — SKIP")
            continue
        te, tf = tokens(en), tokens(fr)
        if te == tf:
            print(f"  {fr.name}: OK ({sum(te.values())} numeric tokens)")
        else:
            failures += 1
            missing = te - tf
            extra = tf - te
            print(f"  {fr.name}: MISMATCH")
            if missing:
                print(f"    in EN only: {dict(list(missing.items())[:8])}")
            if extra:
                print(f"    in FR only: {dict(list(extra.items())[:8])}")
    print("ALL NUMBERS CONSISTENT" if failures == 0
          else f"{failures} FILE(S) INCONSISTENT")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
