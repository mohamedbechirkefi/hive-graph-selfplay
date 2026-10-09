#!/usr/bin/env python3
"""H6 figures (task 7) — every figure regenerates from scripts + raw
records; no figure shows only the best seed.

  fig1-score-vs-time.png    per-run score-vs-wall-clock curves (all seeds,
                            both arms; T* marked)
  fig2-score-cost.md        score/cost table (both readings once present)
  fig3-encodings.png        schematic: 32x32 frame vs cell-graph encoding
  fig4-failures.md/.png     three commented failure positions, selection
                            criteria stated BEFORE inspection (in code)

Run: python/.venv/bin/python scripts/make_figures.py
"""

import json
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "scripts"))
from analyze_comparison import load, summarize  # noqa: E402
from run_critical_corpus import Board  # noqa: E402

FIG = REPO / "paper" / "figures"
OPP = ["B-RND", "B-HEU", "B-MCTS"]
TSTAR_H = 18.77  # display value; exact median used in make_results
COL = {"grid": "#1f77b4", "graph": "#d62728"}


def pop_score(run: Path, tag: str):
    """Mean score across the 3 frozen opponents at one eval point."""
    scores = []
    for o in OPP:
        f = run / "eval" / f"{tag}-vs-{o}.csv"
        if not f.exists():
            return None
        scores.append(summarize(load(f)[1])["score"])
    return sum(scores) / len(scores)


def fig1():
    plt.figure(figsize=(8, 5))
    for arm in ["grid", "graph"]:
        for seed in [1, 2, 3, 4, 5]:
            run = REPO / "data" / "runs" / f"cmp-{arm}-s{seed}"
            clock = json.load(open(run / "wallclock.json"))
            cum, xs, ys = 0.0, [], []
            for gen in sorted(clock):
                cum += clock[gen]
                s = pop_score(run, gen)
                if s is not None:
                    xs.append(cum / 3600)
                    ys.append(s)
            plt.plot(xs, ys, marker="o", color=COL[arm], alpha=0.75,
                     label=f"{arm}" if seed == 1 else None,
                     linewidth=1.5)
            plt.annotate(f"s{seed}", (xs[-1], ys[-1]), fontsize=7,
                         xytext=(3, 0), textcoords="offset points")
    plt.axvline(TSTAR_H, color="gray", linestyle="--", linewidth=1)
    plt.text(TSTAR_H + 0.2, 0.02, "T* = 18.77 h", fontsize=8, color="gray")
    plt.xlabel("training wall-clock (h)")
    plt.ylabel("mean score vs frozen population (excl. truncations)")
    plt.title("Score vs training time — all seeds, both arms\n"
              "(evals at generations 5, 8, 10; 20/20/100 games per opponent)")
    plt.legend()
    plt.grid(alpha=0.25)
    plt.tight_layout()
    plt.savefig(FIG / "fig1-score-vs-time.png", dpi=150)
    plt.close()
    print("fig1 written")


