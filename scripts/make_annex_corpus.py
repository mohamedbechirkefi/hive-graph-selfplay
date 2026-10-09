#!/usr/bin/env python3
"""Generate the corpus annex (EN) from the hand-annotated case files —
the annex never retypes a case; it renders the TOMLs that the test
runners execute. Output: paper/annex-corpus.md
"""

import tomllib
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "paper" / "annex-corpus.md"


def render(case_dir, title, intro):
    lines = [f"## {title}", "", intro, ""]
    for f in sorted(Path(case_dir).glob("*.toml")):
        c = tomllib.load(open(f, "rb"))
        ann = c.get("annotation", {})
        exp = c.get("expect", {})
        lines.append(f"### {c['id']}: {c['title']}")
        lines.append("")
        lines.append(f"- **Rule:** {ann.get('rule', '')} "
                     f"(*{ann.get('source', '')}*)")
        if "setup" in c:
            lines.append(f"- **Setup:** `{';'.join(c['setup'])}`")
        kind = exp.get("kind", "")
        if kind:
            det = {k: v for k, v in exp.items() if k != "kind"}
            lines.append(f"- **Expectation:** {kind} "
                         f"`{det}`" if det else f"- **Expectation:** {kind}")
        just = " ".join(ann.get("justification", "").split())
        lines.append(f"- **Hand-written justification:** {just}")
        lines.append("")
    return lines


def main(report=False):
    title = ("# Annotated position corpora {#sec:app-a}" if report
             else "# Annex A: Hand-annotated position corpora")
    intro_report = ("Every expectation below was written by hand from the "
                    "publisher's rules before any engine run, so that the "
                    "corpus could serve as an unbiased oracle; the engine was "
                    "then run against it. The single disagreement found was "
                    "resolved against the corpus (a One-Hive transit error "
                    "in one setup sequence), and the engine was vindicated. "
                    "These renderings are generated directly from the "
                    "executable test cases, so the tests and this appendix "
                    "cannot drift apart. Setup sequences are given in the "
                    "move notation of the Universal Hive Protocol.")
    intro_annex = ("Every expectation below was written by hand from the "
                   "publisher's rules BEFORE any engine run (oracle-before-"
                   "output); the engine run that followed is journaled, and the "
                   "single disagreement found was resolved against the corpus "
                   "(a One-Hive transit error in a setup sequence), with the "
                   "engine vindicated. These renderings are generated from the "
                   "executable case files by `scripts/make_annex_corpus.py`, so "
                   "the tests and the annex cannot drift apart.")
    lines = [title, "", intro_report if report else intro_annex, ""]
    lines += render(REPO / "tests" / "critical_positions" / "cases",
                    "Critical rules corpus (30 cases)" if report
                    else "A.1 Critical rules corpus (30 cases, H2)",
                    "Rules-correctness cases: placement, sliding/freedom "
                    "to move, gates, stacking, One-Hive, terminal states, "
                    "forced pass, and kernel-guard Pillbug stun cases.")
    lines += render(REPO / "tests" / "tactical_positions" / "cases",
                    "Tactical verification set (5 cases)" if report
                    else "A.2 Tactical verification set (5 cases, H3)",
                    "Search-correctness cases: mate-in-1 by walk and by "
                    "jump from both colours, and self-surround avoidance; "
                    "solved 5/5 by the MCTS baseline at 400, 1600 and "
                    "6400 simulations.")
    out = (REPO / "paper" / "report" / "90-appendix-a-corpus.md"
           if report else OUT)
    out.write_text("\n".join(lines) + "\n")
    n = len([l for l in lines if l.startswith("### ")])
    print(f"{out.name}: {n} cases rendered")


if __name__ == "__main__":
    import sys
    main(report="--report" in sys.argv)
