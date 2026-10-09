#!/usr/bin/env python3
"""Build the final report (EN and FR) from paper/report/{,fr/}*.md:
markdown -> pandoc (typst writer) -> Typst preamble (title page, outline,
lists, numbering, appendix switch) -> PDF via the typst wheel.

Conventions (paper/report/SPEC.md §2): figures `{#fig:x}`, tables
`Table: ... {#tbl:x}`, equations followed by a `{#eq:x}` line, sections
`{#sec:x}`; cross-references as inline raw typst `@fig:x` etc. Files
`NN-*.md` with NN < 90 are body chapters, NN >= 90 appendices; 00-* is
front matter (unnumbered, before the outline); 17-* is the bibliography
(unnumbered).

Usage: python/.venv/bin/python scripts/build_report.py [en|fr|all]
"""

import re
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "paper" / "report"
FIG = REPO / "paper" / "figures"
BUILD = REPO / "paper" / "build"
PANDOC = REPO / ".tools" / "pandoc"
FONT_PATHS = ["/System/Library/Fonts", "/System/Library/Fonts/Supplemental",
              "/Library/Fonts"]
VERSION = "v2.0-draft"

STR = {
    "en": dict(
        lang="en",
        title="Grid vs. Graph Representations for Self-Play Learning in Hive",
        subtitle="A pre-registered comparison under limited compute",
        author="Mohamed Bechir Kefi",
        status="Independent research report (not peer-reviewed)",
        version=f"Version {VERSION}",
        date="October 2026",
        contents="Contents", lof="List of figures", lot="List of tables",
        appendix="Appendix",
        parts={"01": "Part I. Problem and context",
               "04": "Part II. Building the system",
               "09": "Part III. Methodology",
               "11": "Part IV. Results",
               "15": "Part V. Discussion and conclusion",
               "90": "Appendices"},
    ),
    "fr": dict(
        lang="fr",
        title="Représentations en grille et en graphe pour l'apprentissage par auto-jeu à Hive",
        subtitle="Une comparaison pré-enregistrée sous budget de calcul limité",
        author="Mohamed Bechir Kefi",
        status="Rapport de recherche indépendant (non évalué par les pairs)",
        version=f"Version {VERSION}",
        date="Octobre 2026",
        contents="Table des matières", lof="Liste des figures",
        lot="Liste des tableaux", appendix="Annexe",
        parts={"01": "Partie I. Problème et contexte",
               "04": "Partie II. Construction du système",
               "09": "Partie III. Méthodologie",
               "11": "Partie IV. Résultats",
               "15": "Partie V. Discussion et conclusion",
               "90": "Annexes"},
    ),
}


def preamble(s):
    return rf'''
#let horizontalrule = line(start: (25%,0%), end: (75%,0%))
#show terms: it => {{ it.children.map(child => [#strong[#child.term] #block(inset: (left: 1.5em, top: -0.4em))[#child.description]]).join() }}
#let part(t) = {{ pagebreak(weak: true); v(32%); align(center)[#text(size: 24pt, weight: "bold")[#t]]; pagebreak() }}
#set document(title: "{s['title']}", author: "{s['author']}")
#set page(paper: "a4", margin: (top: 2.5cm, bottom: 2.5cm, left: 2.6cm, right: 2.6cm), numbering: "1",
  header: context {{ if counter(page).get().first() > 1 [#set text(size: 8.5pt, fill: luma(90)); #emph[{s['title']}] #h(1fr) #counter(page).display()] }})
#set text(font: "New York", size: 11pt, lang: "{s['lang']}")
#set par(justify: true, leading: 0.62em, spacing: 0.9em)
#set heading(numbering: "1.1")
#show heading.where(level: 1): it => {{ pagebreak(weak: true); v(1.6em); block[#text(size: 20pt, weight: "bold")[#if it.numbering != none [#counter(heading).display(it.numbering) #h(0.6em)] #it.body]]; v(1.0em) }}
#show heading.where(level: 2): it => {{ v(1.0em); block[#text(size: 14pt, weight: "bold")[#if it.numbering != none [#counter(heading).display(it.numbering) #h(0.5em)] #it.body]]; v(0.45em) }}
#show heading.where(level: 3): it => {{ v(0.7em); block[#text(size: 11.5pt, weight: "bold", style: "italic")[#if it.numbering != none [#counter(heading).display(it.numbering) #h(0.4em)] #it.body]]; v(0.3em) }}
#set table(inset: (x: 4.5pt, y: 3.5pt), stroke: (x, y) => if y == 0 {{ (bottom: 0.8pt, top: 0.8pt) }} else {{ (bottom: 0.3pt + luma(175)) }})
#show table.cell.where(y: 0): strong
#show table: set text(size: 9pt)
#show table: set par(justify: false, leading: 0.5em)
#show table: set text(hyphenate: true)
#show table.cell: set align(top)
#show figure.where(kind: table): set figure.caption(position: top)
#set figure.caption(separator: [{' : ' if s['lang'] == 'fr' else ': '}])
#show figure.caption: it => {{ set text(size: 9.5pt); block(width: 94%)[#align(left)[#it]] }}
#set figure(gap: 0.7em)
#show figure: set block(breakable: true)
#show figure: it => {{ v(0.5em); it; v(0.5em) }}
#show heading: set block(sticky: true)
#show math.equation.where(block: true): set block(above: 1.1em, below: 1.1em)
#show raw.where(block: false): set text(size: 7.8pt)
#show link: set text(fill: rgb("#1a3d7c"))
#show raw: set text(font: "Menlo", size: 8.8pt)
#show raw.where(block: true): it => block(fill: luma(246), inset: 7pt, radius: 2pt, width: 100%, it)
#set math.equation(numbering: "(1)")
#show quote.where(block: true): it => block(inset: (left: 1.5em, right: 1.5em), text(style: "italic", it.body))
#set footnote.entry(separator: line(length: 30%, stroke: 0.4pt))
// ---------- title page ----------
#page(numbering: none, header: none)[
  #v(4.5cm)
  #align(center)[
    #text(size: 23pt, weight: "bold")[{s['title']}]
    #v(0.9em)
    #text(size: 14pt)[{s['subtitle']}]
    #v(3.2cm)
    #text(size: 13pt)[{s['author']}]
    #v(1.6cm)
    #text(size: 10.5pt)[{s['status']}]
    #v(0.35em)
    #text(size: 10.5pt)[{s['version']}, {s['date']}]
  ]
]
#counter(page).update(1)
'''