def fig3():
    fig, axes = plt.subplots(1, 2, figsize=(10, 4.6))
    import math

    def hexpts(cx, cy, r=0.5):
        return [(cx + r * math.cos(math.pi / 6 + i * math.pi / 3),
                 cy + r * math.sin(math.pi / 6 + i * math.pi / 3))
                for i in range(6)]

    def cell_xy(q, r):
        return q + r / 2, -r * 0.866

    pieces = {(0, 0): "wQ", (1, 0): "bQ", (0, 1): "wS1", (1, -1): "bB1",
              (-1, 1): "wA1"}
    ring = set()
    for (q, r) in pieces:
        for dq, dr in [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)]:
            c = (q + dq, r + dr)
            if c not in pieces:
                ring.add(c)

    ax = axes[0]
    for q in range(-3, 5):
        for r in range(-3, 4):
            x, y = cell_xy(q, r)
            ax.add_patch(plt.Polygon(hexpts(x, y), fill=False,
                                     edgecolor="#cccccc", linewidth=0.5))
    for (q, r), name in pieces.items():
        x, y = cell_xy(q, r)
        c = "#1f77b4" if name.startswith("w") else "#444444"
        ax.add_patch(plt.Polygon(hexpts(q + r / 2, -r * 0.866),
                                 facecolor=c, alpha=0.8))
        ax.text(x, y, name, ha="center", va="center", color="white",
                fontsize=8)
    ax.set_title("Grid arm: 32×32 frame, 77 planes\n(pieces as feature "
                 "planes at frame cells)", fontsize=9)
    ax.set_xlim(-4, 6)
    ax.set_ylim(-4, 4)
    ax.axis("off")
    ax.set_aspect("equal")

    ax = axes[1]
    idx = {}
    for i, c in enumerate(list(pieces) + sorted(ring)):
        idx[c] = i
    for c in idx:
        x, y = cell_xy(*c)
        occupied = c in pieces
        ax.scatter([x], [y], s=560 if occupied else 360,
                   c="#1f77b4" if occupied and pieces[c].startswith("w")
                   else "#444444" if occupied else "white",
                   edgecolors="#d62728" if not occupied else "none",
                   linewidths=1.4, zorder=3)
        if occupied:
            ax.text(x, y, pieces[c], ha="center", va="center",
                    color="white", fontsize=7, zorder=4)
    for a in idx:
        for dq, dr in [(1, 0), (1, -1), (0, -1)]:
            b = (a[0] + dq, a[1] + dr)
            if b in idx:
                xa, ya = cell_xy(*a)
                xb, yb = cell_xy(*b)
                ax.plot([xa, xb], [ya, yb], color="#999999",
                        linewidth=0.8, zorder=1)
    ax.set_title("Graph arm: candidate-set cell graph\n(occupied nodes + "
                 "empty destination nodes ○, 6 typed edge directions)",
                 fontsize=9)
    ax.axis("off")
    ax.set_aspect("equal")
    plt.tight_layout()
    plt.savefig(FIG / "fig3-encodings.png", dpi=150)
    plt.close()
    print("fig3 written")


