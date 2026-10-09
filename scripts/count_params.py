#!/usr/bin/env python3
"""Exact parameter counts of the study's networks (derived artifact for
the report): instantiates each architecture exactly as the campaign
drivers did and writes results/comparison/parameter-counts.md.
Usage: cd python && ../python/.venv/bin/python ../scripts/count_params.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "python"))
import torch  # noqa: E402
from hivenet.model import HiveNet  # noqa: E402
from hivenet.graph_model import HiveGraphNet  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "results" / "comparison" / "parameter-counts.md"


def count(m):
    return sum(p.numel() for p in m.parameters())


def main():
    torch.manual_seed(0)
    nets = [
        ("Grid arm — HiveNet c96×b8", HiveNet(channels=96, blocks=8)),
        ("Graph arm — HiveGraphNet h152×L8", HiveGraphNet(hidden=152, layers=8)),
        ("A1 variant — untyped edges", HiveGraphNet(hidden=152, layers=8, untyped_edges=True)),
        ("A2 variant — no global pooling", HiveGraphNet(hidden=152, layers=8, no_gpool=True)),
    ]
    rows = [(n, count(m)) for n, m in nets]
    grid, graph = rows[0][1], rows[1][1]
    lines = ["# Exact parameter counts (derived from the model code)", "",
             "Counted with `sum(p.numel() for p in model.parameters())` on the "
             "architectures as instantiated by the campaign drivers.", "",
             "| Network | Parameters | Rounded | Relative to grid |",
             "| --- | ---: | ---: | ---: |"]
    for n, c in rows:
        lines.append(f"| {n} | {c:,} | {c/1e6:.2f} M | {100*(c-grid)/grid:+.1f}% |")
    lines += ["", f"Graph − grid = {graph-grid:,} parameters = "
              f"{100*(graph-grid)/grid:+.2f}% (the figure +2.1% quoted in "
              "earlier documents is the ratio of the rounded millions "
              "1.47/1.44; the exact ratio is "
              f"{100*(graph-grid)/grid:+.1f}%)."]
    OUT.write_text("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