def outline(s):
    return rf'''
#pagebreak(weak: true)
#outline(title: "{s['contents']}", depth: 2, indent: 1.3em)
#pagebreak(weak: true)
#outline(title: "{s['lof']}", target: figure.where(kind: image))
'''


def appendix_switch(s):
    return rf'''
#counter(heading).update(0)
#set heading(numbering: "A.1", supplement: "{s['appendix']}")
'''


def pandoc_body(md_text, workdir):
    tmp = workdir / "_body.md"
    tmp.write_text(md_text)
    out = workdir / "_body.typ"
    subprocess.run([str(PANDOC), str(tmp), "-f", "markdown", "-t", "typst",
                    "--wrap=none", "-o", str(out)], check=True)
    return out.read_text()


def attach_labels(typ):
    """Tables: `{#tbl:x}` left in the caption by pandoc -> label after the
    figure's closing paren. Equations: a `{#eq:x}` paragraph after display
    math -> label attached to the equation."""
    out, pending = [], None
    for line in typ.splitlines():
        m = re.search(r"\s*\{\\#(tbl:[\w-]+)\}", line)
        if m:
            pending = m.group(1)
            line = line.replace(m.group(0), "")
        if pending and line.strip() == ")":
            line = line + " <" + pending + ">"
            pending = None
        # cell alignment: pandoc's `auto` inherits the centred figure
        # alignment; text columns read better left-aligned.
        if line.lstrip().startswith("align: ("):
            line = line.replace("auto", "left")
        out.append(line)
    typ = "\n".join(out)
    typ = re.sub(r"\$\s*\{\\#(eq:[\w-]+)\}", r"$ <\1>", typ)
    # pandoc renders \left( \right) as scaled brackets; plain delimiters
    # auto-size in Typst math.
    typ = re.sub(r"#scale\(x: \d+%, y: \d+%\)\[\\\(\]", "(", typ)
    typ = re.sub(r"#scale\(x: \d+%, y: \d+%\)\[\\\)\]", ")", typ)
    typ = typ.replace("#h(-1em)", "")   # LaTeX \! negative thin space
    # 64-character hashes cannot wrap inside table cells: show them on
    # two lines of 32 characters.
    typ = re.sub(r"`([0-9a-f]{32})([0-9a-f]{8,32})`",
                 lambda m: "`" + m.group(1) + "`#linebreak()`" + m.group(2) + "`", typ)
    return typ


TABLE_SEP = re.compile(r"^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$")


