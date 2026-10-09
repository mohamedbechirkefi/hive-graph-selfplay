#!/usr/bin/env python3
"""Traceability check for the report (SPEC §6.1): every numeric token in
paper/report/*.md must occur somewhere in the evidence base (docs/,
journal/, results/, configs/, tests cases, the verified paper/*.md
sections, the workspace decision log and methodology docs). Tokens that
appear nowhere are listed with their paragraph for manual review — they
are either computed/rounded (forbidden) or invented.

Usage: python3 scripts/check_report_sources.py [chapter-file ...]
"""

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
WS = REPO.parent
REPORT = REPO / "paper" / "report"
SOURCES = [REPO / "docs", REPO / "journal", REPO / "results", REPO / "configs",
           REPO / "tests", REPO / "paper", REPO / "python" / "hivenet",
           REPO / "scripts", WS / "state" / "decisions.md",
           WS / "docs", WS / "plan_recherche_hive_trading.md"]
EXT = {".md", ".csv", ".toml", ".yaml", ".yml", ".txt", ".py", ".sh", ".json"}
NUM = re.compile(r"(?<![\w])[−\-+]?\d+(?:,\d{3})*(?:\.\d+)?(?:\s*%)?")
TRIVIAL = {str(i) for i in range(0, 13)}  # small integers: too common to check


def norm(t):
    return t.replace(",", "").replace("−", "-").replace(" ", "").lstrip("+")


def tokens(text):
    return {norm(t) for t in NUM.findall(text)}


def evidence():
    toks = set()
    for root in SOURCES:
        if root.is_file():
            toks |= tokens(root.read_text(errors="ignore"))
            continue
        for p in root.rglob("*"):
            if p.suffix in EXT and p.is_file() and "report" not in p.parts \
                    and "build" not in p.parts:
                try:
                    toks |= tokens(p.read_text(errors="ignore"))
                except Exception:
                    pass
    return toks


def main(argv):
    files = [Path(a) for a in argv] or sorted(REPORT.glob("[0-9][0-9]-*.md"))
    ev = evidence()
    total_bad = 0
    for f in files:
        text = f.read_text()
        bad = []
        for para in re.split(r"\n\s*\n", text):
            body = re.sub(r"<!--.*?-->", "", para, flags=re.S)
            body = re.sub(r"`@[\w:-]+`\{=typst\}", "", body)
            for t in tokens(body):
                core = norm(t).rstrip("%").lstrip("-")
                if core in TRIVIAL:
                    continue
                if norm(t) not in ev and core not in ev and (core + "%") not in ev:
                    bad.append((t, body.strip().replace("\n", " ")[:70]))
        total_bad += len(bad)
        print(f"{f.name}: {len(bad)} untraceable token(s)")
        for t, ctx in bad[:40]:
            print(f"   {t!r:14} … {ctx}")
    print("ALL TRACEABLE" if total_bad == 0 else f"{total_bad} TOKEN(S) TO REVIEW")
    return 1 if total_bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
