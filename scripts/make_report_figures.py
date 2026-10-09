#!/usr/bin/env python3
"""Schematic report figures (no data, no best-seed selection involved):

  fig8-pipeline.png       the self-play generation loop, both arms
  fig9-architectures.png  HiveNet vs HiveGraphNet block diagrams
  fig10-timeline.png      project chronology, July-October 2026

Facts come from paper/annex-architectures.md, paper/annex-reproduction.md,
docs/inventory.md, the journal YAML headers and ../state/decisions.md
(verified against `git log --date=short` on 2026-10-09). Nothing here is
measured; it is drawn.

Run: python/.venv/bin/python scripts/make_report_figures.py [--check]
  --check prints every pair of overlapping text boxes and every text box
  that leaves the canvas (render-time measurement), then exits non-zero
  if any were found.
"""

import sys
from datetime import datetime as dt
from itertools import combinations
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.dates as mdates  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch, Patch, Rectangle  # noqa: E402
from matplotlib.text import Text  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
FIG = REPO / "paper" / "figures"
DPI = 200

# ---- palette (muted; grid = blue, graph = orange, shared = grey) ----------
C = {
    "grid":   {"ec": "#2a78d6", "fc": "#dce8f8", "fc2": "#b7d3f6"},
    "graph":  {"ec": "#d95926", "fc": "#fbe3d8", "fc2": "#f6c3ad"},
    "shared": {"ec": "#898781", "fc": "#f0efec", "fc2": "#e1e0d9"},
    "plain":  {"ec": "#898781", "fc": "#ffffff", "fc2": "#ffffff"},
}
INK, INK2, MUTED, LINE = "#0b0b0b", "#52514e", "#898781", "#6f6e69"

plt.rcParams.update({
    "font.family": "DejaVu Sans",
    "mathtext.fontset": "dejavusans",
    "font.size": 8,
    "savefig.dpi": DPI,
    "savefig.facecolor": "white",
    "figure.facecolor": "white",
})

FS_TITLE, FS_BODY, FS_SMALL = 8.0, 7.5, 7.0
LS = 1.25  # line spacing


# ---- primitives (coordinates in inches, origin bottom-left) ---------------
def canvas(w, h):
    fig = plt.figure(figsize=(w, h))
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(0, w)
    ax.set_ylim(0, h)
    ax.set_aspect("equal")
    ax.axis("off")
    return fig, ax


def box(ax, x, y, w, h, title=None, lines=(), kind="shared", *, fs=FS_BODY,
        fs_title=FS_TITLE, pad=0.07, valign="top", dashed=False, fill=None,
        title_color=INK, lw=1.0, rounding=0.05, zorder=2):
    """Rounded box with an optional bold title and body lines."""
    col = C[kind]
    patch = FancyBboxPatch(
        (x, y), w, h, boxstyle=f"round,pad=0,rounding_size={rounding}",
        linewidth=lw, edgecolor=col["ec"], facecolor=fill or col["fc"],
        linestyle=(0, (3, 2)) if dashed else "-", zorder=zorder)
    ax.add_patch(patch)
    line_h = fs * LS / 72.0
    block_h = (fs_title * LS / 72.0 if title else 0) + len(lines) * line_h
    cy = y + h / 2 + block_h / 2 if valign == "center" else y + h - pad
    if title:
        ax.text(x + pad, cy, title, fontsize=fs_title, fontweight="bold",
                color=title_color, ha="left", va="top", zorder=zorder + 1)
        cy -= fs_title * LS / 72.0
    for ln in lines:
        ax.text(x + pad, cy, ln, fontsize=fs, color=INK2, ha="left",
                va="top", zorder=zorder + 1)
        cy -= line_h
    return patch


def arrow(ax, p, q, *, color=LINE, lw=1.0, scale=9, zorder=3, style="-|>"):
    ax.add_patch(FancyArrowPatch(p, q, arrowstyle=style, mutation_scale=scale,
                                 linewidth=lw, color=color, shrinkA=0,
                                 shrinkB=0, zorder=zorder))