def widen_tables(md):
    """Rewrite each pipe table's separator row so that the dash counts are
    proportional to the columns' content (pandoc derives relative column
    widths from them when a row exceeds the text width); numeric columns
    stay narrow, text-heavy columns get the room they need."""
    lines = md.splitlines()
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if TABLE_SEP.match(line) and i > 0 and lines[i - 1].lstrip().startswith("|"):
            # collect the whole table: header (i-1), sep (i), rows after
            j = i + 1
            rows = [lines[i - 1]]
            while j < len(lines) and lines[j].lstrip().startswith("|"):
                rows.append(lines[j]); j += 1
            cells = [[c.strip() for c in r.strip().strip("|").split("|")] for r in rows]
            ncol = max(len(r) for r in cells)
            seps = [c.strip() for c in line.strip().strip("|").split("|")]
            # Width model (points, 9 pt table font): every column must at
            # least fit its longest unbreakable word; the remaining width is
            # shared in proportion to the columns' content length.
            TEXT_PT = 453.0
            mins, content = [], []
            for k in range(ncol):
                col = [r[k] for r in cells if k < len(r)]
                longest = max((len(c) for c in col), default=4)
                word = max((max((len(w) for w in c.split()), default=0) for c in col), default=4)
                mins.append(min(word * 5.0 + 12, 340.0))
                content.append(6 + min(longest, 70))
            spare = TEXT_PT - sum(mins)
            if spare < 0:            # too many long words: let hyphenation work
                mins = [m * TEXT_PT / sum(mins) for m in mins]
                spare = 0
            tot = float(sum(content))
            weights = [int(round(mins[k] + spare * content[k] / tot)) for k in range(ncol)]
            new_seps = []
            for k in range(ncol):
                sep = seps[k] if k < len(seps) else "---"
                left = sep.startswith(":"); right = sep.endswith(":")
                dashes = "-" * max(3, weights[k])
                new_seps.append((":" if left else "") + dashes + (":" if right else ""))
            out.append(lines[i - 1]) if False else None
            out.append("| " + " | ".join(new_seps) + " |")
            i += 1
            continue
        out.append(line)
        i += 1
    return "\n".join(out)


URL = re.compile(r'(?<![\"\[(])(https?:(?:\\/\\/|//)[^\s\)\]>]+?)(?=[\s\)\]>]|[.,;](?:\s|$)|$)')


def linkify(typ):
    """Bare URLs (pandoc escapes `//` as `\/\/` in Typst text) become
    clickable links that display themselves."""
    def repl(m):
        shown = m.group(1)
        target = shown.replace("\\/", "/")
        return '#link("' + target + '")[' + shown + ']'
    return URL.sub(repl, typ)


def assemble(lang):
    s = STR[lang]
    src = SRC if lang == "en" else SRC / "fr"
    files = sorted(p for p in src.glob("[0-9][0-9]-*.md"))
    if not files:
        sys.exit(f"no chapter files under {src}")
    front = [f for f in files if f.name.startswith("00-")]
    body = [f for f in files if not f.name.startswith("00-") and int(f.name[:2]) < 90]
    apps = [f for f in files if int(f.name[:2]) >= 90]

    def md_of(f):
        return f.read_text().rstrip() + "\n"

    work = BUILD / f"report-{lang}-work"
    work.mkdir(parents=True, exist_ok=True)
    parts = []
    for f in body:
        key = f.name[:2]
        if key in s["parts"]:
            parts.append(f"```{{=typst}}\n#part[{s['parts'][key]}]\n```\n")
        if key == "17":
            # bibliography: hanging indent, unjustified, clickable URLs
            bib = linkify(attach_labels(pandoc_body(md_of(f), work)))
            parts.append("```{=typst}\n#[\n#set par(hanging-indent: 1.8em, justify: false, first-line-indent: 0em)\n#set text(size: 10pt)\n"
                         + bib + "\n]\n```\n")
            continue
        parts.append(md_of(f))
    if apps:
        parts.append(f"```{{=typst}}\n#part[{s['parts']['90']}]\n"
                     f"{appendix_switch(s)}\n```\n")
        for f in apps:
            parts.append(md_of(f))
    front_md = widen_tables("\n\n".join(md_of(f) for f in front))
    body_md = widen_tables("\n\n".join(parts))

    front_typ = attach_labels(pandoc_body(front_md, work)) if front else ""
    body_typ = attach_labels(pandoc_body(body_md, work))
    if lang == "fr":
        # Sources keep the English thousands comma so the FR/EN numeric
        # identity check can compare tokens; the French edition renders
        # the separator as a narrow no-break space (decimal point kept,
        # stated in the front matter).
        thousands = re.compile(r"(?<=\d),(?=\d{3}(?!\d))")
        front_typ = thousands.sub("\u202f", front_typ)
        body_typ = thousands.sub("\u202f", body_typ)
    doc = preamble(s) + "\n" + front_typ + "\n" + outline(s) + "\n" + body_typ
    doc += (f"\n\n#v(2em)\n#align(center)[#text(size: 8.5pt, fill: luma(110))"
            f"[{VERSION}, {date.today().isoformat()}]]\n")
    (BUILD / "figures").mkdir(parents=True, exist_ok=True)
    for png in FIG.glob("*.png"):
        shutil.copy(png, BUILD / "figures" / png.name)
    typ = BUILD / f"report-{lang}.typ"
    typ.write_text(doc)
    return typ


def compile_pdf(typ):
    import typst
    pdf = typ.with_suffix(".pdf")
    typst.compile(str(typ), output=str(pdf), root=str(BUILD),
                  font_paths=FONT_PATHS)
    try:
        from pypdf import PdfReader
        n = len(PdfReader(str(pdf)).pages)
    except Exception:
        n = "?"
    print(f"{pdf.name}: {n} pages, {pdf.stat().st_size // 1024} KB")
    return pdf


if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    for lang in (["en", "fr"] if which == "all" else [which]):
        compile_pdf(assemble(lang))