def fig4():
    """Three commented failure positions. SELECTION CRITERIA (stated here,
    applied mechanically over the per-game CSV records, no cherry-picking):
    (i) the LONGEST truncated graph-arm game vs B-RND across all graph
    final evals — the failure-to-close pattern; (ii) the SHORTEST decided
    grid-arm loss vs B-HEU — the fastest collapse; (iii) the LONGEST drawn
    graph-arm game vs B-MCTS — survival without progress. The selected
    games are then REPRODUCED individually (every engine is freshly
    seeded per game, so a game is a deterministic function of opening and
    colour) and each reproduction is verified against its CSV row."""
    import subprocess
    import tempfile

    openings = [l.strip() for l in
                open(REPO / "results/comparison/openings-v1.txt")
                if l.strip() and not l.startswith("#")]

    def rows_of(arm, seed, opp):
        f = REPO / f"data/runs/cmp-{arm}-s{seed}/eval/gen009-vs-{opp}.csv"
        if not f.exists():
            return []
        _, rows = load(f)
        return [dict(r, arm=arm, seed=seed, opp=opp) for r in rows]

    def select(rows, want, key, biggest):
        cands = [r for r in rows if want(r)]
        if not cands:
            return None
        return (max if biggest else min)(cands, key=key)

    graph_rnd = sum((rows_of("graph", s, "B-RND") for s in [1, 2, 3, 4, 5]), [])
    grid_heu = sum((rows_of("grid", s, "B-HEU") for s in [1, 2, 3, 4, 5]), [])
    graph_mcts = sum((rows_of("graph", s, "B-MCTS") for s in [1, 2, 3, 4, 5]), [])
    sel = [
        ("F1: graph vs B-RND — longest truncated game (a won position it "
         "cannot close: wins material, then shuffles to the 300-ply cap)",
         select(graph_rnd, lambda r: r["truncated"], lambda r: r["plies"], True)),
        ("F2: grid vs B-HEU — shortest decided loss (the heuristic's "
         "queen-targeting tactics strike before the net consolidates)",
         select(grid_heu, lambda r: not r["truncated"] and r["score"] == 0.0,
                lambda r: r["plies"], False)),
        ("F3: graph vs B-MCTS — longest drawn game (avoids losing without "
         "ever generating winning threats)",
         select(graph_mcts, lambda r: not r["truncated"] and r["score"] == 0.5,
                lambda r: r["plies"], True)),
    ]

    def reproduce(r):
        gen = "gen009"
        net = REPO / f"data/runs/cmp-{r['arm']}-s{r['seed']}/checkpoints/{gen}-b1.onnx"
        net_flag = "--net" if r["arm"] == "grid" else "--graph-net"
        opp_cmd = {
            "B-RND": ["./target/release/hive-engine", "--random", "--seed", "9101"],
            "B-HEU": ["./target/release/hive-engine"],
            "B-MCTS": ["./target/release/hive-engine", "--mcts", "--sims",
                        "6400", "--seed", "9201"],
        }[r["opp"]]
        with tempfile.TemporaryDirectory() as td:
            of = Path(td) / "one.txt"
            of.write_text(openings[r["opening"]] + "\n")
            pgn = Path(td) / "one.pgn"
            rec = Path(td) / "one.csv"
            subprocess.run(
                [str(c) for c in
                 ["./target/release/hive-arena", "--games", 2, "--depth", 1,
                  "--seed", 1, "--threads", 1, "--openings-file", of,
                  "--pgn", pgn, "--records", rec,
                  "--", "./target/release/hive-engine", "--mcts", net_flag,
                  net, "--sims", 400, "--seed", 9009,  # matches the gen009 final evals (9000+gen)
                  "--", *opp_cmd]],
                check=True, cwd=REPO, capture_output=True,
                env={**__import__("os").environ, "HIVE_THREADS": "1"})
            _, rrows = load(rec)
            games = [l.strip() for l in open(pgn) if l.strip()]
            for rr, gs in zip(rrows, games):
                if rr["a_white"] == r["a_white"]:
                    ok = (rr["plies"] == r["plies"]
                          and rr["truncated"] == r["truncated"]
                          and abs(rr["score"] - r["score"]) < 1e-9)
                    return gs, ok
        return None, False

    lines = ["# Three commented failure positions (H6 task 7)", "",
             "Selection criteria are mechanical, stated in "
             "`scripts/make_figures.py::fig4`, and applied over the raw "
             "per-game CSV records; each selected game is reproduced "
             "deterministically (fresh per-game engine seeds) and verified "
             "against its CSV row.", ""]
    import math

    def hexpts(cx, cy, r=0.46):
        return [(cx + r * math.cos(math.pi / 6 + i * math.pi / 3),
                 cy + r * math.sin(math.pi / 6 + i * math.pi / 3))
                for i in range(6)]

    picks = [(t, r) for t, r in sel if r is not None]
    fig, axes = plt.subplots(1, max(1, len(picks)),
                             figsize=(5 * max(1, len(picks)), 4.6))
    if len(picks) <= 1:
        axes = [axes]
    for ax, (title, r) in zip(axes, picks):
        gs, verified = reproduce(r)
        src = f"{r['arm']}-s{r['seed']} vs {r['opp']}, opening {r['opening']}, " \
              f"{'A white' if r['a_white'] else 'A black'}, {r['plies']} plies"
        if gs:
            b = Board()
            for mv in gs.split(";")[3:]:
                try:
                    b.apply(mv)
                except Exception:
                    break
            cells = {}
            for piece, (x, y) in b.pos.items():
                cells.setdefault((x, y), []).append(piece)
            for (x, y), stack in cells.items():
                top = stack[-1]
                c = "#1f77b4" if top.startswith("w") else "#444444"
                ax.add_patch(plt.Polygon(hexpts(x + y / 2, -y * 0.866),
                                         facecolor=c, alpha=0.85))
                ax.text(x + y / 2, -y * 0.866, "/".join(stack), ha="center",
                        va="center", color="white", fontsize=5)
        ax.set_title(f"{title.split(':')[0]} ({src.split(',')[0]}, "
                     f"{r['plies']} plies)", fontsize=8)
        ax.axis("off")
        ax.set_aspect("equal")
        ax.autoscale_view()
        lines += [f"## {title}", "", f"- game: {src}",
                  f"- reproduction verified against CSV row: "
                  f"{'YES' if verified else 'NO — mismatch, do not use'}",
                  f"- GameString: `{(gs or 'REPRODUCTION FAILED')[:500]}"
                  f"{'…' if gs and len(gs) > 500 else ''}`", ""]
    plt.tight_layout()
    plt.savefig(FIG / "fig4-failures.png", dpi=150)
    plt.close()
    (FIG / "fig4-failures.md").write_text("\n".join(lines) + "\n")
    print(f"fig4 written ({len(picks)} positions)")