def label(ax, x, y, s, *, fs=FS_SMALL, color=INK2, ha="left", va="center",
          weight="normal", style="normal", zorder=4, **kw):
    return ax.text(x, y, s, fontsize=fs, color=color, ha=ha, va=va,
                   fontweight=weight, fontstyle=style, zorder=zorder, **kw)


# ---- fig 8: the self-play generation loop ---------------------------------
def fig8():
    W, H = 7.0, 4.85
    fig, ax = canvas(W, H)

    # top row: network container -----------------------------------------
    cx, cy, cw, ch = 0.2, 3.1, 4.0, 1.55
    box(ax, cx, cy, cw, ch, kind="plain", rounding=0.06, zorder=1)
    label(ax, cx + 0.1, cy + ch - 0.12, "Current network, generation g (ONNX)",
          fs=FS_TITLE, color=INK, weight="bold")
    ay, ah = cy + 0.71, 0.6
    box(ax, 0.33, ay, 1.75, ah, "Grid arm: encoder + body",
        ["77×32×32 planes", "→ HiveNet, 1.44 M params"], kind="grid",
        fs=FS_SMALL, fs_title=7.5)
    box(ax, 2.32, ay, 1.75, ah, "Graph arm: encoder + body",
        ["224-node cell graph", "→ HiveGraphNet, 1.47 M params"],
        kind="graph", fs=FS_SMALL, fs_title=7.5)
    label(ax, 2.2, ay + ah / 2, "or", fs=FS_SMALL, color=MUTED, ha="center",
          style="italic")
    dy, dh = cy + 0.1, 0.38
    box(ax, 0.33, dy, 3.74, dh, "Shared action decoder",
        ["(piece slot, destination) + pass · legal masking"], kind="shared",
        fs=FS_SMALL, fs_title=7.5, pad=0.05)
    arrow(ax, (0.33 + 0.875, ay), (0.33 + 0.875, dy + dh), color=C["grid"]["ec"])
    arrow(ax, (2.32 + 0.875, ay), (2.32 + 0.875, dy + dh), color=C["graph"]["ec"])

    # self-play workers
    sx, sw = 4.7, 2.1
    box(ax, sx, cy, sw, ch, "Self-play workers",
        ["PUCT MCTS, 128 / 32 simulations",
         "playout-cap randomization 25 %",
         "Dirichlet root noise",
         "temperature sampling, 12 plies",
         "resignation −0.92, 10 % audit",
         "300-ply truncation"], kind="shared", valign="center")
    arrow(ax, (cx + cw, cy + ch / 2), (sx, cy + ch / 2))

    # middle row ----------------------------------------------------------
    my, mh = 1.7, 0.9
    box(ax, 0.2, my, 1.5, mh, "Export (ONNX)", ["→ next generation"],
        kind="shared", valign="center")
    box(ax, 2.1, my, 2.2, mh, "Training",
        ["SGD, lr 0.02 cosine, batch 256",
         "2 epochs per generation",
         "legal-masked policy loss",
         "+ 0.6 × value loss"], kind="shared")
    box(ax, sx, my, sw, mh, "Training records (v3, 818 B)",
        ["position · legal-move list",
         "MCTS visit distribution",
         "outcome incl. truncation"], kind="shared")
    arrow(ax, (sx + sw / 2, cy), (sx + sw / 2, my + mh))          # play -> rec
    arrow(ax, (sx, my + mh / 2), (4.3, my + mh / 2))              # rec -> train
    arrow(ax, (2.1, my + mh / 2), (1.7, my + mh / 2))             # train -> exp
    arrow(ax, (0.95, my + mh), (0.95, cy))                        # exp -> net
    label(ax, 1.08, (my + mh + cy) / 2,
          "× 10 generations per run (500 games each) · 5 seeds per arm",
          fs=FS_SMALL, color=INK, style="italic")

    # evaluation branch ---------------------------------------------------
    ey, eh = 0.2, 1.05
    box(ax, 0.2, ey, 6.6, eh, "Evaluation of every exported generation",
        ["100 paired games per frozen opponent",
         "on 250 frozen openings",
         "400 simulations, no noise"], kind="shared")
    arrow(ax, (0.95, my), (0.95, ey + eh))
    label(ax, 1.05, (my + ey + eh) / 2, "each generation", fs=FS_SMALL,
          color=MUTED, style="italic")
    label(ax, 3.75, ey + eh - 0.13, "frozen opponent population:",
          fs=FS_SMALL, color=INK2)
    for i, name in enumerate(["B-RND", "B-HEU", "B-MCTS@6400"]):
        bx = 3.75 + i * 1.0
        box(ax, bx, ey + 0.18, 0.9, 0.42, kind="plain")
        label(ax, bx + 0.45, ey + 0.39, name, fs=FS_BODY, color=INK,
              ha="center", weight="bold")

    fig.savefig(FIG / "fig8-pipeline.png")
    return fig


# ---- fig 9: the two network architectures ---------------------------------
def column(ax, x0, w, kind, hdr, inp, stem, body_title, rows_word, card,
           policy, value, params, dashed):
    col = C[kind]
    label(ax, x0 + w / 2, 6.26, hdr, fs=10, color=col["ec"], ha="center",
          weight="bold")
    # input / stem
    y_in, h_in = 5.56, 0.5
    box(ax, x0, y_in, w, h_in, inp[0], inp[1:], kind=kind, fs=FS_SMALL)
    y_st, h_st = 5.0, 0.36
    box(ax, x0, y_st, w, h_st, stem[0], stem[1:], kind=kind, fs=FS_SMALL,
        pad=0.05)
    arrow(ax, (x0 + w / 2, y_in), (x0 + w / 2, y_st + h_st), color=col["ec"])
    # body
    y_b, h_b = 2.7, 2.1
    box(ax, x0, y_b, w, h_b, body_title, kind=kind)
    arrow(ax, (x0 + w / 2, y_st), (x0 + w / 2, y_b + h_b), color=col["ec"])
    # 8 stacked rows
    rx, rw, rh, rg = x0 + 0.1, 0.85, 0.17, 0.02
    ry = y_b + h_b - 0.34
    for i in range(8):
        yy = ry - i * (rh + rg) - rh
        hi = i in (2, 5)
        ax.add_patch(Rectangle((rx, yy), rw, rh, facecolor=col["fc2"] if hi
                               else "white", edgecolor=col["ec"],
                               linewidth=0.7, zorder=3))
        label(ax, rx + 0.05, yy + rh / 2, f"{rows_word} {i}" +
              (" · GP" if hi else ""), fs=6.5, color=INK, zorder=4)
    y_rows_bot = ry - 8 * (rh + rg) + rg
    # detail card
    kx, kw_ = x0 + 1.12, w - 1.12 - 0.1
    ky, kh = y_b + 0.08, h_b - 0.42
    box(ax, kx, ky, kw_, kh, kind="plain", lw=0.7, rounding=0.03)
    label(ax, kx + 0.07, ky + kh - 0.1, card["title"], fs=7.5, color=INK,
          weight="bold")
    cy = ky + kh - 0.2
    for ln in card.get("pre", []):
        label(ax, kx + 0.07, cy, ln, fs=FS_SMALL, color=INK2, va="top")
        cy -= 0.2
    cy -= 0.02
    for sub in card["subs"]:
        sh = 0.1 + len(sub) * (6.8 * LS / 72.0)
        box(ax, kx + 0.07, cy - sh, kw_ - 0.14, sh, sub[0], sub[1:],
            kind=kind, fs=6.8, fs_title=6.8, pad=0.045, dashed=dashed,
            fill="white", rounding=0.02, lw=0.9 if dashed else 0.7,
            title_color=col["ec"] if dashed else INK)
        cy -= sh + 0.06
    for ln in card.get("post", []):
        label(ax, kx + 0.07, cy, ln, fs=FS_SMALL, color=INK2, va="top")
        cy -= FS_SMALL * LS / 72.0
    mid = (ry + y_rows_bot) / 2
    arrow(ax, (rx + rw, mid), (kx, mid), color=MUTED, lw=0.8, scale=7)
    # heads
    y_h, h_h = 1.4, 1.08
    pw, vw = 1.95, w - 1.95 - 0.1
    box(ax, x0, y_h, pw, h_h, policy[0], policy[1:], kind=kind, fs=FS_SMALL)
    box(ax, x0 + pw + 0.1, y_h, vw, h_h, value[0], value[1:], kind=kind,
        fs=FS_SMALL)
    arrow(ax, (x0 + pw / 2, y_b), (x0 + pw / 2, y_h + h_h), color=col["ec"])
    arrow(ax, (x0 + pw + 0.1 + vw / 2, y_b), (x0 + pw + 0.1 + vw / 2, y_h + h_h),
          color=col["ec"])
    label(ax, x0 + w / 2, 1.2, params, fs=8.5, color=col["ec"], ha="center",
          weight="bold")