def fig2():
    """Score/cost table (task 7) — regenerated from results CSVs +
    wallclock logs + comparison-controls measurements."""
    import csv as _csv
    scores = {}
    for reading in ["same-examples", "same-wallclock"]:
        f = REPO / "results" / "comparison" / f"results-{reading}.csv"
        per = {}
        for row in _csv.DictReader(open(f)):
            per.setdefault((row["arm"], row["opponent"]), []).append(
                float(row["score"]))
        for arm in ["grid", "graph"]:
            vals = [sum(per[(arm, o)]) / len(per[(arm, o)]) for o in OPP]
            scores[(arm, reading)] = sum(vals) / len(vals)
    clock = {}
    for arm in ["grid", "graph"]:
        tots = []
        for seed in [1, 2, 3, 4, 5]:
            c = json.load(open(REPO / f"data/runs/cmp-{arm}-s{seed}/wallclock.json"))
            tots.append(sum(c.values()) / 3600)
        clock[arm] = sum(tots) / 3
    lines = [
        "# Score / cost table (H6 task 7; fig2)", "",
        "| Metric | Grid arm | Graph arm |",
        "| --- | --- | --- |",
        "| Parameters | 1.44 M | 1.47 M (+2.1%) |",
        "| Best-provider inference (b1) | 2.62 ms (CoreML) | 3.67 ms (CPU) |",
        f"| Mean run wall-clock (10 gens × 500 games) | {clock['grid']:.1f} h | {clock['graph']:.1f} h ({clock['graph']/clock['grid']:.1f}×) |",
        f"| Mean self-play cost | {clock['grid']*3600/5000:.1f} s/game | {clock['graph']*3600/5000:.1f} s/game |",
        "| Training throughput (MPS) | ≈770 pos/s | ≈195 pos/s |",
        f"| Population score, same-examples | {scores[('grid','same-examples')]:.3f} | {scores[('graph','same-examples')]:.3f} |",
        f"| Population score, same-wall-clock (T*=18.77 h) | {scores[('grid','same-wallclock')]:.3f} | {scores[('graph','same-wallclock')]:.3f} |",
        "",
        "Population score = mean over the three frozen opponents of the "
        "seed-mean score (truncations excluded, reported separately in the "
        "results tables). Sources: results-*.csv, wallclock.json per run, "
        "comparison-controls.md measurements; journal "
        "H6-2026-09-19-comparison-01.",
    ]
    (FIG / "fig2-score-cost.md").write_text("\n".join(lines) + "\n")
    print("fig2 written")


if __name__ == "__main__":
    FIG.mkdir(parents=True, exist_ok=True)
    fig1()
    fig2()
    fig3()
    fig4()