def fig9():
    W, H = 7.0, 6.5
    fig, ax = canvas(W, H)
    w = 3.25
    column(
        ax, 0.15, w, "grid", "HiveNet (grid arm)",
        ["Input: 77 × 32 × 32 planes",
         "float32 ∈ [0, 1]; 32×32 BFS-unwrapped frame"],
        ["3×3 conv stem → 96 channels (BN, ReLU)"],
        "8 residual blocks, 96 channels", "block",
        {"title": "each block",
         "pre": [r"$h' = \mathrm{ReLU}(h + F(h))$"],
         "subs": [["F: two 3×3 convolutions + BN",
                   "hex adjacency = 7 of the 9 taps;",
                   "2 corner taps: dead weights"],
                  ["global-pooling bias",
                   "blocks 2 and 5 only (rows GP):",
                   "mean ‖ max pooled → linear",
                   "→ per-channel bias, inside F"]],
         "post": ["residual add, then ReLU"]},
        ["Policy head", "1×1 conv → 28 piece-slot planes",
         "flatten → 28,672 spatial logits", "+ pass logit (pooled features)",
         "= 28,673 logits"],
        ["Value head", "global mean pool", "→ 64 → 3", "(W / D / L)"],
        "1.44 M parameters", dashed=False)
    column(
        ax, 3.6, w, "graph", "HiveGraphNet (graph arm)",
        ["Input: ≤ 224 nodes × 56 features",
         "‖ 23 globals per node; (224 × 6) neighbour index"],
        ["Linear → 152 channels"],
        "8 relational message-passing layers, 152 ch", "layer",
        {"title": "each layer",
         "pre": [r"$h'_i = \mathrm{ReLU}(W_{\mathrm{self}}\,h_i + "
                 r"\Sigma_{d=1}^{6}\, W_d\,h_{n_i(d)} + b)$"],
         "subs": [["typed relations (ablation A1)",
                   "W_d: one weight matrix per hex",
                   "direction d = 1…6, plus W_self"],
                  ["global-pooling bias (ablation A2)",
                   "layers 2 and 5 only (rows GP):",
                   "masked mean ‖ max pooled → linear",
                   "→ per-channel bias"]],
         "post": ["+ residual; padded nodes masked"]},
        ["Policy head (per legal move)", "for each legal (slot, destination):",
         "MLP(dest emb ‖ source emb", "      ‖ slot emb[32]) → logit",
         "source: standing node (move) or", "learned reserve vector (place)",
         "+ one learned pass logit"],
        ["Value head", "masked mean ‖ max", "pooling ‖ globals", "→ 64 → 3",
         "(W / D / L)"],
        "1.47 M parameters (+1.5 %)", dashed=True)
    label(ax, 3.6 + w / 2, 1.0,
          "dashed = component removed in the ablations (A1, A2)",
          fs=6.5, color=C["graph"]["ec"], ha="center", style="italic")
    box(ax, 0.15, 0.25, 6.7, 0.6, "Shared by both arms",
        ["identical legal-set masking · softmax over exactly the legal set · "
         "identical MCTS visit-distribution targets",
         "fixed-shape ONNX export · same Rust inference path · same search, "
         "records and training conventions"],
        kind="shared", fs=FS_SMALL, pad=0.06)
    fig.savefig(FIG / "fig9-architectures.png")
    return fig


# ---- fig 10: chronology ----------------------------------------------------
def d(s):
    return dt.strptime(s, "%Y-%m-%d %H:%M" if " " in s else "%Y-%m-%d")


BAR = {
    "both":     {"fc": "#cfcec8", "ec": "#898781", "hatch": None},
    "graph":    {"fc": C["graph"]["fc2"], "ec": C["graph"]["ec"], "hatch": None},
    "prior":    {"fc": "white", "ec": "#898781", "hatch": "////"},
    "analysis": {"fc": "white", "ec": "#52514e", "hatch": None},
}


def fig10():
    W, H = 7.0, 4.45
    Y_TOP, Y_BOT = 1.95, 2.35                # inches above / below baseline
    fig = plt.figure(figsize=(W, H))
    left_in, gap_in, right_margin = 0.3, 0.22, 0.12
    wl = 1.85
    wr = W - left_in - gap_in - wl - right_margin
    y0 = (H - (Y_TOP + Y_BOT)) / 2 / H
    hf = (Y_TOP + Y_BOT) / H
    width_in = {}

    def make_ax(x_in, w_in, t0, t1):
        ax = fig.add_axes([x_in / W, y0, w_in / W, hf])
        ax.set_xlim(mdates.date2num(t0), mdates.date2num(t1))
        ax.set_ylim(-Y_BOT, Y_TOP)
        ax.axis("off")
        ax.axhline(0, color=MUTED, lw=1.2, zorder=1)
        width_in[ax] = w_in
        return ax

    axL = make_ax(left_in, wl, d("2026-07-01"), d("2026-08-31"))
    axR = make_ax(left_in + wl + gap_in, wr, d("2026-09-07"), d("2026-10-12"))

    def days_per_in(ax):
        return (ax.get_xlim()[1] - ax.get_xlim()[0]) / width_in[ax]

    def ticks(ax, items):
        for s, txt in items:
            x = mdates.date2num(d(s))
            ax.plot([x, x], [0, -0.07], color=MUTED, lw=0.8, zorder=1)
            ax.text(x, -0.1, txt, fontsize=6.3, color=MUTED, ha="center",
                    va="top")

    ticks(axL, [("2026-07-01", "1 Jul 2026"), ("2026-08-01", "1 Aug")])
    ticks(axR, [("2026-09-08", "8 Sep"), ("2026-09-15", "15 Sep"),
                ("2026-09-22", "22 Sep"), ("2026-09-29", "29 Sep"),
                ("2026-10-06", "6 Oct")])

    # axis break glyph
    for ax, xfrac in ((axL, 1.0), (axR, 0.0)):
        xa = ax.get_xlim()[0] + xfrac * (ax.get_xlim()[1] - ax.get_xlim()[0])
        dx = days_per_in(ax) * 0.05
        for off in (-0.6, 0.6):
            ax.plot([xa - dx + off * dx, xa + dx + off * dx], [-0.08, 0.08],
                    color=MUTED, lw=1.0, clip_on=False, zorder=5)

    def milestone(ax, s, lines, level, ha="left"):
        """Dot on the baseline, leader up to `level`, text block whose
        bottom sits at `level`; lines read top-down (date line first)."""
        x = mdates.date2num(d(s))
        ax.plot([x, x], [0, level - 0.03], color=MUTED, lw=0.7, zorder=2)
        ax.plot(x, 0, "o", ms=5.5, mfc=INK2, mec="white", mew=0.8, zorder=6)
        off = days_per_in(ax) * 0.04
        xt = x + off if ha == "left" else x - off
        lh = FS_SMALL * LS / 72.0
        n = len(lines)
        for k, ln in enumerate(lines):
            ax.text(xt, level + (n - 1 - k) * lh, ln, fontsize=FS_SMALL,
                    color=INK if k == 0 else INK2,
                    fontweight="bold" if k == 0 else "normal",
                    ha=ha, va="bottom", zorder=6)

    def bar(ax, s0, s1, lane_y, kind, inside=None, below=(), right=None,
            h=0.24, draw=True, below_ha="center"):
        x0, x1 = mdates.date2num(d(s0)), mdates.date2num(d(s1))
        st = BAR[kind]
        if draw:
            ax.add_patch(Rectangle((x0, lane_y - h / 2), x1 - x0, h,
                                   facecolor=st["fc"], edgecolor=st["ec"],
                                   hatch=st["hatch"], linewidth=0.8, zorder=3))
        if inside:
            ax.text((x0 + x1) / 2, lane_y, inside, fontsize=6.5, color=INK,
                    ha="center", va="center", zorder=4)
        yy = lane_y - h / 2 - 0.04
        xb = (x0 + x1) / 2 if below_ha == "center" else x0
        for i, ln in enumerate(below):
            ax.text(xb, yy, ln, fontsize=6.8,
                    color=INK if i == 0 else INK2, ha=below_ha, va="top",
                    zorder=4)
            yy -= 6.8 * LS / 72.0
        if right:
            off = days_per_in(ax) * 0.06
            ax.text(x1 + off, lane_y + 0.01, right[0], fontsize=6.8,
                    color=INK, ha="left", va="bottom", zorder=4,
                    fontweight="bold")
            if len(right) > 1:
                ax.text(x1 + off, lane_y - 0.02, right[1], fontsize=6.8,
                        color=INK2, ha="left", va="top", zorder=4)

    # headers
    axL.text(mdates.date2num(d("2026-07-01")), Y_TOP - 0.02, "Prior work",
             fontsize=7.5, color=MUTED, fontweight="bold", ha="left", va="top")
    axR.text(mdates.date2num(d("2026-09-07")), Y_TOP - 0.02,
             "Research programme (H0–H8)", fontsize=7.5, color=MUTED,
             fontweight="bold", ha="left", va="top")

    L1, L2, L3 = -0.5, -1.15, -1.8

    # ---- left: prior work ----
    milestone(axL, "2026-07-12", ["12 Jul: engine first build",
                                  "rules kernel, UHP,",
                                  "alpha-beta, arena,",
                                  "NN pipeline, MCTS"], 0.3)
    axL.plot(mdates.date2num(d("2026-08-14")), 0, "o", ms=5.5, mfc=INK2,
             mec="white", mew=0.8, zorder=6)
    bar(axL, "2026-07-12", "2026-08-14", L1, "prior",
        below=["Jul–Aug: prior self-play loop,",
               "19 generations (demonstration);",
               "gen 20 aborted 14 Aug", "(disk full)"])

    # ---- right: research programme ----
    milestone(axR, "2026-09-09", ["9 Sep: programme start",
                                  "inventory, engine validation,",
                                  "baselines frozen"], 1.3)
    milestone(axR, "2026-09-10", ["10 Sep: protocol frozen v1.0",
                                  "after the pilot"], 0.8)
    milestone(axR, "2026-09-16", ["16 Sep: equal-time",
                                  "cutoff T* computed"], 0.3)
    milestone(axR, "2026-09-26", ["26 Sep: seed extension +",
                                  "A1′ supplement approved"], 1.3)
    milestone(axR, "2026-10-09", ["9 Oct: final 5-seed",
                                  "analysis and report"], 0.8, ha="right")

    bar(axR, "2026-09-09", "2026-09-11", L1, "both", below_ha="left",
        below=["pipeline + both encoders built", "9–10 Sep"])
    bar(axR, "2026-09-20", "2026-10-02", L1, "graph", inside="ablations A1, A2",
        below=["20 Sep – 2 Oct", "(runs to 27 Sep)"])
    bar(axR, "2026-09-10 12:42", "2026-09-17 22:31", L2, "both",
        inside="main campaign", below=["10–17 Sep: 6 runs", "(3 seeds × 2 arms)"])
    bar(axR, "2026-09-27", "2026-10-02", L2, "both", inside="seeds 4–5")
    bar(axR, "2026-10-02", "2026-10-06", L2, "graph", inside="A1′")
    bar(axR, "2026-09-27", "2026-10-06", L2, "both", draw=False,
        below=["extension runs", "27 Sep – 6 Oct"])
    bar(axR, "2026-09-18", "2026-09-20", L3, "analysis",
        right=["18–19 Sep: analysis, H1 rejected", "(3 seeds, both readings)"])

    handles = [Patch(facecolor=BAR[k]["fc"], edgecolor=BAR[k]["ec"],
                     hatch=BAR[k]["hatch"], label=t)
               for k, t in (("both", "both arms"),
                            ("graph", "graph-arm variants"),
                            ("analysis", "analysis"),
                            ("prior", "prior work (demonstration, not evidence)"))]
    fig.legend(handles=handles, loc="lower center", ncol=4, frameon=False,
               fontsize=6.8, handlelength=1.6, handleheight=0.9,
               bbox_to_anchor=(0.5, 0.0), columnspacing=1.4)
    fig.savefig(FIG / "fig10-timeline.png")
    return fig


# ---- render-time text check -----------------------------------------------
def check(fig, name):
    fig.canvas.draw()
    r = fig.canvas.get_renderer()
    texts = [t for t in fig.findobj(Text) if t.get_text().strip()
             and t.get_visible()]
    bbs = [(t, t.get_window_extent(r)) for t in texts]
    bad = 0
    fb = fig.bbox
    for t, b in bbs:
        if (b.x0 < fb.x0 - 1 or b.x1 > fb.x1 + 1 or b.y0 < fb.y0 - 1
                or b.y1 > fb.y1 + 1):
            print(f"[{name}] CLIPPED: {t.get_text()!r}")
            bad += 1
    for (t1, b1), (t2, b2) in combinations(bbs, 2):
        if b1.overlaps(b2):
            ov = (max(0, min(b1.x1, b2.x1) - max(b1.x0, b2.x0))
                  * max(0, min(b1.y1, b2.y1) - max(b1.y0, b2.y0)))
            if ov > 4:  # px^2
                print(f"[{name}] OVERLAP ({ov:.0f} px²): {t1.get_text()!r} "
                      f"<> {t2.get_text()!r}")
                bad += 1
    return bad


def main():
    FIG.mkdir(parents=True, exist_ok=True)
    do_check = "--check" in sys.argv
    bad = 0
    for fn, name in ((fig8, "fig8"), (fig9, "fig9"), (fig10, "fig10")):
        fig = fn()
        if do_check:
            bad += check(fig, name)
        plt.close(fig)
    for f in ("fig8-pipeline.png", "fig9-architectures.png",
              "fig10-timeline.png"):
        print(f"wrote {FIG / f} ({(FIG / f).stat().st_size:,} B)")
    if do_check and bad:
        print(f"{bad} text problem(s)")
        sys.exit(1)


if __name__ == "__main__":
    main()
