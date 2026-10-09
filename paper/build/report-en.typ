
#let horizontalrule = line(start: (25%,0%), end: (75%,0%))
#show terms: it => { it.children.map(child => [#strong[#child.term] #block(inset: (left: 1.5em, top: -0.4em))[#child.description]]).join() }
#let part(t) = { pagebreak(weak: true); v(32%); align(center)[#text(size: 24pt, weight: "bold")[#t]]; pagebreak() }
#set document(title: "Grid vs. Graph Representations for Self-Play Learning in Hive", author: "Mohamed Bechir Kefi")
#set page(paper: "a4", margin: (top: 2.5cm, bottom: 2.5cm, left: 2.6cm, right: 2.6cm), numbering: "1",
  header: context { if counter(page).get().first() > 1 [#set text(size: 8.5pt, fill: luma(90)); #emph[Grid vs. Graph Representations for Self-Play Learning in Hive] #h(1fr) #counter(page).display()] })
#set text(font: "New York", size: 11pt, lang: "en")
#set par(justify: true, leading: 0.62em, spacing: 0.9em)
#set heading(numbering: "1.1")
#show heading.where(level: 1): it => { pagebreak(weak: true); v(1.6em); block[#text(size: 20pt, weight: "bold")[#if it.numbering != none [#counter(heading).display(it.numbering) #h(0.6em)] #it.body]]; v(1.0em) }
#show heading.where(level: 2): it => { v(1.0em); block[#text(size: 14pt, weight: "bold")[#if it.numbering != none [#counter(heading).display(it.numbering) #h(0.5em)] #it.body]]; v(0.45em) }
#show heading.where(level: 3): it => { v(0.7em); block[#text(size: 11.5pt, weight: "bold", style: "italic")[#if it.numbering != none [#counter(heading).display(it.numbering) #h(0.4em)] #it.body]]; v(0.3em) }
#set table(inset: (x: 4.5pt, y: 3.5pt), stroke: (x, y) => if y == 0 { (bottom: 0.8pt, top: 0.8pt) } else { (bottom: 0.3pt + luma(175)) })
#show table.cell.where(y: 0): strong
#show table: set text(size: 9pt)
#show table: set par(justify: false, leading: 0.5em)
#show table: set text(hyphenate: true)
#show table.cell: set align(top)
#show figure.where(kind: table): set figure.caption(position: top)
#set figure.caption(separator: [: ])
#show figure.caption: it => { set text(size: 9.5pt); block(width: 94%)[#align(left)[#it]] }
#set figure(gap: 0.7em)
#show figure: set block(breakable: true)
#show figure: it => { v(0.5em); it; v(0.5em) }
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
    #text(size: 23pt, weight: "bold")[Grid vs. Graph Representations for Self-Play Learning in Hive]
    #v(0.9em)
    #text(size: 14pt)[A pre-registered comparison under limited compute]
    #v(3.2cm)
    #text(size: 13pt)[Mohamed Bechir Kefi]
    #v(1.6cm)
    #text(size: 10.5pt)[Independent research report (not peer-reviewed)]
    #v(0.35em)
    #text(size: 10.5pt)[Version v2.0-draft, October 2026]
  ]
]
#counter(page).update(1)

#heading(level: 1, numbering: none)[Abstract]
<abstract>
Hive is a boardless hexagonal strategy game whose moves are (piece, destination) pairs over an ever-changing set of cells, which makes it, in principle, a natural candidate for graph neural encodings in place of the convolutional grid encodings standard in AlphaZero-style systems. We test that intuition under a pre-registered protocol frozen before any comparison run: one grid CNN and one capacity-matched (+1.5%) relational message-passing network share a rules-validated engine, one action decoder, identical training settings, a frozen three-opponent population and 250 frozen openings, evaluated under two budget readings (equal training examples; equal wall-clock at a pre-registered cutoff) with five independent seeds per arm and truncation reported as its own outcome. The hypothesis is rejected: the graph arm scores lower against two of three opponents under both readings, at twice the wall-clock cost, with its deficit concentrated in converting won positions. Ablations show that the graph arm's typed edge relations are necessary for optimization stability, while its global pooling is dispensable. The result is negative, pre-registered and fully reproducible from the released records.

#strong[Keywords.] Hive; AlphaZero; graph neural networks; representation learning; pre-registration; negative result.

#heading(level: 1, numbering: none)[Résumé]
<résumé>
Hive est un jeu de stratégie hexagonal sans plateau dont les coups sont des paires (pièce, destination) sur un ensemble de cellules en perpétuel changement, ce qui en fait, en principe, un candidat naturel pour des encodages par réseaux de neurones en graphe plutôt que pour les encodages convolutifs en grille standards des systèmes de type AlphaZero. Nous testons cette intuition sous un protocole pré-enregistré, gelé avant toute exécution comparative : un CNN en grille et un réseau relationnel à passage de messages de capacité appariée (+1.5%) partagent un moteur validé côté règles, un décodeur d'actions unique, des réglages d'entraînement identiques, une population gelée de trois adversaires et 250 ouvertures gelées, évalués sous deux lectures budgétaires (à exemples d'entraînement égaux ; à temps mural égal à un seuil pré-enregistré), avec cinq graines indépendantes par bras et la troncature rapportée comme un résultat à part entière. L'hypothèse est rejetée : le bras graphe obtient un score inférieur contre deux des trois adversaires sous les deux lectures, à un coût en temps mural double, son déficit se concentrant dans la conversion des positions gagnées. Les ablations montrent que les relations d'arêtes typées du bras graphe sont nécessaires à la stabilité de l'optimisation, tandis que son agrégation globale (global pooling) est dispensable. Le résultat est négatif, pré-enregistré et entièrement reproductible à partir des enregistrements publiés.

#strong[Mots-clés.] Hive ; AlphaZero ; réseaux de neurones en graphe ; apprentissage de représentations ; pré-enregistrement ; résultat négatif.

#heading(level: 1, numbering: none)[Status, code and declaration of assistance]
<status-code-and-declaration-of-assistance>
#strong[Status.] Independent research report prepared in view of a doctoral application. It is not peer-reviewed and is not a publication of any institution. Version 2.0-draft, October 2026; the experimental content is final and no number differs from the frozen raw results of 9 October 2026.

#strong[Code and artifacts.] The engine, the training pipeline, both encoders, the frozen configurations, the raw per-game evaluation records and the scripts that regenerate every table and figure of this report form one repository (release tag and access to be fixed at the time of diffusion). A fresh-environment reproduction scenario is described in @sec:app-g; the provenance of every result is tabulated in @sec:app-e.

#strong[Declaration of assistance by an artificial-intelligence system.] This study was executed under a human-as-principal-investigator methodology in which an AI research assistant (Claude, Anthropic) implemented code, ran the computational campaigns, kept the experiment journals and drafted text, under a system of six decision gates reserving every scientific commitment to the human author: the freezing of protocol, opponents and openings, every expenditure of compute, anything made public and the deletion of any data. The human author chose the question, approved each gated decision in writing, verified the conclusions and owns every claim. @sec:working-method documents this working methodology, its rationale and its record.

#strong[Conventions.] Scores are means over decided games (win 1, draw 0.5, loss 0) against a fixed opponent population; games stopped at the experimental move cap are #emph[truncated] and are reported as a separate outcome, never as draws. Intervals in brackets are 95% percentile bootstrap intervals with the independent training run (seed) as the resampling unit. The arm trained on the grid encoding is the #emph[grid arm];; the arm trained on the graph encoding is the #emph[graph arm];. A glossary with the French equivalents of all technical terms is given in @sec:app-f.

#pagebreak(weak: true)
#outline(title: "Contents", depth: 2, indent: 1.3em)
#pagebreak(weak: true)
#outline(title: "List of figures", target: figure.where(kind: image))

#part[Part I. Problem and context]
= Introduction
<sec:introduction>
== Context: learning to play from self-play, and the cost of representation
<context-learning-to-play-from-self-play-and-the-cost-of-representation>
Since AlphaZero, the dominant recipe for learning to play a board game without human examples has been stable: a neural network estimates, for a position, a probability distribution over moves (the #emph[policy];) and an expected outcome (the #emph[value];); a Monte-Carlo tree search guided by the network produces stronger decisions than the network alone; the games the search plays against itself become the training data of the next network (Silver et al., 2018). The recipe is general, but one of its ingredients is not: the way a position is presented to the network. For chess, shogi and Go the answer was natural: the board is a fixed rectangular array, and a position becomes a stack of image-like planes read by a convolutional network. The success of this #emph[grid] encoding rests on a property these games share: every square exists at every moment, at a fixed place.

Hive does not have that property. It is a two-player game of perfect information played with hexagonal tiles and no board: the tiles themselves form the playing surface (the #emph[hive];), the surface changes shape every turn, tiles can climb on top of one another, and a move is best described as "this piece goes to that cell" over a set of cells that exists only relative to the current hive. The natural mathematical object for such a position is a graph rather than an image, with cells as nodes, adjacency as edges and stacks as node attributes; the natural network is then a graph neural network, which reads a variable-size graph directly and needs no frame. Grid encodings can still be applied to Hive by unfolding the hive into a large fixed frame, as every learning system for the game has done so far; but doing so introduces anchoring choices, empty space and a very large discrete move space whose structure the network must learn from scratch.

== The problem: an intuition that cuts both ways
<the-problem-an-intuition-that-cuts-both-ways>
It is tempting to conclude that a graph encoding must learn Hive better. This study was designed because the intuition is genuinely uncertain. On one side, a graph network matches the game's native structure and carries no anchoring artifacts. On the other side, Hive's outcomes hinge on short-range #emph[surround] tactics (a queen bee loses when its six neighbouring cells are occupied), and short-range pattern recognition is precisely the regime in which convolutional locality is strongest. Moreover, a graph over the #emph[occupied] cells alone cannot express the legal destinations of a move, which are properties of empty space; the graph must therefore carry empty candidate cells, and it is not known whether a simple message-passing network, given such a graph, learns the sliding, climbing and connectivity constraints of the rules better than a convolutional network given the unfolded frame.

The prior evidence does not settle the question. The only published AlphaZero-style study of Hive compared five board encodings and found that the choice of encoding measurably changes learning, but all five were grid encodings and the resulting engines remained weaker than plain search (de Goede et al., 2022). The two direct grid-versus-graph comparisons in other games point in opposite directions: in Hex, under a value-based learner rather than self-play, a graph network dominated on long-range dependencies while the convolutional network stayed sharper at local patterns (Keller et al., 2023); in chess, under self-play, a graph-attention network out-learned convolutional baselines, although from a single training run per model and without seed replication (Rigaux & Kashima, 2024). None of these studies ran both arms under one self-play pipeline, at matched capacity, under a matched budget, with several independent training runs per arm, on Hive. @sec:related develops this positioning.

== Research questions and hypothesis
<research-questions-and-hypothesis>
The study asks one main question and two secondary ones.

- #strong[RQ-H1 (representation).] At comparable training budget, does a graph architecture learn a better policy than a grid architecture for base-game Hive, within an AlphaZero-style self-play pipeline?
- #strong[RQ-H2 (efficiency).] How do the two representations compare when the budget is read as the number of training examples, and when it is read as wall-clock time on the same hardware?
- #strong[RQ-H3 (components).] Which components of the graph architecture carry its behaviour, in particular its direction-typed relations and its global pooling?

The hypothesis under test, #strong[H1];, states that a simple message-passing graph network, receiving the hive as a graph, reaches a higher mean score against a fixed opponent population than a grid convolutional network receiving a 32×32 unfolded frame, at equal training budget. H1 was not presumed true: the protocol (@sec:protocol) states explicitly that a negative or null result is a publishable outcome, and it fixed, before any comparison run, the opponents, the openings, the budgets, the evaluation settings, the statistical unit and the rule by which H1 would be rejected.

== What was done
<what-was-done>
Both encodings were built behind one shared action decoder on one rules-validated engine; the two networks were matched in capacity to within +1.5% (1.44 M against 1.47 M parameters); five independent seeds per arm were trained under identical self-play settings for ten generations of 500 games each; the comparison was read in two ways, at equal training examples and at equal wall-clock at a pre-registered cutoff, against a frozen population of three opponents (legal-random, a documented heuristic, and a search agent without network at 6,400 simulations) on 250 frozen openings, with truncation treated as a first-class outcome throughout. Two ablations removed one component each of the graph arm at full parity, and a third, explicitly two-component run supplemented the first ablation after it proved untrainable.

== What was found
<what-was-found>
The hypothesis is rejected. The grid arm scores higher against two of the three opponents under both budget readings, at roughly half the wall-clock cost; the largest upper bound of any interval on a graph advantage is +0.028. The graph arm's deficit concentrates in local tactical conversion: it wins material against the random opponent and then fails to close, truncating 20--57% of those games where the grid arm truncates almost none. The ablations localise the graph arm's machinery: its direction-typed relations are necessary for optimization itself (removing them made training diverge in every seed), while its global pooling is dispensable.

== Contributions
<contributions>
Three contributions are claimed, each verifiable from the released repository.

+ #strong[The first controlled, budget-matched, multi-seed grid-versus-graph comparison for Hive];, with both arms under the same AlphaZero-style pipeline, read under two budget equalisations, and a pre-registered negative answer (@sec:results-main, @sec:results-cost; raw records released).
+ #strong[A reproducible comparison harness for frameless, stacking games];: a rules engine validated independently of learning; two encoders pinned byte-exactly across two implementation languages; a shared decoder over a variable action set; truncation-aware evaluation; and a frozen-artifact discipline (@sec:engine to @sec:protocol).
+ #strong[A component attribution for the graph arm];, in which the typed relations determine trainability and the pooling has a null effect, with an honestly labelled two-component supplement (@sec:results-ablations).

The construction of software, however substantial, is not counted as a scientific contribution in itself; it is reported because the result cannot be evaluated without it.

== How this report is organised
<how-this-report-is-organised>
Part I states the problem: @sec:background gives the rules of Hive, the formalisation used, and the elements of self-play learning, state representation and small-sample evaluation a reader needs; @sec:related positions the study against prior work. Part II describes how the system was built and when (@sec:chronology): the engine and its validation (@sec:engine), the learning pipeline (@sec:pipeline), the two representations and networks (@sec:representations), and the frozen opponent population (@sec:baselines). Part III explains the methodology and why it was chosen: the pre-registered experimental protocol (@sec:protocol) and the gated human-AI working method (@sec:working-method). Part IV reports the results by question: the main comparison (@sec:results-main), cost and efficiency (@sec:results-cost), ablations (@sec:results-ablations) and a qualitative analysis of failure positions and training behaviour (@sec:results-qualitative). Part V discusses mechanisms and threats to validity (@sec:discussion) and concludes (@sec:conclusion). The bibliography and webography follow the conclusion. The appendices contain the annotated position corpora, the architectures and data formats in full, every hyperparameter and seed, the statistical procedures with the raw per-seed tables, the provenance of every result, a glossary with French equivalents, and the reproduction guide.

== How to read the numbers
<how-to-read-the-numbers>
Every score in this report is a mean over #emph[decided] games against one frozen opponent, with win = 1, draw = 0.5 and loss = 0; games stopped at the 300-ply experimental cap are counted separately as #emph[truncations] and are never scored as draws. Every interval is a 95% percentile bootstrap interval whose resampling unit is the independent training run (the #emph[seed];), not the game: a thousand games played by one network are one observation of that network, not a thousand observations of the method. Differences between arms are written as graph minus grid, so a negative number favours the grid arm. All numbers trace to raw per-game records through the chain documented in @sec:app-e.

= Background: Hive, self-play learning and state representations
<sec:background>
This chapter sets out what the rest of the report takes for granted: the rules of Hive and what makes it awkward for learning machines; the formal objects the study manipulates, including the truncation convention; AlphaZero-style self-play as the system implements it, including a loss that departs from the usual form in two deliberate respects; the two state representations compared; the budget conventions under which they are compared; and the statistics for evaluating agents from a handful of independent training runs.

== The game of Hive
<sec:bg-hive>
Hive, designed by John Yianni and published by Gen42 Games, is a two-player, perfect-information, zero-sum game of alternating moves. It is played without a board: hexagonal tiles are placed on any flat surface, and the tiles in play define the playing surface. In the base game each player owns eleven tiles: one queen bee, two spiders, two beetles, three grasshoppers and three soldier ants. Three further tiles (mosquito, ladybug, pillbug) exist as expansions; the engine used here implements them, but no result in this report involves an expansion.

=== Placement
<placement>
Play begins with one player placing a tile and the other joining a tile of their own to it edge to edge. Afterwards, a tile entering play may not touch a tile of the opponent's colour. The queen bee must enter by each player's fourth turn, and no tile may move before its owner's queen is in play. The study adopts the tournament opening rule (no queen on either player's first turn), which is the convention of the Universal Hive Protocol and of both reference engines against which the rules kernel was validated; the publisher's 2010 rulesheet alone would permit a first-turn queen.

=== Movement
<movement>
The queen bee slides one cell. The beetle also moves one cell but may climb on top of the hive; a tile covered by a beetle cannot move, and for placement purposes a stack takes the colour of the beetle on top. The grasshopper does not slide at all: it jumps in a straight line over one or more adjacent tiles to the first empty cell beyond them. The spider slides exactly three cells along the outside of the hive, without backtracking. The soldier ant slides to any reachable cell around the hive. Beetle climbs produce stacks, and a stack's height matters: a tile moving above ground level must also be able to slide, and a #emph[beetle gate] formed by two taller neighbouring stacks blocks it.

Two global constraints cut across these movements. The #strong[One-Hive rule] requires the tiles in play to remain connected at all times: a tile that is the only link between two parts of the hive may not move, whatever its own movement rule would allow. The #strong[freedom-to-move rule] requires a sliding tile to pass physically between its neighbours: a cell whose two flanking cells are both occupied cannot be slid into or out of. Together they mean that the legal moves of a piece depend on the whole configuration rather than on the piece's neighbourhood alone.

=== End of the game
<end-of-the-game>
The game ends as soon as a queen bee is surrounded on all six sides by tiles of any colour; its owner loses, even when the owner's own move completed the surround. If one move completes the surround of both queens, the game is drawn; the engine additionally declares a draw on threefold repetition. A player who can neither place nor move must pass, and the opponent moves again.

=== Why Hive is hard for machines
<why-hive-is-hard-for-machines>
Four properties make Hive an unusual object for the methods of @sec:bg-selfplay, all of which were developed on games with a fixed board.

#emph[Frameless geometry.] There is no board tensor to fill in. A position is a finite connected set of occupied cells of arbitrary shape and extent, plus the empty cells around it; its absolute location and orientation carry no meaning. Any fixed-size array encoding must therefore choose an anchor and a frame, a modelling decision with consequences (@sec:bg-representations).

#emph[Stacking.] Beetles climb, so a cell may carry several tiles, and buried tiles remain relevant: they count toward surrounds and reappear when the beetle leaves.

#emph[Branching and length.] Kampert et al.~(2021) measure an average branching factor that stabilises around 60, roughly twice that of chess, and find that full-width search to depth four already costs tens of seconds on a highly optimised engine, so the bottleneck is evaluation quality rather than search speed. Games are long: the longest search-guided game observed while profiling the engine ran 202 plies, and self-play from a randomly initialised network reached the 300-ply cap of @sec:bg-formal in 56.7% of games.

#emph[Legality is non-local.] Under the One-Hive and freedom-to-move rules, whether a move exists depends on the global configuration (articulation points of the hive, gates formed by distant stacks) and on empty space. The same authors found no cheap reliable hand-crafted evaluation: the intuitive count of tiles around the enemy queen is actively misleading when weighted heavily. Hence the case for learning the evaluation, and for asking which representation lets a network learn it most efficiently.

== Formalisation used in the study
<sec:bg-formal>
@tbl:notation collects the symbols used from here on.

A #strong[state] $s$ comprises the tiles in play with their cells and stack levels, the tiles still in hand for each player, the side to move, the ply count, and a marker for the tile moved on the previous ply (relevant only under the pillbug expansion; carried for kernel uniformity and part of the hashed position). The engine exposes $s$ over the Universal Hive Protocol, and its rules correctness was established independently of any learning component (@sec:engine).

An #strong[action] is a pair $a = (p \, d)$ of a piece $p$ and a destination cell $d$, together with one distinguished action, #emph[pass];, which is legal exactly when no move exists. The pair identifies a Hive move uniquely, since the rare cases in which a tile could reach the same cell by two mechanisms produce identical successor states. Pieces are addressed relative to the side to move, so that an action index means the same thing for either colour. The set of legal actions $A (s)$ is produced by the engine's move generator; both learned architectures receive it and normalise their policies over exactly $A (s)$ through a shared decoder (@sec:bg-representations). The #strong[transition] $s' = T (s \, a)$ is the engine's move application.

#strong[Outcomes] are expressed from the perspective of the player to move in the state being scored: a win is $+ 1$, a loss $- 1$, a draw $0$. Because a player can lose by surrounding their own queen, the implementation computes the sign from the result and the side to move rather than assuming that the previous mover won.

#strong[Experimental truncation.] Self-play and evaluation games are stopped after 300 plies. A game stopped this way is #emph[not] a draw. It forms a fourth outcome class, #emph[truncated];, carried as such through the data format, the training loss (truncated records contribute no value target, @sec:bg-selfplay), the match runner, every result table (a separate truncation-rate column) and the statistical analysis. The cap was set from measurement, above the longest observed search-guided game, and was frozen with the rest of the protocol on 10 September 2026, before any comparison run. Treating a capped game as a draw would silently teach the value head that long, unresolved games are balanced; keeping truncation separate makes its frequency a reported quantity and lets the sensitivity of every conclusion to the cap be tested (@sec:bg-evaluation).

#figure(
  align(center)[#table(
    columns: (39.29%, 60.71%),
    align: (left,left,),
    table.header([Symbol], [Meaning],),
    table.hline(),
    [$s$, $s'$], [a game state and its successor],
    [$A (s)$], [the set of legal actions in $s$ (moves, plus pass when no move exists)],
    [$a = (p \, d)$], [an action: piece $p$ to destination cell $d$],
    [$T (s \, a)$], [the transition (the engine's move application)],
    [$z in { + 1 \, 0 \, - 1 }$], [terminal outcome from the mover's perspective: win, draw, loss],
    [truncated], [fourth outcome class: game stopped at the 300-ply cap; never a draw],
    [$p_theta (a divides s)$, $v_theta (s)$], [network policy over $A (s)$ and network value in $[- 1 \, 1]$],
    [$P (s \, a)$, $N (s \, a)$, $Q (s \, a)$], [prior, visit count and mean value of a search edge],
    [$N (s)$], [visit count of the node $s$],
    [$c$], [exploration constant of the selection rule (1.4)],
    [$epsilon$, $alpha$], [root-noise mixing weight (0.25 in self-play, 0 in evaluation) and concentration (0.15)],
    [$pi (a divides s)$], [recorded root visit distribution; the policy target],
    [$lambda_v$], [weight of the value loss (0.6)],
    [$h_i$, $h_i'$], [embedding of graph node $i$ before and after a message-passing layer],
    [$n_i (d)$], [the neighbour of node $i$ in hexagonal direction $d in { 1 \, dots.h \, 6 }$],
    [$W_(upright(s e l f))$, $W_d$, $b$], [self-weight, direction-typed weights and bias of a message-passing layer],
    [score], [mean of win $= 1$, draw $= 0.5$, loss $= 0$ over non-truncated evaluation games],
    [seed], [one independent training run; the unit of analysis],
  )]
  , caption: [Notation used in this report.]
  , kind: table
  ) <tbl:notation>

== Self-play learning in the AlphaZero family
<sec:bg-selfplay>
=== Policy-value network and search
<policy-value-network-and-search>
AlphaZero (Silver et al., 2018) learns to play from the rules alone. A single network with parameters $theta$ maps a state to a policy $p_theta (dot.op divides s)$ over actions and a value $v_theta (s)$ estimating the outcome for the player to move. The network does not play directly: it guides a Monte-Carlo tree search, and the search, which is stronger than the raw network, generates the games on which the network is then trained. Silver et al.~ran 800 simulations per move during self-play and reached superhuman strength in chess, shogi and Go with thousands of specialised accelerators and a single training run per game; the study described here keeps the algorithmic core and changes the scale, the game and the statistics.

Search proceeds by repeated descents from the root. At a node $s$ the implementation selects the edge maximising

$ Q (s \, a) + c thin P (s \, a) thin frac(sqrt(N (s)), 1 + N (s \, a)) $ <eq:puct>

with $c = 1.4$, which is the PUCT rule of Silver et al.~Here $P (s \, a)$ is the network prior, normalised over $A (s)$; $N (s \, a)$ the number of visits through the edge; $N (s)$ the parent's visit count, taken as at least one; and $Q (s \, a)$ the mean of the values backed up through the edge from the parent's point of view (the child's values are negated, its side to move being the opponent). Two implementation details matter for reproducibility. Leaf evaluations are batched: a descent that reaches an unevaluated leaf waits for the batch to fill, and meanwhile a #emph[virtual loss] (one extra visit counted as a loss in both $Q$ and $N$) is placed on every edge of its path, so that concurrent descents spread out. And an edge whose child has never been visited takes $Q (s \, a) = Q (s) - 0.2$, where $Q (s)$ is the parent's own mean value: a #emph[first-play urgency] reduction that discourages opening every child before deepening the promising ones. A new leaf is scored by the network; its value is backed up along the path with alternating sign, and terminal nodes back up their exact outcome. When the simulation budget is spent, the search returns the most-visited root move and the vector of root visit counts.

=== Exploration in self-play
<exploration-in-self-play>
Two devices make self-play games diverse. At the root, the priors are mixed with noise, $P (s \, a) arrow.l (1 - epsilon) thin P (s \, a) + epsilon thin eta_a$, with $epsilon = 0.25$ and $eta$ a random vector drawn once per search from an approximate Dirichlet distribution of concentration $alpha = 0.15$ (approximated in the implementation by normalised transformed uniform draws rather than exact Gamma variates). Silver et al.~scaled $alpha$ to each game's typical number of legal moves ($0.3$ for chess, $0.15$ for shogi, $0.03$ for Go); the value used here is their shogi setting. For the first 12 plies of a game the move actually played is sampled in proportion to the root visit counts (temperature one); thereafter the most-visited move is played. Evaluation games apply none of this: $epsilon = 0$, no temperature, the most-visited move always played, at 400 simulations per decision, enforced by test and pinned by configuration.

=== Training targets and the loss as implemented
<training-targets-and-the-loss-as-implemented>
Every recorded decision yields a training example: the state, the root visit distribution $pi (dot.op divides s)$ (the fifteen most-visited actions, renormalised), the legal set $A (s)$, and the game's eventual outcome $z$ from that state's mover's perspective, or else the marker #emph[truncated];. The policy target is the search distribution rather than the move played, because the search improves on the network's prior and the network is trained to predict that improvement.

Both arms minimise the same loss. For a mini-batch of $B$ records let $K subset.eq { 1 \, dots.h \, B }$ be the records whose outcome is a win, draw or loss, and let $q_theta (dot.op divides s)$ be the three-way softmax of the value head over those three classes. Then

$ cal(L) (theta) = - 1 / B sum_(b = 1)^B sum_(a in A (s_b)) pi (a divides s_b) thin log p_theta (a divides s_b) #h(0em) - #h(0em) lambda_v thin 1 / lr(|K|) sum_(b in K) log q_theta (z_b divides s_b) \, #h(2em) lambda_v = 0.6 . $ <eq:loss>

The first term is the cross-entropy between the recorded visit distribution and the network policy, where $p_theta (dot.op divides s)$ is a softmax over #emph[exactly] the legal set (the grid arm sets every illegal logit to a large negative constant before the softmax; the graph arm produces logits for legal candidates only), so that illegal actions carry identically zero mass in both arms and training uses the normalisation that search uses. The second term is the cross-entropy of the three-class outcome, averaged over the $lr(|K|)$ non-truncated records only (a batch without any contributes nothing) and down-weighted by $lambda_v = 0.6$. The two departures from a plain joint policy-value loss are the legal masking, which removes a confound between the arms (the grid arm's 28,673-way head would otherwise spend capacity suppressing indices that are never legal), and the exclusion of truncated games from the value target, the training-side half of the truncation convention.

=== Economies for small budgets
<economies-for-small-budgets>
The cost of self-play is dominated by search. Wu (2020) showed in the KataGo project that an AlphaZero-style pipeline can be made far more sample-efficient by a handful of representation-agnostic changes. The one adopted here, identically for both arms, is #strong[playout-cap randomization];: the value head needs many games while the policy head needs deep searches, so most decisions are searched cheaply and not recorded, and a minority receive a full search and become training examples. Wu used full searches of 600--1,000 visits on about a quarter of turns and fast searches of 100--200 visits otherwise; the study uses 128 and 32 simulations and records one decision in four, values that were measured on the study machine, as the protocol chapter explains. Self-play also ends a game by #strong[resignation] when the root value falls below $- 0.92$, recording a loss for the resigning side; in 10% of games, chosen before the first move, resignation is disabled so that the rate at which a "lost" position would in fact have been saved can be audited, a standard safeguard of self-play pipelines.

== State representations
<sec:bg-representations>
Everything above is indifferent to how a state is handed to the network, which is the variable of this study. @fig:encodings shows one position under the two encodings compared.

#figure(image("figures/fig3-encodings.png", width: 90.0%),
  caption: [
    A five-tile Hive position under the two encodings compared in this study. Left, the grid arm's view: the position embedded in a fixed 32×32 frame of hexagonal cells (drawn for orientation), each frame cell carrying 77 feature values, so that tiles appear as activations at frame coordinates. Right, the graph arm's view: the cell graph over the candidate set, in which occupied cells (filled, labelled by colour and tile) and every empty cell adjacent to the hive (open circles), together the set of all legal destinations, are joined by edges typed with the six hexagonal directions. Both views derive from the same engine state without loss; only the structure offered to the network differs.
  ]
)
<fig:encodings>

=== Stacked planes for convolutional networks
<stacked-planes-for-convolutional-networks>
The canonical encoding of the AlphaZero family is a stack of binary or scalar planes over the board array, read by a residual convolutional network, which convolution makes translation-equivariant, with a receptive field that widens with depth. Silver et al.~used more than a hundred planes over the 8×8 chess board and 17 planes for Go, and expressed the policy itself as spatial planes. The encoding presupposes a fixed array. For Hive one must manufacture it: the grid arm unwraps the engine's board, stored on a wrapping torus, by breadth-first traversal from any occupied cell, translates the position so that the centre of its bounding box lands on the centre of a 32×32 frame, and writes 77 planes: piece planes indexed by owner, bug type and stack level; planes for pinned tiles, the last-moved tile and both sides' legal placement regions; and constant planes for the side to move, queen liberties, ply and reserves. On axial coordinates the six hexagonal neighbours of a cell are a subset of its 3×3 square neighbourhood, so ordinary 3×3 convolutions cover hexagonal adjacency, two corner weights never meeting a neighbour. The frame is sized so that any base-game position and its ring of candidate cells fit by construction, and the encoder asserts this on every call. No rotation or reflection canonicalisation is applied: the frame fixes translation but not orientation.

=== Graphs and message passing
<graphs-and-message-passing>
The alternative is to hand the network the adjacency structure itself. A graph neural network computes each node's embedding from the node's own features and its neighbours' embeddings, with weights shared across all nodes and all graphs. In the neighbourhood-aggregation scheme of Hamilton et al.~(2017), layer $k$ computes $h_v^k = sigma ( W dot.op [thin h_v^(k - 1) thin ; thin upright(A G G) ({ h_u^(k - 1) : u in cal(N) (v) }) thin] )$ for every node $v$, where AGG is a permutation-invariant function of the neighbour set. Because the weights belong to the layer and not to the node, one trained network embeds a graph of any size or shape. This is the inductive property that a frameless, variable-size Hive position calls for, and that the grid arm's fixed frame only approximates. Plain neighbourhood aggregation ignores edge semantics: a neighbour is a neighbour. In Hive the #emph[direction] of a neighbour matters (a grasshopper jumps along a line; a gate is formed by the two cells flanking one direction), so the graph arm uses #strong[direction-typed relations];, one weight matrix per hexagonal direction. Its message-passing layer updates the embedding of cell $i$ as

$ h_i' = upright(R e L U) ( h_i + W_(upright(s e l f)) thin h_i + b + sum_(d = 1)^6 W_d thin h_(n_i (d)) ) \, $ <eq:mp>

where $n_i (d)$ is the neighbour of $i$ in direction $d$ (the term vanishes when no such neighbour exists within the candidate set), $W_(upright(s e l f))$ and $b$ are the self-transformation and its bias, the six $W_d$ are the direction-typed matrices, and the leading $h_i$ is a residual connection. Nodes are the cells of the candidate set, that is, every occupied cell and every empty cell adjacent to the hive, so that each legal destination, including the empty ones, is a first-class object the policy can score; a graph over pieces alone would have nothing to attach a destination to. Tiles are not separate nodes: a cell's features describe its whole stack level by level, so stacking enters as node content rather than graph structure. Global information (side to move, ply, queen liberties, reserves by bug type) enters as a vector broadcast to every node at input and concatenated to the pooled representation at the heads. Because message passing propagates one hop per layer while queen safety depends on the whole hive, every third layer also adds a #strong[global-pooling bias];, after the global-pooling device of Wu (2020): the mean and maximum of the node embeddings, passed through a linear map and added to every node. The value head reads a masked mean-and-max pooling of the final embeddings; the policy head scores each legal (piece, destination) pair from the destination node's embedding, the moving piece's current node (or a learned vector for placements from hand) and an embedding of the piece slot.

=== What a graph network does and does not provide
<what-a-graph-network-does-and-does-not-provide>
A graph encoding grants no invariance for free. The encoding is coordinate-free: no absolute coordinate appears anywhere, so questions of anchoring do not arise. Message passing with direction-typed edges is nevertheless #emph[not] rotation-invariant (rotating the hive permutes the relation types), receptive fields are limited by depth, and no rule of Hive is known to the network. Legality is supplied per position by the engine through the shared decoder's legal mask, identically for both arms, and neither network ever computes it. Any invariance claim about the learned function must be measured, not assumed. Conversely, the grid arm is not without global context: two of its residual blocks also carry a global-pooling bias, so the two arms differ in how adjacency is presented rather than in whether they can see the whole position.

== Compute budgets and the two readings
<sec:bg-budgets>
"At comparable budget" is the clause that gives the research question its meaning, and it is ambiguous. The large self-play papers state budgets in hardware terms. Silver et al.~report accelerator counts and wall-clock for a single run per game, with generation and training hardware accounted separately, which permits no cost-normalised comparison between architectures. Wu (2020) instead reports hardware type and count, wall-clock, self-play games and training samples, and plots strength against cumulative cost rather than iterations. Jones (2021), training AlphaZero-style agents on Hex at a deliberately small-laboratory scale, measures budgets in FLOP-seconds, GPU-hours and samples, draws #emph[compute frontiers] (the best strength attainable per unit of compute), and finds that training and test-time compute trade against each other: about ten times more training compute replaced about fifteen times more search at constant strength. Hence an evaluation must fix the search budget identically across arms, or it confounds representation quality with search.

The study therefore accounts every run in four denominations, namely wall-clock, hardware (machine, cores, accelerator), number of training states consumed, and simulations per decision, and reads the comparison under two equalisations. Under the #strong[same-examples reading] both arms train on the same number of self-play states, generated with the same simulation budget per decision, and the question is which representation extracts more from each example. Under the #strong[same-wall-clock reading] both arms receive the same number of hours on the same machine, and the question is which representation delivers more strength per hour. The two readings can disagree: a graph network that is better per example but slower per example (in self-play inference, in training, or both) can win the first and lose the second. Neither is privileged; both are reported side by side, the cost asymmetry between the arms measured on the study machine and charged rather than equalised away, and both use the same evaluation search budget.

== Evaluating agents at small scale
<sec:bg-evaluation>
Measuring the strength of a learned Hive agent raises three questions: against whom, with what score, and with what notion of uncertainty.

#emph[Against whom.] Hive has no public ladder of reference networks of the kind KataGo was measured against, and no perfect player to anchor a rating scale as MoHex anchors Jones's Hex experiments; win rate against a random player saturates and cannot separate decent agents (Kampert et al., 2021). The study therefore evaluates against a #strong[fixed opponent population] of three agents, frozen on 9 September 2026 before any training run and never retuned, re-versioned or extended afterwards: B-RND, uniform among legal moves; B-HEU, a greedy agent over a documented hand-crafted evaluation with hash-pinned weights; and B-MCTS, the same tree search as the learned agents but with uniform priors and the hand-crafted evaluation as leaf value, at 6,400 simulations per decision. No checkpoint of either arm belongs to the population, so no arm is scored against itself. Every match plays paired games from the same pre-drawn openings with colours swapped, so that all arms, seeds and opponents face identical opening and colour schedules. Elo-style ratings, where printed, are descriptive, relative to this population, and never a headline number.

#emph[With what score.] The primary metric is the mean #strong[score] against the population, with a win counting 1, a draw 0.5 and a loss 0, computed over non-truncated games only. Truncated games are excluded from the mean and reported as a separate #strong[truncation rate] in every table; a sensitivity column additionally scores truncations as 0.5, and bracketing treatments (truncations as losses, truncations as wins) bound what any alternative cap could change. If the direction of a conclusion changes with the cap, that fragility is itself a reported finding.

#emph[With what uncertainty.] Agarwal et al.~(2021) showed that deep reinforcement learning results from a handful of training runs are routinely over-read: conclusions from point estimates reverse under interval analysis, and uncertainty is badly underestimated below about ten runs. Their remedy, interval estimates from a stratified bootstrap over runs rather than bare means, is adopted with the adaptation they note for a single task: stratification collapses to a bootstrap over seeds. The #strong[seed];, one independent training run, is the unit of analysis. Evaluation games are first aggregated to one score per (seed, opponent) cell; an arm's mean and interval then come from a percentile bootstrap over the seed-level scores, with 10,000 resamples and the 0.025 and 0.975 quantiles as the 95% interval, and the graph-minus-grid contrast resamples both arms' seed sets independently. Games are never pooled as independent observations: thousands of games from one model measure that model precisely but say nothing about the variability between training runs, which is what the comparison is about.

These conventions (frozen opponents, a score that keeps truncation visible, the seed as the unit, intervals over seeds) were fixed in the protocol before any comparison run existed. @sec:protocol states them in full, with the number of seeds, the pre-registered rejection rule and the equal-time cutoff.

= Related work and positioning
<sec:related>
This chapter is organised by problem rather than by paper: Hive-playing programs; the cost of network-guided self-play; representations of states and variable action sets; direct grid-versus-graph comparisons; and evidence standards for few-run studies. Only works read in full during the study are cited. @tbl:related-matrix compares the closest of them with the present design, and @sec:related-positioning states what is reproduced, modified, held identical, and claimed.

== Programs that play Hive
<sec:related-hive>
Scholarly work on Hive is thin and almost entirely classical. Kampert et al.~(2021) built heuristic minimax and MCTS agents on the BeeKeeper engine and documented the game's size: the average branching factor stabilises around 60, roughly twice that of chess (≈30), and even a highly optimised engine generates only ≈400k nodes per second late in the game. Their most robust finding is negative: the intuitive count of tiles around the enemy queen carries little evaluation signal once its weight is tuned, whereas a distance-to-queen term helps; and the win rate against a random player saturates and cannot separate decent agents. Their agents, like the thesis-level attempts they survey, remained below strong human play; their closing suggestion, to insert a lightweight neural network, is what the next work took up.

AZ-Hive (de Goede et al., 2022) is the closest prior work and the direct motivation of this study: an AlphaZero-style loop on base Hive through the same engine, the hex lattice mapped onto a skewed-axis 26×26 array read by a 4-layer CNN with 12-fold symmetry augmentation, and five board encodings crossed with two action encodings (absolute-coordinate versus tile-relative), each configuration trained for 4 h with 5 repeats. Two results matter here. The choice of encoding has a visible effect: with tile-relative actions the hybrid board encoding clearly wins while the original and simple encodings show no win-rate improvement within 4 h, and with absolute-coordinate actions the ordering changes. And the learned engines stayed weak: after 24 h of training the self-play engine rated 1063 in a BayesElo round robin (400 matches per engine, first-move advantage zeroed) against 1181 for plain MCTS and 1355 for the engine's minimax (untrained 704, random 778). Every encoding in their design space is a dense array over a fixed frame; no graph representation appears anywhere in the paper (confirmed against the full text). The authors estimate a full exploration of that space at tens of training-years, the limited-compute framing this study inherits.

Outside the literature, one public hobby project (hiveGo; Pfeifer, 2018--2026) attaches a feed-forward evaluator to an alpha-beta searcher and a "tiny GNN" to an AlphaZero-style loop for Hive in one code base, with a hexagonal-convolution model flagged as broken. It reports no controlled evaluation (no fixed opponents, game counts, seeds or intervals) and never compares its representation families under matched conditions. It is cited as an existence proof that a graph encoder for Hive has been built, and as a small instance of the gap that runs through the field.

== Network-guided search and the cost of self-play
<sec:related-selfplay>
AlphaZero (Silver et al., 2017/2018) fixed the algorithmic template this study inherits: a policy-value network guides PUCT search in self-play (800 simulations per move), the state is presented as stacked spatial planes (8×8×119 for chess) and the policy itself is expressed as spatial planes, the canonical grid parameterisation from which the grid arm descends. Its evidence style is what a small-compute study must depart from: one training run per game, a budget denominated in hardware (5,000 first-generation TPUs for self-play, 64 second-generation TPUs for training), and evaluation against a single reference engine per game. AlphaZero never varies the encoding at fixed budget.

KataGo (Wu, 2020) showed how compressible that cost is: fewer than 30 V100 GPUs for 19 days (≈1.4 GPU-years, 4.2M self-play games, ≈241M training samples) reached the strength ELF OpenGo had reached with ≈74 GPU-years, a claimed gain of ≈50×, and it set the budget-reporting standard followed here: hardware, wall-clock, games and samples, strength against cumulative cost, and one ablation run per technique. Of its economies this study adopts exactly one, playout-cap randomization, because it is representation-agnostic and applies identically to both arms; the Go-specific input features and auxiliary targets, which would smuggle domain knowledge into one encoding, are not copied. KataGo's global pooling gives a convolutional body global context and partly compensates the locality of a grid encoder, which is why the grid arm keeps a global-pooling bias and the graph arm's own global-pooling bias is ablated rather than assumed.

Polygames (Cazenave et al., 2020) is the strongest representative of the grid paradigm done right: fully convolutional bodies with global pooling make the network independent of board size, and the framework produced the first zero-learning program to beat strong human players at 19×19 Hex. That invariance holds inside the fixed-topology grid paradigm: it scales boards whose adjacency is known in advance. Hive is not among its games, and a boardless, stacking game offers no fixed lattice to scale.

Jones (2021) is the closest methodological licence for conclusions at small scale: AlphaZero-style agents trained on Hex from 3×3 to 9×9 with ≈500 GPU-hours in total showed smooth compute-performance frontiers (≈500 Elo per order of magnitude of training compute within a board size), evidence that small self-play experiments carry extrapolatable signal. The same work supplies a warning the protocol encodes: about 10× more training compute replaced about 15× more search at constant strength, so evaluation visit counts must be pinned or a representation comparison becomes a search-budget comparison. Jones used fully connected networks only; representation was never an axis.

== Representing states and variable action sets
<sec:related-representation>
GraphSAGE (Hamilton et al., 2017) grounds the inductive message-passing family the graph arm belongs to: per-layer weights shared across all nodes embed any graph, including graphs never seen in training, and every Hive position is an unseen graph. Vanilla GraphSAGE has no edge semantics and keeps depth small (two layers gave most of its gains); the graph arm adds direction-typed relations (the six hex directions, one weight matrix each) and aggregates over full neighbourhoods, since a Hive cell has at most six neighbours. Depth against budget is a real axis: Keller et al.~(2023) needed fifteen message-passing layers for Hex's long-range dependencies.

Pointer networks (Vinyals et al., 2015) justify scoring a variable candidate set: the output distribution is a softmax over compatibility scores of exactly the candidates present in the input, so no capacity is spent on a fixed, mostly illegal output lattice. The shared action decoder is the board-game form of that mechanism: a distribution over the legal (piece, destination) pairs of the position, which both arms emit over the same action space, built, masked, normalised and trained the same way. Because one cannot point at an element absent from the input, the graph contains empty candidate destinations as first-class nodes.

MDP-homomorphic networks (van der Pol et al., 2020) supply the theory for why representation could matter at small compute: equivariance to the joint state-action symmetry shrinks the hypothesis space and sped up learning on CartPole, a grid world and Pong at equal environment steps. The construction needs a known, small, exact group; base Hive has no board edge, so its symmetry group is large (translations combined with the twelve-element hexagonal group). This study builds no equivariant layers. The graph encoding is coordinate-free by construction, but message passing with directional edge types is not rotation-invariant, so no invariance was assumed of the graph network and none is claimed.

== Direct grid-versus-graph comparisons
<sec:related-direct>
Three works compare a grid encoder with a graph encoder on a board game. None is on Hive, and no two share game, learning algorithm, budget and statistics.

Keller et al.~(2023) ran a parameter-matched CNN-versus-GNN comparison on Hex: a fifteen-layer SAGEConv network (≈487K parameters) against a residual CNN and a U-Net (≈481K parameters), each trained for ≈110 A100-hours at 11×11. The GNN made 1 error on a long-range-dependency suite spanning 8×8 to 25×25 boards where the CNNs made 31 and 36, transferred zero-shot to unseen board sizes and overfit less, while the CNN remained sharper at local patterns in direct play. Three features limit its reach here. The controlled comparison ran under RainbowDQN, and the CNN arm never trained under tree search: the AlphaZero-style run (800 simulations per move, three A100s for ≈6 days) exists for the GNN only. The graph is a Hex-specific Shannon-game reduction in which played cells are contracted away, so every node is an empty cell and actions biject to nodes; the authors state that comparably efficient formulations are not known for other games. And the work is a preprint.

Rigaux and Kashima (2024) report the opposite sign for chess, at a peer-reviewed venue: an edge-featured graph attention network (GATEAU) whose policy is read out over move edges increases playing strength an order of magnitude faster than a same-framework convolutional AlphaZero (learning-speed experiment: eight RTX A5000 GPUs for ≈13 d 16 h), and a model trained on 5×5 Gardner chess transfers to 8×8 (Elo 807±46 with no 8×8 exposure, 1876±47 after 100 fine-tuning iterations). Three features confound a representation claim, each stated by the authors or visible in the paper: every model was trained exactly once, so the reported intervals (delta-method intervals on a Jeffreys-prior Elo estimate) cover match-sampling uncertainty only; "comparable parameters" spans 1.0M for the graph model against 2.2M for the CNN; and the action parameterisation changes together with the representation (an edge readout against a fixed grid head). Chess also gives each edge rich hand-designed semantics (direction, promotion, piece capabilities) that an adjacency graph of Hive does not have.

Ben-Assayag and El-Yaniv (2021) replaced AlphaZero's CNN with a three-layer graph isomorphism network over the square lattice, plus a global dummy node, to train on small Othello, Gomoku and Go boards and play larger ones on one TITAN X: ≈3 days of small-board training beat an AlphaZero trained for up to 30 days on the target board (54% on 16×16 Othello, 84% on 20×20, 100% on 17×17 Gomoku), each figure averaged over five independent runs with standard errors. This is a transfer claim under deliberately asymmetric budgets, not an equal-budget representation comparison, and its actions live on nodes. It nevertheless has the best replication hygiene of the three, and its dummy node is a reminder that shallow message passing needs an explicit global path.

Read together, the three comparisons do not fix a sign for Hive. They make a graph advantage plausible (long-range structure, size transfer, less overfitting) while showing that a CNN can win on local patterns, that the published positive result rests on one run per model with a confounded decoder, and that what the edges encode may matter more than graph structure itself. Hive's play is dominated by local adjacency tactics around the queen, where the Hex evidence favours the grid.

== Evidence standards for few-run comparisons
<sec:related-evidence>
Agarwal et al.~(2021) supply the statistical frame for this regime. Re-analysing published deep-RL results, they show that conclusions from point estimates frequently reverse under interval analysis, that comparisons with 3--5 runs are often not supported by their own data, and that uncertainty is badly underestimated below about ten runs; they prescribe interval estimates everywhere, aggregation per run before any comparison, stratified bootstrap resampling of runs, and a probability-of-improvement statistic in place of bare means. With a single game, stratification collapses to a bootstrap over seeds, so the number of independent training runs is what matters. This study follows the prescriptions with the seed as the resampling unit: one score per seed and opponent, intervals on the graph−grid difference computed over seeds with pairing preserved, and a decision rule written before any run. By contrast, AZ-Hive repeated each 4 h configuration 5 times, Ben-Assayag and El-Yaniv averaged five runs, Keller et al.~and KataGo report one main run, and Rigaux and Kashima trained each model once.

== Summary of the closest works
<sec:related-table>
@tbl:related-matrix places the eight closest works beside the present design.

#figure(
  align(center)[#table(
    columns: (11.75%, 13.53%, 15.3%, 15.3%, 15.3%, 14.41%, 14.41%),
    align: (left,left,left,left,left,left,left,),
    table.header([Work], [Environment], [Representation], [Search], [Budget], [Evidence protocol], [Difference from this study],),
    table.hline(),
    [AZ-Hive (de Goede et al., 2022)], [Hive, base game], [5 dense hex-lattice array encodings × 2 action encodings, all CNN; 26×26 frame], [AlphaZero-style MCTS], [4 h per configuration, 5 repeats; one 24 h engine], [Loss curves; win rate vs random; BayesElo round robin], [No graph arm; conclusions on early learning speed; engines below plain MCTS],
    [Kampert et al.~(2021)], [Hive, base game], [Hand-crafted heuristic features], [Minimax (alpha-beta, transposition table), MCTS variants; 0.01--1 s per move], [One compute node], [Win rate vs random; turns-to-win; Elo round robin], [No learning, no representation question; agents below human level],
    [Keller et al.~(2023)], [Hex 8×8--25×25 (Shannon-game graph)], [15-layer SAGEConv GNN (≈487K) vs ResNet and U-Net (≈481K)], [RainbowDQN for the comparison; AlphaZero-style (800 simulations) for the GNN only], [≈110 A100-hours per model], [Long-range test suite; size transfer; one run per model], [CNN arm never under self-play search; Hex-specific graph; per-node actions; preprint],
    [Rigaux & Kashima (2024)], [Chess (8×8) and 5×5 Gardner], [Edge-featured graph attention (GATEAU) with edge policy readout, vs CNN planes], [AlphaZero-style MCTS], [8×A5000, ≈13 d 16 h], [Relative Elo with delta-method intervals; one run per model], [Single run, no seed variance; 1.0M vs 2.2M parameters; decoder changes with representation],
    [Ben-Assayag & El-Yaniv (2021)], [Othello, Gomoku, Go; small boards → large], [3-layer GIN over the square lattice + global dummy node; node policy], [AlphaZero-style MCTS, 100 simulations], [1×TITAN X; ≈3 d vs 30 d, asymmetric by design], [Win rate vs random, greedy and AlphaZero; 5 runs with standard errors], [Transfer claim, not an equal-budget comparison; node-only actions; code unreleased],
    [Polygames (Cazenave et al., 2020)], [Hex, Havannah, Othello and others; not Hive], [Fully convolutional + global pooling (grid)], [AlphaZero-style MCTS], [Not comparable per run], [Competition results; wins vs strong humans at 19×19 Hex], [Grid paradigm only; fixed-topology boards],
    [KataGo (Wu, 2020)], [Go], [CNN planes + global features and pooling], [PUCT-MCTS with playout-cap randomization], [Fewer than 30 V100 for 19 days (≈1.4 GPU-years)], [Bayesian Elo vs an external ladder; per-technique ablations; one main run], [Cost-reduction study, not a representation comparison; Go-specific features],
    [Jones (2021)], [Hex 3×3--9×9], [Fully connected residual networks], [AlphaZero-style MCTS], [≈500 GPU-hours total, swept], [Elo anchored to perfect play; compute frontiers], [Representation never varied; no perfect-play anchor exists for Hive],
    [This study], [Hive, base game], [Grid: 77 planes on a 32×32 frame, residual CNN (1.44M); graph: cell graph with six direction-typed relations, message passing (1.47M); shared action decoder], [Same PUCT-MCTS for both arms; 128/32 simulations with playout-cap randomization; 400 at evaluation], [One machine; 10 generations × 500 games per run; same-examples and same-wall-clock readings], [5 independent seeds per arm; frozen three-opponent population; seed-level bootstrap intervals; pre-registered rejection rule], [none],
  )]
  , caption: [Closest prior work compared with this study (environment, representation, search, budget, evidence protocol, and the difference from the present study).]
  , kind: table
  ) <tbl:related-matrix>

== Positioning
<sec:related-positioning>
#strong[What is reproduced.] The AlphaZero-style loop as published (policy-value network, PUCT search with root noise, visit-distribution policy targets, joint policy-value loss; Silver et al., 2018), with KataGo's playout-cap randomization in self-play (Wu, 2020). The grid arm reproduces the AZ-Hive family of encodings in spirit: the hex lattice embedded in a fixed frame and read by a residual CNN (de Goede et al., 2022), here a 32×32 frame unwrapped by breadth-first traversal, centred on the occupied bounding box and carrying 77 planes. Evaluation follows Kampert et al.~(2021) and AZ-Hive in measuring against fixed, non-learned opponents. The rules engine and classical search that serve both arms predate the study (built in July 2026 as an engine project and validated against the two reference engines listed in the webography); the study-specific pipeline, both encoders, the graph network, the baselines and the protocol were built from September 2026.

#strong[What is modified.] The representation axis gains the graph arm that none of the Hive works has: a cell graph over the position's candidate set (every occupied cell plus its ring of empty neighbours, so that every scorable destination is a node), with 56 node features carrying the full stack composition, six direction-typed relations realised as relation-specific weight matrices, a global vector and a global-pooling bias. The two arms are capacity-matched to within +1.5% (1.44M against 1.47M parameters), far tighter than the 1.0M-against-2.2M comparison of Rigaux and Kashima (2024). And the evidence protocol replaces single-run Elo curves with the few-run discipline of Agarwal et al.~(2021): five independent seeds per arm, seed-level bootstrap intervals on the graph−grid difference, and a rejection rule written into a protocol frozen on 10 September 2026 against an opponent population frozen on 9 September 2026, both before any training run.

#strong[What stays identical across arms.] Everything except the state encoder and network body: the engine, the tree search and its budgets (128 or 32 simulations per decision with playout-cap randomization in self-play, 400 at evaluation), the action space over (piece, destination) pairs with its legality mask, targets and loss, the training loop, the data pipeline, the generation schedule, the evaluation harness, the pre-drawn paired openings, the three opponents (legal-random, heuristic, and search at 6,400 simulations without a network), and the machine. Budget is read twice, as the same number of training examples and as the same wall-clock on the same hardware, because a representation that is better per example but slower per example can lose the second reading; both are reported side by side.

#strong[What is claimed.] No prior work runs a controlled, budget-matched grid-versus-graph comparison for Hive with both arms under one self-play pipeline. The scoped contribution is therefore the first controlled, multi-seed grid-versus-graph comparison for Hive that is budget-matched under both the same-examples and the same-wall-clock reading, with both arms trained under one AlphaZero-style self-play pipeline, in a frameless, stacking game whose actions are (piece, destination) pairs and whose graph must carry empty candidate destinations. It is deliberately not "the first grid-versus-graph comparison in a board game", which Keller et al.~(2023) and Rigaux and Kashima (2024) preclude. The perimeter comprises one variant (base Hive), one grid network and one relational message-passing network at one matched capacity, one machine, frozen opponents, openings and protocol, two budget readings, five seeds per arm. Within it the question is answered in the results chapters; outside it nothing is claimed. The contrast with the positive chess result and the long-range-versus-local asymmetry in Hex is taken up in the discussion chapter.

#part[Part II. Building the system]
= How and when the system and the study were built
<sec:chronology>
The software behind this study has three layers of provenance with different evidential weight. The rules engine, the classical search and the first neural pipeline were built in July 2026 as an engine project aimed at playing strength, not at a controlled comparison. A first AlphaZero-style self-play loop ran on that engine from July to August 2026; it is a demonstration and nothing more. Everything that carries evidence here (corpora, opponent population, protocol, both encoders and networks, campaigns and analyses) was built and run from 9 September 2026 onward (@tbl:timeline, @fig:timeline).

== The engine project (July 2026)
<the-engine-project-july-2026>
The engine project set out to build a Hive program for all eight game types of the Universal Hive Protocol (the base game and every combination of the Mosquito, Ladybug and Pillbug expansions), strong enough to play automated matches against the two public reference engines, MzingaEngine and nokamute. Its design was staged: a classical alpha-beta engine with a handcrafted evaluation first, as sparring partner and test oracle; then an AlphaZero-style combination of Monte-Carlo tree search and a neural network trained by self-play. The core was written in Rust, training in Python and PyTorch, and in-engine inference used ONNX with the CoreML execution provider at fixed shapes. The plan was sized for a single Apple M4 Pro (14 cores, 24 GB).

The repository's first commits and the project's status note both carry the date 12 July 2026. The note records what that first build day reached: rules kernel, protocol input/output, alpha-beta engine and match arena complete; perft counts matching the published reference tables to depth 7 for all eight game types; differential fuzzing against MzingaEngine and nokamute passed over 27k and 66k positions; conformance 21/21; the neural pipeline (frame, policy encoding, records, data generation, a 1.44M-parameter network, ONNX export) complete; the inference go/no-go passed at 2,246 evaluations per second at batch 128 on CoreML; the network-guided search started. The note also records strength figures (100% against MzingaEngine, 79.2% against nokamute at 1 s per move, +232 Elo); these are the engine project's own numbers, and the study makes no use of them.

== The prior self-play loop (July--August 2026)
<the-prior-self-play-loop-julyaugust-2026>
A supervised bootstrap from alpha-beta games ran overnight on 12--13 July 2026, and the first generation of the self-play loop started on 13 July 2026. Each generation played 2000 games at 600 full and 150 cheap simulations per decision on 2 threads, taking roughly 150,000--157,000 s; a candidate was gated over 60 games at 2 s per move against the incumbent and promoted above 50%. Nineteen generations completed. Promotions were intermittent (generations 6, 7, 11, 14 and 19 among those logged, gate scores from about 45% to 63%), training metrics fluctuated rather than climbed (policy top-1 roughly 43--47%, value accuracy roughly 58--63%), and generation 19 was promoted at 56.7%. Generation 20 aborted on 14 August 2026 when the disk filled; the loop has not run since.

The loop is classified as a demonstration, not evidence, for reasons fixed in writing on 9 September 2026 before any study work began: single seed, single architecture, no controlled compute budget, no opponent population fixed in advance. It shows that an end-to-end self-play pipeline was built and ran; it shows nothing about representation quality or learning efficiency. The study inherits the engine and its validation evidence, not the loop's results. The author stopped the loop permanently on 9 September 2026, excluded its generation-19 checkpoint from the frozen opponent population the same day, and deleted the original workspace on 10 September 2026, leaving the research copy as the only copy of the prior work.

== The research programme (from 9 September 2026)
<the-research-programme-from-9-september-2026>
#strong[9 September 2026: inventory, validation, baselines.] The programme opened with an inventory separating working demonstrations from reproducible comparisons, and two framing choices: base game only, and a game reaching the move cap is never scored as a draw. The engine's validation suites were re-run on the study machine, an Apple M1 Pro (10 cores, 16 GB): perft to depth 6 for all eight game types in 8.32 s, conformance 21/21, differential fuzzing at 27,829 positions against each reference engine, plane crosscheck at 240 positions. A 30-case corpus of critical positions, annotated by hand from the publisher's rules and committed before any engine run, gave 29/30 on the first run, with the single disagreement resolved against the corpus, and 30/30 on the second. Seeded random-game invariant checks applied and undid 10.9M transitions without a violation, and a throughput profile measured the costs the protocol would later carry. The three baseline opponents were built, characterised over 100 paired games per pairing, and frozen by the author that day with the search opponent at 6,400 simulations and the prior checkpoint excluded; the author postponed the protocol freeze until a pilot had re-measured the proposed budgets with a study-scale network. The CoreML inference defect found during profiling was fixed the same evening.

#strong[9--10 September 2026: pipeline, pilot, freezes, encoders, launch.] The study-specific pipeline was built on 9 September (a record format with a distinct truncation outcome, legal-masked training, seven automated pre-training checks); its pilot self-play began at 20:44 that evening, and the pilot's single generation of 300 games, training and evaluation completed on 10 September. On the pilot's measurements the author froze the protocol at version 1.0 on 10 September 2026, with its hash and commit recorded. The same day the grid encoder was re-used with a hardened bounds check, the graph encoder and network were written and property-tested, both encoders were pinned by cross-language golden tests (240 and 160/160 positions), 250 four-ply openings were generated blind and frozen by the author, and the author approved the campaign at its full size, launched at 12:42.

#strong[10--19 September 2026: main campaign and three-seed analysis.] Six runs (two arms × three seeds) executed in sequence and finished on 17 September 2026 at 22:31. On 16 September, with five of six runs complete, the equal-time cutoff was computed from the grid arm's wall-clocks alone, as pre-registered (18.77 h), before any cross-arm number existed, and the evaluation volume was kept at 100 games per pairing after a precision check. Cutoff-checkpoint evaluations ran on 18 September (about 11 h); that day the rule that every selected failure position be reproduced exposed a record-loss defect in the match runner, fixed after an audit showed no campaign file affected. The three-seed analysis of 19 September 2026 rejected the hypothesis under the pre-registered rule.

#strong[19 September -- 9 October 2026: ablations, extension, final analysis.] Ablation configurations were prepared on 19 September, with one substitution decided that day; the author approved the ablation campaign on 20 September 2026, both ablations at full three-seed parity with the main comparison. The edge-typing ablation's divergence (non-finite outputs in generation 0 for 3/3 seeds) was diagnosed on 23 September; the pooling ablation's runs completed on 24, 26 and 27 September and were analysed on 2 October. On 26 September 2026 the author approved, with pre-commitments stated before any new run, a symmetric extension to five seeds per arm and the two-component supplement to the diverged ablation. Seeds 4 and 5 ran from 27 September to 2 October, with cutoff evaluations on 6 October; the supplement ran from 2 to 6 October. The final five-seed analysis of 9 October 2026 confirmed the rejection; the report was assembled in English and French the same day, then expanded at the author's request with no number, claim or frozen artifact changed.

== Timeline
<timeline>
#figure(
  align(center)[#table(
    columns: (19.21%, 46.8%, 34%),
    align: (left,left,left,),
    table.header([Date], [Milestone], [Evidence produced],),
    table.hline(),
    [12 July 2026], [Engine project: first commits; kernel, protocol, alpha-beta, arena, neural interface, tree search], [Status note: perft to depth 7 (8 types), fuzz 27k/66k positions, conformance 21/21, inference 2,246 evals/s at batch 128],
    [12--13 July 2026], [Supervised bootstrap from alpha-beta games], [Bootstrap logs (demonstration only)],
    [13 July -- 14 August 2026], [Prior self-play loop: 19 generations; promotions at 6, 7, 11, 14, 19; generation 20 aborted on a full disk], [Loop logs; generation-19 checkpoint (preserved, excluded)],
    [9 September 2026], [Programme opens: inventory; validation suites re-run; corpus 30/30; 10.9M-transition invariant checks; throughput profile; CoreML fix; baselines characterised and frozen], [Inventory; validation entries; population freeze record with hashes],
    [9--10 September 2026], [Pipeline; pilot (300 games); protocol frozen v1.0; encoders golden-tested (240, 160/160); 250 openings frozen; campaign launched 12:42], [Pilot entry; protocol hash; encoder entries; openings hash; campaign log],
    [10--17 September 2026], [Main campaign: 6 runs in sequence, finished 17 September 22:31], [Per-run wall-clock logs, checkpoints, evaluation records],
    [16 September 2026], [Equal-time cutoff from grid wall-clocks (18.77 h) before any cross-arm comparison; 100 games per pairing kept], [Monitoring entry with the derivation],
    [18--19 September 2026], [Cutoff evaluations; figures; record-loss defect fixed; three-seed analysis: hypothesis rejected], [Result tables, arm contrasts, figures; methodology log entry],
    [20 September 2026], [Ablation campaign approved and launched (two ablations × 3 seeds)], [One-component configuration diffs],
    [23 September 2026], [Edge-typing ablation diagnosed: non-finite from generation 0 in 3/3 seeds; guards added], [Divergence entry],
    [26 September 2026], [Five-seed extension and two-component supplement approved with pre-commitments], [Decision records quoting the pre-commitments],
    [27 September -- 6 October 2026], [Seeds 4--5 (to 2 October), cutoff evaluations (6 October); supplement (2--6 October); pooling ablation analysed (2 October)], [Run logs; ablation entries],
    [9 October 2026], [Final five-seed analysis (rejection stands); supplement analysed; report assembled in English and French, then expanded], [Final result tables; report],
  )]
  , caption: [Chronology of the engine project and the study, from the repository's commit history, the status note of 12 July 2026, the loop logs, the dated journal entries and the decision records carrying the author's approvals; the last column names the artifact documenting each milestone.]
  , kind: table
  ) <tbl:timeline>

#figure(image("figures/fig10-timeline.png", width: 90.0%),
  caption: [
    Project chronology, July--October 2026: engine project (12 July), prior self-play loop classified as a demonstration (13 July -- 14 August), and research programme (9 September -- 9 October) with freezes (population 9 September; protocol and openings 10 September), main campaign (10--17 September), equal-time cutoff (16 September), three-seed analysis (19 September), ablations (20 September -- 6 October), seed extension (27 September -- 6 October) and final five-seed analysis (9 October).
  ]
)
<fig:timeline>

= The Hive engine: design, implementation and validation
<sec:engine>
Every arm, opponent and evaluation in this study shares the engine. A self-play study trains on positions the engine itself generates and scores, so a rules defect would teach both arms the same wrong game and silently invalidate the comparison rather than merely adding noise. The engine was built in July 2026 as an independent project (@sec:chronology) and validated along four independent lines on 9 September 2026, before any baseline or training work. This chapter covers its goals, architecture, board representation, move generation, validation, throughput, and the two fixes recorded before training.

== Design goals
<design-goals>
The engine project fixed five goals. The first was rules fidelity: all eight game types of the Universal Hive Protocol, with exact agreement to the reference engine's published perft tables and per-ply agreement of legal-move sets with two independent reference engines as acceptance criteria. The second was protocol interoperability over standard input and output, so that MzingaEngine and nokamute can be driven as subprocesses. The third was staged strength: a classical alpha-beta engine with a handcrafted evaluation first, as sparring partner and test oracle, then AlphaZero-style tree search guided by a self-play-trained network (Silver et al., 2018). The fourth was single-machine feasibility, meaning an allocation-free Rust kernel, fixed-shape ONNX exports for the CoreML execution provider, and an inference go/no-go before any self-play. The fifth was verification built in from the start: unit tests per rule, perft fast in the standard suite and deep nightly, cross-engine differential fuzzing, make/unmake hash property tests, and a tactical regression suite.

Two further properties mattered more for the study than strength: the rules kernel performs no input or output and holds no global state, so one kernel referees arena games, generates self-play and serves the protocol; and every stochastic component is seeded, so any recorded game replays deterministically.

== Architecture
<architecture>
The engine is a Rust workspace of small crates with one-way dependencies: the rules kernel at the bottom, protocol and evaluation above it, the two search backends above those, and the arena, self-play generators and shipped binary on top (@tbl:engine-components). Three choices deserve a word. The classical search has no null-move pruning, because Hive's forced-pass states make tempo-based pruning unsound in exactly the positions that matter, the queen races; its quiescence covers only Hive's forcing moves, those landing on or beside the enemy queen. The network-guided search is generic over an evaluator with one output contract, so the handcrafted evaluation with uniform priors (the study's no-network opponent), the grid network on CoreML and the graph network on the CPU provider all run through the identical tree search. The self-play generator implements the KataGo economies of Wu (2020): playout-cap randomization, Dirichlet root noise, early-move temperature, and resignation with an audit fraction. Root noise stays off in every other backend.

#figure(
  align(center)[#table(
    columns: (22.74%, 37.97%, 39.29%),
    align: (left,left,left,),
    table.header([Component], [Role], [Properties the study relies on],),
    table.hline(),
    [Rules kernel], [State, move generation, make/unmake, hashing, notation, perft, canonicalisation], [No input/output, no global state; all eight game types; referees every game],
    [Protocol server and client], [Universal Hive Protocol over standard streams; subprocess driver for other engines], [Every response block ends with `ok`; any backend plugs in behind one trait],
    [Handcrafted evaluation], [Static evaluation, negamax convention], [Queen liberties dominant, piece activity, tempo; weights hash-pinned for the heuristic opponent],
    [Classical search], [Principal-variation search, iterative deepening], [Lock-free shared transposition table (XOR-validated), lazy SMP, killer/history ordering, late-move reductions, aspiration windows; no null move; queen-targeting quiescence],
    [Neural interface], [32×32 frame of 77 planes; 28,673-way (piece, destination) policy index; training records (112-byte one-hot, 176-byte with visit distribution, study version with model stamp, legal-index list, truncation outcome)], [Byte-identical to the Python decoder (golden-tested)],
    [Network-guided search], [Batched PUCT tree search over an evaluator], [Replay-based descent, virtual loss; three evaluators, one output contract; noise off unless self-play enables it],
    [Match arena], [Paired colour-swapped games from seeded random openings or a fixed file (pair #emph[i] plays line #emph[i];)], [Every reply validated by the kernel; 300-ply cap a separate outcome, excluded from the score and reported as a rate],
    [Self-play generators], [Alpha-beta bootstrap data; tree-search self-play], [Playout-cap randomization, root noise, temperature, resignation with audit; seeded],
    [Shipped binary], [Protocol front-end over all backends], [Alpha-beta by default; tree search with heuristic, grid or graph network; legal-random; seed and simulation flags],
  )]
  , caption: [Components of the engine, their roles, and the properties the study relies on. One rules kernel generates, referees and serves every game in this report; the three frozen opponents and both study arms are backends of the same binary.]
  , kind: table
  ) <tbl:engine-components>

== Board representation and hashing
<board-representation-and-hashing>
Hive has no board: pieces define the playing surface, and a hive drifts across the plane as it grows. The engine nevertheless uses a fixed 64×64 grid of cells in axial coordinates, wrapping into a torus, on a counting argument: a hive contains at most 28 pieces, so it spans at most 28 cells along any axis, and on a 64×64 torus every local query (adjacency, slides, jumps) is indistinguishable from the same query on an infinite plane. Each cell stores its top piece, stacks live in a side table, and the maximum stack height is 7 (a ground piece under 4 beetles and 2 mosquitoes).

Because the hive never leaves the torus, coordinates never need renormalising during a game, which keeps the position hash fully incremental: make and unmake XOR the moved pieces' keys in and out, and no re-centring ever forces a recomputation or invalidates transposition-table entries. Translation symmetry is therefore irrelevant inside a search tree; canonicalisation under translation and the 12 hex symmetries is isolated at the boundary with the network frame and the opening book. The Zobrist hash is computed by a mixing function rather than lookup tables (a full table would be about 6 MB; mixing a packed (piece, cell, level) key costs about 2 ns with zero memory) and folds in the side to move, the last-moved piece and an early-game phase component. Repetition detection drops the phase component, so the same arrangement reached at different plies compares equal, but keeps side to move and last-moved piece, the stun rights, much as chess repetition keys keep en-passant rights; a third occurrence is a draw unless the game is already decided by surround.

== Move generation and rule edge cases
<move-generation-and-rule-edge-cases>
Move generation follows the reference engine's conventions, because those are what its published perft tables count: the queen may not be placed on either player's first turn (the tournament opening rule), for identical in-hand bugs only the lowest ordinal is placeable, a player with no placement and no movement receives the single move `pass`, and a finished game generates no moves.

Sliding and gate legality is evaluated on a #emph[lifted] view of the board, the occupancy with the mover removed from its origin cell. On that view the #strong[freedom-to-move] rule for a ground-level slide step reads: the destination must be empty, and of the two cells adjacent to both origin and destination exactly one must be occupied; with zero the piece would detach in transit, and with two the gate is too narrow to pass. The #strong[height gate] for climbing moves (beetle and ladybug steps, both legs of a pillbug throw) blocks a step if and only if both common neighbours are strictly higher than both the level the mover starts above and the destination stack; the above-ground beetle gate of the tournament FAQ falls out of this rule without a special case. The #strong[One-Hive] rule is an articulation-point computation: a ground-level piece may be lifted if and only if its cell is not a cut vertex of the occupied-cell graph, found by a lowlink depth-first search once per move generation; tops of stacks are exempt, since the cell keeps its node, and a pinned pillbug may still throw, since it does not itself move.

The #strong[stun rule] of the Pillbug expansion, under which a piece moved on the previous turn may neither move nor be moved, needs a single field: the piece physically moved or placed on the previous ply. A piece is stunned if and only if it is that piece and belongs to the side to move; a pillbug may not throw that piece; the stun lapses after one opponent turn; placement also sets the field. The #strong[mosquito] copies each adjacent bug type and is a pure beetle on top of the hive; the #strong[ladybug] moves exactly two steps on top and one down. Because mosquito multi-copy, ladybug multi-path and walk-versus-throw can derive the same move more than once, the generated list is sorted and de-duplicated; if it is then empty, `pass` is generated.

=== Why a (piece, destination) pair identifies a move
<why-a-piece-destination-pair-identifies-a-move>
The policy spaces of both arms and the de-duplication above rest on the claim that (piece, destination cell) determines the successor state. A placement takes the piece from hand to an empty cell, so the pair fixes the result. A movement starts from the piece's current location, which the state determines uniquely, and ends on top of the destination stack, whose height the state also determines; so the pair fixes the board. The only way two distinct actions share a pair is a pillbug throw of a piece to a cell it could also have walked to. Both produce the same board, so the successors could differ only in the record of which piece moved last, and the engine stores only #emph[which] piece moved, not how. That suffices: at the start of a player's turn, if the last-moved piece is their own, the opponent can only have thrown it, so it is frozen this turn; if it is the opponent's, the player's pillbug may not throw it either way, and nothing else depends on the distinction. Hence the walk--throw collision yields identical states, and a policy head indexed by (piece, destination) plus pass loses nothing.

== Validation campaign (September 2026)
<validation-campaign-september-2026>
All validation evidence was re-established on 9 September 2026 on the study machine, an Apple M1 Pro (10 cores, 16 GB), with the reference engines freshly fetched (MzingaEngine v0.16.0, the protocol's reference implementation, and nokamute 1.0.3 built from source), before any baseline or training work. Four lines of evidence bound four different failure modes; a fifth check pins the data path to the training code.

=== Perft against published tables
<perft-against-published-tables>
Perft counts legal-move paths to a given depth under the reference engine's conventions, so its published tables serve as ground truth; it is exhaustive within its depth, and any discrepancy in move generation (a missing move, an extra move, a wrong stacking rule) shifts a count. The standard suite checks depth ≤5 for all eight game types on every build, a dedicated run checks depth 6, and the nightly run checks depth 7. On 9 September 2026 the standard suite passed and the depth-6 run completed in 8.32 s with every count matching; depth 7 was not repeated that day, so the study claims depth ≤6, with depth 7 last matched in July 2026 (@tbl:perft-base, @tbl:perft-types).

#figure(
  align(center)[#table(
    columns: (40.97%, 59.03%),
    align: (left,right,),
    table.header([Depth], [Nodes],),
    table.hline(),
    [1], [4],
    [2], [96],
    [3], [1,440],
    [4], [21,600],
    [5], [516,240],
    [6], [12,219,480],
  )]
  , caption: [Perft node counts for the base game, depths 1--6, as published for the reference engine and reproduced exactly by the rules kernel on 9 September 2026 (no queen on a player's first turn; identical in-hand bugs counted once; forced pass counts as one move; a finished game generates none).]
  , kind: table
  ) <tbl:perft-base>

#figure(
  align(center)[#table(
    columns: (23.03%, 21.93%, 25.88%, 29.17%),
    align: (left,right,right,right,),
    table.header([Game type], [Depth 4], [Depth 5], [Depth 6],),
    table.hline(),
    [Base], [21,600], [516,240], [12,219,480],
    [Base+M], [45,414], [1,252,800], [34,233,432],
    [Base+L], [45,414], [1,252,800], [34,233,672],
    [Base+P], [45,414], [1,255,932], [34,395,984],
    [Base+ML], [86,400], [2,725,920], [85,201,200],
    [Base+MP], [86,400], [2,730,888], [85,492,248],
    [Base+LP], [86,400], [2,730,240], [85,457,136],
    [Base+MLP], [151,686], [5,427,108], [192,353,904],
  )]
  , caption: [Perft node counts at depths 4--6 for all eight game types (M = Mosquito, L = Ladybug, P = Pillbug), as published for the reference engine and matched by the rules kernel; the Mosquito and Ladybug variants share counts through depth 5 and separate only at depth 6, hence the depth-6 run.]
  , kind: table
  ) <tbl:perft-types>

=== Reference-engine agreement
<reference-engine-agreement>
The protocol conformance harness shipped with nokamute passed 21/21. More stringently, differential fuzzing plays seeded random games while asserting, after every ply, #emph[set equality] of the legal-move sets returned by the engine and by a reference. At seed 20260909 with 25 games per game type, both references agreed on every one of 27,829 positions (the identical count is expected: same seed, same games); the nightly run repeats this at 200 games per type against nokamute and 100 against MzingaEngine. Agreement with two independent code bases bounds a misreading shared with the engine, not one shared by the whole community of implementations, which the next line addresses.

=== The hand-annotated critical corpus
<the-hand-annotated-critical-corpus>
Thirty critical positions were annotated by hand from the publisher's rules: the base-game rulesheet cited by page, the Pillbug sheet, and the World Hive Tournaments rules FAQ for above-ground gates and stun clarifications. The tournament opening rule was declared as the study's convention. Every expectation was written from the rules text, never from or against the engine, and the corpus was committed before the first run. Each case is a protocol move sequence from the empty board, hence reachable and independently checkable, with an expectation of one of seven kinds: the exact move set of a focal piece (possibly empty), a single move legal or illegal, every move a placement of a named piece, no movement moves, forced pass, or a terminal state. The runner drives the engine over the protocol, resolves move strings to cells with a geometry-only parser that knows no game rules, and compares (piece, destination) sets. @tbl:corpus-coverage lists the coverage; the full corpus with every justification is in @sec:app-a.

#figure(
  align(center)[#table(
    columns: (65.34%, 34.66%),
    align: (left,left,),
    table.header([Rule area], [Cases],),
    table.hline(),
    [Opening and placement rules], [C001--C005],
    [Sliding, freedom to move, gates], [C006--C012],
    [Beetle and stacking, beetle gate above ground level, stack colour], [C013--C018, C028],
    [One-Hive, rings, grasshopper cut point], [C019--C020, C027],
    [Terminal states: win, draw by simultaneous surround], [C021--C022],
    [Forced pass], [C023],
    [Pillbug ability, stun, just-moved guards (kernel guards, Base+P)], [C024--C026],
    [Spider step count; queen move enumerations], [C008, C029; C006, C011, C030],
  )]
  , caption: [Coverage of the 30-case hand-annotated critical corpus by rule area, with case identifiers as used in the corpus appendix. Expectations were written from the publisher's rules and committed before any engine run; three Pillbug cases guard the shared kernel's stun logic and lie outside the study's base-game perimeter.]
  , kind: table
  ) <tbl:corpus-coverage>

The first run returned 29 passes and one setup error. The disputed case was the simultaneous-surround draw: its setup moved the black queen one step with both flanking cells empty, so the hive would have been "left unlinked while the piece is in transit", which is precisely the illegal-move example the rulesheet gives for the One-Hive rule; the engine's rejection was the rule-mandated behaviour. The disagreement was resolved #emph[against the corpus];: the setup was rerouted through an intermediate cell so every step keeps an occupied flanking cell, the expected outcome (a draw) was left unchanged, and the correction was documented in the case file. The second run returned 30/30. The record of the corpus being wrong is kept deliberately: committed-before-run expectations cut both ways. Two limits are declared: no external review by a Hive-literate reader yet, and 30 cases sit at the bottom of the 30--50 range the research plan proposed; the strongest cases are the enumerations (13 destinations in one sliding case, 6 in a beetle case).

=== The tactical suite
<the-tactical-suite>
A second hand-annotated set verifies the #emph[search] rather than the rules. It holds five positions with a known good outcome: a win in one by a walking piece and by a jumping piece, each for both colours, and a position where the mover must avoid completing its own queen's surround. Since several pieces can often reach the winning cell, expectations are destination-based: the searcher's move must, or must not, land on a named cell. The network-free tree search solved 5/5 at 400, 1,600 and 6,400 simulations. Value signs under player alternation are covered by automated tests (the evaluation negates when the side to move flips; mate-in-one scores and root values are positive for the mover, both colours). One setup slip, a piece-ordering error in one case, was caught at the first run because the cases had been committed beforehand; the engine was right, so the setup was corrected and the incident recorded. The same external-review limit applies.

=== Random invariant checks
<random-invariant-checks>
Seeded random games across all eight game types check four invariants after every transition: every generated move is accepted by the apply path and undo restores the exact game string; the hive remains connected; the protocol game string round-trips to the same position, result and sorted legal-move set; and pass is played exactly when the move list is empty. A violation would halt with game type, seed, game, ply and game string for archiving as a regression case; none arose (@tbl:invariants). The default run is in the standard suite on every build, the deep run in the nightly script.

#figure(
  align(center)[#table(
    columns: (17.29%, 17.29%, 14.22%, 19.69%, 16.63%, 14.88%),
    align: (left,left,right,right,right,right,),
    table.header([Run], [Games], [Plies walked], [Generated moves applied and undone], [Violations], [Duration],),
    table.hline(),
    [Default (every build)], [4 per type × 8 types, ≤150 plies], [4,029], [253,936], [0], [2.7 s],
    [Deep (nightly)], [3 rounds × 20 per type × 8 types, ≤400 plies], [161,546], [10,665,686], [0], [214 s],
  )]
  , caption: [Seeded random-game invariant checks of 9 September 2026 over all eight game types (apply/undo exactness, hive connectivity, game-string round trip, pass exactly when no move exists). Deterministic given the seeds; durations on the study machine.]
  , kind: table
  ) <tbl:invariants>

=== Cross-language data-path check and scope
<cross-language-data-path-check-and-scope>
The grid arm's plane encoder in Rust and the decoder in the Python training code are required to be byte-identical; a golden-file crosscheck over 240 positions confirmed exact agreement on 9 September 2026 and runs nightly. The graph encoder built on 10 September received the same treatment, with 160 of 160 positions across all eight game types agreeing exactly on the first run.

These lines bound different failure modes (exhaustiveness at depth, agreement with references, fidelity to the rules text, search correctness, invariant stability), but none proves full-game perfection, and code coverage is deliberately not claimed as correctness evidence. The stop rule that an incorrect engine suspends all training-side work was not triggered; baseline and pipeline work proceeded the same day.

== Throughput profile
<throughput-profile>
Before any simulation budget or move cap was fixed, the engine's costs were measured on the study machine with short runs on the existing binaries, the prior loop's generation-19 checkpoint serving only as a realistic inference workload (@tbl:throughput).

#figure(
  align(center)[#table(
    columns: (48.79%, 51.21%),
    align: (left,left,),
    table.header([Measurement], [Value],),
    table.hline(),
    [Perft(5), base game], [516,240 nodes in 1.36 ms (≈380 MN/s)],
    [Perft(6), base game], [12.2 M nodes in 26.5 ms (≈461 MN/s)],
    [Alpha-beta, opening position, depth 10], [7.20 Mnps],
    [Alpha-beta, midgame position, depth 8], [4.67 Mnps],
    [Alpha-beta decision at depth 4], [≈40 ms, single thread],
    [Full games at depth 4 (6 threads, 100 games)], [22 s wall, 4.6 games/s, 4,397 recorded positions],
    [Game length at depth 4 (30 seeded games)], [mean 55.0, median 39, 90th percentile 80, maximum 202 plies; none reached the 300-ply cap],
    [Network inference, Python ONNX package, CPU provider, batch 1], [23.5 ms per evaluation (43 evaluations/s)],
    [Network inference, Python ONNX package, CoreML provider, batch 1], [2.62 ms per evaluation (382 evaluations/s)],
    [Network inference, Rust bindings, CoreML provider], [crashed (fixed below)],
    [Protocol round trip from Python], [21.7 µs per `validmoves` (46,051 requests/s); 21.6 µs per play--undo pair],
  )]
  , caption: [Throughput profile measured on 9 September 2026 on the study machine (Apple M1 Pro, 10 cores, 16 GB), release builds, profiling seed 20260909, game-length seeds 1001--1030 (lengths include 6 random opening plies); network inference measured with the prior loop's generation-19 checkpoint (77×32×32 input) as workload.]
  , kind: table
  ) <tbl:throughput>

Three conclusions followed, each a measured proposal later confirmed by the pilot and frozen in the protocol. Legal-move generation is nowhere near a bottleneck; network evaluation dominates every decision, and the CoreML path decides feasibility: at 2.62 ms per evaluation a 128-simulation decision costs about 0.34 s and a 64-simulation decision about 0.17 s on one thread, whereas the CPU path is about 9× slower. The observed game lengths supported a 300-ply cap, above the observed maximum of 202 yet bounded, with truncation as its own outcome. Lastly, a protocol round trip at 21.7 µs is three to four orders of magnitude below any per-decision cost; since self-play generation lives entirely in Rust and exchanges data with Python through binary shard files, no in-process binding was built.

== Two engine-side fixes recorded before training
<two-engine-side-fixes-recorded-before-training>
Profiling surfaced two defects, each recorded as a finding first and fixed afterwards in the study's own code rather than silently patched.

#strong[CoreML execution provider.] The Rust inference path panicked on the study machine with the message "Unable to compute the prediction using a neural network model", while the Python ONNX package ran the same model on CoreML at 2.62 ms per evaluation (55 of 64 nodes on CoreML, 5 partitions). The message names the cause: the Rust bindings (version 2.0.0-rc.12) default to CoreML's legacy #emph[NeuralNetwork] format, whereas the Python package uses #emph[MLProgram];. Requesting MLProgram, a one-option change, restored CoreML inference, verified on 9 September 2026 with the self-play generator: at 600 full and 150 cheap simulations, 2 games on 2 threads took 44 s (≈44 thread-seconds per game, against ≈320 on the CPU fallback and ≈150 on the prior loop's working path); at the study's eventual 128/32 budget, 8 games on 4 threads took 24 s, about 3 s of wall-clock and 12 thread-seconds per game, which put a 2000-game generation at roughly 1.7 h. The full test suite, the tactical suite (5/5) and the critical corpus (30/30) were green after the change. These probes are feasibility anchors; the pilot re-measured with the study's own networks.

#strong[Truncation is not a draw.] Both prior-work generators capped games at 300 plies and mapped the cap to a draw, and the tree search's internal rollouts capped at 120 plies. Scoring a truncated game as a draw would let the cap manufacture or erase an advantage undetected, so the study's convention, fixed on 9 September 2026 before any measurement code was written, makes truncation a fourth outcome category everywhere: excluded from the primary score, reported as a separate rate, scored 0.5 in a sensitivity check. The prior-work code was left as a recorded finding; the study's record format carries a distinct truncation value in the outcome byte, the arena excludes truncated games from the score and reports the rate, and training excludes truncated records from the value loss. All of this landed with the study's record format on 9--10 September 2026, before the pilot.

With the engine validated, profiled and corrected on these two points, the study-specific pipeline, the opponents and the two encoders were built on top of it; the following chapters describe them.

= The self-play learning pipeline
<sec:pipeline>
Both arms of the comparison are trained and evaluated by one pipeline, built in September 2026 on top of the engine of @sec:engine. It is deliberately ordinary, an AlphaZero-style loop in the sense of Silver et al.~(2018) with the compute-saving devices of Wu (2020), since its only requirement is to be identical for the two arms. The search that generates games, the record that stores them, the loss, the export path, the evaluation arena and the automated checks are all shared; only the state encoder and the network body (@sec:representations) differ between the grid arm and the graph arm. @fig:pipeline gives the overview; the sections below describe each stage, then the pilot of 10 September 2026 that validated the loop end to end, and the one harness defect it caught.

#figure(image("figures/fig8-pipeline.png", width: 90.0%),
  caption: [
    The generation loop shared by both arms. Self-play with Monte-Carlo tree search produces training records; the records train a network; the network is exported to ONNX and drives the next generation's self-play; at fixed generations the exported network is evaluated against the frozen opponent population (B-RND, B-HEU, B-MCTS) on frozen openings. The grid arm and the graph arm differ only in the state encoder and the network body inside the boxes marked "network".
  ]
)
<fig:pipeline>

== The generation loop
<the-generation-loop>
A training run is identified by an arm and a seed. The generation-0 network is a seeded random initialisation, exported to ONNX before any game is played; the base seed of run $s$ is $100 \, 000 times s$, and generation $g$ uses base seed $+ thin g$ for both self-play and training, so no two runs share a random stream. In the configuration under which all study runs executed, a run comprises 10 generations of 500 self-play games each, with four worker threads, on one machine.

Each generation proceeds as in the pseudo-code below. The current network plays the generation's games against itself; the positions searched at the full simulation budget become records, stamped with the generation number and a hash of the generating network. A network is trained on those records, exported, and becomes the current network; a checkpoint is kept at every generation so that the same-wall-clock reading (@sec:protocol) can later select the last checkpoint completed before the equal-time cutoff. Generations are numbered 1 to 10 throughout this report; the run logs and the pseudo-code below count them from 0. After the fifth and the eighth generation, and after the tenth and last, the exported network is evaluated against the frozen opponent population. The driver passes neither a warm-start nor a resume checkpoint to the trainer: the network of generation $g$ is a fresh seeded initialisation trained for two epochs on the records of generation $g$ alone, which were produced by the network of generation $g - 1$ (by the random initialisation when $g = 0$). There is no replay window across generations.

```
run(arm, seed s):
    θ ← seeded random initialisation (base seed 100,000 × s), exported to ONNX
    for g in 0 … 9:
        D_g ← SELF-PLAY(θ, 500 games; seed base + g)
                 128 / 32 simulations, 25 % of decisions at 128 (recorded)
                 Dirichlet root noise ε = 0.25; visit-proportional sampling for 12 plies
                 resign below −0.92 (10 % of games never resign); truncate at 300 plies
        θ ← TRAIN(fresh seeded initialisation, D_g; seed base + g)
                 2 epochs, batch 256, SGD lr 0.02 (cosine), momentum 0.9, wd 1e-4
                 loss = masked policy cross-entropy + 0.6 × value cross-entropy
                 (truncated records excluded from the value term)
        EXPORT(θ) → ONNX, static shapes; checkpoint kept; wall-clock of g logged
        if g ∈ {4, 7} or g = 9:
            EVALUATE(θ) vs B-RND, B-HEU, B-MCTS on the frozen openings
                 400 simulations, no noise, argmax; 20 games/opponent (g ∈ {4, 7}), 100 (g = 9)
```

The seven-check battery of @sec:pipeline-checks is a separate command run against real shards. The pilot driver ran it after every generation's self-play; the campaign driver that executed the frozen matrix did not re-run it per generation, relying on the battery having passed on real shards and on the engine-side tests that run with every build.

== Self-play workers and search settings
<self-play-workers-and-search-settings>
Self-play runs entirely in the Rust engine; the Python side never sits in a per-move loop and receives its data as binary shard files. The search is PUCT Monte-Carlo tree search with exploration constant $c = 1.4$, batched leaf evaluation and exact back-up of terminal values. Four devices, applied identically to both arms, shape the games into training data.

#emph[Playout-cap randomization] (Wu, 2020). Each decision is searched at the full budget of 128 simulations with probability 0.25 and at the cheap budget of 32 simulations otherwise; only the full-budget decisions are recorded. The device trades policy-target quality on a quarter of the moves for many more games per hour, which is what the value head needs. The 128/32 pair was not taken from the research plan: it was measured on the study machine after the CoreML execution provider was restored on 9 September 2026 and confirmed with a study-scale network in the pilot.

#emph[Exploration.] Dirichlet noise with $epsilon = 0.25$ is mixed into the root prior, and for the first 12 plies the move is sampled in proportion to the root visit counts; from ply 12 onward the most-visited move is played. The evaluation path carries $epsilon = 0$ as its code default and no sampling, a separation enforced by test (check 6 below).

#emph[Resignation with audit.] A side resigns when the root value from its perspective falls below $- 0.92$; in 10 % of games, drawn at the start of the game, resignation is disabled so that the threshold can be audited against played-out outcomes.

#emph[Truncation.] A game that reaches 300 plies without a result is truncated. Truncation is a distinct outcome (the fourth value of the outcome byte) and is never recorded as a draw; the cap sits beyond the longest search-guided game observed during engine profiling (202 plies). Generation-0 play from a random initialisation truncates often (56.7 % of games in the pilot), which the separate category absorbs by design and the protocol's cap-sensitivity procedure exists to probe.

== The training record
<the-training-record>
Each recorded position is a fixed-length record of 818 bytes (format version 3), written by the generator and read identically by both arms' data loaders. It stores the position in absolute piece coordinates: 28 pieces × (x, y, level), with a sentinel for pieces in hand. Alongside the position it stores the side to move, the last-moved piece (for the stun rule), the ply, the game-type bits, both sides' queen liberties and reserve counts, and the one-hive-pinned bitmask. Any consumer reconstructs the state, its frame and its candidate set exactly from these bytes, so the grid encoder and the graph encoder derive from the same source.

Three fields were added for this study. A #emph[model stamp] (generation number and network hash) in bytes 100--107 answers, for every shard, which network generated it; the check battery asserts that every record's stamp matches the run manifest. The #emph[legal-move index list] (bytes 178--817, capped at 320 entries; the largest branching measured in real play is 213) enables legal-masked training in both arms without re-running move generation. The #emph[outcome byte] takes four values from the perspective of the side to move: 0 loss, 1 draw, 2 win, 3 truncated. The policy target is the search's root visit distribution over the shared action space, stored as its top-15 entries with the total visit count.

Records of the prior demonstration loop (versions 1 and 2) carry no stamp and no legal list, and their cap games were labelled as draws; they are not training inputs for the study. Every run keeps three separate trees, for self-play records (the training inputs), checkpoints and evaluation outputs; an audit asserts that no evaluation file is ever referenced by a training configuration (check 7).

== The training procedure
<the-training-procedure>
Training is identical for both arms down to the optimiser state: stochastic gradient descent with learning rate 0.02 cosine-annealed to one hundredth of its initial value over the generation, momentum 0.9, weight decay $10^(- 4)$, batch size 256, two epochs per generation, and a value-loss weight of 0.6. One record in fifty is held out as a validation split, on which policy top-1 (masked as in training) and value accuracy (over non-truncated records) are reported after each epoch. No hyperparameter search was performed for either arm.

The loss is the one written out in @eq:loss of @sec:background: the cross-entropy between the recorded visit distribution and the network policy over the legal set, plus 0.6 times the three-way outcome cross-entropy, the value term averaged over the batch's non-truncated records only. The policy distribution $p_theta (dot.op divides s)$ is normalised over exactly the legal set: the grid arm fills the illegal entries of its flat logit tensor with $- 10^9$ before the log-softmax, while the graph arm computes logits only for legal (slot, destination) rows, so the two arms produce the same family of distributions over the same legal sets. The value head is a three-way win/draw/loss classifier; a truncated record contributes to the policy term but is excluded from the value term, never trained as a draw.

Checkpoints carry the model, optimiser and scheduler state, the step and epoch counters, the random-number state and the run configuration; the per-epoch shuffle is re-seeded from the run seed and the epoch index, so a run resumed from an epoch boundary replays the identical batch order (check 5). One change was made to the loop after the main campaign: on 23 September 2026, after an ablation run had diverged to a non-finite loss and self-played on it silently for ten generations, a guard was added that halts training on a non-finite loss; it leaves every finite computation unchanged. Training throughput was benchmarked on 10 September 2026 at 274 positions/s for the grid network and 138 positions/s for the graph network (batch 128, forward and backward, on the machine's GPU backend); the campaign runs loaded their data in-process rather than through worker processes, so their training phases ran at or below these figures. Generation rather than training dominates a generation's wall-clock in either arm.

== Export and inference
<export-and-inference>
After training, the checkpoint is exported to ONNX with static input shapes, one graph per batch size (the campaign exported the batch-1 graph that match play and self-play use). Static shapes are required by the CoreML execution provider; the graph arm obtains them by padding every position to a fixed node capacity and a fixed move capacity with masks. The exported graph then runs inside the Rust search through the same inference path for both arms.

The execution provider is where the two arms genuinely differ in cost, and the difference is reported rather than equalised away (@tbl:inference, measured 10 September 2026). The grid arm's convolutional network runs fastest on CoreML; the graph arm's gather-heavy network is split by CoreML into 15 sub-graphs with 147 of 287 nodes supported, and runs fastest on the CPU provider. Each arm therefore used its best available provider: grid on CoreML at 2.62 ms per evaluation, graph on CPU at 3.67 ms, a ratio of ≈1.4× against the graph arm. The same-wall-clock reading of the protocol charges each arm this true cost on this machine; the same-examples reading is unaffected.

#figure(
  align(center)[#table(
    columns: (41.85%, 29.3%, 28.85%),
    align: (left,right,right,),
    table.header([Execution path], [Grid arm], [Graph arm],),
    table.hline(),
    [PyTorch, CPU], [11.03], [10.51],
    [ONNX Runtime, CPU], [23.5], [#strong[3.67];],
    [ONNX Runtime, CoreML], [#strong[2.62];], [9.84],
    [Provider used in the study], [2.62 (CoreML)], [3.67 (CPU)],
  )]
  , caption: [Inference latency of the two capacity-matched networks (grid 1.44 M parameters, graph 1.47 M) at batch size 1, in milliseconds per network evaluation, measured on the study machine (Apple M1 Pro, 10 cores, 16 GB) on 10 September 2026 across three execution paths; one measurement series per cell, no interval reported. Bold marks the provider each arm used in self-play and evaluation.]
  , kind: table
  ) <tbl:inference>

The CoreML path itself had to be repaired first: on 9 September 2026 the Rust inference layer crashed under CoreML because it requested the provider's legacy model format; requesting the modern format restored it, and a probe at 128/32 simulations with the prior loop's network as workload ran at ≈3 s per game of wall-clock on four threads. This probe is the origin of the "≈3 s/game with a trained network" estimate quoted in the protocol.

== The evaluation arena
<the-evaluation-arena>
Evaluation is independent of training in data, settings and seeds. The arena plays #emph[paired] games: pair $i$ of every match plays opening line $i$ of a frozen file of 250 unique legal four-ply base-game openings, once with each colour, so that every arm, seed and opponent faces an identical opening-and-colour schedule (verified by a test that hashes the schedules). The openings were generated blind by a seeded random walk over the engine's legal moves and frozen on 10 September 2026, before any comparison run, with their content hash recorded. Final evaluations use 100 games per opponent (openings 0--49), intermediate ones 20.

The network under evaluation searches 400 simulations per decision with no Dirichlet noise and no temperature: the most-visited move is played, deterministically. These settings were pinned on 9 September 2026 in a versioned configuration and by a unit test asserting that the search's defaults carry $epsilon = 0$; the match-play interface exposes no way to enable noise, so the evaluation path cannot explore by accident. The visit count is fixed for a reason: Jones (2021) measures a train-time/test-time compute trade-off under which a floating evaluation budget would let measured strength drift. The opponents are invoked exactly as frozen (@sec:baselines), with their own fixed seeds; the network side uses seed 9000 plus the generation index (9500 for the evaluations at the equal-time cutoff). Games are capped at 300 plies; truncations are excluded from the score, reported as a separate rate, and scored 0.5 in a sensitivity line. An evaluation game costs ≈23--32 s at this budget.

Scores are win = 1, draw = 0.5, loss = 0 over non-truncated games, aggregated to one score per (seed, opponent) cell before any statistics are computed; the seed rather than the game is the resampling unit (@sec:protocol).

== Seven automated pre-training checks
<sec:pipeline-checks>
Before any training output was trusted, seven properties of the data path and the training loop were turned into automated assertions and run as one command against real self-play shards (@tbl:checks). They go beyond unit tests of isolated functions: checks 1--3 run on recorded positions through a real forward pass, check 4 is a short experiment with a stated criterion, and checks 5--7 exercise the resume, evaluation and layout contracts end to end.

#figure(
  align(center)[#table(
    columns: (22.47%, 37.89%, 39.65%),
    align: (left,left,left,),
    table.header([Check], [What it asserts], [How it is tested],),
    table.hline(),
    [1 Legal-set normalisation], [The masked policy puts exactly zero probability on illegal actions and sums to one over the legal set], [Real forward pass on recorded positions; illegal mass asserted equal to 0],
    [2 Move-index identity], [Encode → index → decode is the identity on all legal moves across game types; every stored target and played index is legal], [Rust round-trip test; data-side scan of every record's target entries against its legal list],
    [3 Outcome perspective], [The outcome byte is one of four values, correct for the side to move in both colours; truncated records are excluded from the value loss], [Rust sign batteries (evaluation, alpha-beta, search root); data-side comparison of the value loss with its truncation-filtered reference],
    [4 Tiny-batch overfit], [A fixed small batch reaches near-perfect fit], [Policy argmax 15/15, value 15/15, residual KL 0.09 to the soft targets],
    [5 Save and resume], [An interrupted run resumed from a checkpoint reproduces bitwise-identical model and optimiser state and keeps the planned learning-rate schedule], [Two training legs on CPU; every model tensor and optimiser tensor compared for exact equality],
    [6 No exploration at evaluation], [The evaluation path carries ε = 0 and no temperature], [Unit test on the search defaults; settings pinned in a versioned configuration],
    [7 Evaluation never feeds training], [No evaluation game is a training input], [Audit of every training configuration's shard list against the evaluation tree],
  )]
  , caption: [The seven automated pre-training checks, run as one command against real self-play shards before training output was trusted. Each row states the property asserted and the mechanism that asserts it; check 4 is an experiment with a numeric criterion, the others are assertions that pass or fail.]
  , kind: table
  ) <tbl:checks>

Check 4 deserves a note on its criterion. Visit distributions are soft targets with irreducible entropy, so "loss tends to zero" is the wrong test; the criterion is the Kullback--Leibler divergence to the target-entropy floor. The check's first run was reported as a failure for two reasons unrelated to the network: the loss had been compared against zero rather than the floor, and the validation holdout had been included. The criterion was corrected and the correction recorded. On the pilot shard the corrected check gave KL 0.093, policy argmax 15/15, value 15/15.

== The pilot of 10 September 2026
<the-pilot-of-10-september-2026>
The loop was first run end to end at a deliberately small budget: one generation from a seeded random initialisation of the grid network (1.44 M parameters), 300 self-play games at 128/32 simulations with playout-cap randomization, three training epochs (the campaign later used two), batch 256, the masked policy loss, and an independent evaluation against the frozen population under the pinned settings with 30 games per opponent. Self-play started on the evening of 9 September 2026; the evaluation completed on 10 September.

#emph[Generation.] The 300 games yielded 17,237 recorded positions; 170 of 300 games (56.7 %) were truncated at the 300-ply cap and none ended by resignation, since a random-initialisation value head never crosses the threshold. Generation took ≈60 min on four threads, ≈12 s per game: untrained play runs long, whereas the trained-network probe of the previous day measured ≈3 s per game at the same budget, so per-generation cost falls as play sharpens.

#emph[Checks.] All seven passed on the real shard: illegal policy mass exactly 0 and legal mass 1; every stored and played index legal; a valid outcome domain with 12,806 truncated records excluded from the value loss; the overfit result above; save and resume bitwise-identical at step 2110; evaluation noise structurally off; evaluation and training trees disjoint.

#emph[Training.] On 16,893 training and 344 validation records, the losses decreased (policy ≈3.4 nats at the end against ≈4.1 for a uniform distribution over ≈60 legal moves); validation policy top-1 reached 4--5 % against a uniform-legal chance level of ≈1--2 %; validation value accuracy was 42--46 % over the 94 non-truncated validation records; throughput ≈772 positions/s. The value signal is thin at generation 0 because 74 % of records are truncation-masked.

#emph[Evaluation.] @tbl:pilot-eval gives the result. The generation-0 network beat legal-random in every decided game (28 wins, 2 truncations) and scored 3.3 % against both the heuristic and the 6,400-simulation search.

#figure(
  align(center)[#table(
    columns: (39.04%, 19.74%, 18.42%, 22.81%),
    align: (left,right,right,right,),
    table.header([Opponent], [W/D/L], [Score], [Truncated],),
    table.hline(),
    [B-RND (legal-random)], [28/0/0], [100.0 %], [2/30],
    [B-HEU (heuristic)], [0/2/28], [3.3 %], [0/30],
    [B-MCTS (search, 6,400 simulations)], [0/2/28], [3.3 %], [0/30],
  )]
  , caption: [Independent evaluation of the pilot's generation-0 grid network (one training run, 300 self-play games at 128/32 simulations, three epochs) against the three frozen opponents, at 400 simulations per decision without noise, 30 paired colour-swapped games per opponent. Score = wins + ½ draws over non-truncated games, in %; truncations at the 300-ply cap are counted separately. Pilot volume: no interval is reported and this is not a study result.]
  , kind: table
  ) <tbl:pilot-eval>

#emph[What the pilot diagnosed.] The profile (dominance over legal-random, near-total loss to the two mid-band opponents) was interpreted in the mandated order: rules, value signs, search, data. The first three had been validated independently (@sec:engine, @sec:baselines), so the gap after one generation reflects data and iteration rather than a defect; the indicated lever is more generations rather than more capacity, and no capacity change was made. The pilot also supplied the two budget confirmations the protocol freeze was waiting for: 128/32 simulations are feasible at study scale (worst case ≈12 s per game at generation 0, improving toward ≈3 s), and the 300-ply cap is workable precisely because truncation is a separately reported outcome. The protocol was frozen with these values the same day. The pilot's limits are those of its size: one seed, 30 games per opponent, generation 0 only, grid arm only. The iteration of the loop was exercised in structure but was not actually run.

== A harness defect caught during the pilot
<a-harness-defect-caught-during-the-pilot>
The first evaluation pass of the pilot did not produce @tbl:pilot-eval. It returned 0/2/28 against all three opponents, including legal-random, which a network that had learned anything should not lose to. Following the same investigation order, the game records were inspected: the opponents' replies were identical across the three pairings. The interactive shell loop used for that first pass had passed each opponent's command-line flags as a single argument, so every opponent fell back to the engine's default search backend and all three matches had in fact been played against the heuristic. The pilot driver proper, which builds argument lists explicitly, does not have this defect; rerun with explicit arguments, the evaluation produced the coherent table above.

The incident was kept as a worked example rather than discarded, because identical results across supposedly different conditions should be treated as a harness alarm before being read as a finding. The rule proved its worth two weeks later, when three "independent" ablation seeds returned game-count-identical evaluations and the alarm led directly to the silent divergence described in @sec:results-ablations. A second, minor slip of the same pilot, in which the check battery initially invoked a system Python interpreter with a broken deep-learning installation for check 5, was fixed by pinning the project's own environment.

= The two state representations and their networks
<sec:representations>
The study's independent variable is the state representation together with the network body that reads it, and nothing else. This chapter specifies both arms as they were run: encodings, networks, the shared action decoder, capacity matching, the cost asymmetries that were measured rather than removed, the tests that pin each encoder, and the ablation variants. @fig:encodings shows one position under both encodings, @fig:architectures the two networks, and @sec:app-b the layer tables, the decoder arithmetic and the record layout.

The two sides do not have the same history. The grid frame, its planes and the convolutional network were built in July 2026 within the engine project and carried the earlier 19-generation self-play demonstration; on 10 September 2026 they were reused unchanged as the baseline representation, with one hardening of the frame's overflow check. Everything on the graph side (encoding, network, tensor builders in both implementation languages, and their tests) was built on 10 September 2026 for this study, against a decoder contract fixed the day before.

== What varies between the arms, and what provably does not
<what-varies-between-the-arms-and-what-provably-does-not>
Both arms share the rules engine, the search, the frozen opponent population and pinned evaluation settings, the record format, the training targets and outcome conventions (truncation a fourth outcome, excluded from the value loss), the action space with its legal-set normalisation, and the training loop (two epochs per generation, batch 256, learning rate 0.02, value-loss weight 0.6, stochastic gradient descent with momentum 0.9 under a cosine schedule). Neither arm was tuned beyond capacity matching. Each shared element is enforced rather than asserted: one decoder contract with identical masking, one record format, a cross-language golden test per encoder, and one Rust Monte-Carlo tree search evaluating both arms through static-shape ONNX exports. What differs is exactly enumerable: the representation, the network body, and their measured hardware interactions.

=== The shared action decoder
<the-shared-action-decoder>
A Hive move is uniquely identified by (piece, destination cell): a walk and a throw landing the same piece on the same cell produce identical successor states. The decoder addresses the piece by a side-to-move-relative slot: the mover's 14 pieces in roster order, then the opponent's 14 in slots 14--27 (they exist because the Pillbug expansion moves enemy pieces; in the base game they are never legal). It addresses the destination by a cell of the candidate set, every occupied cell plus the ring of empty cells adjacent to the hive, which contains every legal destination by construction. One extra action, pass, is legal exactly when no move exists. The grid arm materialises this space as a flat vector of 28,673 logits indexed by slot × 1024 + y × 32 + x over its 32 × 32 frame, the last index being pass. The graph arm materialises no such vector: for each legal (slot, destination) pair it computes one logit from the embeddings of the destination node, the piece's source and the slot, and scores a pass row the same way. The action a logit refers to is the identical pair in both arms; this is the pointer-network mechanism (Vinyals et al., 2015) of scoring each element of a variable candidate set and normalising over exactly that set.

Four properties are shared verbatim. Masking: logits exist only for the legal set the engine generates, the softmax runs over exactly that set, and probability mass on illegal actions is identically zero; the first of the seven automated pre-training checks asserts this through a real forward pass for whichever arm is under test. Order independence: scores attach to (slot, destination) pairs, never to positions in the legal list. Tiebreak: argmax ties break toward the lowest flat index, the grid indexing defining the tiebreak for both arms. Targets: the root visit distribution of the search over the same space, stored as its top 15 (index, visit weight) entries with the total visit count; the value target is a scalar in \[−1, 1\] from the side to move (win +1, loss −1, draw 0), and truncation contributes no value target in either arm. The contract was fixed on 9 September 2026, before either encoder was built for the study. The rationale is that the confounder is controlled by identity of action space, mask and targets rather than by both arms producing the same tensor; imposing the flat tensor on the graph network would have carried the frame, a grid artefact, into the graph arm.

== The grid encoding
<the-grid-encoding>
=== Frame, anchoring and overflow
<frame-anchoring-and-overflow>
The engine's board is a 64 × 64 wrapping byte grid (a torus) with absolute axial coordinates. For encoding, a position is unwrapped from the torus by breadth-first search from an arbitrary occupied cell (wrapping cannot split the hive, which is connected by rule) and translated so that the centre of the occupied bounding box lands at (16, 16) of a fixed 32 × 32 frame. Hex adjacency on axial coordinates is a 7-cell subset of the 3 × 3 neighbourhood, so ordinary 3 × 3 convolutions cover it, the two non-neighbour corners of each kernel becoming learnable dead weights. Anchoring is by bounding-box centre only: no rotation or reflection canonicalisation, and no symmetry augmentation (see the end of this chapter).

A 28-piece hive spans at most 28 cells per axis after unwrapping, so the occupied box plus the full ring of candidate destinations fits the frame with margin, by construction. The argument is also enforced at run time: the frame constructor carries an always-on assertion, present in release builds, so that any cell mapping outside the frame stops the program loudly and no piece or destination can vanish or alias silently. Until 10 September 2026 this was a debug-only assertion compiled out of release builds, a silent-corruption hazard that the overflow review closed. Extremal tests place all 28 pieces in a straight line along each axis and prove that every occupied and ring cell maps without aliasing; a long random-game drift test covers ordinary play.

=== The 77 feature planes
<the-77-feature-planes>
#figure(
  align(center)[#table(
    columns: (20.09%, 79.91%),
    align: (left,left,),
    table.header([Planes], [Content],),
    table.hline(),
    [0--63], [Piece planes: owner (mover = 0, opponent = offset 32) + bug type (8 types: Q, S, B, G, A, M, L, P) × 4 + min(stack level, 3); owner, type and height are encoded jointly, one plane per combination],
    [64], [One-hive-pinned top pieces (articulation cells of the hive)],
    [65], [Cell of the last-moved piece (stun-relevant state)],
    [66], [Legal placement cells for the side to move],
    [67], [Legal placement cells for the opponent],
    [68], [Side to move is white (constant plane)],
    [69, 70], [Queen liberties (mover, opponent) / 6 (constant planes; 0 if the queen is unplaced)],
    [71], [Ply / 100 (constant plane)],
    [72--74], [Game-type bits M, L, P (constant planes)],
    [75, 76], [Reserve counts (mover, opponent) / 14 (constant planes)],
  )]
  , caption: [The 77 input planes of the grid encoding. Each plane is a 32 × 32 float32 map with values in \[0, 1\]; a "constant" plane broadcasts one scalar over the whole frame. Owner is side-to-move-relative, matching the decoder's slots and the value head's perspective.]
  , kind: table
  ) <tbl:grid-planes>

The joint piece planes record, per cell, who owns the piece at each stack level, what it is and how high it sits, levels 3 and above merged. The placement planes follow the standard adjacency rule (an empty cell adjacent to at least one of the player's top pieces and none of the opponent's) without the opening-turn exceptions; they are hints only, since legality itself is supplied to both arms by the engine's mask. The graph encoder uses the same simplified rule.

=== The grid network
<the-grid-network>
HiveNet is a residual convolutional network in the style of KataGo (Wu, 2020), sized at 96 channels and 8 residual blocks. A 3 × 3 convolutional stem takes the 77 planes to 96 channels (batch normalisation, ReLU); each residual block applies two 3 × 3 convolutions with batch normalisation, a residual addition and a ReLU; blocks 2 and 5 (counting from 0) add a global-pooling bias before the residual addition: the channel-wise mean and maximum over the frame are concatenated, passed through a linear layer and added back per channel. This injects a global signal twice, queen safety being a global property. The policy head is a 1 × 1 convolution to 28 piece-slot planes, flattened to 28,672 spatial logits, plus a pass logit from the mean-pooled features: 28,673 outputs. The value head maps the mean-pooled features through a 64-unit hidden layer to three logits (win, draw, loss from the side to move). The network has 1.44 M parameters, counted by the training code.

== The graph encoding
<the-graph-encoding>
=== Nodes, pieces and destinations
<nodes-pieces-and-destinations>
The graph encoding is coordinate-free: no absolute coordinate appears in it. Its nodes are the cells of the candidate set (every occupied cell and every empty cell adjacent to the hive), which is exactly the decoder's destination universe, so every scorable destination is a first-class node. The choice follows from the rules: Hive's destinations and sliding constraints are properties of empty space, and a graph over occupied cells alone would have nothing to score for most moves. Keller et al.~(2023) reached the analogous conclusion for Hex, whose formulation keeps only empty cells as nodes, and a pointer-style decoder can only point at elements that exist (Vinyals et al., 2015). An explicit occupancy feature distinguishes empty candidates from occupied nodes. Pieces are not separate nodes: since the decoder addresses a move as (slot, destination cell), a piece's identity enters the policy through its slot embedding and its location through the node it stands on; cell nodes carry the full stack composition level by level, so no piece information is lost and the graph stays half the size it would have with piece nodes. This is a documented design choice.

=== Node features, typed relations and global features
<node-features-typed-relations-and-global-features>
#figure(
  align(center)[#table(
    columns: (23.4%, 76.6%),
    align: (left,left,),
    table.header([Features], [Content],),
    table.hline(),
    [0--49], [Five stack levels (0--4), ten features each: present bit, owner-is-mover bit, bug-type one-hot over the 8 types],
    [50], [Stack height / 5],
    [51], [Empty-candidate bit (1 for an empty ring cell)],
    [52], [One-hive-pinned bit (the top piece is an articulation point of the hive)],
    [53], [Last-moved bit (stun-relevant)],
    [54], [Legal-placement bit for the side to move],
    [55], [Legal-placement bit for the opponent],
  )]
  , caption: [The 56 node features of the graph encoding, one vector per candidate-set cell. Stacking is represented level by level up to height 5 (heights above 5 cannot occur in the base game; the height scalar still records them). Owner is side-to-move-relative.]
  , kind: table
  ) <tbl:graph-node-features>

Edges are the directed adjacencies between candidate-set cells, typed by the six hex directions (east, north-east, north-west, west, south-west, south-east), stored as a neighbour-index tensor (per node, the index of its neighbour in each direction, with a sentinel for none) and realised in the network as six relation-specific weight matrices. The reverse of direction d is (d + 3) mod 6, a symmetry the property tests check. Adjacency to cells outside the candidate set is excluded: those cells are empty and not adjacent to the hive, so they cannot influence legality or value.

#figure(
  align(center)[#table(
    columns: (28.7%, 71.3%),
    align: (left,left,),
    table.header([Features], [Content],),
    table.hline(),
    [0], [Side to move is white],
    [1], [Ply / 100],
    [2, 3], [Queen liberties (mover, opponent) / 6; 0 if the queen is unplaced],
    [4--11], [Mover's reserve count per bug type / 3 (8 types)],
    [12--19], [Opponent's reserve count per bug type / 3 (8 types)],
    [20--22], [Game-type bits M, L, P],
  )]
  , caption: [The 23 global features of the graph encoding. The vector is concatenated to every node's input and again to the pooled representation in the value head.]
  , kind: table
  ) <tbl:graph-globals>

Reserves enter per bug type because placement legality and material planning depend on which bugs remain in hand; the grid arm carries the two totals as constant planes and can recover per-type counts from its piece planes, so neither arm receives information the other cannot reconstruct.

=== Fixed capacities and loud overflow
<fixed-capacities-and-loud-overflow>
The tensors have fixed shapes, 224 nodes and 321 move rows (320 legal moves, the record's cap, plus one pass row), and, like the frame, an always-on overflow check: a position exceeding either capacity fails loudly rather than silently. Measured maxima over 300 real self-play records were 67 nodes and 124 legal moves, well under capacity. Fixed shapes keep the ONNX export static, so the graph arm runs under the same Rust search and inference path as the grid arm; dynamic shapes would have forced a different inference route and a per-arm asymmetry where the design must be identical.

=== Coverage of the engine's state, and what the network is not given
<coverage-of-the-engines-state-and-what-the-network-is-not-given>
#figure(
  align(center)[#table(
    columns: (42.6%, 57.4%),
    align: (left,left,),
    table.header([State component (influences legality or outcome)], [Graph element],),
    table.hline(),
    [Piece positions, owners, types], [node stack-level features],
    [Stacking (beetle climbs, buried pieces)], [per-level features and height],
    [Empty candidate destinations], [empty-candidate nodes],
    [Adjacency geometry and directions], [typed edges (6 directions)],
    [One-hive pins], [pinned bit (engine-computed articulation)],
    [Stun state (last-moved piece)], [last-moved bit],
    [Side to move], [mover-relative features and global bit],
    [Queen placement deadline], [ply global and reserve features],
    [Reserves], [per-type global counts],
    [Game type], [global bits],
    [Placement legality regions], [placement bits (engine-derived rule)],
    [Move legality itself], [excluded: supplied per position by the engine through the decoder's legal mask, identically to the grid arm; the network never computes legality],
    [Absolute board coordinates], [excluded: coordinate-free by design, so anchoring questions do not arise],
  )]
  , caption: [Coverage map from the components of the engine's game state to the elements of the graph encoding. The last two rows state what is deliberately absent.]
  , kind: table
  ) <tbl:graph-coverage>

No invariance and no rule is granted for free. The encoding contains no absolute coordinates, but the learned function is not thereby translation- or rotation-invariant: message passing with direction-typed relations is not rotation-invariant, receptive fields are limited by depth (one hop per layer), and no rule of Hive is known to the network; legality arrives from the engine through the mask, for both arms alike. The protocol treats any invariance as a question to be measured rather than presumed, and this chapter asserts none.

=== The graph network
<the-graph-network>
HiveGraphNet begins with a linear layer from each node's 56 features, concatenated with the 23 globals, to 152 channels, masked to real nodes; a zero row at index 224 stands in for absent neighbours. Eight relational message-passing layers follow, each computing

$ h'_i = upright(R e L U)  (h_i + W_(upright(s e l f)) thin h_i + b + sum_(d = 1)^6 W_d thin h_(n_i (d))) $ <eq:relayer>

where $n_i (d)$ is the neighbour of node $i$ in direction $d$ (the zero row when absent), $W_(upright(s e l f))$ carries the bias $b$, and the six $W_d$ are the direction-typed matrices without bias; the output is masked to real nodes. Layers 2 and 5 (counting from 0), that is every third layer, add a global-pooling bias inside the non-linearity: the masked mean and masked maximum over the real nodes are concatenated, passed through a linear layer and added to every node. Message passing alone is limited by depth, whereas queen safety is a global property.

The value head concatenates the masked mean, the masked maximum and the global vector and maps them through a 64-unit hidden layer to the same three win/draw/loss logits as the grid arm. The policy head is the decoder's per-candidate scorer: for each legal (slot, destination) row it concatenates the destination node's embedding, a source embedding and a 32-dimensional slot embedding and maps them through a 128-unit hidden layer to one logit; the source embedding is the piece's standing node for a movement and a learned reserve vector for a placement. The pass row is scored by the same scorer from the pass-slot embedding, the reserve vector and the zero row; it is a learned constant and immaterial, because pass is legal only when no move exists and then wins the softmax alone. Illegal rows are masked before the softmax, which runs over the legal rows in the loss and in the inference evaluator exactly as the grid arm's masked softmax. The network has 1.47 M parameters, +1.5 % relative to the grid network. It is an inductive message-passing encoder in the sense of Hamilton et al.~(2017), extended with relation-specific weights per direction over exact neighbourhoods of degree at most six, which is exactly what the protocol prescribes.

#figure(image("figures/fig9-architectures.png", width: 90.0%),
  caption: [
    Block diagrams of the two networks. Left, HiveNet (grid arm): 3 × 3 convolutional stem, 8 residual blocks of 96 channels with a global-pooling bias in blocks 2 and 5, a flat 28,673-way policy head and a 3-way value head, 1.44 M parameters in total. Right, HiveGraphNet (graph arm): input linear layer to 152 channels, 8 relational message-passing layers with six direction-typed matrices and a global-pooling bias every third layer, a per-candidate policy scorer over destination, source and slot embeddings, and a masked mean‖max value head, 1.47 M parameters in total. Both networks feed the shared action decoder; only the encoder and the body differ.
  ]
)
<fig:architectures>

== Capacity matching and measured cost asymmetries
<capacity-matching-and-measured-cost-asymmetries>
Capacity was matched by sizing the graph network's width and depth (152 channels, 8 layers) to the grid network's parameter count (96 channels, 8 blocks): 1.47 M against 1.44 M, +1.5 %, reported. What could not be matched is the cost of running each network on the study machine, where the two representations interact with the hardware in opposite ways.

#figure(
  align(center)[#table(
    columns: (38.11%, 27.97%, 33.92%),
    align: (left,right,right,),
    table.header([Inference path], [Grid (HiveNet)], [Graph (HiveGraphNet)],),
    table.hline(),
    [PyTorch, CPU], [11.03 ms], [10.51 ms],
    [ONNX inference, CPU provider], [23.5 ms], [3.67 ms],
    [ONNX inference, CoreML provider], [2.62 ms], [9.84 ms],
    [Best available provider], [2.62 ms (CoreML)], [3.67 ms (CPU)],
  )]
  , caption: [Inference cost per position evaluation at batch size 1 for the two networks, measured on 10 September 2026 on the study machine (Apple M1 Pro, 10 cores, 16 GB, macOS 15.3.1). Milliseconds per evaluation; one measurement configuration, no interval.]
  , kind: table
  ) <tbl:inference-cost>

The convolutional network runs fastest on the CoreML accelerator; the graph network runs fastest on the CPU, because under CoreML only 147 of its 287 operators are supported, the gather-heavy operations fall back across 15 partitions, and the accelerator path ends up slower than the CPU path. At each arm's best provider the per-evaluation cost ratio is ≈1.4× against the graph arm. Self-play and evaluation therefore ran each arm on its best provider through the same search.

#figure(
  align(center)[#table(
    columns: (37.14%, 27.91%, 34.95%),
    align: (left,right,right,),
    table.header([Training path], [Grid (HiveNet)], [Graph (HiveGraphNet)],),
    table.hline(),
    [PyTorch, CPU, forward only], [138 pos/s], [478 pos/s],
    [PyTorch, MPS, forward + backward], [274 pos/s], [138 pos/s],
  )]
  , caption: [Training throughput at batch size 128 under matched conditions for the two networks, in positions per second, same machine and date as the inference table. The study trains on the MPS path.]
  , kind: table
  ) <tbl:training-throughput>

Training shows the reverse pattern: on the CPU the graph network is \~3.5× faster per position, on the MPS path used for training \~2× slower, gather and scatter dominating there. Training is a minor share of a generation's wall-clock either way (in the pilot, ≈3.5 min of training against ≈60 min of self-play for a generation-0 generation), so the inference asymmetry drives the campaign-level cost difference. The figures are single-machine and single-configuration, exclude the graph dataloader's Python build cost, and the MPS numbers are a plain forward-and-backward pass without the optimizer step. These asymmetries are reported rather than equalised. They are genuine interactions between a representation and the hardware, and equalising them, whether by throttling the grid arm or by forcing the graph arm onto a slower provider, would manufacture a parity that no user of either representation would experience. The protocol instead reads the comparison twice: under the same-examples reading the asymmetries are irrelevant, both arms playing the same number of games with the same generator settings; under the same-wall-clock reading each arm is charged its true cost on this machine. The campaign-level consequence is reported with the cost results.

== Pinning the encoders: golden and property tests
<pinning-the-encoders-golden-and-property-tests>
Each encoder exists twice, in Rust inside the engine and the search and in Python inside the training loop, and agreement between the two is proven rather than assumed. For the grid arm the Rust encoder and the Python decoder are byte-identical by contract, enforced by a nightly golden crosscheck over 240 positions; after the assertion hardening the crosscheck passed and the interface crate's suite stood at 7/7 including the new extremal tests; any later change must keep it green or be recorded as a finding.

For the graph arm, training builds the tensors in Python from the engine-generated (and themselves crosschecked) records. A property battery over 300 real records passed in full: no information loss (every piece, stack level, reserve count, stun state and turn datum in the record appears in the tensors); capacities respected, with an overflow probe raising loudly; edge symmetry; legal-move tensor validity with every stored target inside the legal list; and zero illegal probability mass through a real forward pass. One builder fix was needed: the empty board at ply 0 has an empty candidate set, and the builder now mirrors the frame's canonical first cell, (16, 16). The Rust builder used at inference mirrors the Python builder (same cell ordering, feature layout, direction order, simplified placement rule and loud overflow), and a golden crosscheck over 160 pseudo-random positions across all 8 game types found 160/160 exactly equal on its first run; it runs nightly beside the plane crosscheck. The graph evaluator inside the search builds tensors and move rows in the search's move order, runs the static-shape export on the CPU provider, applies the softmax over the legal rows and converts the three-way output to P(win) − P(loss), which is the grid evaluator's output contract.

A wiring validation (two epochs on the generation-0 pilot data, one seed) ran at 194 positions per second on MPS, dataloader included, with a validation policy top-1 of 4.7 % and a value accuracy of 40.4 %, the same profile as the grid arm on the identical data (4--5 %, \~43 %); a smoke match of 6 games at 200 simulations against the legal-random opponent gave 2 wins, 0 losses and 4 truncations with no illegal reply. These figures establish only that the wiring is sound; they are not a comparison result.

== The two ablation variants
<the-two-ablation-variants>
#figure(
  align(center)[#table(
    columns: (32.16%, 44.93%, 22.91%),
    align: (left,left,right,),
    table.header([Variant], [Single component changed], [Parameters],),
    table.hline(),
    [Full graph arm (reference)], [none], [1.47 M],
    [Untyped edges ("naive adjacency")], [the six direction-typed matrices replaced by one shared matrix], [0.54 M],
    [No global pooling], [the global-pooling bias removed from every layer], [1.37 M],
  )]
  , caption: [The graph-arm ablation variants. Each differs from the full graph arm in exactly one network component; the encoder, the decoder, the training settings, the budgets, the evaluation settings, the opponents and the openings are identical. Parameters in millions, measured by the training code's parameter counter.]
  , kind: table
  ) <tbl:ablation-variants>

The parameter differences are inherent to the removed components and are reported rather than equalised; widening the untyped network to compensate would change a second component. The naive-adjacency variant is the ablation the research plan called for; it tests the premise, written into the protocol before any run, that a naive adjacency graph may not suffice. The no-global-pooling variant was substituted on 19 September 2026 for the planned augmentation-removal ablation, which had nothing to remove once augmentation was excluded from the full method; it was chosen because the main comparison's mechanism signal (the graph arm's relative strength sat in its value head while its policy stayed locally weak) made the pooled signal the sharpest remaining single-component question. A supplementary two-component variant, untyped edges plus a global gradient-norm clip of 1.0, was approved on 26 September 2026 after the untyped variant proved untrainable at parity settings, diverging to non-finite values in generation 0 in 3 of 3 seeds; its numbers are labelled as a two-component difference wherever they appear and nothing it shows is attributed to edge typing alone. Outcomes are reported with the ablation results.

== Symmetry augmentation: excluded by decision
<symmetry-augmentation-excluded-by-decision>
Neither arm trains with symmetry augmentation, by a decision of 10 September 2026 taken before any comparison run. Exclusion makes the identical-data rule trivially true: implementing the hex symmetries consistently across two representations (rotations and reflections of the frame on one side, permutations of the direction types on the other) is subtle, and an asymmetry there would contaminate the main comparison. It also keeps the secondary symmetry question separable as an additive ablation, and it matches the characterised baseline: the earlier pipeline had documented a 12-fold augmentation as an intention but never implemented it. The frozen protocol never specified augmentation; both arms therefore see each position in whatever orientation the game produced.

== Limits of what this chapter establishes
<limits-of-what-this-chapter-establishes>
This chapter establishes the identity of everything except the representation; it says nothing about the merit of either representation. The cost figures come from one machine in one configuration; another accelerator could reverse the inference asymmetry. The capacity match, to +1.5 %, is a match of parameter counts rather than of compute. The graph arm is one point in a large design space (cell nodes, six direction types, a pooled bias every third layer, a per-candidate scorer), and the study compares one grid network with one graph network at one capacity and budget; nothing here says another graph design would behave the same. Finally, the hex symmetries are neither canonicalised nor augmented in either arm, so any symmetry-related difference between the arms is a property of the learned functions rather than of the encodings.

= The frozen opponent population
<sec:baselines>
== Why a fixed population rather than a rating against moving targets
<why-a-fixed-population-rather-than-a-rating-against-moving-targets>
The primary metric of the study is a mean score against a fixed population of opponents (win = 1, draw = 0.5, loss = 0 over non-truncated games, with truncations reported as their own rate) rather than an Elo rating; the reason is comparability. A rating estimated from games among the agents being trained moves whenever the agents move: a later checkpoint changes the scale against which an earlier one was measured, and two arms trained separately share no scale at all. Go has an external ladder of public networks and Hex a perfect-play anchor, which Wu (2020) and Jones (2021) respectively use to pin their ratings; Hive has neither. A population fixed in advance and shared by both arms, all seeds and both budget readings is the substitute: it makes scores comparable across everything the study varies, and it closes the channel by which an opponent might be adjusted after results are seen. The population was therefore frozen on 9 September 2026, before any training run, and has not been added to, removed from, retuned or re-versioned since. Where tooling prints an Elo-style number in this report, it is descriptive and relative to this population only.

== The three opponents
<the-three-opponents>
All three opponents run on the validated engine, the same rules kernel that generates both arms' training games, over the Universal Hive Protocol; they are fully seeded and reproducible.

#strong[B-RND, legal-random.] A uniform draw over the legal moves of the position. The generator advances per query and is mixed with the position hash, so the agent is deterministic given its seed and the game history. It is the floor of the population and anchors the score scale; any learned or heuristic agent must dominate it.

#strong[B-HEU, documented heuristic.] A greedy one-ply argmax of the engine's handcrafted evaluation, single-threaded, extended by the searcher's quiescence over moves that target the enemy queen. The evaluation is the weighted sum of the features in @tbl:heuristic-weights, in centipawn-like units with positive values favouring the side to move; its negation under player alternation is pinned by an automated test. The weights are the engine's defaults as built in July 2026, inherited unchanged and fixed for the study by a cryptographic hash of the weight file and by a test that fails if any value changes: no tuning occurred while the population was characterised and none can occur afterwards without breaking the suite. Tuning after the results have been seen is therefore ruled out by construction.

#figure(
  align(center)[#table(
    columns: (31.35%, 22.96%, 45.7%),
    align: (left,right,left,),
    table.header([Feature], [Weight(s)], [Rationale],),
    table.hline(),
    [Queen liberties (empty cells around own queen, 0 to 6)], [−2000, −700, −350, −150, −50, 0, +20], [Dominant term: distance to surround is the game's objective; steeply convex as liberties vanish],
    [Enemy piece adjacent to own queen], [−90 each], [Enemy neighbours are permanent surround material],
    [Friendly piece adjacent to own queen], [−20 each], [Own pieces crowd escape cells and can be pinned there],
    [Enemy piece on top of own queen], [−180], [A covered queen cannot flee and the cell counts against it],
    [Piece free to move (per bug: Q, S, B, G, A, M, L, P)], [15, 35, 55, 40, 80, 55, 50, 40], [Mobility approximates material in Hive; the ant is the most valuable mover],
    [Piece pinned or immobile (same order)], [0, 4, 8, 6, 10, 6, 6, 4], [A pinned piece is nearly dead material; small residual for latent value],
    [Piece in hand], [+6 each], [Placement flexibility and tempo],
    [Own pillbug adjacent to own queen], [+40], [Rescue-throw availability; inert in the base game],
  )]
  , caption: [Features and weights of the heuristic opponent. The evaluation is the weighted sum of these terms for the side to move minus the same for the opponent, in centipawn-like units (positive = good for the side to move). Weights are the engine's July 2026 defaults, hash-pinned and test-enforced; the pillbug term belongs to the shared kernel and never fires in the base game used by the study.]
  , kind: table
  ) <tbl:heuristic-weights>

#strong[B-MCTS, search without a network.] PUCT Monte-Carlo tree search on the same engine with uniform priors and the same handcrafted evaluation, squashed through a hyperbolic tangent, as leaf value; no neural network and no exploration noise in match play. Its budget is 6,400 simulations per decision, measured at ≈27 ms per decision on one thread of the study machine; the budget was set from this measurement rather than from the placeholder budgets of the research plan.

== Tactical verification before use
<tactical-verification-before-use>
The search opponent was verified on five tactical positions annotated by hand from the publisher's rules and committed before any run, under the same discipline as the engine-validation corpus of @sec:engine. The positions are a mate in one by a perimeter walk and by a grasshopper jump, each from both colours, and a position in which the only safe move avoids surrounding one's own queen. B-MCTS solved 5 of 5 at 400, 1,600 and 6,400 simulations. Value signs under player alternation are pinned by automated tests at three levels: the evaluation negates exactly when the side to move flips; alpha-beta scores a mate in one above the mate threshold for the mover, whichever colour moves; and the search's root value is strongly positive for the winning mover, whichever colour moves. A piece-ordering slip in the set-up of the tactical cases was itself caught by this procedure (the engine was right and the set-up wrong) and was recorded rather than silently corrected.

== Characterisation
<characterisation>
The three agents were played round-robin on 9 September 2026: 100 paired, colour-swapped games per pairing from common seeded random four-ply openings, with referee-validated moves and a 300-ply cap, truncations excluded from the score and reported separately. The whole characterisation took about ten minutes on the study machine; @tbl:baseline-characterisation gives the results.

#figure(
  align(center)[#table(
    columns: (20.13%, 18.38%, 14.88%, 18.82%, 27.79%),
    align: (left,right,right,right,right,),
    table.header([Pairing (A vs B)], [W/D/L for A], [Score of A], [Truncated], [Elo difference (descriptive)],),
    table.hline(),
    [B-HEU vs B-RND], [100/0/0], [100.0 %], [0/100], [≈+2400],
    [B-MCTS vs B-RND], [99/1/0], [99.5 %], [0/100], [+920 \[+730, +1200\]],
    [B-MCTS vs B-HEU], [23/29/48], [37.5 %], [0/100], [−89 \[−150, −32\]],
  )]
  , caption: [Round-robin characterisation of the three opponents on 9 September 2026, 100 paired colour-swapped games per pairing from common seeded four-ply openings, 300-ply cap; B-HEU at depth 1, B-MCTS at 6,400 simulations per decision. Score = wins + ½ draws over non-truncated games, in %; truncations are counted separately (none occurred). The Elo column is descriptive only: a logistic transform of the score with a normal-approximation 95 % interval that treats games as independent, which the paired design makes slightly conservative; a perfect score has no finite Elo, so the 100--0 result is shown as the approximate value the tooling prints.]
  , kind: table
  ) <tbl:baseline-characterisation>

The heuristic won all 100 games against legal-random; the search won 99 and drew 1; against the heuristic the search scored 23 wins, 29 draws and 48 losses. The last pairing is a score of 37.5 %, −89 Elo with interval \[−150, −32\], which excludes parity; none of the 300 games reached the 300-ply cap, consistent with the game-length profile measured during engine validation. Within this population, legal-random is a clean floor, and the heuristic and the search form a mid band roughly 90 Elo apart with different styles, sharp greedy tactics on one side and sampled search on the other. As for the limits, 100 games per pairing is pilot volume, giving intervals of about ±5 percentage points at scores near 40--60 %; the arena's interval is an unpaired approximation; everything was measured on one machine, and the search's cost figures are machine-specific by design.

One ordering was not expected and is reported as found: the 6,400-simulation search sits #emph[below] the one-ply heuristic. The diagnosis recorded at the time is that uniform priors spread 6,400 simulations thinly over Hive's branching factor of roughly 60 moves, yielding an effectively shallow search, while the heuristic's depth-1 argmax with queen-targeting quiescence is tactically sharp; the tanh-squashed leaf value also saturates on queen-danger positions, flattening the signal the search receives. A diagnostic probe supports this reading: at 25,600 simulations (four times the budget, ≈110 ms per decision) the search scored 9/9/6 = 56.2 % against the heuristic over 24 games, descriptive Elo \[−66, +163\], so the search does scale past the heuristic with budget. The finding is consistent with the Hive literature, where learned engines lose to plain search (de Goede et al., 2022) and strong heuristic minimax is hard to beat (Kampert et al., 2021). No opponent was retuned after this observation: the population went to the freeze exactly as characterised, with the choice between 6,400 simulations (characterised, 27 ms per decision) and 25,600 (near parity, 110 ms per decision, requiring re-characterisation) left to the human.

== The freeze of 9 September 2026
<the-freeze-of-9-september-2026>
The population was presented for freezing with its configurations, the weight file's hash, the characterisation above, the budget sub-choice for the search opponent, and one open question: whether to include the checkpoint promoted by the prior self-play loop of August 2026 as a fourth, "frozen-network" member. The author approved the freeze on 9 September 2026 with the search opponent at 6,400 simulations and the prior checkpoint excluded; the decision log records the approval and the hashes.

The frozen population is exactly the three agents above, B-MCTS at 6,400 simulations, identified by the hash of each configuration file and of the weight file together with the engine code commit at the freeze. From that moment, any touch of any opponent constitutes a new study. Later engine commits touched the record format, the graph arm and the arena's input/output, but no searcher, evaluation weight or search default; the weight-pinning test was green at every commit. The third-party reference engines used for differential testing of the rules (@sec:engine) are not members of the population, and no study result derives from them.

The exclusion of the prior checkpoint was deliberate, proposed before the human decided it. That checkpoint is the nineteenth generation of a loop that ran in August 2026 with 2000 games per generation at 600 full and 150 cheap simulations, gated by 60 games against the incumbent and promoted at 56.7 %. It rests on a single seed and a single architecture, without a controlled compute budget or an opponent population fixed in advance. Three reasons were recorded. Its provenance adds no controlled information and invites misreading: any score against it would look like a comparison with "the old AI". Running it at the time depended on an inference path that was being repaired that very day, which would have coupled a frozen artifact to an unresolved fix. And the three agents already span the floor and a mid band of two distinct styles. The checkpoint is preserved and may appear as descriptive context; it is never a member of the population and no number in this report is measured against it.

Two limits carry forward. The characterisation volume is 100 games per pairing with an unpaired-approximation interval, which is adequate to place the opponents relative to one another but not to support study conclusions; those rest on the seed-level analysis of @sec:protocol. And the five tactical cases, like the engine-validation corpus, have not been reviewed by an external Hive-literate reader.

#part[Part III. Methodology]
= Experimental methodology: a pre-registered, frozen protocol
<sec:protocol>
This chapter states what the comparison fixed in advance, how, when, and above all why. The governing protocol was frozen as version 1.0 on 10 September 2026, before any comparison run and after a pilot had confirmed every measured value in it; it declares any later change a new study, and none was made. Constants, hyperparameters and seeds are tabulated in @sec:app-c; raw per-seed tables and the cutoff checkpoint map in @sec:app-d.

== Why pre-register, and why freeze, at small compute
<sec:protocol-why>
A comparison on one machine with a handful of seeds leaves the experimenter great freedom after the fact: which checkpoint counts as "the" result; which opponents, at what strength; which seeds are reported; whether a game that hits the move cap is a draw, a loss, or nothing; which metric becomes the headline. Each choice, made after the numbers are visible, can manufacture or erase an effect of exactly the size such a study can detect; the garden of forking paths needs no conscious dishonesty. Two further risks are silent retuning of a baseline in view of the test result, and asymmetric attention to the arm one expects to win.

Pre-registration removes these degrees of freedom by one rule: every commitment that could bias an observation is made before the observation exists. Here that meant artifacts frozen under a content hash, each dated and approved by the author, and a protocol that names them and fixes the metric, the budget readings, the resampling unit and what outcome would count against the hypothesis. The protocol states that the hypothesis "is not presumed true" and that "a negative or null result is a publishable outcome of this study; the work does not need to confirm H1 to count". The negative answer eventually obtained was therefore a planned deliverable rather than a failure to be explained away.

Freezing followed a fixed order (@tbl:fixed-timeline): the opponent population (@sec:baselines) and the evaluation search settings on 9 September 2026; the protocol on 10 September 2026, once the pilot had re-measured the budgets and the move cap with the study's own networks, so that the frozen text carries no placeholders; the 250 shared openings and the comparison matrix with its cutoff rule the same day. The first comparison run started on 10 September 2026 at 12:42. Freezing after the pilot was the author's choice: it allowed the budgets to be confirmed on the actual arms and avoided a second freeze, which would have weakened what a freeze means.

The research plan's stop rules also bounded the design: an incorrect engine suspends training, so engine validation (@sec:engine) precedes all training; a budget overrun cuts configurations, never honesty; two weeks without an interpretable result shrink the scope; once the final evaluation set has been consulted the method is no longer adjusted against it. Hence the ablations were declared secondary and cuttable from the outset, and neither arm gained a second architecture when the graph arm underperformed.

== Research questions and the hypothesis
<sec:protocol-rq>
The frozen protocol poses one primary question and one hypothesis, reproduced as frozen.

#strong[RQ-H1.] At comparable training budget, does a graph architecture learn a better policy than a grid architecture for base-game Hive, within an AlphaZero-style self-play pipeline?

#strong[Hypothesis H1.] A simple message-passing graph network, receiving the hive as a graph, reaches a higher mean score against a fixed opponent population than a grid CNN receiving the 32×32 BFS-unwrapped frame, at equal training budget.

The protocol itself gives reasons for not presuming H1. Stacking and above all the #emph[empty] candidate destinations must be represented correctly, and a naive adjacency graph over occupied cells may not suffice, because destinations and sliding constraints are properties of empty space. Prior evidence was also split, with graph networks favouring long-range structure and convolutions local patterns in Hex (Keller et al., 2023).

The rejection rule, written before any comparison run, is quoted verbatim; its section references point to the protocol's own sections on budget readings and on seeds and uncertainty:

#quote(block: true)[
What would reject H1 \[…\]: against the frozen opponent population, under #strong[both] budget readings of §5, the graph arm shows no seed-consistent advantage (no consistent per-seed ordering in its favour), #strong[and] the interval on the score difference --- computed with the resampling unit stated in §6 --- excludes a meaningful graph advantage. That outcome is reported as-is: "at this budget, on this variant, the graph representation did not help."
]

The rule is conjunctive: per-seed ordering #emph[and] interval must both fail to favour the graph arm, so one lucky seed cannot rescue the hypothesis and one unlucky seed cannot reject it. It applies under both budget readings, and it fixes the resampling unit in advance. One limit should be stated plainly: the frozen text says "meaningful" without a numeric threshold. The verdict therefore reports the largest upper bound of all graph−grid intervals, so that a reader can apply any threshold they consider meaningful; the study claims none it did not pre-register.

Two secondary questions follow. RQ-H2 asks whether the comparison changes when the budget is read per example rather than per hour; it is pre-registered in the matrix as the two budget readings. RQ-H3 asks what the graph arm's distinctive components contribute; its ablation specifications were written on 19 September 2026, after the main result was known (@sec:protocol-ablations). The protocol's own time-permitting question, robustness to translation and symmetry, was declared the first thing to drop under schedule pressure, and it was dropped.

== Design: two arms, five seeds, ten generations
<sec:protocol-design>
Only the state encoding and the network body differ between arms (@sec:representations): a residual CNN over the 32×32 BFS-unwrapped, bounding-box-centred frame (1.44 M parameters) against a relational message-passing network over the cell graph (1.47 M, +1.5%). Both share the rules engine, the search, the shared action decoder, the training loop, the budgets and the evaluation harness. Neither received any hyperparameter search.

Each run comprises 10 generations of 500 self-play games. Self-play searches 128 simulations per decision on a random quarter of decisions and 32 on the rest, following the playout-cap randomization of Wu (2020), and only full-budget decisions yield targets. It samples from the visit distribution for 12 plies, resigns below −0.92 with a 10% no-resign audit, and truncates at 300 plies. Each generation trains 2 epochs at batch 256 and learning rate 0.02 with the legal-masked policy loss. A checkpoint is kept and the wall-clock logged at every generation, which makes the second budget reading possible.

These values were measured rather than taken from the plan's starting points of 64 and 128 simulations. Profiling on 9 September 2026 put one network evaluation at 2.62 ms on the accelerated provider, and the pilot of 10 September 2026 confirmed ≈12 s per game at generation 0, falling toward ≈3 s as play sharpens. The 300-ply cap lies beyond the longest search-guided game observed (202 plies). The pilot showed random-initialisation self-play truncating 56.7% of games at that cap, which is tolerable only because truncation is its own reported outcome.

Seeds came in two stages, both disclosed. The matrix pre-registered three seeds per arm (1--3; base seed 100,000 × seed) and noted a five-seed option "if budget allows". The three-seed campaign, approved on 10 September 2026, ran sequentially on one machine, four worker threads per run, under an estimate of ≈4.6 days and a 20 GB free-disk guard. After both readings of the three-seed matrix had been analysed (19 September 2026), the author approved on 26 September 2026 seeds 4 and 5 for both arms under three pre-commitments written before any new run: (a) all five seeds per arm enter the final analysis regardless of the new seeds' direction; (b) the equal-time cutoff stays at its already-computed value; (c) the two-stage collection is disclosed. Seeds added symmetrically under an unchanged rule are a decision about statistical power rather than a tuning channel; the three-seed verdict stays on record.

== The two budget readings and the equal-time cutoff
<sec:protocol-readings>
A network that learns more per example but costs more per example can lose at equal hours, so the protocol mandates two readings of one campaign. The asymmetry is real: the best available provider gives 2.62 ms per evaluation for the grid arm (accelerated) but 3.67 ms for the graph arm (on the CPU, since its gather-heavy operations fall back from the accelerator), and the graph runs took 2.0× the grid training wall-clock (36.7 vs 18.0 h over five seeds; 35.7 vs 18.2 h over the original three pairs). The interaction is reported and charged rather than equalised away.

#strong[Same-examples reading.] Both arms train for 10 generations × 500 games with identical generator settings, hence on the same number of games at the same simulation budget; each run is read at its final checkpoint (generation index 9 in the run logs, which count from 0).

#strong[Same-wall-clock reading.] The cutoff (T\* in tables and figures) was defined by a rule in the pre-registered matrix: the median full-run wall-clock of the three grid runs, every run of both arms then read at its last checkpoint completed at or before it. The rule gives the grid arm its full budget by construction, charges the graph arm its true cost, and is score-free. It was executed on 16 September 2026, with five of six runs complete and the last graph run still training, from grid clocks alone and before any cross-arm number existed: median(18.77, 16.73, 19.07) = 18.77 h. Per-generation clocks count self-play, training and export; evaluation time is excluded for every run alike. The exact median, which is the first grid run's own total, is the operative value. When tables were regenerated for five seeds, the rounded constant briefly excluded that run's last checkpoint at its inclusive boundary; restoring the exact value reproduced the record of 16 September exactly.

Selection is mechanical and its outcome is part of the result (@tbl:d-cutoff): generation indices 9, 9, 8, 9, 9 for the grid runs and 3, 4, 4, 2, 5 for the graph runs. At equal wall-clock the graph arm had completed 3--6 of its ten generations, the grid arm nine or ten. Cutoff checkpoints were evaluated after the campaigns (18 September 2026; 6 October 2026 for the extension) at the same 100-game volume; where the cutoff checkpoint is the final one, the final evaluation is reused.

== Evaluation: frozen population, frozen openings, pinned search
<sec:protocol-eval>
#strong[Opponent population.] The population comprises three opponents, frozen by the author on 9 September 2026 before any training run: B-RND, uniform over the engine's legal moves, seeded; B-HEU, the documented hand-written evaluation played greedily at depth 1, weights pinned by hash and by a test; B-MCTS, search without a network at 6,400 simulations per decision. The prior demonstration loop's checkpoint was excluded: its single-seed, uncontrolled provenance would have invited a reading as "the old AI". The search opponent's 37.5% against the heuristic was diagnosed and deliberately not retuned, since the freeze forbids adjusting an opponent in view of results; no opponent was touched afterwards.

#strong[Openings and pairing.] Games start from 250 unique legal four-ply openings generated blind by a seeded random walk over the engine's legal moves (generator seed 20260910), frozen on 10 September 2026 under their content hash. Pair #emph[i] of every match plays line #emph[i] once with each colour, so every arm, seed, checkpoint and opponent faces an identical opening-and-colour schedule (a harness test showed byte-identical schedules for different agents and match seeds). Final and cutoff evaluations play 100 paired games per opponent (openings 0--49, both colours); intermediate evaluations at generations 4 and 7 play 20 per opponent and serve only the trajectory figures.

#strong[Why 100 games.] The final volume was recalibrated after the first finals: on 16 September 2026 the seed-to-seed spread against the heuristic (0.080--0.190, SD ≈ 0.056) was about twice the per-pairing game noise at 100 games (SE ≈ 0.03), so more games could not materially narrow the seed-level interval. The volume stayed at 100; the only lever is more seeds, which the extension later provided.

#strong[Pinned search.] Every evaluation of a trained network runs 400 simulations per decision, with no Dirichlet root noise (the code default, asserted by a test) and a deterministic best move; these settings were pinned on 9 September 2026 by a versioned configuration and never changed. Fixed visit counts matter because training and test compute trade off (Jones, 2021); a floating evaluation budget would let measured strength drift with the search rather than with the network. The evaluated network is seeded 9000 + generation for in-run evaluations and 9500 for cutoff sets, B-RND 9101 and B-MCTS 9201 (B-HEU is deterministic). Evaluation games never feed back into training; an audit check verifies the separation.

== Statistics and the truncation policy
<sec:protocol-stats>
#strong[Metric and unit.] The primary metric is the mean score against the population (win 1, draw 0.5, loss 0) over the non-truncated games of a (seed, opponent) cell; game-level data are first aggregated to one score per cell, and the seed is the unit of analysis. Games played by one trained network are not independent samples of the #emph[method];: they share that network's weights, and how well a representation learns varies across independent runs far more than across games of one run. Pooling thousands of games from one model yields intervals precise about the wrong thing (Agarwal et al., 2021); no table in this report does so.

#strong[Intervals.] Seed-level means and their 95% intervals are percentile bootstraps with 10,000 resamples over seeds. For the graph−grid contrast the two seed sets are resampled independently: training seeds are not paired across arms, whereas the pairing that does exist (identical openings and colours) is held constant across arms and absorbed within each cell. Every table shows every seed; none reports a best seed. Elo, where printed, is descriptive and relative to this population only.

#strong[Truncation.] A game reaching the 300-ply cap is never a draw: truncations are a fourth outcome category everywhere, and each table carries the truncation rate beside the score. The primary score excludes truncated games; a sensitivity column scores them 0.5; two bounding treatments score every truncated game of the arm under test as a loss and as a win; and the direction of the contrast is reported under all four treatments. The "win" treatment bounds what any larger cap could do, which is why bounds replace a re-run at a larger cap. The policy proved necessary: against the random opponent the graph arm truncated 20--57% of its games where the grid arm truncated 0--1%, and, scored as draws, that pathology would have disappeared into half-points.

== Exclusion criteria and the record
<sec:protocol-exclusions>
A run may be excluded only for a process failure (a crash, corrupted data, or an engine error such as a rules defect exploited by an agent); a bad score is never an exclusion criterion. Across the main campaign, the extension and the ablations, no run failed, was restarted, or was excluded. Two incidents touched the measurement machinery. On 18 September 2026 the match runner was found to drop its records when every game of a match truncated; an audit showed no campaign file affected, and the defect was fixed before the cutoff evaluations ran. On 23 September 2026 the first ablation's three runs, complete without process failure, were found to have diverged to non-finite outputs in generation 0; the divergence was detected because three independently seeded runs returned evaluations identical to the game count. The divergence is reported as the result; the runs are not excluded, but their evaluation tables are not strength measurements. A loud halt on non-finite loss was added to the training loops the same day; healthy runs are unaffected.

== Ablation design
<sec:protocol-ablations>
The ablation rules were fixed before the ablation runs: at most two ablations, each removing exactly one component from the full graph arm to answer one question, at full parity with the reference (seeds 1--3, the same budgets, frozen opponents, openings and pinned evaluation); a capacity change inherent to the removed component is reported, never equalised by changing a second component; and where more than one component differs, no effect is attributed to the graph. A1 replaces the six direction-typed edge matrices by one shared matrix (naive adjacency; 0.54 M parameters, the typed matrices being the component), testing the protocol's own premise. A2 removes the global-pooling bias from every layer (1.37 M). A2 is a substitution: the plan's first ablation removes symmetry augmentation, but the full method was fixed without augmentation on 10 September 2026, because consistent hex-symmetry transforms across two representations risked contaminating the main comparison, so there was nothing to remove. The substitute question was chosen on 19 September 2026 in view of the main result's mechanism signal (the graph arm's relative strength sat in its value head). This is a post-result choice of #emph[question];, disclosed here, under an unchanged analysis. The author approved both ablations at three seeds on 20 September 2026.

A1 proved untrainable at parity, so a supplement A1′ was added and labelled explicitly as two-component: untyped edges plus a global gradient-norm clip of 1.0, the only optimizer change in the study. Approved on 26 September 2026, it answers only the question "what does a #emph[trained] naive-adjacency network score?"; no A1′ number is attributed to edge typing alone.

== Resources actually consumed
<sec:protocol-resources>
All runs executed on one Apple M1 Pro (10 cores, 16 GB, macOS 15.3.1), sequentially, four worker threads per run; no paid compute or data was used. @tbl:campaigns lists the four campaigns; training wall-clock per run sums the per-generation clocks (self-play, training, export), evaluation games excluded. Over the ten main-comparison runs these totals ranged from 16.7 to 19.1 h (grid) and 26.6 to 49.9 h (graph), 273.5 h in all; the three-seed campaign occupied the machine ≈7.4 days, ≈163 h including its cutoff evaluations; an evaluation game at 400 simulations took ≈23--32 s. The first ablation's runs are short (7.61--8.01 h) because a non-finite policy plays short degenerate games.

#figure(
  align(center)[#table(
    columns: (24.45%, 11.01%, 30.62%, 33.92%),
    align: (left,right,left,left,),
    table.header([Campaign], [Runs], [Dates (2026)], [Wall-clock per run],),
    table.hline(),
    [Main comparison, seeds 1--3], [6], [10 Sep 12:42 → 17 Sep 22:31; cutoff evaluations 18 Sep (\~11 h)], [grid 18.77 / 16.73 / 19.07 h; graph 43.07 / 32.71 / 31.28 h],
    [Ablations A1, A2], [6], [20 Sep 14:08 → 27 Sep 17:13], [A1 7.75 / 8.01 / 7.61 h (diverged); A2 39.90 / 47.44 / 32.05 h],
    [Extension, seeds 4--5], [4], [27 Sep → 2 Oct; cutoff evaluations 6 Oct (≈6 h)], [grid 18.23 / 17.19 h; graph 49.86 / 26.57 h],
    [Supplement A1′], [3], [2 Oct → 6 Oct], [23.89 / 30.35 / 27.68 h],
  )]
  , caption: [Compute consumed by the four campaigns on the single study machine (four worker threads per run, runs sequential, no paid compute). Wall-clock per run is the training wall-clock under one accounting for every campaign (per-generation self-play, training and export seconds summed, evaluation games excluded); the first-ablation runs are short because their training had diverged. ]
  , kind: table
  ) <tbl:campaigns>

== What was fixed before the first comparison run, and what came after
<sec:protocol-timeline>
@tbl:fixed-timeline places every commitment relative to the first comparison run; hashes and values are in @sec:app-c, the provenance index in @sec:app-e.

#figure(
  align(center)[#table(
    columns: (29.58%, 13.91%, 27.15%, 29.36%),
    align: (left,left,left,left,),
    table.header([Element], [Fixed on (2026)], [Timing], [Safeguard],),
    table.hline(),
    [Opponent population; prior checkpoint excluded], [9 Sep], [before training], [hashes; never touched],
    [Evaluation search settings], [9 Sep], [before training], [configuration and test],
    [Protocol v1.0, including the rejection rule], [10 Sep], [after the pilot, before the first comparison], [content hash; change = new study],
    [250 shared openings], [10 Sep], [before the first comparison], [generated blind; content hash],
    [Comparison matrix, including the cutoff rule], [10 Sep], [before the first comparison], [rule is score-free],
    [Equal-time cutoff value, 18.77 h], [16 Sep], [mid-campaign, before any cross-arm number], [grid clocks only; exact median],
    [Final evaluation volume, 100 games per opponent], [16 Sep], [after the first finals], [pre-configured value kept],
    [Ablation specifications A1, A2], [19 Sep], [after the main result], [one-component rule; choice disclosed],
    [Seeds 4--5], [26 Sep], [after the three-seed analysis], [three written pre-commitments],
    [Supplement A1′], [26 Sep], [after A1's divergence], [labelled two-component],
  )]
  , caption: [Chronology of the study's commitments relative to the first comparison run (10 September 2026, 12:42). Rows one to five preceded any comparison number; the later rows were added afterwards under the safeguard stated. ]
  , kind: table
  ) <tbl:fixed-timeline>

== Question → experiment → result matrix
<sec:protocol-matrix>
#figure(
  align(center)[#table(
    columns: (26.87%, 24.23%, 48.9%),
    align: (left,left,left,),
    table.header([Question], [Experiment], [Result and where],),
    table.hline(),
    [RQ-H1 (representation): does the graph arm learn a better policy than the grid arm at comparable budget?], [Grid vs graph, 5 seeds per arm, frozen population and openings, read at the same examples and at the equal-time cutoff], [Score and uncertainty per seed and opponent; graph−grid contrast with seed-level bootstrap intervals; verdict under the frozen rule (@sec:results-main; raw tables in @sec:app-d)],
    [RQ-H2 (efficiency): does the answer change per example versus per hour?], [The same campaign read at the final checkpoints, then at the cutoff checkpoints], [Score-versus-training-time curves and the score/cost table (@sec:results-cost)],
    [RQ-H3 (components): what do the graph arm's distinctive components contribute?], [One component removed at a time at full parity, 3 seeds each (A1 edge typing; A2 global pooling), plus the labelled two-component supplement A1′], [Ablation table: per-seed scores, truncation rates, seed-level intervals against the full graph arm (@sec:results-ablations)],
  )]
  , caption: [The study's three questions, the experiment that addresses each, and the form and location of its result. RQ-H1 is the pre-registered primary question; RQ-H2 and RQ-H3 are secondary. ]
  , kind: table
  ) <tbl:rq-matrix>

= Working methodology: gated human--AI research
<sec:working-method>
This chapter describes how the study was conducted, as a collaboration between one human researcher and an AI assistant under written operating rules that reserve every irreversible or scientific decision to the human, and why that arrangement was chosen. It is the expanded form of the AI-assistance statement in the front matter; the identifiers behind every statement made here are listed in @sec:app-e.

== Why a gated method
<why-a-gated-method>
The study was carried out by a single researcher with limited time and a single laptop (Apple M1 Pro, 10 cores, 16 GB) as its only compute. An AI coding assistant multiplies throughput under those constraints but introduces a specific hazard: generated text and code fail #emph[plausibly];, in that they look right at exactly the places nobody checks, and an assistant has no persistent memory worth trusting between working sessions. A study produced this way can accumulate fluent but untraceable claims. The response was to make research quality a property of #strong[process artifacts] rather than of memory or trust: a journal entry for every measurement, frozen documents identified by cryptographic hash, a register pairing every claim with its evidence and its limit, and an append-only decision log in which a reversed decision is never edited but superseded by an entry that links back. Working sessions are stateless; each rebuilds its understanding from these files, so a crashed session loses nothing.

Three further choices follow. The assistant is routed by #emph[goals];: the plan defines end states, each phase is an executable document with ordered tasks, acceptance checks and exit criteria, and the assistant optimises for "the phase's evidence exists" rather than "the requested edit was made". The irreversible categories of action are enumerated as #strong[gates] and reserved for the human, keeping the assistant's autonomy where mistakes are cheap and reversible. And commitments precede the observations that could bias them (annotations before engine output, behavioural pins before code changes, measurements before budgets), while the assistant's substantial outputs, the operating documents included, pass through verification passes prompted to #emph[refute] them. Report sections are written while the work happens, because a report assembled afterwards turns memory into narrative.

== Division of labour
<division-of-labour>
#strong[The human is the principal investigator.] He owns the research questions, every scientific commitment (protocol, population and opening freezes), every expenditure of compute, everything that leaves the machine, and the final word on every claim. The scientific responsibility for this report is his alone and cannot be delegated.

#strong[The AI assistant executes the plan.] The assistant is Claude (Anthropic), operating as Claude Code sessions. Given the plan and the state files, it plans, implements, tests, measures, journals and drafts toward the plan's end state; sessions start from an intent ("continue", or a phase name) rather than from a task list. It implemented the encoders, the graph network, the training pipeline, the baselines and the evaluation harness inside the perimeter each phase document fixes; pinned existing behaviour before changing it; profiled before proposing budgets and piloted before campaigns; journaled every experiment with hypothesis, commit, configuration, seeds, data version, hardware, duration, cost, metrics, failures and interpretation; and drafted the report as it went. Its own decisions are logged with the same discipline, and several are explicit #emph[proposals] that became binding only through the author's approval at a gate; the proposal to exclude the prior demonstration checkpoint from the opponent population is one example.

What the assistant never decides is listed in the operating rules: it never crosses a gate (no freezing, spending, publishing, contacting or destroying without a recorded human decision); never writes an oracle after seeing model output, because that contamination is irreversible; never produces an untraceable number; never touches a frozen artifact, since any post-freeze change is by definition a new study; and never makes a claim without a row in the claims register.

== The six gates
<the-six-gates>
The boundary is drawn mechanically rather than left to judgement. #strong[G-FREEZE];: freezing a protocol, split or test set, and any later touch of a frozen artifact. #strong[G-SPEND];: paid calls, purchases, budget caps, starting or restarting long compute jobs. #strong[G-PUBLIC];: anything leaving the machine (pushes, licence choices, publication). #strong[G-RIGHTS];: reuse of material whose ownership is not established. #strong[G-ADMIN];: institutional contact. #strong[G-DESTRUCTIVE];: deleting data, models or results, overwriting raw results, killing running jobs. At a gate the assistant records the pending request, parks that phase and routes to other work; a phase document saying "do X" is never authorisation to cross. @tbl:gates lists every gate decision the author took and summarises the basis of each; the decision log holds the author's approvals in their original wording.

#figure(
  align(center)[#table(
    columns: (15.45%, 18.76%, 28.48%, 37.31%),
    align: (left,left,left,left,),
    table.header([Date], [Gate], [Decision], [Basis and conditions recorded],),
    table.hline(),
    [2026-09-09], [G-PUBLIC], [Licence chosen (MIT, copyright 2026); remotes created, kept #strong[private] until the research is finished], [Decided on the author's written instruction; the remotes to become public only through a further decision at this gate, once the research is finished],
    [2026-09-09], [G-SPEND / G-DESTRUCTIVE], [Prior self-play loop permanently stopped; never restarted], [Decided on the author's written instruction; the loop's checkpoint preserved in the research copy; no restart permitted without a new decision],
    [2026-09-09], [G-FREEZE (review)], [Protocol freeze deferred until the pilots had re-measured the proposed budgets with the study's own networks], [Decided on a draft carrying measured values labelled as proposals; the freeze scheduled after the pilots so that it would consume confirmed values rather than proposals],
    [2026-09-09], [G-FREEZE], [Opponent population frozen: legal-random, heuristic, search at 6,400 simulations; prior checkpoint excluded; hashes and engine commit recorded], [Approved after the characterisation round-robin; the search opponent fixed at 6,400 simulations; the prior checkpoint excluded; configuration and weight hashes and the engine commit recorded],
    [2026-09-10], [G-FREEZE], [Protocol frozen as version 1.0, hash and commit recorded, no placeholders], [Approved on the pilot's measured values; protocol hash and commit recorded; no placeholder left],
    [2026-09-10], [G-DESTRUCTIVE], [Pre-study workspace archive deleted by the author directly; the research copy became the sole copy of the prior work], [Carried out by the author himself; the research copy declared the sole copy of the prior work, its pre-study files placed under the destructive-action gate],
    [2026-09-10], [G-FREEZE], [250 shared 4-ply openings frozen, generated blind from a documented seed], [Approved on a file generated blind with nothing tunable; content and file hashes and the generator seed recorded],
    [2026-09-10], [G-SPEND], [Main campaign: 2 arms × 3 seeds, 10 generations × 500 games, ≈4.6 days estimated], [Approved at the full sizing among the options presented from measured per-game costs; runs sequential and resumable; raw results never overwritten],
    [2026-09-20], [G-SPEND], [Ablation campaign: A1 and A2, 3 seeds each at full parity, ≈9 days estimated], [Approved at full three-seed parity with the main comparison, among the sizings presented from measured graph-arm run costs],
    [2026-09-26], [G-SPEND], [Supplementary two-component A1′ run at a corrected ≈4-day sizing], [Approved at a corrected sizing of about four days, after the initial estimate had been revised; queued after the extension; its results confined to a labelled two-component supplement],
    [2026-09-26], [G-SPEND], [Main comparison extended to 5 seeds per arm, ≈4.8 days, under three pre-commitments stated before any new run], [Approved with three written pre-commitments (all-seeds analysis, cutoff unchanged, two-stage collection disclosed); seeds added symmetrically to both arms under identical settings],
  )]
  , caption: [Gate decisions taken by the author during the study, in the order recorded in the decision log. G-RIGHTS and G-ADMIN were not crossed; nothing has left the machine, so G-PUBLIC remains open for diffusion. ]
  , kind: table
  ) <tbl:gates>

Two entries deserve more comment than the table gives. The deferral of 9 September shows a gate working against haste: offered a protocol with measured values, the author waited for pilot confirmation so that the freeze would consume confirmed numbers rather than proposals. The 5-seed extension shows a post-hoc power decision kept from becoming a tuning channel: before any new run it was recorded that (a) the final analysis would use all five seeds per arm regardless of the new seeds' direction, (b) the equal-time cutoff would stay at the value computed on 16 September, never recomputed after seeing results, and (c) the report would disclose that seeds 4--5 were collected after the 3-seed analysis. The results chapters honour all three. The scope of this report was itself an authorial decision, recorded on 9 October 2026 with the constraint that no frozen artifact, number or claim could change.

== Scientific principles enforced in every phase
<scientific-principles-enforced-in-every-phase>
Beyond the gates, the operating rules bind every phase regardless of who executes it.

+ #strong[Oracles before model output.] Test positions and benchmark cases are annotated before any engine or model sees them; afterwards an unbiased expectation can no longer be written.
+ #strong[Characterise before changing.] Existing behaviour is pinned with tests before modification; a failing pin is recorded as a finding rather than fixed silently.
+ #strong[Everything is journaled];: identifier, date, hypothesis, commit, configuration, seed, data version, hardware, duration, cost, metrics, artifact paths, failures, interpretation.
+ #strong[No untraceable numbers.] Every figure links to a journal entry or raw result; numbers inherited from the plan are labelled planning proposals until measured.
+ #strong[Negative results are kept] and reported alongside the best runs.
+ #strong[Fair baselines.] Compared methods receive the same model, budget and attempt count; a strawman baseline invalidates a study.
+ #strong[Truncation is not a draw.] A game stopped at the move cap is a separate outcome, reported separately and sensitivity-tested.
+ #strong[Multi-seed honesty.] No conclusion rests on one seed; per-seed results and uncertainty are reported, with the seed as the unit of resampling.
+ #strong[Prior work is read-only.] Pre-study material is never edited in place; imports carry a provenance note; unclear rights go to G-RIGHTS.
+ #strong[A claims register.] Every claim has a row (claim, evidence, section, limit) or it does not appear.
+ #strong[Write as you go.] A phase is not closed until its report section exists: protocol before experiments, method during implementation, results only from frozen raw tables.

== What the discipline caught
<what-the-discipline-caught>
The operating rules require an append-only log of every incident in which the method caught something, missed something, changed an outcome through a gate, or cost real overhead; entries are never forced. @tbl:incidents assembles those entries with incidents recorded in the experiment journals.

#figure(
  align(center)[#table(
    columns: (15.04%, 32.3%, 27.88%, 24.78%),
    align: (left,left,left,left,),
    table.header([Date], [Incident], [How it was caught], [Consequence],),
    table.hline(),
    [2026-09-09], [First draft of the phase documents held 33 defects, including a validation↔freeze deadlock and two unexecutable tasks], [refutation-prompted verification pass], [28 fixes, re-verified clean before any research ran],
    [2026-09-09], [A hand-annotated critical position disagreed with the engine], [expectations committed before the run], [resolved #emph[against] the corpus (One-Hive transit case); record kept],
    [2026-09-09], [Prior self-play generators mapped the 300-ply cap to a draw], [truncation principle applied retroactively at review], [fixed before the pipeline phase; truncation a separate outcome everywhere],
    [2026-09-09], [Python--Rust boundary about to become a preference debate], [measurement first: 21.7 µs per round-trip against ≥40 ms per decision], [no in-process binding built],
    [2026-09-09], [Setup slip (piece ordering) in the tactical test set], [five cases hand-annotated and committed before being run], [engine right, setup wrong; journaled],
    [2026-09-09], [Search opponent scored only 37.5% against the heuristic; a 4× budget probe reached 56.2%], [diagnosed at characterisation], [deliberately #strong[not] retuned: the population freeze forbids post-hoc tuning],
    [2026-09-09], [Two concurrent working sessions allocated the same decision identifier (#strong[missed] at the time)], [later cross-check], [entry renumbered; single-writer rule for shared state files],
    [2026-09-09], [Overhead: the operating documents consumed a full working session (≈1M agent tokens, 17 subagents) before any research work], [none], [front-loaded fixed cost, accepted],
    [2026-09-10], [First pilot evaluation returned identical 0/2/28 against all three opponents, legal-random included], [identical-results alarm; diagnosis order rules → signs → search → data], [a shell loop had passed each opponent's flags as one argument: every match was against the heuristic; rerun],
    [2026-09-18], [Reproducing an all-truncated pair for a failure figure returned no records], [every selected position must be reproduced and verified against its record], [latent record-loss path fixed; audit: no campaign evaluation affected],
    [2026-09-23], [All three A1 ablation seeds returned game-count-identical evaluations], [the same identical-results alarm], [training had diverged to NaN at generation 0 and self-played on NaN for nine more generations; non-finite guards added; divergence kept as the finding],
    [2026-10-09], [Regenerated equal-time checkpoint map for seeds 1--3 differed from the journaled original], [regenerated outputs checked against the journal before use], [a rounded cutoff constant had broken an inclusive boundary; fixed, original reproduced exactly],
    [2026-10-09], [Generated arm-contrast caption still read "3 per arm" under 5-seed numbers], [page-by-page render pass], [generator derives the seed count and rewrites the file whole; every number byte-identical],
    [2026-10-09], [Stale seed counts in two chapters; stale "pending" limits in the claims register], [placeholder sweep before assembly], [fixed in both languages together],
    [2026-10-09], [Cost-table generator divided five runs' wall-clock by 3 (printing 30.0 h / 61.2 h for 18.0 h / 36.7 h) and carried a training-throughput row (≈770 / ≈195 pos/s) measured under pilot conditions but presented as campaign throughput], [every number re-derived from its raw source with an explicit definition while writing this report], [generator fixed (journaled benchmark 274 / 138 pos/s at batch 128, conditions stated); no score, interval or claim affected; per-paragraph source citations and a token-level traceability checker now gate the report],
    [2026-10-09], [The capacity difference "+2.1%" quoted in every document was the ratio of the rounded parameter counts (1.47/1.44 M); the exact counts give +1.5%], [layer-by-layer tabulation of the architectures recounted the parameters from the code], [corrected everywhere except the append-only journals; exact counts now a generated results artifact; no verdict depends on it],
  )]
  , caption: [Incidents recorded by the methodology log and the experiment journals during the study: what happened, which rule or check caught it, and what followed. ]
  , kind: table
  ) <tbl:incidents>

None of these catches required insight; each came from a mechanical check. One alarm (independent conditions cannot agree to the game count) found a harness defect in the pilot and a silent numerical divergence in an ablation; one rule (commit the expectation, then run) found an annotation error and a setup error on the same day; the reproduce-and-verify step behind a figure found a record-loss path before the equal-time evaluations (where early graph checkpoints genuinely can truncate every game) would have tripped it. Two entries are #emph[gate effects];: the population freeze visibly prevented a results-flattering retuning of the search opponent, and measure-before-commit dissolved an architecture argument with one number. At this scale, harness error was a larger threat than statistical noise, and only mechanical verification found it; the claims register carries this as a process observation from one study, whose stated limit is that no counterfactual exists for what an ungated workflow would have caught.

The cost side is recorded with the same honesty: the method's fixed cost was front-loaded, and the "missed" entry shows the first failure mode of multi-session operation: shared state files need write discipline as well as read discipline. The method did not prevent errors in drafts; it surfaced them before this version through translation passes, numeric identity checks between the two language versions, page renders and adversarial re-reads. A check comparing two languages cannot, however, see a staleness shared by both. The last incident sharpened the standard: a number present in a file is not thereby provenanced; the file must itself derive it from raw data under a stated definition, which is why every paragraph of this report carries a source citation that is checked mechanically.

== What the assistant did not do, and the author's responsibility
<what-the-assistant-did-not-do-and-the-authors-responsibility>
The assistant chose no hypothesis, froze nothing, spent nothing, published nothing, deleted nothing, and decided no claim; it wrote no test expectation after seeing engine output and did not recompute the equal-time cutoff after results were known. The limits of the arrangement are recorded too: the assistant can misread the plan, and the phase documents are its interpretation (the decision log records where reality corrected them); adversarial self-verification remains self-verification at the level of the programme, so the external human review of a subset of annotations and of the report, foreseen in the plan, is not replaced by it; and the assistant's training data may overlap the public Hive literature, so no claim of the form "unseen by the model" is made anywhere in this report.

#strong[AI-assistance declaration.] Implementation, experiment execution, journaling and drafting for this study were carried out with substantial assistance from an AI coding agent (Claude Code, Anthropic), operating under the gated methodology described in this chapter. Every scientific decision, every frozen commitment and every expenditure was made by the author at a gate, as recorded in @tbl:gates; every claim was made or verified by the author, who has personally checked the conclusions he signs and takes full responsibility for the results. The exact wording of this declaration will follow the rules of any venue at diffusion time.

#part[Part IV. Results]
= Results: the main comparison (RQ-H1)
<sec:results-main>
This chapter reports the pre-registered comparison exactly as the frozen protocol defined it: two arms, five independent seeds each, evaluated against the frozen three-opponent population on the 250 frozen openings, under two budget readings. Every table shows every seed. Scores exclude truncated games, which are reported in their own column; intervals are 95% percentile bootstrap intervals over seeds (10,000 resamples). The statistical procedures and the raw tables with all auxiliary columns are in @sec:app-d; the provenance of every number is in @sec:app-e.

== The verdict in one paragraph
<the-verdict-in-one-paragraph>
Under both budget readings, the graph arm shows no seed-consistent advantage against any opponent, and every interval on the graph−grid score difference excludes a meaningful graph advantage: the largest upper bound across the six contrasts is +0.028. The pre-registered rejection rule therefore fires, and #strong[H1 is rejected];. At this budget, on base-game Hive, the graph representation did not help: it scored lower against two of the three frozen opponents under both readings, and no better against the third. The remainder of the chapter shows the evidence behind this paragraph, seed by seed.

== Reading 1: equal number of training examples
<reading-1-equal-number-of-training-examples>
In the first reading both arms are compared at their generation-10 checkpoints: each run has then generated and trained on ten generations of 500 self-play games under identical simulation budgets, so the two arms have consumed the same number of training examples.

#figure(
  align(center)[#table(
    columns: (15.5%, 12.66%, 16.59%, 20.96%, 16.59%, 17.69%),
    align: (left,left,right,right,right,right,),
    table.header([Arm], [Seed], [B-RND score], [B-RND truncation], [B-HEU score], [B-MCTS score],),
    table.hline(),
    [grid], [1], [0.995], [0%], [0.150], [0.125],
    [grid], [2], [0.975], [1%], [0.080], [0.125],
    [grid], [3], [0.990], [1%], [0.190], [0.075],
    [grid], [4], [0.949], [11%], [0.105], [0.085],
    [grid], [5], [0.995], [0%], [0.120], [0.210],
    [graph], [1], [0.733], [57%], [0.025], [0.115],
    [graph], [2], [0.981], [20%], [0.050], [0.125],
    [graph], [3], [0.722], [55%], [0.090], [0.100],
    [graph], [4], [0.688], [44%], [0.125], [0.120],
    [graph], [5], [0.935], [23%], [0.035], [0.115],
  )]
  , caption: [Same-examples reading. Final-checkpoint (generation 10) score of every run against each frozen opponent; 100 paired colour-swapped games per opponent per run on the 250 frozen openings at 400 simulations per move without exploration noise. Score = mean over decided games (win 1, draw 0.5, loss 0). Truncation = share of the 100 games stopped at the 300-ply cap; no game against B-HEU or B-MCTS was truncated by either arm. ]
  , kind: table
  ) <tbl:same-examples>

Against the legal-random opponent every grid seed scores at least 0.949 while graph seeds range from 0.688 to 0.981; against the heuristic, grid seeds range from 0.080 to 0.190 and graph seeds from 0.025 to 0.125; against the search opponent the two arms overlap (0.075--0.210 against 0.100--0.125). The graph arm truncates 20--57% of its games against the random opponent; the grid arm 0--11%.

#figure(
  align(center)[#table(
    columns: (16.81%, 27.65%, 27.65%, 27.88%),
    align: (left,left,left,left,),
    table.header([Arm], [vs B-RND], [vs B-HEU], [vs B-MCTS],),
    table.hline(),
    [grid], [0.981 \[0.964, 0.994\]], [0.129 \[0.098, 0.165\]], [0.124 \[0.087, 0.168\]],
    [graph], [0.812 \[0.710, 0.920\]], [0.065 \[0.034, 0.100\]], [0.115 \[0.107, 0.121\]],
  )]
  , caption: [Same-examples reading. Seed-level mean score per arm and opponent with the 95% bootstrap interval over the five seeds. ]
  , kind: table
  ) <tbl:same-examples-means>

== Reading 2: equal wall-clock on the same machine
<reading-2-equal-wall-clock-on-the-same-machine>
In the second reading each run is taken at the last checkpoint it had completed within the equal-time cutoff of 18.77 hours, the median total wall-clock of the three original grid runs, computed on 16 September 2026 before any cross-arm comparison. Because the graph arm's generations are roughly twice as expensive on this machine, the cutoff selects generation 9 or 10 for the grid runs (the generation-10 checkpoint is reached within the cutoff by four of the five) and generations 3 to 6 for the graph runs: grid seeds 1--5 are read at generations 10, 10, 9, 10 and 10; graph seeds 1--5 at generations 4, 5, 5, 3 and 6 (counting the initial network as generation 1; in the run logs these checkpoints are labelled gen009/gen009/gen008/gen009/gen009 and gen003/gen004/gen004/gen002/gen005).

#figure(
  align(center)[#table(
    columns: (15.5%, 12.66%, 16.59%, 20.96%, 16.59%, 17.69%),
    align: (left,left,right,right,right,right,),
    table.header([Arm], [Seed], [B-RND score], [B-RND truncation], [B-HEU score], [B-MCTS score],),
    table.hline(),
    [grid], [1], [0.995], [0%], [0.150], [0.125],
    [grid], [2], [0.975], [1%], [0.080], [0.125],
    [grid], [3], [0.939], [1%], [0.145], [0.080],
    [grid], [4], [0.949], [11%], [0.105], [0.085],
    [grid], [5], [0.995], [0%], [0.120], [0.210],
    [graph], [1], [0.798], [58%], [0.045], [0.075],
    [graph], [2], [0.926], [39%], [0.055], [0.110],
    [graph], [3], [0.713], [53%], [0.060], [0.105],
    [graph], [4], [0.631], [39%], [0.100], [0.150],
    [graph], [5], [0.980], [24%], [0.045], [0.095],
  )]
  , caption: [Same-wall-clock reading. Score of every run at its last checkpoint completed within the 18.77-hour cutoff, against each frozen opponent; same evaluation as @tbl:same-examples (100 paired games per opponent, 250 frozen openings, 400 simulations, no noise). Truncation = share of games at the 300-ply cap; none against B-HEU or B-MCTS. ]
  , kind: table
  ) <tbl:same-wallclock>

#figure(
  align(center)[#table(
    columns: (16.81%, 27.65%, 27.65%, 27.88%),
    align: (left,left,left,left,),
    table.header([Arm], [vs B-RND], [vs B-HEU], [vs B-MCTS],),
    table.hline(),
    [grid], [0.971 \[0.950, 0.991\]], [0.120 \[0.098, 0.142\]], [0.125 \[0.090, 0.168\]],
    [graph], [0.810 \[0.697, 0.922\]], [0.061 \[0.047, 0.081\]], [0.107 \[0.087, 0.130\]],
  )]
  , caption: [Same-wall-clock reading. Seed-level mean score per arm and opponent with the 95% bootstrap interval over the five seeds. ]
  , kind: table
  ) <tbl:same-wallclock-means>

The picture of the first reading persists at equal time: the grid arm's means are higher against the random and the heuristic opponents and overlapping against the search opponent; the graph arm's truncation against the random opponent is 24--58%.

== The arm contrast
<the-arm-contrast>
#figure(
  align(center)[#table(
    columns: (31.06%, 33.26%, 35.68%),
    align: (left,right,right,),
    table.header([Opponent], [Same-examples: graph − grid], [Same-wall-clock: graph − grid],),
    table.hline(),
    [B-RND (legal-random)], [−0.169 \[−0.272, −0.062\]], [−0.161 \[−0.278, −0.048\]],
    [B-HEU (heuristic)], [−0.064 \[−0.111, −0.017\]], [−0.059 \[−0.087, −0.029\]],
    [B-MCTS (search, 6,400 simulations)], [−0.009 \[−0.055, +0.028\]], [−0.018 \[−0.066, +0.025\]],
  )]
  , caption: [The pre-registered contrast, the difference of seed-level mean scores (graph arm minus grid arm), with the 95% bootstrap interval over seeds (five independent seeds per arm, resampled independently, 10,000 resamples). A negative value favours the grid arm. ]
  , kind: table
  ) <tbl:contrast>

Four of the six contrasts exclude zero, all in the grid arm's favour; the two contrasts against the search opponent straddle zero.

Against the legal-random opponent the graph−grid difference is −0.169 \[−0.272, −0.062\] at equal examples and −0.161 \[−0.278, −0.048\] at equal time; against the heuristic, −0.064 \[−0.111, −0.017\] and −0.059 \[−0.087, −0.029\]; against the search opponent, −0.009 \[−0.055, +0.028\] and −0.018 \[−0.066, +0.025\]. The largest upper bound of any interval is +0.028, which is the largest graph advantage the data leave room for under the most favourable reading and opponent.

The frozen rejection rule required, under both readings, the absence of a seed-consistent graph advantage together with intervals excluding a meaningful graph advantage. Both conditions hold: no opponent shows a consistent per-seed ordering in the graph arm's favour (@tbl:same-examples, @tbl:same-wallclock), and no interval admits an advantage above +0.028. H1 is rejected. The result is consistent across seeds and holds under the two budget equalisations; it does not rest on a single interval.

Five seeds per arm bound the statistics: against the search opponent, where both arms score around 0.1, the data cannot distinguish the arms. The rejection concerns this simple relational message-passing network at this capacity and this budget; it says nothing about graph representations at larger budgets or with other architectures.

== How the five-seed analysis relates to the three-seed analysis
<how-the-five-seed-analysis-relates-to-the-three-seed-analysis>
The protocol pre-registered three seeds per arm with an option of five. The three-seed analysis of 19 September 2026 already rejected H1 under both readings (contrasts against the random opponent −0.175 \[−0.268, −0.007\] and −0.158 \[−0.254, −0.050\]; against the heuristic −0.085 \[−0.143, −0.025\] and −0.072 \[−0.100, −0.028\]; against the search opponent +0.005 \[−0.020, +0.035\] and −0.013 \[−0.040, +0.015\]). Seeds 4 and 5 were then added to both arms under written pre-commitments made on 26 September 2026: the final analysis would use all five seeds under the same rule, the cutoff would stay unchanged, and the two-stage collection would be disclosed. The extension tightened four of the six intervals, absorbed the single graph-better seed pair observed against the heuristic (graph seed 4 at 0.125 against grid seed 4 at 0.105) and the best search-opponent score of any run (grid seed 5 at 0.210), and did not change the verdict. The five-seed tables above are the study's final numbers.

== Can the move cap rescue the hypothesis?
<can-the-move-cap-rescue-the-hypothesis>
Truncation was defined as a separate outcome before the first run, and the protocol required the primary result to be recomputed under alternative treatments of truncated games. The strongest treatment in the graph arm's favour scores every truncated game as a win for the arm under test, which is an upper bound on what any larger cap could deliver. Under that bound, computed from the per-game records of the three original seeds, the graph−grid difference against the random opponent is still −0.072 at equal examples and −0.058 at equal time; the direction of the contrast is unchanged under every treatment (excluded, scored 0.5, scored as loss, scored as win). The cap value therefore cannot reverse the verdict; it can only change its size.

== Where the deficit lives
<where-the-deficit-lives>
Putting the three opponents side by side shows where the deficit lies: it is largest against the weakest opponent and absent against the strongest. Against legal-random, where strength is mostly the ability to finish a surround that nothing resists, the graph arm wins material and then fails to convert; the truncation column is the trace of that failure. Against the heuristic, which attacks the queen directly, the graph arm's defence is weaker than the grid arm's. Against the search opponent, both arms are in a low-score regime where ten generations of small-budget self-play have not produced an attack either arm can sustain. @sec:results-qualitative examines these mechanisms on individual games; @sec:discussion weighs the explanations.

#figure(image("figures/fig1-score-vs-time.png", width: 92.0%),
  caption: [
    Mean score against the frozen population (average of the three opponents, truncations excluded) as a function of cumulative training wall-clock, for all ten main runs; evaluations at generations 5, 8 and 10 (20, 20 and 100 games per opponent). Blue: grid arm; red: graph arm; one line per seed. The dashed vertical line marks the equal-time cutoff of 18.77 hours.
  ]
)
<fig:score-vs-time>

@fig:score-vs-time shows the two readings at once: at any given wall-clock the grid arm sits above the graph arm, and at the cutoff the graph runs have completed less than half of their generations. @sec:results-cost quantifies the cost side.

= Results: cost and efficiency (RQ-H2)
<sec:results-cost>
The second research question asks how the two representations compare when the budget is read as a number of training examples and when it is read as time on the same hardware. The protocol required both readings and required every run to report its wall-clock, its hardware, the number of training states consumed and the simulations per decision. This chapter reports those costs and puts the two readings side by side.

== What each arm costs on the study machine
<what-each-arm-costs-on-the-study-machine>
#figure(
  align(center)[#table(
    columns: (49.67%, 27.91%, 22.42%),
    align: (left,right,right,),
    table.header([Metric], [Grid arm], [Graph arm],),
    table.hline(),
    [Parameters], [1.44 M], [1.47 M (+1.5%)],
    [Best-provider inference, batch 1], [2.62 ms (neural accelerator)], [3.67 ms (CPU)],
    [Training wall-clock per run, mean of 5 seeds (10 generations × 500 games)], [18.0 h], [36.7 h (2.0×)],
    [Equivalent self-play cost], [13.0 s/game], [26.4 s/game],
    [Training throughput benchmark (batch 128, forward + backward)], [274 pos/s], [138 pos/s],
    [Population score, same-examples reading], [0.411], [0.331],
    [Population score, same-wall-clock reading (cutoff 18.77 h)], [0.405], [0.326],
  )]
  , caption: [Cost and score summary per arm (H-T2). Training wall-clock covers self-play generation and training for the ten generations of a run, evaluation games excluded, averaged over the five seeds; the equivalent self-play cost divides it by the 5,000 games of a run. Inference and training-throughput figures are benchmark measurements of 10 September 2026 on the study machine (Apple M1 Pro, 10 cores, 16 GB). Population score = mean over the three frozen opponents of the seed-level mean score (truncations excluded). ]
  , kind: table
  ) <tbl:cost>

The two networks are matched in size. The graph arm's single evaluation is 1.4× slower at its best provider, its training throughput is half that of the grid arm, and a full run costs it twice the wall-clock. Per run, the five grid seeds took 18.77, 16.73, 19.07, 18.23 and 17.19 hours of training wall-clock; the five graph seeds took 43.07, 32.71, 31.28, 49.86 and 26.57 hours.

The measured wall-clock ratio is 2.0× (36.7 h against 18.0 h on average). At the sizing stage the ratio had been estimated at 1.7×; the measured ratio over the first five completed runs was 2.1×, and the estimate was replaced by the measured figure in all budget accounting before any comparison was computed.

Self-play generation dominates the wall-clock of both arms; in the pilot, generation 0 took about 60 minutes of self-play against about 3.5 minutes of training. The graph arm's extra cost is therefore paid mostly in the search, through its slower per-position inference and its CPU execution. The asymmetry is a property of the deployment hardware: the convolutional network maps cleanly onto the machine's neural accelerator (2.62 ms per evaluation), whereas the gather-heavy graph network falls back to the CPU for a large share of its operations and runs fastest there (3.67 ms on the CPU against 9.84 ms on the accelerator, with 147 of 287 operator nodes supported). The protocol chose to report and charge this asymmetry rather than to equalise it away. The same-wall-clock reading thus reflects what each representation costs on this machine, while the same-examples reading is unaffected by it.

On a different accelerator the ratio could change in either direction; on the CPU alone the graph network is the faster of the two at inference (3.67 ms against 23.5 ms). The cost figures in this chapter are therefore specific to this hardware by construction; the parameter counts and the throughput figures are the portable part.

== The two readings side by side
<the-two-readings-side-by-side>
Under the same-examples reading, both arms are compared after ten generations; the grid arm's population score is 0.411 and the graph arm's 0.331. Under the same-wall-clock reading, each run is taken at its last checkpoint within 18.77 hours (generation 9 or 10 for the grid runs, generation 3 to 6 for the graph runs), and the population scores are 0.405 and 0.326. The two readings therefore give the same ordering and nearly the same gap: 0.081 at equal examples and 0.079 at equal time, in the grid arm's favour.

The pre-registered reason for reading the budget twice was the possibility of a representation that learns more per example but less per hour, in which case the two readings would disagree and both would have to be reported. Here they agree: the graph arm learns less per example and also less per hour. The equal-time reading does not create the deficit; it enlarges one that the per-example reading already shows, since within the cutoff the graph arm completes fewer than half of its generations.

The population score averages three opponents of very different difficulty, so it is a summary for this comparison only and hides the opponent structure of the result; the per-opponent tables of @sec:results-main are the primary evidence. Scores at the intermediate generations (5 and 8) come from 20-game evaluations sized for monitoring and do not enter any interval.

== Score as a function of time
<score-as-a-function-of-time>
@fig:score-vs-time in @sec:results-main plots the population score of every run against its cumulative training wall-clock. Two features of the curves answer RQ-H2 directly. First, at every wall-clock at which both arms have an evaluation, every grid run lies above every graph run; the arms' bands do not cross. Second, the grid runs' curves flatten after their first evaluations (against the random opponent they are near the ceiling by generation 5), while the graph runs' curves keep moving non-monotonically throughout their longer runs; at the cutoff the graph runs have had 3 to 6 generations and are still in the regime where seed-to-seed variation dominates. Within this budget, the extra time gave the graph arm more generations without producing a crossing.

== Resources consumed by the study
<resources-consumed-by-the-study>
The main comparison consumed ten training runs totalling about 274 hours of training wall-clock (five grid runs, 90.0 h; five graph runs, 183.5 h), plus the evaluation games (100 games per opponent per checkpoint at roughly 23--32 seconds per game at 400 simulations, for the final and the cutoff checkpoints of every run) and the monitoring evaluations at generations 5 and 8. The three ablation cells added nine graph-arm runs (training wall-clock under the same accounting: A1 7.61--8.01 h each because the divergent networks played short games; A2 32.05--47.44 h; A1′ 23.89--30.35 h). All computation ran sequentially on one laptop kept awake, with no cloud or paid resources; the campaigns span 10 September to 6 October 2026.

= Results: component ablations (RQ-H3)
<sec:results-ablations>
This chapter answers the third research question: which of the graph arm's two distinctive components, its six direction-typed relations and its global-pooling bias, carry its behaviour. Each ablation removes one component and nothing else, at the full method's settings (same budgets, same seeds, same frozen opponents and openings, same evaluation), with three seeds per cell; a third run, explicitly labelled as a two-component change, supplements the first ablation. Throughout, nothing is attributed beyond the single component that changed.

== Design of the three cells
<design-of-the-three-cells>
#figure(
  align(center)[#table(
    columns: (18.28%, 27.75%, 16.3%, 9.91%, 27.75%),
    align: (left,left,right,right,left,),
    table.header([Cell], [What changes relative to the full graph arm], [Parameters], [Seeds], [Status],),
    table.hline(),
    [A1: naive adjacency], [the six direction-typed message matrices are replaced by a single shared matrix], [0.54 M], [3], [one-component, at parity],
    [A2: no global pooling], [the global-pooling bias is removed from every layer], [1.37 M], [3], [one-component, at parity],
    [A1′: naive adjacency, stabilised], [as A1, plus gradient-norm clipping at 1.0], [0.54 M], [3], [#strong[two-component];, never attributed to typing alone],
    [Reference: full graph arm], [none], [1.47 M], [5], [main comparison],
  )]
  , caption: [The ablation cells. Parameter counts are measured; the parameter differences are inherent to the removed components and are reported rather than compensated. ]
  , kind: table
  ) <tbl:ablation-cells>

== A1: removing the typed relations removes trainability
<a1-removing-the-typed-relations-removes-trainability>
With one shared message matrix in place of six typed ones, training diverged to non-finite values in generation 0 for all three seeds; every later generation self-played and trained on non-finite network outputs. The symptom that triggered the diagnosis was statistical rather than numerical. The three seeds' final evaluations were identical down to the game count (for instance 0 wins, 0 draws and 100 losses against the heuristic for each seed), which independent seeded trainings cannot produce. The checkpoints have distinct hashes, but every forward pass returns non-finite policy and value from the first checkpoint onward.

The cell's evaluation tables are therefore not strength measurements, since a non-finite policy plays a deterministic, degenerate game independent of its weights; they are excluded as scores, and the H-T3 cell reads "training diverged (3/3 seeds)". The runs took 7.75, 8.01 and 7.61 hours of training wall-clock against a graph-arm mean of 36.70 hours, because non-finite priors degrade the search into short games of about 42 plies with no truncations and no resignations; the configured budget in games and simulations was fully consumed.

At parity settings, the naive-adjacency variant cannot be trained at all, so the typed relations contribute, at minimum, the optimization stability of the whole arm. Nothing about their contribution to playing strength can be measured at parity, because the variant never trains. The explanation offered here, a reasoned argument rather than a measured decomposition, is that a single shared matrix receives the summed gradient of six neighbour terms, roughly six times the per-matrix gradient scale of the typed variant, at an identical learning rate and momentum. The protocol had stated, before any run, that a naive adjacency graph "may not suffice"; under these conditions it does not even optimize.

No learning-rate sweep was run, because changing the learning rate would have made A1 a two-component difference. The silent passage of non-finite values for ten generations was a tooling gap: the training loops had no non-finite guard, and their loss print cadence (every 100 steps) never fired on epochs of about 20 steps. The gap was closed on 23 September 2026 by halting both training loops loudly on a non-finite loss; the behaviour of healthy runs is unchanged, and the ablation result stands.

== A2: removing global pooling changes nothing measurable
<a2-removing-global-pooling-changes-nothing-measurable>
#figure(
  align(center)[#table(
    columns: (17.88%, 28.7%, 24.28%, 29.14%),
    align: (left,left,left,left,),
    table.header([Opponent], [A2 (no pooling), seeds 1/2/3], [Full graph arm, seeds 1/2/3], [Difference A2 − full \[95% interval\]],),
    table.hline(),
    [B-RND], [0.768 (59%) / 0.714 (65%) / 0.952 (17%)], [0.733 (57%) / 0.981 (20%) / 0.722 (55%)], [−0.001 \[−0.170, +0.165\]],
    [B-HEU], [0.050 / 0.070 / 0.025], [0.025 / 0.050 / 0.090], [−0.007 \[−0.043, +0.030\]],
    [B-MCTS], [0.070 / 0.125 / 0.105], [0.115 / 0.125 / 0.100], [−0.013 \[−0.043, +0.013\]],
  )]
  , caption: [Ablation A2: final-checkpoint scores per seed (same-examples reading; truncation rate in parentheses where non-zero; 100 games per opponent per seed on the 250 frozen openings) and the seed-bootstrap interval on the difference against the full graph arm's three original seeds (10,000 resamples, independent seed sets). ]
  , kind: table
  ) <tbl:a2>

All three A2 runs trained healthily (finite outputs, distinct per-seed results); their training wall-clocks of 39.90, 47.44 and 32.05 hours lie within the full graph arm's band (26.57--49.86 h).

Removing the global-pooling bias changed the score by −0.001 \[−0.170, +0.165\] against the random opponent, −0.007 \[−0.043, +0.030\] against the heuristic and −0.013 \[−0.043, +0.013\] against the search opponent. Every interval straddles zero, and the random-opponent cell is dominated by seed variance in both variants (truncation rates between 17% and 65% across seeds).

The hypothesis that pooling carried the graph arm's value learning is not supported. Eight layers of directional message passing alone reproduce the full arm's behaviour, including its failure mode: the conversion pathology against the random opponent is present in both variants. At this scale the global-pooling bias is dispensable.

The cell has three seeds; the 0.10 M parameter difference is inherent to the removed component; and "no measurable effect" is bounded by intervals of width ±0.17 against the random opponent, where a small effect could hide.

== A1′: the stabilised naive-adjacency variant (two-component supplement)
<a1-the-stabilised-naive-adjacency-variant-two-component-supplement>
#figure(
  align(center)[#table(
    columns: (16.26%, 28.13%, 15.16%, 15.82%, 24.62%),
    align: (left,left,right,right,left,),
    table.header([Opponent], [A1′ seeds 1/2/3 (truncation)], [A1′ mean (3 seeds)], [Full graph mean (5 seeds)], [Difference \[95% interval\]],),
    table.hline(),
    [B-RND], [0.566 (47%) / 0.671 (59%) / 0.995 (0%)], [0.744], [0.810], [−0.066 \[−0.254, +0.130\]],
    [B-HEU], [0.035 / 0.135 / 0.110], [0.093], [0.061], [+0.032 \[−0.011, +0.078\]],
    [B-MCTS], [0.090 / 0.195 / 0.060], [0.115], [0.107], [+0.008 \[−0.040, +0.063\]],
  )]
  , caption: [Supplement A1′, untyped relations plus gradient clipping at 1.0 (two components differ from the full method). Final-checkpoint scores per seed, three-seed means, the full graph arm's five-seed means, and the seed-bootstrap interval on the difference over the two unequal seed sets. ]
  , kind: table
  ) <tbl:a1prime>

With a single added stabiliser, all three trainings stayed finite and the non-finite guard never fired, which confirms the remedy implied by the divergence diagnosis. Training wall-clocks of 23.89, 30.35 and 27.68 hours lie at the fast end of the graph arm's band.

The stabilised variant scores within the full graph arm's band against all three opponents: −0.066 \[−0.254, +0.130\], +0.032 \[−0.011, +0.078\] and +0.008 \[−0.040, +0.063\]; every interval straddles zero.

Taken together with A1, the most that can be said is that at this scale the measurable contribution of direction-typed relations lies in optimization stability; no strength contribution beyond it is detectable.

Every number in this cell is confounded by the gradient clip by construction and is never attributed to edge typing alone. The cell has three seeds and wide intervals, and seed 3's 0% truncation against 47--59% for seeds 1--2 shows that the conversion pathology remains seed-volatile in this variant too.

== Summary table H-T3
<summary-table-h-t3>
#figure(
  align(center)[#table(
    columns: (26.27%, 30.68%, 43.05%),
    align: (left,left,left,),
    table.header([Ablation], [Component removed], [Outcome],),
    table.hline(),
    [A1 naive adjacency], [direction-typed relation matrices → one shared matrix], [training diverged (non-finite, generation 0, 3/3 seeds); untrainable at parity; typed relations ⇒ at minimum optimization stability],
    [A2 no global pooling], [global-pooling bias in all layers], [null effect: −0.001 / −0.007 / −0.013 against the three opponents, all intervals straddling zero; failure modes unchanged; pooling dispensable],
    [A1′ supplement (two-component)], [untyped relations + gradient clipping 1.0], [trains; scores within the full arm's band (−0.066 / +0.032 / +0.008); never attributed to typing alone],
  )]
  , caption: [Component attribution for the graph arm (H-T3). Differences are variant minus full graph arm, seed-level means, three seeds per ablation cell. ]
  , kind: table
  ) <tbl:ht3>

Within the tested perimeter, the answer to RQ-H3 is that of the graph arm's two distinctive components, one is necessary for trainability itself and the other is dispensable. Whether the typed relations also contribute playing strength beyond stability cannot be decided from these cells.

= Results: failure positions and training behaviour
<sec:results-qualitative>
Aggregate scores say that the graph arm learned less; they do not say how it fails. This chapter looks at three individual games selected by mechanical criteria, at the truncation channel that carries the mechanism, and at what the training metrics of all ten main runs show.

== Three failure positions, selected mechanically
<three-failure-positions-selected-mechanically>
The research plan asks for three commented failure positions with explicit selection criteria. The criteria are mechanical and were applied over the raw per-game records: F1 is the longest truncated game of the graph arm against the legal-random opponent; F2 is the shortest decided loss of the grid arm against the heuristic opponent; F3 is the longest drawn game of the graph arm against the search opponent. Each selected game was reproduced deterministically from its recorded opening and per-game seeds and verified move by move against its recorded result row before being rendered; all three reproductions matched. This verification step exposed a latent defect in the match runner (a path that skipped writing records when every game of a match was truncated); the defect was fixed before the equal-time evaluations, and an audit found that it had affected no campaign data (@sec:working-method).

#figure(image("figures/fig4-failures.png", width: 100.0%),
  caption: [
    Three commented failure positions, reproduced and verified against their recorded result rows. F1 (left): graph arm, seed 1, against legal-random, opening 2, white; the game reaches the 300-ply cap with the graph arm materially ahead but unable to complete the surround. F2 (centre): grid arm, seed 2, against the heuristic, opening 2, black; a decided loss in 19 plies to the heuristic's queen-targeting tactics. F3 (right): graph arm, seed 3, against the search opponent, opening 19, white; a 79-ply draw in which the graph arm never generates a winning threat.
  ]
)
<fig:failures>

#emph[F1: a won position the graph arm cannot close.] The graph arm wins material early, then shuffles pieces around a partially surrounded enemy queen until the cap. The failure is tactical rather than evaluative: the arm is ahead and stays ahead, but it does not find, or does not prefer, the forcing sequence that completes the surround. This is the pattern behind the arm's 20--57% truncation rate against the random opponent, and it is invisible in any evaluation that scores capped games as draws.

#emph[F2: the price of early-regime policies against sharp tactics.] The grid arm's shortest loss against the heuristic lasts 19 plies. The heuristic's dominant queen-liberty term drives it straight at the queen before the network's policy has consolidated a defence. The game illustrates why both arms score low against the two strong opponents after ten generations, since the regime is still early, and why the comparison's resolution is highest against the random opponent.

#emph[F3: avoiding defeat without creating threats.] Against the search opponent, the graph arm's longest draw (79 plies) shows a network that defends adequately, in that it avoids losing, but never builds a winning attack. Against this opponent the two arms are statistically indistinguishable (@sec:results-main); F3 is a reminder that "indistinguishable" here means both arms draw or lose, not that either plays well.

== The truncation channel, run by run
<the-truncation-channel-run-by-run>
#figure(image("figures/fig7-truncation.png", width: 80.0%),
  caption: [
    Final-evaluation truncation rate against the legal-random opponent for each of the ten main runs (final checkpoints; 100 games per run at 400 simulations on the 250 frozen openings; 300-ply cap). Blue: grid arm seeds 1--5; red: graph arm seeds 1--5. Truncation is reported separately from draws throughout the study.
  ]
)
<fig:truncation>

The graph arm truncated 57%, 20%, 55%, 44% and 23% of its games against the random opponent at the final checkpoint for seeds 1 to 5; the grid arm truncated 0%, 1%, 1%, 11% and 0%. Against the heuristic and the search opponent, no game of either arm reached the cap.

The truncation gap is the largest behavioural difference between the arms, larger than any score gap, and its direction is consistent across seeds: every graph seed truncates more than every grid seed. Grid seed 4 (11%) exceeds no graph seed, but it shows that the pathology is not strictly exclusive to one arm. Because truncation was defined as its own outcome before the first run, the pathology is visible instead of being absorbed into draws; and because the cap cannot rescue the hypothesis (@sec:results-main), the channel is diagnostic rather than decisive.

The graph arm's random-opponent score is consequently measured on fewer decided games (between 43 and 80 per seed), which widens its interval; the sensitivity analysis bounds this effect without removing it.

== What the training metrics show
<what-the-training-metrics-show>
#figure(image("figures/fig6-training-metrics.png", width: 100.0%),
  caption: [
    Training metrics by generation for the ten main-campaign runs (epoch-1 line of each generation): left, policy top-1 agreement with the MCTS visit distribution on the self-play validation split; right, value accuracy on non-truncated samples. Blue: grid arm; red: graph arm; one line per seed. Ablation runs are excluded.
  ]
)
<fig:training>

Both arms fit their self-play data throughout the ten generations: policy top-1 rises with generation in every run, and value accuracy on non-truncated samples rises for both arms. The graph arm's value accuracy is comparable to the grid arm's, while its policy top-1 trails.

The gap between the arms is therefore not a plain optimization failure of the full graph arm (unlike the ablated naive-adjacency variant, which did not optimize at all). The graph arm learns a usable evaluation of positions and a weaker policy. The failure positions give the same picture, adequate judgement of who is better and inadequate generation of forcing moves, and this motivates the first follow-up in @sec:conclusion.

Training metrics are computed on each run's own self-play validation split, whose distribution shifts with the generation and differs between arms; they are evidence about fitting, not about strength, and no number from this figure enters any interval or any claim of the main comparison.

== Per-opponent trajectories
<per-opponent-trajectories>
#figure(image("figures/fig5-per-opponent.png", width: 100.0%),
  caption: [
    Score against each frozen opponent at the evaluated generations (5, 8 and 10; 20, 20 and 100 games per opponent respectively) for every main run. Blue: grid arm; red: graph arm; one line per seed. Scores exclude truncated games.
  ]
)
<fig:per-opponent>

The per-opponent trajectories decompose the aggregate curves of @sec:results-cost: against the random opponent, grid seeds approach the ceiling early and stay there, while graph seeds spread widely and move non-monotonically; against the heuristic and the search opponent, both arms remain in a low band whose generation-to-generation movement is of the order of the game-count noise at 20 games (the intermediate evaluations were sized for monitoring and not for inference; only the 100-game final evaluations enter the tables).

#part[Part V. Discussion and conclusion]
= Discussion and threats to validity
<sec:discussion>
The hypothesis was rejected exactly as the frozen protocol defined rejection. This chapter asks what the result means, which explanations the data support and which they merely suggest, how the result relates to the prior work that motivated it, and what could be wrong with it. The threats are organised as the research plan prescribes: internal, measurement, statistical and external.

== Reading the result
<reading-the-result>
Three observations shape how the result should be read.

First, the deficit is opponent-shaped. It is largest against the legal-random opponent, clear against the heuristic and absent against the search opponent (@tbl:contrast). A graph arm that was simply weaker everywhere would show a uniform deficit; a deficit concentrated where games are decided by finishing a surround that nothing resists points at #emph[local tactical conversion] rather than positional judgement.

Second, the truncation channel carries the mechanism. The graph arm wins material against the random opponent and then fails to close: 20--57% of those games end at the 300-ply cap, against 0--11% for the grid arm (@fig:truncation, @fig:failures F1). This pattern is invisible in any study that scores capped games as draws, and it is why the protocol insisted, before the first run, that truncation be an outcome of its own.

Third, the ablations sharpen the reading. At parity settings, removing the direction-typed relations did more than weaken the graph arm; it destroyed trainability outright (non-finite divergence in generation 0 for all three seeds), so the typed relations carry at minimum the optimization stability of the whole arm. Removing the global-pooling bias changed the scores by ≈0.00 ± 0.17, −0.01 ± 0.04 and −0.01 ± 0.03 against the three opponents, with failure modes unchanged. The arm's distinctive machinery therefore lives in its directional relations rather than in its pooling. Once the naive variant is stabilised by gradient clipping, however, it plays within the full arm's band, so the measurable contribution of the typed relations at this scale is concentrated in optimization rather than in representation (@sec:results-ablations).

== Which explanations are demonstrated, and which are plausible
<which-explanations-are-demonstrated-and-which-are-plausible>
The research plan distinguishes an explanation demonstrated by ablation from one that is merely plausible. Four candidate explanations of the gap deserve this treatment.

#emph[Geometry (plausible, not demonstrated).] Hive's tactics are dominated by short-range surround geometry, the regime in which Keller et al. (2023) found convolutional networks stronger than graph networks in Hex. A 3×3 convolution over the unfolded frame sees a cell's whole neighbourhood, and stacked residual blocks see the neighbourhood of the neighbourhood, at no learning cost; the message-passing network must compose the same patterns from six typed relations one hop at a time. This is consistent with every observation above, but no ablation in this study isolates receptive-field composition, so it remains a hypothesis.

#emph[Capacity (controlled).] The two networks differ by +1.5% in parameter count (1.44 M against 1.47 M), in the graph arm's favour. Capacity does not explain a graph deficit.

#emph[Decoder (controlled).] Both arms score the identical set of legal (piece, destination) pairs with identical masking, normalisation, targets and tie-breaking; the decoder cannot favour one arm. What does differ is the #emph[parameterisation] behind the shared interface: a flat 28,673-way tensor for the grid arm, a per-candidate scoring function for the graph arm. That difference is part of what "representation" means in this study rather than a confound of it.

#emph[Speed (demonstrated for the second reading only).] The graph arm's generations cost roughly twice as much wall-clock on this machine, so at equal time it completes fewer than half of its generations (@sec:results-cost). This demonstrably widens the gap in the same-wall-clock reading; it plays no role in the same-examples reading, where the deficit already exists.

#emph[Optimization (partly demonstrated).] The ablations show that the full graph arm's optimization is fragile in one specific way (it depends on typed relations for stability), but the training curves of the full arm (@fig:training) show it fitting its data in every seed. Nothing indicates that the full arm failed to optimize; the gap is a gap between two trained networks. Whether a different learning rate or normalisation would have favoured the graph arm was not tested, because neither arm received any tuning. The zero-tuning policy is symmetric, but it is not neutral if one architecture is more sensitive to its defaults, a point taken up under external validity.

== Relation to prior work
<relation-to-prior-work>
The result does not contradict the positive graph findings of Rigaux and Kashima (2024) in chess or the long-range advantage Keller et al. (2023) measured in Hex. It bounds where their optimism transfers. The chess result rests on a single training run per model with intervals covering Elo estimation only, a loose capacity match and arm-specific decoders; the Hex result was obtained under a value-based learner, with a game-specific graph construction, and found the convolutional arm sharper at local patterns, which is the regime that decides Hive games at small budgets. The present rejection is seed-consistent across five runs per arm under two pre-registered budget readings, with capacity matched and the decoder shared. Read together, the three studies suggest that the sign of the grid-versus-graph comparison depends on the game's tactical range and on the evidence standard, rather than on the graph paradigm as such. The one prior AlphaZero study of Hive (de Goede et al., 2022) had already shown that encoding choice changes learning within the grid family; this study extends the finding across families and finds the grid side ahead.

== Internal validity: bugs and comparability
<internal-validity-bugs-and-comparability>
The engine is validated independently of learning: perft equality with published tables to depth 6 for all eight game types, 21/21 protocol conformance, 27,829-position differential agreement of legal-move sets with two reference engines, a 30-case rules-derived corpus annotated before any run, and 10.9 million random transitions without an invariant violation (@sec:engine). Both encoders are pinned byte-exactly against cross-language golden tests run nightly (240 and 160 positions). The arms share the decoder, the records, the losses, the budgets, the search and the frozen evaluation; capacity differs by +1.5% and is reported.

Residual risks remain. The graph architecture is one point in design space; a different graph network might behave differently, and nothing is claimed beyond this one. Tooling defects were found #emph[during] the study: a match-runner path that dropped records when every game of a match was truncated, a training loop that let non-finite values pass silently for ten generations, and a results generator whose per-run wall-clock average still divided by the original three runs after the extension to five. Each was caught by the verification discipline (@sec:working-method), fixed, and audited: the first touched no campaign data; the second affected only the ablation it exposed and became that ablation's result; the third affected two cost-table rows and no score, interval or claim. They illustrate the study's most practical lesson: at this scale the dominant failure mode is harness error rather than chance, and only mechanical verification catches it.

== Measurement validity: opponents and truncation
<measurement-validity-opponents-and-truncation>
Scores are relative to a population of three fixed opponents spanning floor-to-mid strength; no universal strength claim is made. All trained arms still lose heavily to the two strong baselines after ten generations, so the comparison lives in a low-score regime in which differences against the search opponent cannot be resolved. Truncation is handled as its own outcome with sensitivity bounds: the cap cannot reverse the verdict, but the graph arm's high truncation rates mean its random-opponent score is measured on fewer decided games (43--80 per seed), which widens its interval. The evaluation openings are frozen and shared, so an opening-set effect would affect both arms alike; it could still shape absolute scores.

== Statistical validity: seeds and dependencies
<statistical-validity-seeds-and-dependencies>
Five seeds per arm bound the statistics. The rejection rests on more than a single interval: on seed-consistency across two opponents and two readings simultaneously, on four of six intervals excluding zero, and on a bounds analysis of the cap. The pre-committed extension from three to five seeds tightened four of the six intervals and absorbed the most graph-favourable seeds observed without changing the verdict; the contrast against the search opponent remains indistinguishable from zero under both readings and is reported as such. The arm contrast bootstraps seeds rather than games, so no game-level pseudo-replication enters any interval, and the two arms' seed sets are resampled independently, which is conservative for a paired design in which both arms play the same openings.

== External validity: variant, hardware and budget
<external-validity-variant-hardware-and-budget>
One variant (base Hive without expansions), one machine, one small budget (ten generations of 500 games; between 16.7 and 19.1 hours of training wall-clock per grid run and between 26.6 and 49.9 hours per graph run), early-regime self-play throughout. The inference-provider asymmetry is a genuine property of the deployment hardware: the convolutional network runs fastest on the machine's neural accelerator, the gather-heavy graph network fastest on the CPU. It is reported and charged, and on different accelerators the wall-clock reading could shift while the same-examples reading would not. The zero-tuning policy is symmetric but may not be neutral: graph networks are commonly more sensitive to optimizer defaults than residual convolutional networks, and the first ablation showed that this family is fragile under these defaults; a tuned graph arm might narrow the gap, at the cost of breaking the symmetry of the comparison. Nothing here generalises to other games, larger budgets or richer graph architectures. The study answers its pre-registered question inside its pre-registered perimeter, and the negative answer is the finding. Encoding choice matters, as the earlier Hive study found, and for Hive at small budget it favours the grid.

== A property of the pipeline that bounds the absolute strength reached
<a-property-of-the-pipeline-that-bounds-the-absolute-strength-reached>
One property of the shared pipeline deserves to be stated as plainly as possible, because it shapes how the "ten generations" of this study should be read. The campaign driver trains the network of each generation from a fresh seeded initialisation, for two epochs, on the records of that generation alone; it passes neither a warm-start checkpoint nor a replay window to the trainer (@sec:pipeline). The loop still improves across generations, because the network of generation $g$ is trained on games played by the search guided by the network of generation $g - 1$, and that search is stronger than the raw network; but no weights are carried forward and no record is reused. Each network therefore sees the positions of 500 games, which is a small training set by the standards of self-play learning, and the absolute strength reached after ten generations (near the ceiling against the random opponent, around 0.1 against the two strong opponents) must be read against that fact. For the #emph[comparison] the property is neutral: it is identical in both arms, both encoders see exactly the same records, and the frozen protocol specified identical training conventions rather than a particular warm-start policy. For the #emph[generalisation] of the result it is a limit in addition to those already listed: a pipeline that accumulated data and carried weights would reach a different regime, in which the ordering of the arms is an open question. A successor study should carry weights across generations and train on a window of recent generations, as the large self-play systems do, with both changes applied identically to both arms.

== What we would do differently
<what-we-would-do-differently>
Four changes would strengthen a successor study without changing its logic. The first is the warm-start and replay window just described. The intermediate evaluations (20 games per opponent at generations 5 and 8) were sized for monitoring and are too noisy to carry inference; a successor should evaluate every generation at the final volume if the curves are to be analysed. The equal-time reading should be accompanied by an equal-#emph[energy] reading on heterogeneous accelerators, since wall-clock alone hides the provider asymmetry. And the zero-tuning symmetry should be complemented by a small, identical, pre-registered tuning budget for both arms, so that fragility under defaults is measured rather than inherited.

= Conclusion and perspectives
<sec:conclusion>
== The answer to the research question
<the-answer-to-the-research-question>
The tested perimeter is base-game Hive, one capacity-matched simple relational message-passing network against one grid convolutional network, ten generations of small-budget self-play, five independent seeds per arm, a frozen three-opponent population and 250 frozen openings. Within that perimeter, #strong[the answer to the main research question is no];: the graph representation did not learn a better policy than the grid representation, neither when both arms consumed the same number of training examples nor when both received the same wall-clock on the same machine, and the pre-registered rejection rule fired exactly as it had been frozen. The graph arm's deficit is largest where Hive is most tactical (against the legal-random opponent, −0.169 and −0.161 under the two readings) and clear against the heuristic opponent (−0.064 and −0.059); against the search opponent the two arms are indistinguishable (−0.009 and −0.018, intervals straddling zero). The graph arm pays roughly twice the wall-clock per run. Its characteristic failure is to win material without converting the win; this shows as 20--57% of its games against the random opponent ending at the move cap, and it is observable only because truncation was never folded into draws.

The result bounds, rather than contradicts, the positive graph findings reported for Hex under value-based learning and for chess under self-play. Where short-range surround tactics decide games and budgets are small, the frame artifacts of a grid encoding turn out to be cheaper than framelessness. The component analysis adds a mechanistic reading: of the graph arm's two distinctive components, the direction-typed relations are necessary for optimization itself (removing them at identical settings made training diverge in every seed), while the global-pooling bias is dispensable at this scale.

== Contributions, as demonstrated
<contributions-as-demonstrated>
Three contributions were announced in @sec:introduction; each is demonstrated in the chapters named there. (1) A controlled, budget-matched, multi-seed grid-versus-graph comparison for Hive, with both arms under one self-play pipeline and a pre-registered negative answer (@sec:results-main, @sec:results-cost). (2) A reproducible comparison harness for frameless, stacking games, released with the raw records: a rules-validated engine, two encoders pinned byte-exactly across two languages, a shared variable-action decoder, truncation-aware evaluation and frozen-artifact discipline (@sec:engine to @sec:protocol). (3) A component attribution for the graph arm with an honestly labelled two-component supplement (@sec:results-ablations).

== Two follow-ups motivated by the data
<two-follow-ups-motivated-by-the-data>
The first follow-up targets the #strong[conversion pathology];, which the data isolate as a policy defect rather than a value defect: the graph arm's value accuracy in training is comparable to the grid arm's while its policy fails at forcing sequences (@sec:results-qualitative). A natural experiment is a search-time remedy applied identically to both arms under the same frozen evaluation, as a one-component change to the shared pipeline: a deeper evaluation budget in positions the value head already judges won, or auxiliary training targets for forcing moves. The second follow-up concerns the #strong[stability finding];: the ablation and its supplement showed that direction-typed relations matter mostly for optimization at this scale, but the supplement's gradient clipping confounds the attribution. A controlled study of normalisation and gradient-scale choices for relation-shared graph layers would decouple trainability from representational content and would say whether naive adjacency, properly stabilised, is sufficient for Hive.

== A method that stands regardless of the sign
<a-method-that-stands-regardless-of-the-sign>
Pre-registration with frozen artifacts, two budget readings, truncation as an outcome, seed-level inference and reporting written as the work progressed turned a negative answer into a usable scientific object on a single laptop. The same discipline, described in @sec:working-method together with the incidents it caught, is the part of this work most directly transferable to other small-compute studies.

#[
#set par(hanging-indent: 1.8em, justify: false, first-line-indent: 0em)
#set text(size: 10pt)
#heading(level: 1, numbering: none)[Bibliography]
<bibliography>
Agarwal, R., Schwarzer, M., Castro, P. S., Courville, A., & Bellemare, M. G. (2021). Deep reinforcement learning at the edge of the statistical precipice. In #emph[Advances in Neural Information Processing Systems] (NeurIPS 2021) (peer-reviewed; Outstanding Paper Award). arXiv:2108.13264 (v4, 5 January 2022). #link("https://doi.org/10.48550/arXiv.2108.13264")[https:\/\/doi.org/10.48550/arXiv.2108.13264]

Ben-Assayag, S., & El-Yaniv, R. (2021). Train on small, play the large: Scaling up board games with AlphaZero and GNN. arXiv preprint arXiv:2107.08387v1 (18 July 2021) (no peer-reviewed version found as of 26 September 2026). #link("https://doi.org/10.48550/arXiv.2107.08387")[https:\/\/doi.org/10.48550/arXiv.2107.08387]

Cazenave, T., Chen, Y.-C., Chen, G.-W., Chen, S.-Y., Chiu, X.-D., Dehos, J., Elsa, M., Gong, Q., Hu, H., Khalidov, V., Li, C.-L., Lin, H.-I., Lin, Y.-J., Martinet, X., Mella, V., Rapin, J., Roziere, B., Synnaeve, G., Teytaud, F., Teytaud, O., Ye, S.-C., Ye, Y.-J., Yen, S.-J., & Zagoruyko, S. (2020). Polygames: Improved zero learning. #emph[ICGA Journal];, 42(4), 244--256. #link("https://doi.org/10.3233/ICG-200157")[https:\/\/doi.org/10.3233/ICG-200157]. Preprint: arXiv:2001.09832 (January 2020).

de Goede, D., Kampert, D., & Varbanescu, A. L. (2022). The cost of reinforcement learning for game engines: The AZ-Hive case-study. In #emph[Proceedings of the 13th ACM/SPEC International Conference on Performance Engineering] (ICPE 2022, Beijing), pp.~145--152. #link("https://doi.org/10.1145/3489525.3511685")[https:\/\/doi.org/10.1145/3489525.3511685]

Hamilton, W. L., Ying, R., & Leskovec, J. (2017). Inductive representation learning on large graphs. In #emph[Advances in Neural Information Processing Systems] (NIPS 2017) (peer-reviewed). arXiv:1706.02216 (v4, 10 September 2018). #link("https://doi.org/10.48550/arXiv.1706.02216")[https:\/\/doi.org/10.48550/arXiv.1706.02216]

Jones, A. L. (2021). Scaling scaling laws with board games. arXiv preprint arXiv:2104.03113v2 (15 April 2021) (not peer-reviewed). #link("https://doi.org/10.48550/arXiv.2104.03113")[https:\/\/doi.org/10.48550/arXiv.2104.03113]

Kampert, D., Varbanescu, A.-L., Müller-Brockhausen, M., & Plaat, A. (2021). Mimicking the human approach in the game of Hive. In #emph[2021 IEEE Symposium Series on Computational Intelligence] (SSCI 2021, Orlando). IEEE Xplore document 9659999. #link("https://ieeexplore.ieee.org/document/9659999/")[https:\/\/ieeexplore.ieee.org/document/9659999/]. Preprint circulated as "Better AI for Hive: Mimicking human game-play strategies".

Keller, Y., Blüml, J., Sudhakaran, G., & Kersting, K. (2023). From images to connections: Can DQN with GNNs learn the strategic game of Hex? arXiv preprint arXiv:2311.13414 (22 November 2023) (not peer-reviewed; OpenReview submission dYaeDrazj5). #link("https://arxiv.org/abs/2311.13414")[https:\/\/arxiv.org/abs/2311.13414]

Rigaux, T., & Kashima, H. (2024). Enhancing chess reinforcement learning with graph representation. In #emph[Advances in Neural Information Processing Systems 37] (NeurIPS 2024, main conference track). #link("https://doi.org/10.52202/079017-0006")[https:\/\/doi.org/10.52202/079017-0006]. Preprint: arXiv:2410.23753v1 (31 October 2024), #link("https://doi.org/10.48550/arXiv.2410.23753")[https:\/\/doi.org/10.48550/arXiv.2410.23753]

Silver, D., Hubert, T., Schrittwieser, J., Antonoglou, I., Lai, M., Guez, A., Lanctot, M., Sifre, L., Kumaran, D., Graepel, T., Lillicrap, T., Simonyan, K., & Hassabis, D. (2018). A general reinforcement learning algorithm that masters chess, shogi, and Go through self-play. #emph[Science];, 362(6419), 1140--1144 (peer-reviewed). #link("https://doi.org/10.1126/science.aar6404")[https:\/\/doi.org/10.1126/science.aar6404]. Preprint (2017): Mastering chess and shogi by self-play with a general reinforcement learning algorithm, arXiv:1712.01815v1 (5 December 2017), #link("https://doi.org/10.48550/arXiv.1712.01815")[https:\/\/doi.org/10.48550/arXiv.1712.01815]

van der Pol, E., Worrall, D. E., van Hoof, H., Oliehoek, F. A., & Welling, M. (2020). MDP homomorphic networks: Group symmetries in reinforcement learning. In #emph[Advances in Neural Information Processing Systems] (NeurIPS 2020) (peer-reviewed). arXiv:2006.16908 (v2, 20 January 2021). #link("https://arxiv.org/abs/2006.16908")[https:\/\/arxiv.org/abs/2006.16908]

Vinyals, O., Fortunato, M., & Jaitly, N. (2015). Pointer networks. In #emph[Advances in Neural Information Processing Systems 28] (NIPS 2015) (peer-reviewed). arXiv:1506.03134 (v2, 2 January 2017). #link("https://arxiv.org/abs/1506.03134")[https:\/\/arxiv.org/abs/1506.03134]

Wu, D. J. (2020). Accelerating self-play learning in Go. arXiv preprint arXiv:1902.10565v5 (9 November 2020); presented at the AAAI-20 Workshop on Reinforcement Learning in Games (not a full peer-reviewed proceedings paper). #link("https://doi.org/10.48550/arXiv.1902.10565")[https:\/\/doi.org/10.48550/arXiv.1902.10565]

#heading(level: 1, numbering: none)[Webography]
<webography>
edre (GitHub user). #emph[nokamute];: Hive engine in Rust, with a Universal Hive Protocol conformance tester and a built-in match runner \[source-code repository\]. GitHub. #link("https://github.com/edre/nokamute")[https:\/\/github.com/edre/nokamute]. Version 1.0.3 used as a reference engine. Consulted July 2026 (engine design) and 9 September 2026 (validation campaign).

jonthysell (GitHub user). #emph[Mzinga];: reference Hive engine and project wiki, including the Universal Hive Protocol specification and the perft tables \[source-code repository and wiki\]. GitHub. #link("https://github.com/jonthysell/Mzinga")[https:\/\/github.com/jonthysell/Mzinga]; perft tables: #link("https://github.com/jonthysell/Mzinga/wiki/Perft")[https:\/\/github.com/jonthysell/Mzinga/wiki/Perft]. Release MzingaEngine v0.16.0 used as a reference engine. Consulted July 2026 (engine design) and 9 September 2026 (validation campaign).

Pfeifer, J. (GitHub user janpfeifer). (2018--2026). #emph[hiveGo --- Go implementation of Hive game] \[source-code repository\]. GitHub. Created 24 August 2018; main branch, commit d6ff95418d2b (20 August 2026). #link("https://github.com/janpfeifer/hiveGo")[https:\/\/github.com/janpfeifer/hiveGo]. Consulted 26 September 2026.

World Hive Tournaments. #emph[Rules of Hive: Rules FAQ] \[web page\]. #link("https://www.worldhivetournaments.com/rules-of-hive/")[https:\/\/www.worldhivetournaments.com/rules-of-hive/]. Consulted 9 September 2026.

Yianni, J. (2010). #emph[Hive rules] \[publisher's rules sheet\]. Gen42 Games. #link("https://www.gen42.com/wp-content/uploads/Hive-rules.pdf")[https:\/\/www.gen42.com/wp-content/uploads/Hive-rules.pdf]. Consulted 9 September 2026.

Yianni, J. #emph[The Pillbug: Additional Hive Pieces] \[publisher's rules sheet\]. Gen42 Games. #link("https://www.gen42.com/wp-content/uploads/Pillbug\_Rules.pdf")[https:\/\/www.gen42.com/wp-content/uploads/Pillbug\_Rules.pdf]. Consulted 9 September 2026.
]
#part[Appendices]

#counter(heading).update(0)
#set heading(numbering: "A.1", supplement: "Appendix")
= Annotated position corpora
<sec:app-a>
Every expectation below was written by hand from the publisher's rules before any engine run, so that the corpus could serve as an unbiased oracle; the engine was then run against it. The single disagreement found was resolved against the corpus (a One-Hive transit error in one setup sequence), and the engine was vindicated. These renderings are generated directly from the executable test cases, so the tests and this appendix cannot drift apart. Setup sequences are given in the move notation of the Universal Hive Protocol.

== Critical rules corpus (30 cases)
<critical-rules-corpus-30-cases>
Rules-correctness cases: placement, sliding/freedom to move, gates, stacking, One-Hive, terminal states, forced pass, and kernel-guard Pillbug stun cases.

=== C001: Queen Bee may not be placed on the first turn (tournament rule)
<c001-queen-bee-may-not-be-placed-on-the-first-turn-tournament-rule>
- #strong[Rule:] Tournament opening rule (#emph[Tournament variant of the official rules (README source 4); Gen42 2010 rulesheet p.~3 alone would allow it];)
- #strong[Setup:] \`\`
- #strong[Expectation:] move\_illegal `{'move': 'wQ'}`
- #strong[Hand-written justification:] The 2010 base rulesheet says the Queen 'can be placed at any time from your first to your fourth turn' (p.~3), but the tournament variant (adopted by UHP and both reference engines, and the convention this study fixes) forbids placing the Queen Bee on either player's first turn. White's first move 'wQ' must therefore be rejected.

=== C002: Queen must be placed on the fourth turn if not placed before
<c002-queen-must-be-placed-on-the-fourth-turn-if-not-placed-before>
- #strong[Rule:] Placing your Queen Bee (#emph[Gen42 Hive rulesheet p.~3];)
- #strong[Setup:] `wS1;bS1 wS1-;wG1 -wS1;bG1 bS1-;wA1 -wG1;bA1 bG1-`
- #strong[Expectation:] all\_moves\_place `{'piece': 'wQ'}`
- #strong[Hand-written justification:] 'You must place your Queen Bee on your fourth turn if you have not placed it before.' (p.~3). It is White's fourth turn and wQ is still in hand, so every legal move must be a placement of wQ. (Movement moves are additionally excluded by the Moving rule, p.~3: no moving before the queen is placed.) Setup legality: each white placement touches only white pieces, each black placement only black (Placing, p.~2).

=== C003: No piece may move before that player's queen is placed
<c003-no-piece-may-move-before-that-players-queen-is-placed>
- #strong[Rule:] Moving (#emph[Gen42 Hive rulesheet p.~3];)
- #strong[Setup:] `wS1;bS1 wS1-`
- #strong[Expectation:] all\_moves\_are\_placements
- #strong[Hand-written justification:] 'Once your Queen Bee has been placed (but not before), you can decide whether to use each turn after that to place another tile or to move one of the pieces that have already been placed.' (p.~3). White's queen is unplaced on turn 2, so wS1 must have no movement moves; only placements are offered.

=== C004: After the first pieces, placements may not touch the opponent's colour
<c004-after-the-first-pieces-placements-may-not-touch-the-opponents-colour>
- #strong[Rule:] Placing (#emph[Gen42 Hive rulesheet p.~2];)
- #strong[Setup:] `wG1;bS1 wG1/`
- #strong[Expectation:] moves\_for\_piece `{'piece': 'wB1', 'moves': ['wB1 wG1\\', 'wB1 /wG1', 'wB1 -wG1']}`
- #strong[Hand-written justification:] '…with the exception of the first piece placed by each player, pieces may not be placed next to a piece of the opponent's colour.' (p.~2). wG1 sits at the origin with bS1 to its north-east. Of wG1's five empty neighbours (E, SE, SW, W, NW), the E and NW cells each also touch bS1 (they are the two cells adjacent to both wG1 and its NE neighbour), so a new white piece may go only SE, SW or W of wG1. Expected wB1 placements: exactly those three cells. Hand geometry: axial E=(1,0), NE=(1,-1); neighbours of NE-cell (1,-1) include (1,0)=E-of-origin and (0,-1)=NW-of-origin.

=== C005: Second player's first piece joins the first piece (may touch enemy)
<c005-second-players-first-piece-joins-the-first-piece-may-touch-enemy>
- #strong[Rule:] Playing the Game / Placing (#emph[Gen42 Hive rulesheet pp.~2-3];)
- #strong[Setup:] `wS1`
- #strong[Expectation:] moves\_for\_piece `{'piece': 'bG1', 'moves': ['bG1 wS1-', 'bG1 wS1/', 'bG1 wS1\\', 'bG1 -wS1', 'bG1 /wS1', 'bG1 \\wS1']}`
- #strong[Hand-written justification:] 'Play begins with one player placing a piece from their hand in the centre of the table and the next player joining one of their own pieces to it edge to edge.' (p.~2). This is the first-piece exception to the own-colour placing rule. Black's first piece must join wS1 edge to edge, so bG1 may be placed on any of the six cells adjacent to wS1, and nowhere else.

=== C006: Queen at the hive tip: exactly the two slides that keep contact
<c006-queen-at-the-hive-tip-exactly-the-two-slides-that-keep-contact>
- #strong[Rule:] Queen Bee / Freedom to Move / One Hive (contact) (#emph[Gen42 Hive rulesheet pp.~4, 9, 10];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-`
- #strong[Expectation:] moves\_for\_piece `{'piece': 'wQ', 'moves': ['wQ \\wS1', 'wQ /wS1']}`
- #strong[Hand-written justification:] The Queen 'can move only one space per turn' (p.~4) in a sliding movement (p.~10), and 'all pieces must always touch at least one other piece' (p.~3 NB). wQ sits at the west tip of a straight line of four. Of its five empty neighbours, only the two cells that are also adjacent to its neighbour wS1 (the cells NW and SW of wS1) keep contact with the hive after the slide; the three cells further west touch nothing once the queen leaves. Neither destination is gated (each slide's two flanking cells are one occupied, one empty). Expected: exactly those two moves.

=== C007: Ant enclosed in a pocket: only exit is a gate, so it cannot move
<c007-ant-enclosed-in-a-pocket-only-exit-is-a-gate-so-it-cannot-move>
- #strong[Rule:] Freedom to Move (#emph[Gen42 Hive rulesheet p.~10];)
- #strong[Setup:] `wA1;bS1 wA1-;wQ \wA1;bQ bS1-;wG1 -wA1;bB1 bQ/;wS1 /wA1;bB1 bS1/;wB1 \wQ;bB1 wA1/`
- #strong[Expectation:] moves\_for\_piece `{'piece': 'wA1', 'moves': []}`
- #strong[Hand-written justification:] 'If a piece is surrounded to the point that it can no longer physically slide out of its position, it may not be moved.' (p.~10). Five of the ant's six neighbours are occupied. The only empty neighbour (SE of the ant) is flanked by bS1 (E of the ant) and wS1 (SW of the ant) - the two cells adjacent to both the ant and that space - so the ant cannot physically slide into it. Removing the ant would NOT split the hive (the ring bB1-wQ-wG1-wS1 plus bS1 stays connected), so the block is purely freedom-to-move, not One Hive. The Ant, normally the most mobile piece, has zero legal moves.

=== C008: Spider moves exactly three spaces along the hive edge - two destinations
<c008-spider-moves-exactly-three-spaces-along-the-hive-edge---two-destinations>
- #strong[Rule:] Spider (#emph[Gen42 Hive rulesheet p.~7];)
- #strong[Setup:] `wG1;bS1 wG1-;wQ -wG1;bQ bS1-;wS1 \wQ;bG1 bQ-`
- #strong[Expectation:] moves\_for\_piece `{'piece': 'wS1', 'moves': ['wS1 bS1/', 'wS1 wQ\\']}`
- #strong[Hand-written justification:] 'The Spider moves three spaces per turn - no more, no less. It must move in a direct path and cannot backtrack on itself. It may only move around pieces that it is in direct contact with on each step.' (p.~7). The hive minus the spider is a straight five-piece line whose boundary is a single 14-cell ring with no gates; each ring cell touches the line, and cells off the ring touch nothing (excluded by the contact requirement). From its ring position the spider therefore has exactly two three-step walks - three cells clockwise and three cells anticlockwise: the cell NE of bS1, and the cell SE of wQ. One- and two-step stops are excluded ('no less'), backtracking is excluded.

=== C009: Grasshopper: jumps only along occupied rows, no one-space slides
<c009-grasshopper-jumps-only-along-occupied-rows-no-one-space-slides>
- #strong[Rule:] Grasshopper (#emph[Gen42 Hive rulesheet p.~6];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 \wS1;bG1 bQ-`
- #strong[Expectation:] moves\_for\_piece `{'piece': 'wG1', 'moves': ['wG1 wS1\\', 'wG1 /wQ']}`
- #strong[Hand-written justification:] 'It jumps from its space over any number of pieces (but at least one) to the next unoccupied space along a straight row of joined pieces.' (p.~6). The grasshopper touches occupied cells in exactly two of its six directions: SE (over wS1, landing in the next space, SE of wS1) and SW (over wQ, landing SW of wQ). In the other four directions the adjacent cell is empty, and a jump 'over at least one' piece is impossible - in particular the four adjacent empty cells are NOT destinations: the grasshopper 'does not move around the outside of the Hive like the other creatures'. Expected: exactly the two landing cells.

=== C010: Grasshopper jumps a full five-piece row to the first empty space
<c010-grasshopper-jumps-a-full-five-piece-row-to-the-first-empty-space>
- #strong[Rule:] Grasshopper (#emph[Gen42 Hive rulesheet p.~6];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 -wQ;bG1 bQ-`
- #strong[Expectation:] moves\_for\_piece `{'piece': 'wG1', 'moves': ['wG1 bG1-']}`
- #strong[Hand-written justification:] '…over any number of pieces (but at least one) to the next unoccupied space along a straight row of joined pieces.' (p.~6). Due east the grasshopper faces the unbroken row wQ, wS1, bS1, bQ, bG1; the first unoccupied space beyond it is the cell E of bG1 - the single destination. It must land there, not earlier (every nearer cell in the row is occupied). In all five other directions the adjacent cell is empty, so no jump exists. The grasshopper is a leaf of the hive, so One Hive does not restrict it.

=== C011: Queen's only open neighbour is behind a gate: zero moves
<c011-queens-only-open-neighbour-is-behind-a-gate-zero-moves>
- #strong[Rule:] Freedom to Move (#emph[Gen42 Hive rulesheet p.~10];)
- #strong[Setup:] `wS1;bS1 -wS1;wB1 wS1/;bQ -bS1;wQ wB1-;bG1 \bQ;wS2 wQ/;bA1 /bQ;wG1 -wS2;bS2 /bS1;wA1 wS2\;bB1 \bG1;wG2 wQ\;bG2 \bB1`
- #strong[Expectation:] moves\_for\_piece `{'piece': 'wQ', 'moves': []}`
- #strong[Hand-written justification:] 'Similarly, no piece may move into a space that it cannot physically slide into.' (p.~10). Five of the queen's six neighbours are white pieces; the sixth (the cell W of wG2, equally SE of wB1) is empty, but the two cells adjacent to both the queen and that space are wG2 and wB1 - both occupied - so the queen cannot physically slide in. Removing the queen leaves the white horseshoe wS1-wB1-wG1-wS2-wA1-wG2 connected (and the black chain hangs off wS1 via bS1), so One Hive would allow the move; the block is purely Freedom to Move. Expected: the queen has no legal move.

=== C012: Ant reaches every cell of the hive perimeter (13 destinations)
<c012-ant-reaches-every-cell-of-the-hive-perimeter-13-destinations>
- #strong[Rule:] Soldier Ant / Freedom to Move (#emph[Gen42 Hive rulesheet pp.~8, 10];)
- #strong[Setup:] `wG1;bS1 wG1-;wQ -wG1;bQ bS1-;wA1 \wQ;bG1 bQ-`
- #strong[Expectation:] moves\_for\_piece `{'piece': 'wA1', 'moves': ['wA1 -wQ', 'wA1 \\wG1', 'wA1 \\bS1', 'wA1 \\bQ', 'wA1 \\bG1', 'wA1 bG1/', 'wA1 bG1-', 'wA1 bG1\\', 'wA1 bQ\\', 'wA1 bS1\\', 'wA1 wG1\\', 'wA1 wQ\\', 'wA1 /wQ']}`
- #strong[Hand-written justification:] 'The Soldier Ant can move from its position to any other position around the Hive provided the restrictions are adhered to.' (p.~8). The hive minus the ant is a straight five-piece line; its boundary is a single 14-cell ring with no gates (every slide step is flanked by one line cell and one empty cell), and every ring cell touches the line. The ant starts on the ring at the cell NW of wQ, so it can stop on any of the other 13 ring cells: the west cap (W of wQ), the five north-shoulder cells (NW of each line piece plus NE of bG1), the east cap (E of bG1), and the six south-shoulder cells (SE of each line piece plus SW of wQ). Cells off the ring touch no piece and are excluded (p.~3 NB: pieces must always touch at least one other piece).

=== C013: Beetle on the ground: two slides and two climbs
<c013-beetle-on-the-ground-two-slides-and-two-climbs>
- #strong[Rule:] Beetle (#emph[Gen42 Hive rulesheet pp.~4-5, 10];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bG1 bQ-`
- #strong[Expectation:] moves\_for\_piece `{'piece': 'wB1', 'moves': ['wB1 wS1', 'wB1 wQ', 'wB1 \\bS1', 'wB1 \\wQ']}`
- #strong[Hand-written justification:] 'The Beetle, like the Queen Bee, moves only one space per turn. Unlike any other creature though, it can also move on top of the Hive.' (p.~4). From (NW of wS1) the beetle may climb onto either adjacent piece - wS1 or wQ - or slide along the ground to the two empty cells that keep contact with the hive: NW of bS1 (touching wS1 and bS1) and NW of wQ (touching wQ). The two remaining empty neighbours touch no piece after the beetle lifts, so they are excluded (p.~3 NB). No gate blocks any of the four moves (each is flanked by at most one occupied cell, and for the climbs the flanking stacks are not taller than the destination). Exactly four moves - matching the rulesheet's own beetle example count.

=== C014: Beetle on top of the hive: all six neighbouring cells
<c014-beetle-on-top-of-the-hive-all-six-neighbouring-cells>
- #strong[Rule:] Beetle (#emph[Gen42 Hive rulesheet p.~5; beetle-gate ruling, World Hive Tournaments Rules FAQ];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bG1 bQ-;wB1 wS1;bA1 bG1-`
- #strong[Expectation:] moves\_for\_piece `{'piece': 'wB1', 'moves': ['wB1 bS1', 'wB1 wQ', 'wB1 \\wS1', 'wB1 \\bS1', 'wB1 wS1\\', 'wB1 wQ\\']}`
- #strong[Hand-written justification:] 'From its position on top of the Hive, the Beetle can move from tile to tile across the top of the Hive. It can also drop into spaces that are surrounded and therefore not accessible to most other creatures.' (p.~5). Sitting on wS1, the beetle may move to every one of the six neighbouring cells: across onto bS1 or wQ (both height-1 stacks), or drop to any of the four empty cells around wS1 - each of which still touches wS1 itself, so contact holds. No pair of flanking stacks is taller than both origin (height 1 under the beetle) and destination, so no beetle gate applies (FAQ). One Hive cannot be violated: wS1 stays where it is. Exactly six destinations.

=== C015: Beetle gate: drop between two height-2 stacks is blocked
<c015-beetle-gate-drop-between-two-height-2-stacks-is-blocked>
- #strong[Rule:] Freedom to Move above ground level (beetle gate) (#emph[World Hive Tournaments Rules FAQ; Gen42 Hive rulesheet p.~10];)
- #strong[Setup:] `wS1;bG1 wS1/;wQ /wS1;bQ bG1/;wG1 wS1\;bB1 bQ/;wB1 -wS1;bB1 bQ;wB2 /wQ;bB1 bG1;wB1 wS1;bQ bB1-;wB2 wQ;bQ bB1/;wB2 wG1;bA1 bQ/`
- #strong[Expectation:] move\_illegal `{'move': 'wB1 bB1\\'}`
- #strong[Hand-written justification:] 'When a piece climbs up or down the hive, or moves staying on top of the hive, it must be able to slide according to the freedom to move rule which applies to higher levels than the ground. If two stacks form a gate above the ground level (we call it beetle gate), pieces won't be able to slide through.' (WHT Rules FAQ). wB1 sits on wS1 (its own level: on top of a height-1 piece); the target cell SE of the bB1 stack is empty (height 0). The two cells adjacent to both origin and target carry the stacks bG1+bB1 and wG1+wB2, both height 2 - strictly taller than both the origin without the beetle (1) and the destination (0) - so the beetle cannot slide down between them. The drop must be rejected. (One Hive would allow it: wS1 stays in place; contact holds via the flanking stacks.)

=== C016: A piece with a beetle on top of it cannot move
<c016-a-piece-with-a-beetle-on-top-of-it-cannot-move>
- #strong[Rule:] Beetle (stack immobility) (#emph[Gen42 Hive rulesheet p.~5];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bG1 bQ-;wB1 wS1;bA1 bG1-`
- #strong[Expectation:] move\_illegal `{'move': 'wS1 bS1\\'}`
- #strong[Hand-written justification:] 'A piece with a beetle on top of it is unable to move' (p.~5). wS1 lies under wB1, so any attempt to move wS1 - here a spider move towards the cell SE of bS1 - must be rejected, regardless of whether the path would otherwise be legal for a spider.

=== C017: Stack takes the beetle's colour: white may place beside a covered black queen
<c017-stack-takes-the-beetles-colour-white-may-place-beside-a-covered-black-queen>
- #strong[Rule:] Beetle (stack colour) / Placing (#emph[Gen42 Hive rulesheet pp.~2, 5];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bA1 bS1\;wB1 \bS1;bG1 bA1\;wB1 \bQ;bG2 bG1\;wB1 bQ;bB1 bG2\`
- #strong[Expectation:] move\_legal `{'move': 'wG1 wB1-'}`
- #strong[Hand-written justification:] '…for the purposes of the placing rules on p.~2, the stack takes on the colour of the Beetle.' (p.~5). White's beetle sits on the black queen at the east end of the hive. The cell E of that stack touches no other piece, so a white placement there is adjacent only to a stack whose colour is - by the rule - white. Placing wG1 there must be accepted. (Without the stack-colour rule the cell would be adjacent to a black piece and the placement would be illegal, p.~2.)

=== C018: Stack takes the beetle's colour: black may NOT place beside its own covered queen
<c018-stack-takes-the-beetles-colour-black-may-not-place-beside-its-own-covered-queen>
- #strong[Rule:] Beetle (stack colour) / Placing (#emph[Gen42 Hive rulesheet pp.~2, 5];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bA1 bS1\;wB1 \bS1;bG1 bA1\;wB1 \bQ;bG2 bG1\;wB1 bQ;bB1 bG2\;wG1 -wQ`
- #strong[Expectation:] move\_illegal `{'move': 'bB2 wB1-'}`
- #strong[Hand-written justification:] Mirror of C017: the stack bQ+wB1 counts as WHITE ('the stack takes on the colour of the Beetle', p.~5). The cell E of the stack touches only that stack, so for black it is adjacent to a white piece and 'pieces may not be placed next to a piece of the opponent's colour' (p.~2). Black's attempt to place bB2 there must be rejected - even though the buried piece is black's own queen.

=== C019: One Hive: the only connection between two parts may not move
<c019-one-hive-the-only-connection-between-two-parts-may-not-move>
- #strong[Rule:] One Hive rule (#emph[Gen42 Hive rulesheet pp.~3, 9];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-`
- #strong[Expectation:] moves\_for\_piece `{'piece': 'wS1', 'moves': []}`
- #strong[Hand-written justification:] 'All pieces must always touch at least one other piece. If a piece is the only connection between two parts of the Hive, it may not be moved.' (p.~3 NB); 'The pieces in play must be linked at all times. At no time can you leave a piece stranded (not joined to the Hive) or separate the Hive in two.' (p.~9). wS1 is the interior link between wQ on one side and bS1-bQ on the other: lifting it splits the hive, so the spider has no legal move at all - every destination, however valid as spider movement, is excluded by One Hive.

=== C020: Ring: a piece on a closed loop may move (not a cut point); the ring's eye is gated
<c020-ring-a-piece-on-a-closed-loop-may-move-not-a-cut-point-the-rings-eye-is-gated>
- #strong[Rule:] One Hive rule / Freedom to Move (#emph[Gen42 Hive rulesheet pp.~9, 10];)
- #strong[Setup:] `wS1;bS1 -wS1;wG1 wS1/;bQ -bS1;wQ wS1\;bG1 -bQ;wG2 wG1-;bG2 -bG1;wA1 wQ-;bA1 -bG2;wS2 wG2\;bB1 -bA1`
- #strong[Expectation:] moves\_for\_piece `{'piece': 'wQ', 'moves': ['wQ /wS1', 'wQ /wA1']}`
- #strong[Hand-written justification:] The six white pieces form a closed ring, so removing wQ leaves the other five connected around the loop (and the black tail hangs off wS1): One Hive permits the queen to move. Sliding one space (p.~4), the queen has three empty neighbours: the ring's eye and two outside cells. The eye is flanked by wS1 and wA1 - both occupied - so the queen 'may not move into a space that it cannot physically slide into' (p.~10). The two outside cells (SW of wS1, which touches wS1 and bS1; and SW of wA1, which touches wA1) are unobstructed slides keeping contact. Expected: exactly those two destinations.

=== C021: Game ends when a queen is fully surrounded - even by its own colour
<c021-game-ends-when-a-queen-is-fully-surrounded---even-by-its-own-colour>
- #strong[Rule:] The Object of Hive / The End of the Game (#emph[Gen42 Hive rulesheet pp.~1, 11];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 -wQ;bG1 bQ-;wA1 -wG1;bG2 bQ/;wA2 -wA1;bB1 \bQ;wA3 -wA2;bA1 bS1\;wS2 -wA3;bA2 bQ\`
- #strong[Expectation:] game\_over `{'state': 'WhiteWins'}`
- #strong[Hand-written justification:] 'The pieces surrounding the Queen Bee can be made up of a mixture of both your pieces and your opponent's.' (p.~1). 'The game ends as soon as one Queen Bee is completely surrounded by pieces of any colour. The person whose Queen Bee is surrounded loses the game.' (p.~11). Black's final placement (bA2, SE of its own queen) fills the sixth and last cell around bQ. The surrounding pieces are all black - irrelevant per p.~1 - and it is Black's own move that completes the surround: Black loses, the GameString state must read WhiteWins immediately after that move.

=== C022: One move surrounds both queens simultaneously: draw
<c022-one-move-surrounds-both-queens-simultaneously-draw>
- #strong[Rule:] The End of the Game (#emph[Gen42 Hive rulesheet p.~11];)
- #strong[Setup:] `wS1;bS1 wS1/;wQ wS1\;bB1 bS1-;wA1 -wQ;bQ bB1\;wS2 /wQ;bQ /bB1;wG1 -wS2;bQ wQ-;wB1 -wA1;bA1 bQ\;wG1 wS2-;bG1 \bS1;wB1 \wA1;bA2 bQ-;wB1 \wS1;bA3 bB1\;wG2 -wB1;bG1 bS1\`
- #strong[Expectation:] game\_over `{'state': 'Draw'}`
- #strong[Hand-written justification:] 'The person whose Queen Bee is surrounded loses the game, unless the last piece to surround their Queen Bee also completes the surrounding of the other Queen Bee. In that case the game is drawn.' (p.~11). Before Black's last move, each queen has exactly one empty neighbour - the same cell (1,0), adjacent to both queens (the queens sit side by side, wQ NE-shoulder wS1, bQ beside it). Black's grasshopper at (1,-2) jumps SE over bS1 into that cell, filling the sixth neighbour of both queens with a single piece: the game must end as a Draw, not a win for either side.

=== C023: A player who can neither place nor move must pass
<c023-a-player-who-can-neither-place-nor-move-must-pass>
- #strong[Rule:] Unable to move or place (#emph[Gen42 Hive rulesheet pp.~2, 5, 10, 11];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bQ bS1/;wA1 /wQ;bQ bS1-;wB1 \bS1;bQ bS1/;wB1 bS1;bQ wB1-;wA1 /bQ;bQ wB1/;wA2 /wQ;bQ wB1-;wA2 bQ\;bQ wB1/;wA3 /wQ;bQ wB1-;wA3 bQ-;bQ wB1/;wG1 /wB1;bQ wB1-;wG1 wB1/`
- #strong[Expectation:] must\_pass
- #strong[Hand-written justification:] 'If a player can neither place a new piece or move an existing piece, the turn passes to their opponent who then takes their turn again.' (p.~11). After White's final move Black has: bS1 under wB1 - 'a piece with a beetle on top of it is unable to move' (p.~5), and the stack counts as white for placing (p.~5); and bQ, whose five neighbours are the stack, wG1, wA1, wA2 and wA3, with its single empty neighbour reachable only between wG1 and wA3 - a gate the queen 'cannot physically slide into' (p.~10). No placement is possible either: the only cell adjacent to a black-topped piece is that same gated cell, which also touches white pieces (p.~2). Black is not lost - bQ has an empty neighbour, so it is not surrounded - but must pass.

=== C024: Pillbug special ability: moving an adjacent friendly piece (kernel guard)
<c024-pillbug-special-ability-moving-an-adjacent-friendly-piece-kernel-guard>
- #strong[Rule:] Pillbug special ability (#emph[Gen42 Pillbug rulesheet (English section)];)
- #strong[Setup:] `wP;bS1 wP-;wQ -wP;bQ bS1-`
- #strong[Expectation:] move\_legal `{'move': 'wQ wP\\'}`
- #strong[Hand-written justification:] 'The special ability allows the Pillbug to move an adjacent piece (friend or enemy) two spaces; up onto itself and then down into another empty space adjacent to itself.' (Pillbug rulesheet). wQ is adjacent to wP; the target cell SE of wP is empty and adjacent to wP. None of the four exceptions applies: wQ was not just moved by the other player (Black's last move was placing bQ), wQ is not in a stack, removing wQ does not split the hive (it is a leaf), and no stacked pieces form a gap on the up-and-over path. NOTE: this is a variant-tagged kernel-guard case (protocol §2) - the study variant is base game; Pillbug cases only protect the shared rules kernel.

=== C025: A piece just moved by the enemy pillbug is stunned for one turn (kernel guard)
<c025-a-piece-just-moved-by-the-enemy-pillbug-is-stunned-for-one-turn-kernel-guard>
- #strong[Rule:] Pillbug special ability (immobility of the moved piece) (#emph[Gen42 Pillbug rulesheet (English section); World Hive Tournaments Rules FAQ];)
- #strong[Setup:] `wS1;bP wS1-;wQ -wS1;bQ bP-;wA1 \wQ;bG1 bQ-;wA1 \bP;bG1 -wQ;wG1 -wA1;wA1 bP\`
- #strong[Expectation:] move\_illegal `{'move': 'wA1 bP/'}`
- #strong[Hand-written justification:] 'Furthermore, any piece moved by the Pillbug may not be moved at all (directly or via Pillbug action) on the next player's turn.' (Pillbug rulesheet); FAQ: 'any piece that just moved, in the turn of the other player immediately after is unable to: move, be moved or use the pillbug's ability.' Black's pillbug just threw wA1 up over itself and down to the cell SE of bP (a legal use: wA1 last moved two plies earlier, so the just-moved exception did not block the throw; removing it kept the hive whole since wG1 also touches wS1 and wQ). On White's very next turn the thrown ant is stunned: the attempted ant move to NE of bP must be rejected. Variant-tagged kernel-guard case (protocol §2).

=== C026: Pillbug may not move the piece the opponent just moved (kernel guard)
<c026-pillbug-may-not-move-the-piece-the-opponent-just-moved-kernel-guard>
- #strong[Rule:] Pillbug special ability (exceptions) (#emph[Gen42 Pillbug rulesheet (English section)];)
- #strong[Setup:] `wS1;bP wS1-;wQ -wS1;bQ bP-;wA1 \wQ;bG1 bQ-;wA1 \bP`
- #strong[Expectation:] move\_illegal `{'move': 'wA1 bP\\'}`
- #strong[Hand-written justification:] 'The Pillbug may not move the piece which was just moved by the other player.' (Pillbug rulesheet, first exception). White's ant moved to the cell NW of bP on the immediately preceding ply; Black's attempt to use the pillbug's ability on that same ant - throwing it to SE of bP - must be rejected. (The identical throw becomes legal two plies later, which is case C025's setup.) Variant-tagged kernel-guard case (protocol §2).

=== C027: One Hive binds even the grasshopper: a cut-point cannot jump
<c027-one-hive-binds-even-the-grasshopper-a-cut-point-cannot-jump>
- #strong[Rule:] One Hive rule / Grasshopper (#emph[Gen42 Hive rulesheet pp.~3, 6, 9];)
- #strong[Setup:] `wG1;bS1 wG1-;wQ -wG1;bQ bS1-`
- #strong[Expectation:] moves\_for\_piece `{'piece': 'wG1', 'moves': []}`
- #strong[Hand-written justification:] The grasshopper is exempt from the sliding restriction (p.~10: it 'can jump into or out of a space'), but not from One Hive: 'If a piece is the only connection between two parts of the Hive, it may not be moved.' (p.~3 NB). wG1 sits between wQ and the black pair; lifting it for any jump splits the hive in two, so despite having jump lines in both E and W directions the grasshopper has no legal move.

=== C028: A beetle cannot be PLACED directly on top of the hive
<c028-a-beetle-cannot-be-placed-directly-on-top-of-the-hive>
- #strong[Rule:] Beetle (placement NB) (#emph[Gen42 Hive rulesheet p.~5];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-`
- #strong[Expectation:] move\_illegal `{'move': 'wB1 wS1'}`
- #strong[Hand-written justification:] 'When it is first placed, the Beetle is placed in the same way as all the other pieces. It cannot be placed directly on top of the Hive, even though it can be moved there later.' (p.~5 NB). wB1 is still in hand; the attempt to introduce it on top of wS1 must be rejected. (C013/C014 verify that the same beetle may climb there by a move once placed.)

=== C029: Spider may not stop after one step ('no more, no less')
<c029-spider-may-not-stop-after-one-step-no-more-no-less>
- #strong[Rule:] Spider (#emph[Gen42 Hive rulesheet p.~7];)
- #strong[Setup:] `wG1;bS1 wG1-;wQ -wG1;bQ bS1-;wS1 \wQ;bG1 bQ-`
- #strong[Expectation:] move\_illegal `{'move': 'wS1 \\wG1'}`
- #strong[Hand-written justification:] 'The Spider moves three spaces per turn - no more, no less.' (p.~7). The cell NW of wG1 is exactly one sliding step from the spider's position, and no legal three-step non-backtracking path ends there (the two three-step walks end NE of bS1 and SE of wQ - case C008); a path through that cell passes it at step one and may not stop. The one-step move must be rejected.

=== C030: Queen between two pieces: two slides along the shoulder
<c030-queen-between-two-pieces-two-slides-along-the-shoulder>
- #strong[Rule:] Queen Bee / One Hive / Freedom to Move (#emph[Gen42 Hive rulesheet pp.~4, 9, 10];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bG1 bQ-`
- #strong[Expectation:] moves\_for\_piece `{'piece': 'wQ', 'moves': ['wQ -wB1', 'wQ /wS1']}`
- #strong[Hand-written justification:] The queen touches wS1 (E) and wB1 (NE). Removing her keeps the hive whole (wB1 still touches wS1), so One Hive allows a move. One-space slides (p.~4): of her four empty neighbours, only the cell W of wB1 (keeping contact with wB1) and the cell SW of wS1 (keeping contact with wS1) still touch the hive after she lifts; the two far-western cells touch nothing and are excluded (p.~3 NB). Neither slide is gated (each flanked by exactly one occupied cell). Expected: exactly those two destinations.

== Tactical verification set (5 cases)
<tactical-verification-set-5-cases>
Search-correctness cases: mate-in-1 by walk and by jump from both colours, and self-surround avoidance; solved 5/5 by the MCTS baseline at 400, 1600 and 6400 simulations.

=== T001: White mates in 1: occupy the black queen's last liberty (SE of bQ)
<t001-white-mates-in-1-occupy-the-black-queens-last-liberty-se-of-bq>
- #strong[Rule:] The End of the Game (#emph[Gen42 Hive rulesheet pp.~1, 11];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 -wQ;bG1 bQ-;wA1 -wG1;bG2 bQ/;wA2 -wA1;bB1 \bQ;wA3 -wA2;bA1 bS1\`
- #strong[Expectation:] bestmove\_to\_cell `{'target': 'bQ\\'}`
- #strong[Hand-written justification:] The black queen has exactly one empty neighbour, the cell SE of bQ. Any white piece landing there completes the surround and wins immediately ('the game ends as soon as one Queen Bee is completely surrounded by pieces of any colour', p.~11; mixture of colours allowed, p.~1). The cell is reachable: a white ant can walk the south perimeter in one move (entry past bA1 is not gated), so a winning move exists. No other single move ends the game. The searcher must play onto that cell.

=== T002: Black mates in 1: occupy the white queen's last liberty (SE of wQ)
<t002-black-mates-in-1-occupy-the-white-queens-last-liberty-se-of-wq>
- #strong[Rule:] The End of the Game (#emph[Gen42 Hive rulesheet pp.~1, 11];)
- #strong[Setup:] `wS1;bS1 -wS1;wQ wS1-;bQ -bS1;wG1 wQ-;bG1 -bQ;wG2 wQ/;bG2 -bG1;wB1 \wQ;bA1 -bG2;wA1 wS1\;bA2 -bA1;wA2 wG1-`
- #strong[Expectation:] bestmove\_to\_cell `{'target': 'wQ\\'}`
- #strong[Hand-written justification:] Mirror of T001 with the colours exchanged and black to move. This pair is the player-alternation check at the move level: the winning pattern must be found from both sides. The white queen's only empty neighbour is the cell SE of wQ; a black ant reaches it along the south perimeter (route via SE of bS1's column: the step into the cell is flanked by the occupied wA1 cell, so contact holds and no gate blocks). Landing there completes the surround: Black wins (p.~11).

=== T003: White mates in 1 by grasshopper jump over four pieces (E of bQ)
<t003-white-mates-in-1-by-grasshopper-jump-over-four-pieces-e-of-bq>
- #strong[Rule:] Grasshopper / The End of the Game (#emph[Gen42 Hive rulesheet pp.~6, 11];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 -wQ;bG1 bQ/;wA1 \wQ;bB1 \bQ;wA2 \wA1;bA1 bS1\;wA3 \wA2;bA2 bQ\`
- #strong[Expectation:] bestmove\_to\_cell `{'target': 'bQ-'}`
- #strong[Hand-written justification:] The black queen's only empty neighbour is the cell E of bQ. Due east from wG1 at the west cap runs the unbroken occupied row wQ, wS1, bS1, bQ; the next unoccupied space along that row is exactly the winning cell, so the grasshopper jumps over four pieces and completes the surround (p.~6: 'over any number of pieces … to the next unoccupied space along a straight row of joined pieces'; p.~11: surround ends the game). White ants can also walk in around the perimeter; the expectation is the destination cell, whichever piece the searcher sends.

=== T004: Black mates in 1 by grasshopper jump over four pieces (W of wQ)
<t004-black-mates-in-1-by-grasshopper-jump-over-four-pieces-w-of-wq>
- #strong[Rule:] Grasshopper / The End of the Game (#emph[Gen42 Hive rulesheet pp.~6, 11];)
- #strong[Setup:] `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 \wQ;bG1 bQ-;wG2 \wS1;bA1 bQ\;wA1 wQ\;bA2 bA1\;wA2 /wQ;bA3 bA2\;wB1 \wG1`
- #strong[Expectation:] bestmove\_to\_cell `{'target': '-wQ'}`
- #strong[Hand-written justification:] Alternation mirror of T003 with black jumping. The white queen's neighbours: E wS1, NW wG1 (placed NW of wQ), NE wG2 (placed NW of wS1 = NE of wQ), SE wA1, SW wA2. Five are occupied; only W of wQ is empty. Due east of that gap runs the unbroken row wQ, wS1, bS1, bQ with bG1 at the east cap (3,0): from bG1 the next unoccupied space westward along the row is exactly the gap, so the grasshopper jumps over four pieces and completes the surround (pp.~6, 11). Black's southern tail (bA1..bA3 SE of bG1) keeps black's earlier placements legal and away from white.

=== T005: Do not fill your own queen's last liberty
<t005-do-not-fill-your-own-queens-last-liberty>
- #strong[Rule:] The End of the Game (#emph[Gen42 Hive rulesheet p.~11];)
- #strong[Setup:] `wS1;bS1 -wS1;wQ wS1-;bQ -bS1;wG1 wQ-;bG1 -bQ;wG2 wQ/;bG2 -bG1;wB1 \wQ;bA1 -bG2;wA1 wS1\;bA2 -bA1`
- #strong[Expectation:] bestmove\_avoid\_cell `{'target': 'wQ\\'}`
- #strong[Hand-written justification:] The cell SE of wQ is the white queen's last liberty. White placing or moving any piece there completes the surround of White's own queen: 'the person whose Queen Bee is surrounded loses the game' (p.~11) regardless of who supplied the sixth piece. The placement is perfectly legal (the cell touches only white pieces), so only search judgment prevents it. Any move except one landing on that cell passes; the searcher must not play into it. (This does not assert White survives long-term, since black threatens the same cell; it asserts only that the immediate self-kill is avoided.)

= Architectures, decoder and data formats in detail
<sec:app-b>
This appendix complements @sec:representations with layer-by-layer tables of the two networks and their ablation variants, the exact arithmetic of the shared action decoder, the tensor interface of the graph arm, the byte layout of the self-play record, and the search settings shared by both arms. Parameter totals are the values measured by the training code's parameter counter and were re-verified for this appendix; per-layer counts were not separately recorded, so the tables give shapes and widths only.

== HiveNet, the grid network
<hivenet-the-grid-network>
The input is a tensor of 77 planes × 32 × 32 with float32 values in \[0, 1\] (@tbl:grid-planes). The body and heads are listed in @tbl:hivenet-layers. Hex adjacency on axial coordinates is a 7-cell subset of the 3 × 3 neighbourhood, so the 3 × 3 kernels cover it with two learnable dead corners per kernel.

#figure(
  align(center)[#table(
    columns: (17.92%, 34.07%, 15.27%, 32.74%),
    align: (left,left,left,left,),
    table.header([Stage], [Operation], [Width], [Notes],),
    table.hline(),
    [Input], [77 planes × 32 × 32], [77], [float32 in \[0, 1\]],
    [Stem], [Conv 3 × 3 (no bias), BatchNorm, ReLU], [77 → 96], [padding 1],
    [Block 0], [Conv 3 × 3, BatchNorm, ReLU; Conv 3 × 3, BatchNorm; residual add; ReLU], [96 → 96], [convolutions without bias],
    [Block 1], [as block 0], [96 → 96], [],
    [Block 2], [as block 0, plus a global-pooling bias after the second BatchNorm], [96 → 96], [mean ‖ max over the frame (2 × 96) → linear → 96, added per channel],
    [Block 3], [as block 0], [96 → 96], [],
    [Block 4], [as block 0], [96 → 96], [],
    [Block 5], [as block 2], [96 → 96], [global-pooling bias],
    [Block 6], [as block 0], [96 → 96], [],
    [Block 7], [as block 0], [96 → 96], [],
    [Pooling], [mean over the 32 × 32 frame], [96], [feeds the pass logit and the value head],
    [Policy, spatial], [Conv 1 × 1 (with bias)], [96 → 28], [flattened to 28 × 1024 = 28,672 logits, index slot × 1024 + y × 32 + x],
    [Policy, pass], [Linear on the pooled features], [96 → 1], [appended as index 28,672],
    [Value], [Linear, ReLU, Linear on the pooled features], [96 → 64 → 3], [win / draw / loss logits from the side to move],
    [Total], [], [], [1.44 M parameters],
  )]
  , caption: [HiveNet, the grid arm's network, layer by layer. Blocks are numbered from 0 as in the implementation; the two global-pooling blocks are the ones at one third and two thirds of the depth. Widths are channel counts; the total is the measured parameter count.]
  , kind: table
  ) <tbl:hivenet-layers>

== HiveGraphNet, the graph network
<hivegraphnet-the-graph-network>
The graph arm's network consumes fixed-shape tensors (@tbl:graph-tensors) built from one record by the Python builder for training and by its Rust mirror for inference. Node and global feature layouts are given in @tbl:graph-node-features and @tbl:graph-globals; the body and heads are listed in @tbl:hivegraphnet-layers, and the ablation variants in @tbl:graph-variants.

#figure(
  align(center)[#table(
    columns: (21.9%, 16.15%, 17.48%, 44.47%),
    align: (left,left,left,left,),
    table.header([Tensor], [Shape], [Type], [Content],),
    table.hline(),
    [nodes], [224 × 56], [float32], [node features, zero-padded beyond the real nodes],
    [neighbours], [224 × 6], [int64], [index of the neighbour in each hex direction; 224 = none],
    [node mask], [224], [bool], [1 for a real node],
    [globals], [23], [float32], [global features],
    [moves], [321 × 3], [int64], [(slot, destination node, source node) per legal move; source = 224 for placements and pass; the pass row uses slot 28],
    [move mask], [321], [bool], [1 for a legal row],
    [target], [321], [float32], [visit distribution over the legal rows (training only)],
    [outcome], [scalar], [int64], [0 loss / 1 draw / 2 win / 3 truncated, from the side to move (training only)],
  )]
  , caption: [Tensor interface of the graph arm, per position. Capacities: 224 nodes (occupied cells plus the empty ring) and 321 move rows (320 legal moves, the record's cap, plus one pass row); exceeding either capacity raises an error rather than truncating. Node order is deterministic: occupied cells first, then ring cells, each sorted by (y, x) in frame coordinates.]
  , kind: table
  ) <tbl:graph-tensors>

#figure(
  align(center)[#table(
    columns: (17.7%, 34.73%, 14.16%, 33.41%),
    align: (left,left,left,left,),
    table.header([Stage], [Operation], [Width], [Notes],),
    table.hline(),
    [Input], [node features ‖ broadcast globals], [56 + 23], [per node],
    [Input linear], [Linear], [56 + 23 → 152], [masked to real nodes; a zero row at index 224 stands in for absent neighbours],
    [Layer 0], [relational layer: $W_(upright(s e l f))$ (with bias) + six $W_d$ (no bias); residual; ReLU; mask], [152 → 152], [@eq:relayer],
    [Layer 1], [as layer 0], [152 → 152], [],
    [Layer 2], [as layer 0, plus a global-pooling bias inside the non-linearity], [152 → 152], [masked mean ‖ masked max (2 × 152) → linear → 152, added to every node],
    [Layer 3], [as layer 0], [152 → 152], [],
    [Layer 4], [as layer 0], [152 → 152], [],
    [Layer 5], [as layer 2], [152 → 152], [global-pooling bias],
    [Layer 6], [as layer 0], [152 → 152], [],
    [Layer 7], [as layer 0], [152 → 152], [],
    [Readout], [masked mean ‖ masked max over the real nodes], [2 × 152], [],
    [Value], [Linear, ReLU, Linear on readout ‖ globals], [2 × 152 + 23 → 64 → 3], [win / draw / loss logits from the side to move],
    [Slot embedding], [embedding table], [28 piece slots + pass → 32], [],
    [Reserve vector], [learned vector], [152], [source embedding for placements and for the pass row],
    [Policy], [Linear, ReLU, Linear per move row on destination ‖ source ‖ slot], [2 × 152 + 32 → 128 → 1], [illegal rows filled with a large negative constant before the softmax],
    [Total], [], [], [1.47 M parameters],
  )]
  , caption: [HiveGraphNet, the graph arm's network, layer by layer. Layers are numbered from 0 as in the implementation; the pooling layers are every third layer. Widths are channel counts; the total is the measured parameter count.]
  , kind: table
  ) <tbl:hivegraphnet-layers>

#figure(
  align(center)[#table(
    columns: (30.4%, 47.8%, 21.81%),
    align: (left,left,right,),
    table.header([Variant], [Difference from the full graph arm], [Parameters],),
    table.hline(),
    [Full graph arm], [none], [1.47 M],
    [Untyped edges], [one shared matrix for the six directions, in every layer], [0.54 M],
    [No global pooling], [no pooling bias in any layer], [1.37 M],
    [Untyped edges + gradient clipping (supplement)], [one shared matrix for the six directions, plus a global gradient-norm clip of 1.0 during training (a two-component difference)], [0.54 M],
  )]
  , caption: [The graph-network variants used in the ablations, with their measured parameter counts in millions. The encoder, the decoder, the training settings, the budgets and the evaluation settings are identical across variants; only the named component changes.]
  , kind: table
  ) <tbl:graph-variants>

== The shared action decoder in detail
<the-shared-action-decoder-in-detail>
#strong[Slots.] A piece is addressed by a side-to-move-relative slot (@tbl:decoder-slots): the mover's pieces in roster order, then the opponent's. In the base game, which has 11 pieces per side, only the mover's first 11 slots can ever be legal; the expansion slots and all opponent slots exist for kernel uniformity (the Pillbug expansion moves enemy pieces) and remain inert. Bug types are coded 0--7 in the order Q, S, B, G, A, M, L, P; this code indexes the piece planes of the grid encoding (bug type × 4) and the one-hot block of the graph encoding.

#figure(
  align(center)[#table(
    columns: (17.48%, 31.42%, 19.47%, 31.64%),
    align: (left,left,left,left,),
    table.header([Slot], [Mover's piece], [Slot], [Opponent's piece],),
    table.hline(),
    [0], [Queen], [14], [Queen],
    [1--2], [Spiders], [15--16], [Spiders],
    [3--4], [Beetles], [17--18], [Beetles],
    [5--7], [Grasshoppers], [19--21], [Grasshoppers],
    [8--10], [Ants], [22--24], [Ants],
    [11], [Mosquito], [25], [Mosquito],
    [12], [Ladybug], [26], [Ladybug],
    [13], [Pillbug], [27], [Pillbug],
  )]
  , caption: [Piece slots of the shared action decoder. Slot 28 is the pass slot in the graph arm's move rows; the grid arm's pass is flat index 28,672.]
  , kind: table
  ) <tbl:decoder-slots>

#strong[Flat index (grid arm).] With $(x \, y)$ the destination's frame coordinates, the policy index is $upright("slot") times 1024 + y times 32 + x$; pass is index 28,672 and the vector has 28,673 entries. The same index is what records store, for the played move and for every entry of the visit distribution and of the legal list.

#strong[Per-candidate rows (graph arm).] Each legal index from the record is decoded into a move row: slot = index div 1024; remainder = index mod 1024; $x$ = remainder mod 32, $y$ = remainder div 32; the destination node is the index of cell $(x \, y)$ in the candidate-set ordering; the source node is the standing node of the piece if it is on the board, and the reserve sentinel 224 otherwise; the pass index becomes the row (28, 224, 224). The identity encode → index → decode on all legal moves across game types is the second of the seven automated pre-training checks.

#strong[Shared properties.] Masking: the softmax runs over exactly the legal set (plus pass when legal), implemented as a fill of illegal entries with a large negative constant in both training loops and as a softmax over the legal rows in both inference evaluators; the first automated check asserts zero illegal mass through a real forward pass. Order independence: scores attach to (slot, destination) pairs, never to list positions. Tiebreak: argmax ties break toward the lowest flat index in both arms. Targets: the top 15 (index, visit weight) entries of the root visit distribution, normalised over their support; when every stored weight is zero the target falls back to the played move. Value: a win/draw/loss head trained with truncated records excluded; the search consumes P(win) − P(loss) from the side to move, with terminal values +1, −1 and 0.

== Record format
<record-format>
Self-play positions are written as fixed-size little-endian records in shards that begin with a 16-byte header (8 magic bytes identifying the format version, 8 reserved). The format evolved in three versions: 112 bytes with a one-hot played-move target; 176 bytes adding the top-15 visit distribution; and the study's 818-byte version 3 adding the generating-model stamp and the legal-move index list, which is what enables legal-masked training in both arms. Only version-3 records are study inputs. @tbl:record-layout gives the layout.

#figure(
  align(center)[#table(
    columns: (18.81%, 38.5%, 42.7%),
    align: (left,left,left,),
    table.header([Bytes], [Field], [Encoding],),
    table.hline(),
    [0--83], [28 pieces × (x, y, level)], [one byte each, frame coordinates, absolute piece order; x = 255 means in hand],
    [84], [side to move], [0 white, 1 black],
    [85], [last-moved piece], [piece id; 255 = none (stun state)],
    [86], [ply], [clamped at 255],
    [87], [game-type bits], [1 = M, 2 = L, 4 = P],
    [88, 89], [queen liberties (mover, opponent)], [255 = queen not placed],
    [90, 91], [reserve counts (mover, opponent)], [],
    [92--95], [one-hive-pinned bitmask], [32-bit, one bit per piece id],
    [96--97], [played-move policy index], [16-bit flat index],
    [98], [outcome from the mover's perspective], [0 loss / 1 draw / 2 win / 3 truncated (never a draw)],
    [99], [record version], [3],
    [100--107], [generating-model stamp], [generation (32-bit) then network hash (32-bit); 0 = unstamped],
    [up to 112], [reserved], [zero],
    [112--175], [root visit distribution], [15 × (policy index 16-bit, visit weight 16-bit), then total stored visits (32-bit)],
    [176--177], [legal-move count], [16-bit; 0xFFFF = list unavailable (overflow)],
    [178--817], [legal policy-index list], [16-bit × 320 (cap; measured maximum branching 213); unused slots zero],
  )]
  , caption: [Byte layout of the version-3 self-play record (818 bytes, little-endian). "Mover" is the side to move at the recorded position.]
  , kind: table
  ) <tbl:record-layout>

Both arms read the same record. The grid arm decodes the 77 planes from it; the graph arm builds the cell graph from it; both take their policy target from bytes 112--175, their legal mask from bytes 176--817, and their outcome from byte 98. The Rust writer and the Python readers of the planes and of the graph tensors are pinned byte-identical by the nightly cross-language golden tests over 240 and 160 positions respectively.

== Search settings
<search-settings>
#figure(
  align(center)[#table(
    columns: (23.18%, 41.28%, 35.54%),
    align: (left,left,left,),
    table.header([Setting], [Self-play (training data)], [Independent evaluation],),
    table.hline(),
    [Search], [PUCT Monte-Carlo tree search, c = 1.4, batched leaf evaluation, terminal values backed up exactly], [same],
    [Simulations per decision], [128 on 25 % of decisions (recorded), 32 on the other 75 % (unrecorded); playout-cap randomization], [400],
    [Dirichlet root noise], [ε = 0.25], [0 (the code default, asserted by a test; the engine binary exposes no noise flag)],
    [Move selection], [temperature sampling for the first 12 plies, then argmax], [deterministic argmax],
    [Resignation], [below −0.92, with 10 % of games never resigning (audit)], [not part of the pinned settings],
    [Ply cap], [300; a capped game is recorded as truncated, never as a draw], [300; truncation reported separately],
    [Openings], [none], [4 opening plies, paired colour-swapped, shared opening identifiers across all runs and arms],
    [Inference provider], [each arm's best: CoreML for the grid arm, CPU for the graph arm], [same],
  )]
  , caption: [Search settings shared by both arms. Self-play settings come from the frozen protocol; evaluation settings were pinned by configuration on 9 September 2026, before any training run, and any later change would count as a new study.]
  , kind: table
  ) <tbl:search-settings>

The exploration machinery is structurally confined to self-play: the evaluation path's defaults carry ε = 0 and no temperature, a test asserts those defaults, and the engine binary exposes no flag to enable noise, so the evaluation route cannot opt into it. Self-play opts into noise explicitly. The two paths therefore differ by construction rather than by convention.

= Frozen constants, hyperparameters, seeds and configurations
<sec:app-c>
Every value in this appendix is the one the campaigns actually ran; the configuration and manifest files kept with each run are authoritative, and nothing here is a recommendation. Dates are those of the author's approval or of the mechanical computation that fixed a value; @sec:app-e indexes the corresponding records, and @sec:protocol explains why each value was fixed when it was.

== Frozen constants
<sec:app-c-constants>
#figure(
  align(center)[#table(
    columns: (19.43%, 35.76%, 24.94%, 19.87%),
    align: (left,left,left,left,),
    table.header([Constant], [Value], [Fixed on (2026)], [Approved by],),
    table.hline(),
    [Game variant], [base game (queen, spider, beetle, grasshopper, ant), tournament opening rule; expansions outside the perimeter], [9 Sep (scope); frozen in the protocol 10 Sep], [the author],
    [Move cap and truncation], [300 plies; a truncated game is its own outcome, never a draw; rate reported separately], [9 Sep (convention and measured value); frozen 10 Sep], [the author],
    [Self-play search budget], [128 full / 32 cheap simulations per decision; full fraction 0.25], [10 Sep (protocol)], [the author],
    [Self-play exploration], [temperature sampling for 12 plies; Dirichlet root noise ε = 0.25; resignation at −0.92 with a 10% no-resign audit], [10 Sep (pre-registered matrix)], [the author],
    [Evaluation search], [400 simulations per decision; no root noise; deterministic argmax], [9 Sep], [the author],
    [Evaluation volume], [100 paired games per opponent at final and cutoff checkpoints; 20 per opponent at generations 4 and 7], [10 Sep; confirmed unchanged 16 Sep], [the author],
    [Opponent population], [B-RND (legal-random), B-HEU (heuristic, weights hash-pinned), B-MCTS (search, 6,400 simulations); prior checkpoint excluded], [9 Sep], [the author],
    [Openings], [250 unique legal 4-ply openings; generator seed 20260910; pair #emph[i] plays line #emph[i] with both colours], [10 Sep], [the author],
    [Equal-time cutoff], [18.77 h = median total wall-clock of the three original grid runs; rule in the matrix], [rule 10 Sep; value 16 Sep], [rule: the author; value: computed mechanically],
    [Training seeds], [1--3 per arm; 4--5 added under three written pre-commitments], [10 Sep; extension 26 Sep], [the author],
    [Protocol document], [version 1.0; any later change is a new study], [10 Sep], [the author],
  )]
  , caption: [Frozen experimental constants with the date each was fixed and the approval under which it was fixed. No constant was changed after its date. ]
  , kind: table
  ) <tbl:app-c-frozen>

Frozen artifacts are identified by content hash (@tbl:app-c-hashes). The protocol file carried its hash at the freeze and carries it unchanged; the openings hash covers the 250 opening lines independently of the file header; the heuristic weights are additionally pinned by an automated test that fails if any weight changes.

#figure(
  align(center)[#table(
    columns: (32.45%, 67.55%),
    align: (left,left,),
    table.header([Artifact], [SHA-256],),
    table.hline(),
    [Protocol, version 1.0], [f340a6b64db0f5f0bf126ffb​251c3de339450bde192fd54b​719036a8a3aefeb5],
    [Openings, content (250 lines)], [63b318d071dfc3ecfae35856​36c8e6f7327ddc08e7aed86a​466f915f8005af7b],
    [Heuristic weights (B-HEU)], [d0602f1895fbed70b6f84ac2​a3eb87bd68e811e53acf24d4​d7814a1495b0b97a],
    [B-RND configuration], [f2fc4a06441d3c1a7922838a​6693dbb48ec54543bc34fd81​4d41c9a742514cd7],
    [B-HEU configuration], [7210a0a349c5bad5dcd2df09​9cc6865ee3cb5d8a2c30e106​ce58137804818999],
    [B-MCTS configuration], [3fc8f75cf2b4f21012dd61e9​924408fbfc32c8ea561aa96e​b44f1091ba07364e],
  )]
  , caption: [Content hashes of the frozen artifacts; these are the scientific identifiers of the protocol, the openings and the opponent population. ]
  , kind: table
  ) <tbl:app-c-hashes>

== Training hyperparameters
<sec:app-c-hyper>
The training loop and every hyperparameter are identical for both arms and for all ablation variants, with the single exception noted in the last row.

#figure(
  align(center)[#table(
    columns: (37.09%, 62.91%),
    align: (left,left,),
    table.header([Hyperparameter], [Value (both arms)],),
    table.hline(),
    [Optimizer], [SGD, momentum 0.9, weight decay 1e-4],
    [Learning rate], [0.02, cosine-annealed to lr/100 over each generation's steps],
    [Batch size], [256],
    [Epochs per generation], [2],
    [Policy loss], [cross-entropy against the MCTS visit distribution, softmax over exactly the legal move set],
    [Value loss], [win/draw/loss from the side to move, weight 0.6; truncated records excluded],
    [Training data per generation], [the generation's 500 self-play games; only full-budget (128-simulation) decisions are recorded],
    [Gradient clipping], [none, except in the A1′ supplement (global norm 1.0)],
    [Hyperparameter search], [none, for either arm],
  )]
  , caption: [Training hyperparameters, identical for the grid arm, the graph arm and the ablation variants; the gradient clip of the A1′ supplement is the only optimizer change in the study. ]
  , kind: table
  ) <tbl:app-c-hyper>

== Seed derivation
<sec:app-c-seeds>
Every random choice in the study descends from a recorded seed, so that a run, an evaluation set or a bootstrap interval regenerates identically.

#figure(
  align(center)[#table(
    columns: (31.13%, 68.87%),
    align: (left,left,),
    table.header([Quantity], [Seed],),
    table.hline(),
    [Training run (arm, seed #emph[s];)], [base seed = 100,000 × #emph[s];; seed spaces disjoint across runs],
    [Generation #emph[g] (0--9)], [self-play seed = base + #emph[g];; training seed = base + #emph[g];],
    [Generation-0 network], [seeded random initialisation with the base seed, exported before any self-play],
    [Network under evaluation], [9000 + #emph[g] for in-run evaluations (generations 4, 7 and 9); 9500 for cutoff-checkpoint sets],
    [Opponents], [B-RND 9101; B-MCTS 9201; B-HEU deterministic (no seed)],
    [Match runner], [777,000 + #emph[g] for in-run evaluations; 888,000 for cutoff sets; with fixed openings the opening/colour schedule is seed-independent (schedule hash 8cd84b6564440666 reproduced across runs with different agents and match seeds)],
    [Opening generator], [20260910],
    [Bootstrap], [fixed resampling seed; 10,000 resamples],
  )]
  , caption: [Derivation of every seed used in training, evaluation and analysis. ]
  , kind: table
  ) <tbl:app-c-seeds>

== Configuration of each arm and variant
<sec:app-c-configs>
All five configurations share the frozen constants of @tbl:app-c-frozen and the hyperparameters of @tbl:app-c-hyper; they differ only as stated in the table. Parameter counts are exact counts from the instantiated models; the +1.5% capacity difference between the arms is the exact ratio. Capacity differences in the ablation variants are inherent to the removed component and are reported rather than equalised.

#figure(
  align(center)[#table(
    columns: (18.06%, 25.33%, 15.64%, 17.84%, 9.25%, 13.88%),
    align: (left,left,right,left,left,left,),
    table.header([Variant], [Body], [Parameters], [Difference from the full graph arm], [Seeds], [Inference provider],),
    table.hline(),
    [Grid arm], [residual CNN, 96 channels × 8 blocks, over 77 planes × 32 × 32], [1,443,168], [not applicable (the other arm)], [1--5], [CoreML],
    [Graph arm (full method)], [relational message passing, 152 hidden × 8 layers, slot embedding 32, node capacity 224, six direction-typed relations, global-pooling bias], [1,465,452 (+1.5%)], [reference], [1--5], [CPU],
    [A1 (naive adjacency)], [one shared edge matrix in place of the six direction-typed matrices], [541,292 (−62.5%)], [edge typing removed], [1--3], [CPU],
    [A2 (no global pooling)], [global-pooling bias removed from every layer], [1,372,732 (−4.9%)], [pooling removed], [1--3], [CPU],
    [A1′ (supplement)], [as A1 plus global gradient-norm clip 1.0], [as A1], [two components: edge typing removed and clip added], [1--3], [CPU],
  )]
  , caption: [Configuration of the two arms and the three ablation variants, with exact parameter counts and the difference relative to the grid arm in parentheses. Everything not listed is identical across the five rows. The inference provider is the measured best available per arm on the study machine. ]
  , kind: table
  ) <tbl:app-c-configs>

== Measured machine profile
<sec:app-c-machine>
All wall-clock figures in this report were measured on one Apple M1 Pro (10 cores, 16 GB, macOS 15.3.1), with 4 worker threads per run, runs executed sequentially and the machine kept awake. The inference provider used for each arm's self-play and evaluation is the measured best available on this machine; the graph network's gather-heavy operations are only partly supported by the accelerator (147 of 287 nodes, 15 partitions), which is why its CPU path wins.

#figure(
  align(center)[#table(
    columns: (51.43%, 26.15%, 22.42%),
    align: (left,right,right,),
    table.header([Path (batch 1, per decision-evaluation)], [Grid], [Graph],),
    table.hline(),
    [PyTorch, CPU], [11.03 ms], [10.51 ms],
    [ONNX, CPU provider], [23.5 ms], [3.67 ms],
    [ONNX, CoreML provider], [2.62 ms], [9.84 ms],
    [Best available (used)], [2.62 ms (CoreML)], [3.67 ms (CPU)],
  )]
  , caption: [Inference cost per network evaluation on the study machine, measured on 10 September 2026; the best available path per arm is the one used in self-play and evaluation. ]
  , kind: table
  ) <tbl:app-c-inference>

Training throughput was benchmarked on 10 September 2026 at batch 128, forward and backward, on the machine's GPU backend: 274 positions/s for the grid network and 138 positions/s for the graph network (forward-only on the CPU: 138 and 478 positions/s; the graph network is faster per position on the CPU and slower on the GPU). The campaign runs loaded their data in-process and trained at or below these figures; generation, not training, dominates a generation's wall-clock in either arm. Per-run training wall-clock (self-play, training and export over 10 generations × 500 games, evaluation games excluded) was 16.7--19.1 h for grid runs and 26.6--49.9 h for graph runs, with means of 18.0 h and 36.7 h (per-seed values in @tbl:d-wallclock). An evaluation game at 400 simulations took ≈23--32 s; the search opponent at 6,400 simulations decides in ≈27 ms single-threaded; a subprocess round-trip to the engine costs 21.7 µs. Disk use was estimated at ≈3--5 GB per three-seed campaign against a 20 GB free-space guard.

= Statistical procedures and raw result tables
<sec:app-d>
This appendix states the estimators of the study exactly as they were computed and reproduces, without rounding or recomputation, every per-run number behind the main comparison and the ablations. Values are copied from the regenerated result files and from the dated analysis records; where a record does not state a quantity, the cell says so.

== Score, truncation rate and sensitivity score
<score-truncation-rate-and-sensitivity-score>
An evaluation match between one checkpoint and one opponent is 100 games on the frozen opening lines, each line played once with each colour. A game ends in a win, a draw, a loss, or a truncation at the 300-ply cap. From the game rows of one (seed, opponent) cell three statistics are derived: the #strong[score];, the mean of win = 1, draw = 0.5, loss = 0 over the #emph[non-truncated] games; the #strong[truncation rate];, the number of truncated games divided by the 100 games played; and the #strong[sensitivity score];, the mean over #emph[all] 100 games with every truncated game counted 0.5, reported as a column and never used as the primary metric. Games are aggregated to one score per cell first; the seed is the unit of every later step, and no game enters any interval as an independent observation.

== The seed-level bootstrap
<the-seed-level-bootstrap>
Every interval in the report is a percentile bootstrap whose resampling unit is the seed, that is, one independent training run. For a cell series $s_1 \, dots.h \, s_n$ (one score per seed, with $n$ = 5 in the final analysis and $n$ = 3 in the analysis of 19 September 2026), the procedure draws $n$ indices uniformly with replacement, averages the corresponding scores, repeats this $B$ = 10,000 times, sorts the resample means, and reports the elements at zero-based positions $floor.l 0.025 thin B floor.r$ and $floor.l 0.975 thin B floor.r$ as the 95% interval. No bias correction or acceleration is applied; the point estimate printed beside each interval is the plain mean of the $n$ per-seed scores. The pseudo-random generator is Python's `random.Random` seeded with the constant 0 for every call, so every interval is reproducible to the last digit from the same per-seed inputs.

The arm contrast is the difference of seed-level means, graph minus grid. In each of the $B$ = 10,000 resamples the graph seed set and the grid seed set are resampled #emph[independently];, each with its own size, and the difference of the two resample means is recorded; the sorted differences are cut at the same two positions. Seeds are independent across arms by design (seed $k$ of one arm shares nothing with seed $k$ of the other beyond the frozen openings and opponents), so no pairing across arms is imposed. The same estimator serves seed sets of unequal size: the A1′ supplement (three seeds) against the full graph arm (five seeds) resamples three and five scores respectively.

```
procedure PERCENTILE-CI(x[1..n]; B = 10,000; seed = 0)
    rng <- Random(seed)
    for b in 1..B:
        m[b] <- mean of n draws x[rng.randrange(n)]
    sort m ascending
    return m[floor(0.025 * B)], m[floor(0.975 * B)]       # zero-based positions

procedure DIFF-CI(a[1..p], c[1..q]; B = 10,000; seed = 0)   # a = graph, c = grid
    rng <- Random(seed)
    for b in 1..B:
        d[b] <- (mean of p draws a[rng.randrange(p)]) - (mean of q draws c[rng.randrange(q)])
    sort d ascending
    return d[floor(0.025 * B)], d[floor(0.975 * B)]
```

== Raw per-seed tables: same-examples reading
<raw-per-seed-tables-same-examples-reading>
The same-examples reading evaluates each run's checkpoint after the tenth and last generation (checkpoint identifiers are zero-based, so this is gen009), every run having consumed the same self-play budget of 10 generations × 500 games. @tbl:d-se-scores gives the scores and the truncation rate against legal-random; @tbl:d-sens, after the second reading, gives the sensitivity scores against legal-random under both readings; legal-random is the only opponent against which any game was truncated.

#figure(
  align(center)[#table(
    columns: (16.23%, 13.16%, 17.32%, 17.54%, 17.32%, 18.42%),
    align: (left,left,right,right,right,right,),
    table.header([Arm], [Seed], [B-RND score], [B-RND trunc.], [B-HEU score], [B-MCTS score],),
    table.hline(),
    [grid], [1], [0.995], [0 %], [0.150], [0.125],
    [grid], [2], [0.975], [1 %], [0.080], [0.125],
    [grid], [3], [0.990], [1 %], [0.190], [0.075],
    [grid], [4], [0.949], [11 %], [0.105], [0.085],
    [grid], [5], [0.995], [0 %], [0.120], [0.210],
    [graph], [1], [0.733], [57 %], [0.025], [0.115],
    [graph], [2], [0.981], [20 %], [0.050], [0.125],
    [graph], [3], [0.722], [55 %], [0.090], [0.100],
    [graph], [4], [0.688], [44 %], [0.125], [0.120],
    [graph], [5], [0.935], [23 %], [0.035], [0.115],
  )]
  , caption: [Per-run scores, same-examples reading: the tenth-generation checkpoint of each of five independent training runs per arm (10 generations × 500 self-play games each), 100 paired colour-swapped games per opponent on the frozen openings at 400 simulations per decision, against the frozen population (B-RND legal-random, B-HEU heuristic, B-MCTS search at 6,400 simulations). Score = mean of win 1 / draw 0.5 / loss 0 over non-truncated games (a fraction); trunc. = share of the 100 games stopped at the 300-ply cap, 0 % against B-HEU and B-MCTS in every cell and omitted. Raw values, no interval.]
  , kind: table
  ) <tbl:d-se-scores>

== Raw per-seed tables: same-wall-clock reading
<raw-per-seed-tables-same-wall-clock-reading>
The same-wall-clock reading evaluates each run's last checkpoint completed within the equal-time cutoff (@sec:app-d-cutoff). Where that checkpoint is the final one, the final evaluation set serves both readings, so the grid rows of seeds 1, 2, 4 and 5 are identical in both readings.

#figure(
  align(center)[#table(
    columns: (13.13%, 10.72%, 19.26%, 13.79%, 14.44%, 13.79%, 14.88%),
    align: (left,left,left,right,right,right,right,),
    table.header([Arm], [Seed], [Checkpoint], [B-RND score], [B-RND trunc.], [B-HEU score], [B-MCTS score],),
    table.hline(),
    [grid], [1], [gen009], [0.995], [0 %], [0.150], [0.125],
    [grid], [2], [gen009], [0.975], [1 %], [0.080], [0.125],
    [grid], [3], [gen008], [0.939], [1 %], [0.145], [0.080],
    [grid], [4], [gen009], [0.949], [11 %], [0.105], [0.085],
    [grid], [5], [gen009], [0.995], [0 %], [0.120], [0.210],
    [graph], [1], [gen003], [0.798], [58 %], [0.045], [0.075],
    [graph], [2], [gen004], [0.926], [39 %], [0.055], [0.110],
    [graph], [3], [gen004], [0.713], [53 %], [0.060], [0.105],
    [graph], [4], [gen002], [0.631], [39 %], [0.100], [0.150],
    [graph], [5], [gen005], [0.980], [24 %], [0.045], [0.095],
  )]
  , caption: [Per-run scores, same-wall-clock reading: for each of five independent training runs per arm, the last checkpoint completed within 18.77 h of cumulative training wall-clock (identifiers zero-based; gen009 is the tenth generation), 100 paired colour-swapped games per opponent on the frozen openings at 400 simulations per decision, against the frozen population (B-RND legal-random, B-HEU heuristic, B-MCTS search at 6,400 simulations). Score = mean of win 1 / draw 0.5 / loss 0 over non-truncated games (a fraction); trunc. = share of the 100 games stopped at the 300-ply cap, 0 % against B-HEU and B-MCTS in every cell and omitted. Raw values, no interval.]
  , kind: table
  ) <tbl:d-swc-scores>

#figure(
  align(center)[#table(
    columns: (18.9%, 14.95%, 31.87%, 34.29%),
    align: (left,left,right,right,),
    table.header([Arm], [Seed], [Same-examples: B-RND sens.], [Same-wall-clock: B-RND sens.],),
    table.hline(),
    [grid], [1], [0.9950], [0.9950],
    [grid], [2], [0.9700], [0.9700],
    [grid], [3], [0.9850], [0.9350],
    [grid], [4], [0.9000], [0.9000],
    [grid], [5], [0.9950], [0.9950],
    [graph], [1], [0.6000], [0.6250],
    [graph], [2], [0.8850], [0.7600],
    [graph], [3], [0.6000], [0.6000],
    [graph], [4], [0.6050], [0.5800],
    [graph], [5], [0.8350], [0.8650],
  )]
  , caption: [Sensitivity scores against legal-random (B-RND) under both readings, for the same runs, checkpoints and evaluation volume as @tbl:d-se-scores and @tbl:d-swc-scores: the mean over all 100 games of the cell with every truncated game counted 0.5, at the four-decimal precision of the comma-separated result files. Against B-HEU and B-MCTS no game of any run was truncated under either reading, so there the sensitivity score equals the score of the main tables in every cell. Raw values, no interval.]
  , kind: table
  ) <tbl:d-sens>

== Seed-level means, intervals and arm contrasts
<seed-level-means-intervals-and-arm-contrasts>
@tbl:d-means gives the mean of the five per-seed scores for each arm, opponent and reading with its seed-level bootstrap interval; @tbl:d-contrast gives the graph-minus-grid differences of those means. These are the final numbers of the study.

#figure(
  align(center)[#table(
    columns: (26.75%, 12.72%, 20.18%, 20.18%, 20.18%),
    align: (left,left,right,right,right,),
    table.header([Reading], [Arm], [vs B-RND], [vs B-HEU], [vs B-MCTS],),
    table.hline(),
    [same-examples], [grid], [0.981 \[0.964, 0.994\]], [0.129 \[0.098, 0.165\]], [0.124 \[0.087, 0.168\]],
    [same-examples], [graph], [0.812 \[0.710, 0.920\]], [0.065 \[0.034, 0.100\]], [0.115 \[0.107, 0.121\]],
    [same-wall-clock], [grid], [0.971 \[0.950, 0.991\]], [0.120 \[0.098, 0.142\]], [0.125 \[0.090, 0.168\]],
    [same-wall-clock], [graph], [0.810 \[0.697, 0.922\]], [0.061 \[0.047, 0.081\]], [0.107 \[0.087, 0.130\]],
  )]
  , caption: [Seed-level mean scores of the two arms against each frozen opponent under both budget readings (same-examples: tenth-generation checkpoints after 10 generations × 500 games; same-wall-clock: last checkpoint within 18.77 h), five independent training runs per arm, 100 paired colour-swapped games per opponent and run. Each entry is the plain mean of the five per-run scores (fraction of decided games, truncations excluded) with its 95% percentile bootstrap interval over seeds (10,000 resamples).]
  , kind: table
  ) <tbl:d-means>

#figure(
  align(center)[#table(
    columns: (20.22%, 38.68%, 41.1%),
    align: (left,right,right,),
    table.header([Opponent], [Same-examples: graph − grid], [Same-wall-clock: graph − grid],),
    table.hline(),
    [B-RND], [−0.169 \[−0.272, −0.062\]], [−0.161 \[−0.278, −0.048\]],
    [B-HEU], [−0.064 \[−0.111, −0.017\]], [−0.059 \[−0.087, −0.029\]],
    [B-MCTS], [−0.009 \[−0.055, +0.028\]], [−0.018 \[−0.066, +0.025\]],
  )]
  , caption: [Arm contrast: difference of the seed-level means of @tbl:d-means, graph arm minus grid arm, per frozen opponent and budget reading, five independent training runs per arm; unit: score difference (fraction of decided games). Brackets: 95% percentile bootstrap interval from the five graph seeds and the five grid seeds resampled independently, 10,000 resamples.]
  , kind: table
  ) <tbl:d-contrast>

The seeds were collected in two stages: seeds 1--3 of both arms in the campaign of 10--17 September 2026, analysed on 19 September 2026; seeds 4--5 of both arms between 27 September and 2 October 2026, under a commitment made before they were run to use all five seeds in the final analysis whatever their direction. @tbl:d-three-seed records the three-seed analysis so that both stages are on the record; the extension tightened four of the six contrast intervals, and the largest upper bound of any contrast moved from +0.035 to +0.028.

#figure(
  align(center)[#table(
    columns: (16.59%, 25.11%, 19.43%, 19.43%, 19.43%),
    align: (left,left,right,right,right,),
    table.header([Quantity], [Reading], [vs B-RND], [vs B-HEU], [vs B-MCTS],),
    table.hline(),
    [grid mean], [same-examples], [0.987 \[0.975, 0.995\]], [0.140 \[0.080, 0.190\]], [0.108 \[0.075, 0.125\]],
    [graph mean], [same-examples], [0.812 \[0.722, 0.981\]], [0.055 \[0.025, 0.090\]], [0.113 \[0.100, 0.125\]],
    [grid mean], [same-wall-clock], [0.970 \[0.939, 0.995\]], [0.125 \[0.080, 0.150\]], [0.110 \[0.080, 0.125\]],
    [graph mean], [same-wall-clock], [0.812 \[0.713, 0.926\]], [0.053 \[0.045, 0.060\]], [0.097 \[0.075, 0.110\]],
    [graph − grid], [same-examples], [−0.175 \[−0.268, −0.007\]], [−0.085 \[−0.143, −0.025\]], [+0.005 \[−0.020, +0.035\]],
    [graph − grid], [same-wall-clock], [−0.158 \[−0.254, −0.050\]], [−0.072 \[−0.100, −0.028\]], [−0.013 \[−0.040, +0.015\]],
  )]
  , caption: [The original three-seed analysis of 19 September 2026 (seeds 1--3 of each arm; same opponents, budget readings and evaluation volume as @tbl:d-means): seed-level means and graph-minus-grid contrasts with 95% percentile bootstrap intervals over three seeds per arm (10,000 resamples; arms resampled independently). Superseded by the five-seed tables; kept as the record of the first stage of seed collection.]
  , kind: table
  ) <tbl:d-three-seed>

== The equal-time cutoff and the checkpoint map
<sec:app-d-cutoff>
The cutoff was fixed by a rule stated before the campaign: the median of the full-run training wall-clocks of the grid arm's three original runs. Those totals were 18.77 h, 16.73 h and 19.07 h, so the cutoff is 18.77 h; it was computed on 16 September 2026, before any cross-arm number existed, and the two later grid seeds never entered the median. The final computation takes the median exactly from the per-generation clock files rather than from the rounded constant, so that the defining run's own final checkpoint sits at the cutoff inclusively; the resulting map for seeds 1--3 reproduces the one recorded on 16 September 2026 checkpoint for checkpoint. For each run the checkpoint retained is the last whose cumulative training wall-clock does not exceed the cutoff (@tbl:d-cutoff).

#figure(
  align(center)[#table(
    columns: (14.76%, 12.11%, 23.79%, 23.35%, 25.99%),
    align: (left,left,left,right,left,),
    table.header([Arm], [Seed], [Checkpoint at the cutoff], [Cumulative wall-clock], [Evaluation set],),
    table.hline(),
    [grid], [1], [gen009 (final)], [18.77 h], [final set reused],
    [grid], [2], [gen009 (final)], [16.73 h], [final set reused],
    [grid], [3], [gen008], [17.22 h], [equal-time set],
    [grid], [4], [gen009 (final)], [not stated], [final set reused],
    [grid], [5], [gen009 (final)], [not stated], [final set reused],
    [graph], [1], [gen003], [16.50 h], [equal-time set],
    [graph], [2], [gen004], [16.06 h], [equal-time set],
    [graph], [3], [gen004], [not stated], [equal-time set],
    [graph], [4], [gen002], [not stated], [equal-time set],
    [graph], [5], [gen005], [not stated], [equal-time set],
  )]
  , caption: [Checkpoint retained for the same-wall-clock reading in each of the ten training runs: the last checkpoint completed within the equal-time cutoff of 18.77 h of cumulative training wall-clock (identifiers zero-based; gen009 is the tenth and final generation). Cumulative hours are those stated in the analysis records; "not stated" means the record gives the checkpoint but not the hours. Where the retained checkpoint is the final one, the final evaluation set (100 paired games per opponent) serves both readings; otherwise a separate equal-time set of the same volume was evaluated.]
  , kind: table
  ) <tbl:d-cutoff>

The map is the measured content of the second reading: at equal wall-clock the graph arm had completed 3--6 of its ten generations (4--5 over the original three seeds), the grid arm nine or ten. @tbl:d-wallclock gives the full-run training wall-clocks behind the map. Over the five seeds the means are 18.00 h (grid) and 36.70 h (graph), a ratio of 2.04×; over the original three seeds they were 18.2 h and 35.7 h, a ratio of 2.0×. The equal-time evaluation sets for seeds 1--3 were run on 18 September 2026 (about 11 h), those for the graph arm's seeds 4 and 5 on 6 October 2026 (about 6 h).

#figure(
  align(center)[#table(
    columns: (13.57%, 14.44%, 14.44%, 14.44%, 14.44%, 14.44%, 14.22%),
    align: (left,right,right,right,right,right,right,),
    table.header([Arm], [Seed 1], [Seed 2], [Seed 3], [Seed 4], [Seed 5], [Mean],),
    table.hline(),
    [grid], [18.77], [16.73], [19.07], [18.23], [17.19], [18.00],
    [graph], [43.07], [32.71], [31.28], [49.86], [26.57], [36.70],
  )]
  , caption: [Training wall-clock of each of the ten main-campaign runs, in hours: the per-generation self-play generation and training seconds summed over the 10 generations of the run (10 × 500 games), evaluation games excluded, from each run's clock log; one machine, four worker threads, sequential runs. The sums are 90.0 h (grid) and 183.5 h (graph), 273.5 h in all. The equal-time cutoff is the median of the three grid values of seeds 1--3.]
  , kind: table
  ) <tbl:d-wallclock>

== Cap-sensitivity bounds
<cap-sensitivity-bounds>
The protocol brackets the primary estimator (truncations excluded) with three alternative treatments of every truncated game: counted 0.5 (the sensitivity scores of @tbl:d-sens), counted as a loss for the arm under test, and counted as a win for it; the last is an upper bound on what any larger cap could do for an arm that truncates. The bounds were computed from the per-game records in the analysis of 19 September 2026 (three seeds per arm): with every truncated game scored as a win for the arm under test, the graph-minus-grid contrast against legal-random is still −0.072 under the same-examples reading and −0.058 under the same-wall-clock reading, and its direction is unchanged under every treatment (excluded, 0.5, loss, win). Against B-HEU and B-MCTS no game of either arm was truncated, so all treatments coincide there. The final analysis record does not restate the bounds at five seeds. Because the graph arm truncated 20--57% of its games against legal-random in the original seeds and 23--44% in the extension seeds (grid: 0--1%, one extension seed at 11%), its primary score against that opponent is a mean over fewer decided games (43 to 80 per seed) than the grid arm's.

== Ablation raw tables
<ablation-raw-tables>
Three variants of the graph arm were trained with three seeds each at the full budget (10 generations × 500 games, identical self-play, training and evaluation settings) and evaluated at their tenth-generation checkpoint under the same-examples reading. @tbl:d-abl-runs summarises the variants; @tbl:d-abl-a2 and @tbl:d-abl-a1prime give the per-seed scores of the two that trained; @tbl:d-abl-contrast gives the contrasts against the full graph arm.

#figure(
  align(center)[#table(
    columns: (29.74%, 25.77%, 9.69%, 16.96%, 17.84%),
    align: (left,left,left,right,left,),
    table.header([Variant], [Component changed], [Seeds], [Training wall-clock], [Outcome],),
    table.hline(),
    [A1 (`graph-untyped`)], [six direction-typed edge matrices replaced by one shared matrix], [1, 2, 3], [7.75 / 8.01 / 7.61 h], [training diverged to NaN in generation 0, 3 of 3 seeds],
    [A2 (`graph-nogpool`)], [global-pooling bias removed from every layer (1.37M parameters vs 1.47M)], [1, 2, 3], [39.90 / 47.44 / 32.05 h], [trained; no measurable effect],
    [A1′ (`graph-`#sym.zws`untyped-`#sym.zws`clip`)], [untyped edges #emph[and] gradient-norm clipping at 1.0 (two components)], [1, 2, 3], [23.89 / 30.35 / 27.68 h], [trained; within the full arm's band],
  )]
  , caption: [The three ablation variants of the graph arm, each trained with three independent seeds at the full budget of the main comparison (10 generations × 500 self-play games; same frozen opponents, openings and evaluation settings). Training wall-clock in hours per seed under the same accounting as @tbl:d-wallclock (per-generation self-play and training seconds summed, evaluation games excluded); the reference graph runs of seeds 1--3 took 43.07, 32.71 and 31.28 h. A1's short runs are a symptom of its divergence (a NaN policy plays short degenerate games) rather than a saving.]
  , kind: table
  ) <tbl:d-abl-runs>

No score table is given for A1 because none exists as a strength measurement: every forward pass of all three networks returned NaN for policy and value from the first checkpoint onwards, and the final evaluations of the three independently seeded runs were identical to the game (0 wins, 0 draws and 100 losses against B-HEU; 2 wins and 45 draws with 53% truncation against B-RND), which independent trainings cannot produce. The training logs carry the signature "policy top-1 100.0%, value acc 0.0%" from generation 1 onwards, and the degenerate games averaged about 42 plies with no truncation and no resignation. The raw evaluation files are kept but excluded from every table as scores.

#figure(
  align(center)[#table(
    columns: (15.69%, 13.94%, 13.94%, 13.94%, 14.16%, 14.16%, 14.16%),
    align: (left,right,right,right,right,right,right,),
    table.header([Opponent], [A2 seed 1], [A2 seed 2], [A2 seed 3], [full seed 1], [full seed 2], [full seed 3],),
    table.hline(),
    [B-RND], [0.768 (59 %)], [0.714 (65 %)], [0.952 (17 %)], [0.733 (57 %)], [0.981 (20 %)], [0.722 (55 %)],
    [B-HEU], [0.050 (0 %)], [0.070 (0 %)], [0.025 (0 %)], [0.025 (0 %)], [0.050 (0 %)], [0.090 (0 %)],
    [B-MCTS], [0.070 (0 %)], [0.125 (0 %)], [0.105 (0 %)], [0.115 (0 %)], [0.125 (0 %)], [0.100 (0 %)],
  )]
  , caption: [Per-seed final scores of ablation A2 (global-pooling bias removed) beside the full graph arm's seeds 1--3, same-examples reading: tenth-generation checkpoints, 100 paired colour-swapped games per opponent on the frozen openings at 400 simulations against the frozen population. Score = fraction of decided games won (draws 0.5); truncation rate of the 100 games in parentheses. Three independent training runs per variant; raw values, no interval.]
  , kind: table
  ) <tbl:d-abl-a2>

#figure(
  align(center)[#table(
    columns: (25.88%, 24.78%, 24.78%, 24.56%),
    align: (left,right,right,right,),
    table.header([Opponent], [A1′ seed 1], [A1′ seed 2], [A1′ seed 3],),
    table.hline(),
    [B-RND], [0.566 (47 %)], [0.671 (59 %)], [0.995 (0 %)],
    [B-HEU], [0.035], [0.135], [0.110],
    [B-MCTS], [0.090], [0.195], [0.060],
  )]
  , caption: [Per-seed final scores of the A1′ supplement (untyped edges with gradient clipping at 1.0, an explicitly two-component variant), same-examples reading: tenth-generation checkpoints, 100 paired colour-swapped games per opponent on the frozen openings at 400 simulations against the frozen population. Score = fraction of decided games won (draws 0.5); the truncation rate of the 100 games is given in parentheses where the record states it (legal-random only). Three independent training runs; raw values, no interval.]
  , kind: table
  ) <tbl:d-abl-a1prime>

#figure(
  align(center)[#table(
    columns: (17.29%, 24.73%, 16.19%, 17.07%, 24.73%),
    align: (left,right,right,right,right,),
    table.header([Opponent], [A2 − full (3 vs 3 seeds)], [A1′ mean (3 seeds)], [full graph mean (5 seeds)], [A1′ − full (3 vs 5 seeds)],),
    table.hline(),
    [B-RND], [−0.001 \[−0.170, +0.165\]], [0.744], [0.810], [−0.066 \[−0.254, +0.130\]],
    [B-HEU], [−0.007 \[−0.043, +0.030\]], [0.093], [0.061], [+0.032 \[−0.011, +0.078\]],
    [B-MCTS], [−0.013 \[−0.043, +0.013\]], [0.115], [0.107], [+0.008 \[−0.040, +0.063\]],
  )]
  , caption: [Ablation contrasts against the full graph arm, same-examples reading, frozen population, 100 paired games per opponent and run. A2 − full: difference of seed-level means over seeds 1--3 of both variants. A1′ − full: difference between the A1′ mean over its three seeds and the full graph arm's mean over its five seeds. Unit: score difference (fraction of decided games). Brackets: 95% percentile bootstrap interval, the two seed sets resampled independently with their own sizes, 10,000 resamples. The A1′ contrast is confounded by the clipping and is never attributed to edge typing alone.]
  , kind: table
  ) <tbl:d-abl-contrast>

== Per-generation evaluation data
<per-generation-evaluation-data>
No per-generation score table exists in the result files or the analysis records. The score-versus-time and per-opponent trajectory figures are drawn directly from each run's evaluation records: every main-campaign run was evaluated, with the pinned settings and volume, at the checkpoints of generations 5, 8 and 10 (identifiers gen004, gen007 and gen009) and, where different from the final one, at its equal-time checkpoint; the population score at a point is the mean over the three opponents of the cell scores defined above, and the time axis is the cumulative sum of the run's per-generation training durations. The curves are reproducible from the released per-game records and clock files; their numbers are not reproduced here.

= Provenance of every result
<sec:app-e>
This appendix is the one place in the report where internal identifiers are the point. It gives, for every table and figure, the generated artifact it was taken from, the raw records that artifact was computed from, and the journal entry that recorded the measurement; it then indexes the decision log, reproduces the claims--evidence register in full, and lists where the raw data live together with the hashes of every frozen artifact.

== The evidence chain
<the-evidence-chain>
Every number in this report is reachable along one chain. #strong[Raw per-game records] are written by the evaluation arena as one CSV per (checkpoint, opponent) pairing under the run directory; the file's header lines name both engine command lines verbatim (network path, simulation count, seeds), and every game carries its outcome with truncation as its own category. #strong[Generated tables] are produced by `scripts/`#sym.zws`make_`#sym.zws`results.`#sym.zws`py`, which reads those CSVs and the per-run wall-clock logs, aggregates per (seed, opponent), bootstraps over seeds (10,000 resamples, seed as the unit, no game pooled as i.i.d.), and writes `results/`#sym.zws`comparison/`#sym.zws`*.`#sym.zws`{md,`#sym.zws`csv}`; it never retypes a number. #strong[Figures] are produced by `scripts/`#sym.zws`make_`#sym.zws`figures.`#sym.zws`py` from the same CSVs, wall-clock logs and campaign logs. #strong[The report] is assembled from these files; a source checker verifies that every numeric token in every chapter occurs in the evidence base, and a second checker verifies numeric identity between the English and French versions. The minimal reproduction script rebuilds the engine in a fresh clone, replays a recorded game to an exact match of its shipped row, and regenerates the tables byte-identically (verified 2026-10-09).

#strong[Journals.] Every experiment or measurement has one entry under `journal/`, named `YYYY-`#sym.zws`MM-`#sym.zws`DD-`#sym.zws`<slug>.`#sym.zws`md` and carrying an identifier of the form `<phase>-`#sym.zws`<date>-`#sym.zws`<slug>-`#sym.zws`<nn>` (for example `H6-`#sym.zws`2026-`#sym.zws`10-`#sym.zws`09-`#sym.zws`5seed-`#sym.zws`final-`#sym.zws`01`). The header fixes id, date, hypothesis, git commit, configuration, seeds, data version, hardware, duration and cost; the body has fixed sections: Methods, Raw results and uncertainty, Failures, Limits and confounders, Interpretation, Decision, Artifacts. Negative results and tooling defects are entries like any other. #strong[Decision log.] Every non-trivial decision is an entry `D-nnn` in the workspace file `state/`#sym.zws`decisions.`#sym.zws`md`, append-only: a reversed decision is never edited, a new entry supersedes it and links back. Gate crossings record the author's approval in its original wording. #strong[Methodology log.] `docs/`#sym.zws`methodology-`#sym.zws`log.`#sym.zws`md` (workspace) records, append-only, every incident in which the method caught or missed something.

== From each result to its artifact
<from-each-result-to-its-artifact>
@tbl:prov-results covers the generated tables and figures; @tbl:prov-method covers the validation, baseline, pipeline and encoder evidence cited in the method chapters, which lives in test suites, configurations and journals rather than in generated tables.

#figure(
  align(center)[#table(
    columns: (21.9%, 37.39%, 25%, 15.71%),
    align: (left,left,left,left,),
    table.header([Result in the report], [Generated artifact], [Raw input], [Journal entry],),
    table.hline(),
    [Per-seed scores and truncation rates, same-examples reading (2 arms × 5 seeds × 3 opponents, 100 games each)], [`results/`#sym.zws`comparison/`#sym.zws`results-`#sym.zws`same-`#sym.zws`examples.`#sym.zws`{md,`#sym.zws`csv}`], [`data/`#sym.zws`runs/`#sym.zws`cmp-`#sym.zws`{grid,`#sym.zws`graph}-`#sym.zws`s{1.`#sym.zws`.`#sym.zws`5}/`#sym.zws`eval/`#sym.zws`gen009-`#sym.zws`vs-`#sym.zws`{B-`#sym.zws`RND,`#sym.zws`B-`#sym.zws`HEU,`#sym.zws`B-`#sym.zws`MCTS}.`#sym.zws`csv`], [`H6-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`19-`#sym.zws`comparison-`#sym.zws`01` (3 seeds); `H6-`#sym.zws`2026-`#sym.zws`10-`#sym.zws`09-`#sym.zws`5seed-`#sym.zws`final-`#sym.zws`01` (final)],
    [Per-seed scores and truncation rates, same-wall-clock reading], [`results/`#sym.zws`comparison/`#sym.zws`results-`#sym.zws`same-`#sym.zws`wallclock.`#sym.zws`{md,`#sym.zws`csv}`], [`eval/`#sym.zws`tstar-`#sym.zws`gen00N-`#sym.zws`vs-`#sym.zws`*.`#sym.zws`csv` of each run (the final checkpoint's files where the cutoff checkpoint is the last one) and `wallclock.json`], [same two entries],
    [Arm contrast graph − grid, both readings, bootstrap over seeds], [`results/`#sym.zws`comparison/`#sym.zws`results-`#sym.zws`arm-`#sym.zws`difference.`#sym.zws`md`], [the two CSV files above], [same two entries],
    [Equal-time cutoff T\* = 18.77 h and the checkpoint map at T\*], [numbers in the journal; map re-derived by `make_results.py`], [`wallclock.json` of grid s1--s3 (median of the three totals), then of every run], [`H6-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`16-`#sym.zws`progress-`#sym.zws`01`; re-derivation checked in `H6-`#sym.zws`2026-`#sym.zws`10-`#sym.zws`09-`#sym.zws`5seed-`#sym.zws`final-`#sym.zws`01`],
    [Cap sensitivity bounds (every truncation scored as a win for the arm under test)], [numbers in the journal], [per-game records of the final evaluations], [`H6-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`19-`#sym.zws`comparison-`#sym.zws`01`],
    [Cost table: parameters, best-provider inference, run wall-clock (self-play generation + training, evaluation excluded, mean over the five seeds), self-play cost (that wall-clock / 5,000 games), training-throughput benchmark (batch 128), population scores], [`paper/`#sym.zws`figures/`#sym.zws`fig2-`#sym.zws`score-`#sym.zws`cost.`#sym.zws`md` (regenerated 2026-10-09 after a generator defect was found; see @sec:working-method)], [`wallclock.json` per run; `results-*.csv`; benchmark in `docs/`#sym.zws`representations/`#sym.zws`comparison-`#sym.zws`controls.`#sym.zws`md`], [`H5-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`10-`#sym.zws`encoders-`#sym.zws`01`; `H6-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`19-`#sym.zws`comparison-`#sym.zws`01`],
    [Score versus training wall-clock, all seeds, both arms, T\* marked], [`paper/`#sym.zws`figures/`#sym.zws`fig1-`#sym.zws`score-`#sym.zws`vs-`#sym.zws`time.`#sym.zws`png`], [`eval/*.csv` and `wallclock.json` per run], [`H6-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`19-`#sym.zws`comparison-`#sym.zws`01`; `H6-`#sym.zws`2026-`#sym.zws`10-`#sym.zws`09-`#sym.zws`5seed-`#sym.zws`final-`#sym.zws`01`],
    [Grid planes versus cell graph for one position], [`paper/`#sym.zws`figures/`#sym.zws`fig3-`#sym.zws`encodings.`#sym.zws`png`], [schematic: a synthetic five-piece position drawn in the script; no measured quantity], [`H5-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`10-`#sym.zws`encoders-`#sym.zws`01` (encoding definitions)],
    [Three failure positions F1--F3], [`paper/`#sym.zws`figures/`#sym.zws`fig4-`#sym.zws`failures.`#sym.zws`{md,`#sym.zws`png}`], [`eval/`#sym.zws`gen009-`#sym.zws`vs-`#sym.zws`*.`#sym.zws`csv` and `results/`#sym.zws`comparison/`#sym.zws`openings-`#sym.zws`v1.`#sym.zws`txt`; each game reproduced deterministically and verified against its CSV row], [`H6-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`19-`#sym.zws`comparison-`#sym.zws`01`],
    [Per-opponent score trajectories by generation, 5 seeds], [`paper/`#sym.zws`figures/`#sym.zws`fig5-`#sym.zws`per-`#sym.zws`opponent.`#sym.zws`png`], [`eval/`#sym.zws`{gen004,`#sym.zws`gen007,`#sym.zws`gen009}-`#sym.zws`vs-`#sym.zws`*.`#sym.zws`csv` and `wallclock.json` per run], [`H8-`#sym.zws`2026-`#sym.zws`10-`#sym.zws`09-`#sym.zws`detailed-`#sym.zws`edition-`#sym.zws`01`],
    [Epoch-1 policy top-1 and value accuracy by generation, 10 runs], [`paper/`#sym.zws`figures/`#sym.zws`fig6-`#sym.zws`training-`#sym.zws`metrics.`#sym.zws`png`], [`data/`#sym.zws`runs/`#sym.zws`campaign.`#sym.zws`log`, `data/`#sym.zws`runs/`#sym.zws`extension.`#sym.zws`log` (training logs of the 10 main runs)], [`H8-`#sym.zws`2026-`#sym.zws`10-`#sym.zws`09-`#sym.zws`detailed-`#sym.zws`edition-`#sym.zws`01`],
    [Final-evaluation truncation rate versus legal-random per run], [`paper/`#sym.zws`figures/`#sym.zws`fig7-`#sym.zws`truncation.`#sym.zws`png`], [`eval/`#sym.zws`gen009-`#sym.zws`vs-`#sym.zws`B-`#sym.zws`RND.`#sym.zws`csv` per run], [`H8-`#sym.zws`2026-`#sym.zws`10-`#sym.zws`09-`#sym.zws`detailed-`#sym.zws`edition-`#sym.zws`01`],
    [Ablation table: A1 divergence, A2 null effect, A1′ supplement], [`results/`#sym.zws`ablations/`#sym.zws`README.`#sym.zws`md`], [`data/`#sym.zws`runs/`#sym.zws`cmp-`#sym.zws`graph-`#sym.zws`{untyped,`#sym.zws`nogpool,`#sym.zws`untyped-`#sym.zws`clip}-`#sym.zws`s{1,`#sym.zws`2,`#sym.zws`3}/`#sym.zws`eval/` against the full graph arm's finals], [`H7-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`23-`#sym.zws`a1-`#sym.zws`divergence-`#sym.zws`01`; `H7-`#sym.zws`2026-`#sym.zws`10-`#sym.zws`02-`#sym.zws`a2-`#sym.zws`nogpool-`#sym.zws`01`; `H7-`#sym.zws`2026-`#sym.zws`10-`#sym.zws`09-`#sym.zws`a1prime-`#sym.zws`01`],
    [Pipeline, architecture and chronology schematics], [`paper/`#sym.zws`figures/`#sym.zws`fig8-`#sym.zws`pipeline.`#sym.zws`png`, `fig9-`#sym.zws`architectures.`#sym.zws`png`, `fig10-`#sym.zws`timeline.`#sym.zws`png` (`scripts/`#sym.zws`make_`#sym.zws`report_`#sym.zws`figures.`#sym.zws`py`)], [the system documentation (`docs/inventory.md`), the journal headers and the decision log; no measured quantity], [none],
  )]
  , caption: [Provenance of every generated table and figure: the artifact it is taken from, the raw records that artifact is computed from, and the journal entry that recorded the result. Run directories are abbreviated as `eval/…` for `data/`#sym.zws`runs/`#sym.zws`cmp-`#sym.zws`<arm>-`#sym.zws`s<seed>/`#sym.zws`eval/`#sym.zws`…`. ]
  , kind: table
  ) <tbl:prov-results>

#figure(
  align(center)[#table(
    columns: (40.4%, 33.55%, 26.05%),
    align: (left,left,left,),
    table.header([Evidence in the method chapters], [Where it lives], [Journal entry (date)],),
    table.hline(),
    [Perft tables (8 game types), UHP conformance 21/21, differential fuzzing against two reference engines (27,829 positions at seed 20260909), plane-encoder crosscheck (240 positions)], [test suites under `crates/`, `scripts/`#sym.zws`nightly.`#sym.zws`sh`, `scripts/`#sym.zws`crosscheck_`#sym.zws`planes.`#sym.zws`py`], [`H2-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`suite-`#sym.zws`rerun-`#sym.zws`01` (2026-09-09)],
    [30 hand-annotated critical positions, 30/30 after one setup-side correction], [`tests/`#sym.zws`critical_`#sym.zws`positions/`#sym.zws`cases/`#sym.zws`*.`#sym.zws`toml`; `scripts/`#sym.zws`run_`#sym.zws`critical_`#sym.zws`corpus.`#sym.zws`py`], [`H2-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`corpus-`#sym.zws`run-`#sym.zws`01` (2026-09-09)],
    [Zero invariant violations over 10.9M applied transitions], [`crates/`#sym.zws`hive-`#sym.zws`core/`#sym.zws`tests/`#sym.zws`random_`#sym.zws`invariants.`#sym.zws`rs`], [`H2-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`random-`#sym.zws`invariants-`#sym.zws`01` (2026-09-09)],
    [Throughput profile: 21.7 µs UHP round-trip; 2.62 ms (CoreML) versus 23.5 ms (CPU) per evaluation; game-length distribution behind the 300-ply cap], [commands recorded inline in the entry], [`H2-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`throughput-`#sym.zws`profile-`#sym.zws`01` (2026-09-09)],
    [CoreML inference restored in the Rust pipeline (MLProgram format)], [`crates/`#sym.zws`hive-`#sym.zws`mcts/`#sym.zws`src/`#sym.zws`ort_`#sym.zws`eval.`#sym.zws`rs`], [`H4-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`coreml-`#sym.zws`fix-`#sym.zws`01` (2026-09-09)],
    [Baseline definitions, characterisation round-robin, five tactical cases, weight pin], [`configs/`#sym.zws`baselines/`#sym.zws`*.`#sym.zws`toml`, `docs/baselines.md`, `tests/`#sym.zws`tactical_`#sym.zws`positions/`], [`H3-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`baselines-`#sym.zws`01` (2026-09-09)],
    [Pipeline pilot and the seven automated pre-training checks], [`scripts/`#sym.zws`run_`#sym.zws`pilot.`#sym.zws`py`, `scripts/`#sym.zws`run_`#sym.zws`h4_`#sym.zws`checks.`#sym.zws`sh`, `data/runs/pilot0/`], [`H4-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`10-`#sym.zws`pilot-`#sym.zws`01` (2026-09-10)],
    [Grid and graph encoders, capacity matching (1.44M vs 1.47M), cost asymmetries, property battery], [`docs/`#sym.zws`representations/`#sym.zws`{grid,`#sym.zws`graph,`#sym.zws`comparison-`#sym.zws`controls}.`#sym.zws`md`, `python/`#sym.zws`hivenet/`#sym.zws`{graph_`#sym.zws`dataset,`#sym.zws`graph_`#sym.zws`model}.`#sym.zws`py`], [`H5-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`10-`#sym.zws`encoders-`#sym.zws`01` (2026-09-10)],
    [Rust mirror of the graph encoder, golden crosscheck (160 positions), end-to-end graph arm through the same search], [`scripts/`#sym.zws`crosscheck_`#sym.zws`graph.`#sym.zws`py`, `hive-nn` graph module], [`H5-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`10-`#sym.zws`graph-`#sym.zws`wiring-`#sym.zws`01` (2026-09-10)],
    [Comparison matrix, opening generation, fixed-schedule harness test, campaign sizing], [`configs/`#sym.zws`comparison-`#sym.zws`matrix.`#sym.zws`yaml`, `results/`#sym.zws`comparison/`#sym.zws`openings-`#sym.zws`v1.`#sym.zws`txt`, `results/`#sym.zws`comparison/`#sym.zws`opponents-`#sym.zws`manifest.`#sym.zws`md`], [`H6-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`10-`#sym.zws`matrix-`#sym.zws`01` (2026-09-10)],
    [Report assembly checks and the staleness defect found by the render pass], [`paper/`#sym.zws`final-`#sym.zws`control.`#sym.zws`md`], [`H8-`#sym.zws`2026-`#sym.zws`10-`#sym.zws`09-`#sym.zws`detailed-`#sym.zws`edition-`#sym.zws`01` (2026-10-09)],
  )]
  , caption: [Provenance of the method-chapter evidence (engine validation, baselines, pipeline, encoders, campaign design): the artifacts and the journal entry recording each measurement. ]
  , kind: table
  ) <tbl:prov-method>

== Decision index
<decision-index>
@tbl:prov-decisions lists the decision-log entries relevant to this study with their dates; entries D-002, D-013 and D-018 concern the other projects of the research programme and are omitted. Gate crossings are marked with their gate.

#figure(
  align(center)[#table(
    columns: (13.91%, 21.63%, 64.46%),
    align: (left,left,left,),
    table.header([Entry], [Date], [Decision],),
    table.hline(),
    [D-001], [2026-09-09], [Goal-directed operating rules adopted: routing file, one executable document per phase, gates reserved to the human],
    [D-003], [2026-09-09], [The prior 19-generation self-play loop classified as a demonstration, not evidence; its checkpoint preserved],
    [D-004], [2026-09-09], [Protocol/validation ordering fixed (draft, then measure, then freeze); write-as-you-go and no-real-money rules added; gates park a phase, not the session],
    [D-005], [2026-09-09], [G-PUBLIC / G-SPEND: MIT licence; prior loop permanently stopped; sequential tracks],
    [D-006], [2026-09-09], [Private remotes; methodology documented; full French copy of each report],
    [D-007], [2026-09-09], [Study variant: base game only],
    [D-008], [2026-09-09], [Truncation convention: cap ≠ draw, separate reporting, sensitivity procedure],
    [D-009], [2026-09-09], [Novelty positioning: no pivot; scoped contribution claim against three closest works],
    [D-010], [2026-09-09], [Python--Rust binding by subprocess/UHP (21.7 µs round-trip), no in-process binding],
    [D-011], [2026-09-09], [Measured proposals: 128/32 simulations, 300-ply cap, two follow-up fixes],
    [D-012], [2026-09-09], [G-FREEZE review: protocol freeze deferred until after the pilots],
    [D-014], [2026-09-09], [Baseline definitions and budgets (legal-random, heuristic at depth 1, search at 6,400 simulations)],
    [D-015], [2026-09-09], [Shared action decoder: the (piece slot, destination) contract reused by both arms],
    [D-016], [2026-09-09], [Proposal to exclude the prior checkpoint from the frozen population],
    [D-017], [2026-09-09], [#strong[G-FREEZE];: opponent population frozen, search opponent at 6,400 simulations, prior checkpoint excluded; hashes and engine commit b94e7c1],
    [D-019], [2026-09-09], [Evaluation settings pinned: 400 simulations, no exploration noise, deterministic argmax],
    [D-020], [2026-09-10], [#strong[G-FREEZE];: protocol frozen as v1.0 on the pilot's measured values; sha256 f340a6b6…aefeb5, commit 44a74ff],
    [D-021], [2026-09-10], [Grid representation reused as-is; frame-bounds check made an always-on assertion],
    [D-022], [2026-09-10], [Graph arm: cell graph, fixed-capacity tensors (node cap 224), Python-first with a Rust mirror],
    [D-023], [2026-09-10], [Symmetry augmentation excluded from the full method, both arms],
    [D-024], [2026-09-10], [#strong[G-DESTRUCTIVE] (by the author directly): pre-study workspace archive deleted; research copy is the sole copy of the prior work],
    [D-025], [2026-09-10], [#strong[G-FREEZE];: 250 shared openings frozen, generated blind; content sha256 63b318d0…5af7b],
    [D-026], [2026-09-10], [#strong[G-SPEND];: main campaign approved at full size and launched],
    [D-027], [2026-09-16], [Evaluation volume kept at 100 games per pairing; seed variance dominates game noise],
    [D-028], [2026-09-19], [Ablation (a) substituted by A2 (global-pooling bias); A1 naive adjacency kept],
    [D-029], [2026-09-20], [#strong[G-SPEND];: ablation campaign approved, both ablations at 3 seeds each],
    [D-030], [2026-09-26], [#strong[G-SPEND];: supplementary two-component A1′ approved at its corrected sizing],
    [D-031], [2026-09-26], [#strong[G-SPEND];: extension to 5 seeds per arm approved with three pre-commitments stated before any new run],
    [D-032], [2026-10-09], [Report scope: detailed edition, no frozen artifact, number or claim changed],
  )]
  , caption: [Index of the decision-log entries relevant to this study, in order of recording. ]
  , kind: table
  ) <tbl:prov-decisions>

== Claims--evidence register
<claimsevidence-register>
@tbl:prov-claims reproduces `paper/claims.md` with its section column removed; claim wording is compressed where needed, numbers are unchanged. The rule is: no row, no claim.

#figure(
  align(center)[#table(
    columns: (30.24%, 29.8%, 39.96%),
    align: (left,left,left,),
    table.header([Claim], [Evidence], [Limit],),
    table.hline(),
    [The rules engine reproduces Mzinga's published perft tables for all 8 game types to depth 6 (depth ≤5 in the standard suite, depth 7 in nightly runs).], [`H2-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`suite-`#sym.zws`rerun-`#sym.zws`01`], [depth-bounded node-count equality; d7 re-run not repeated on 2026-09-09 (d≤6 confirmed)],
    [The engine passes the UHP conformance harness of the nokamute reference (21/21).], [`H2-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`suite-`#sym.zws`rerun-`#sym.zws`01`], [conformance = protocol behaviour, not full rules proof],
    [Per-ply legal-move sets are identical to both reference engines (MzingaEngine v0.16.0, nokamute 1.0.3) over seeded random games (27,829 positions at seed 20260909; 200/100 games/type in nightly).], [`H2-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`suite-`#sym.zws`rerun-`#sym.zws`01`], [agreement with references, not with the rulesheet directly; random-walk coverage],
    [The engine agrees with a 30-case corpus of hand-annotated critical positions whose expectations were committed before any engine run (30/30 after one setup-side correction).], [`H2-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`corpus-`#sym.zws`run-`#sym.zws`01`; `tests/`#sym.zws`critical_`#sym.zws`positions/`], [corpus annotations not externally reviewed (declared limit); 30 cases at the low end of the 30--50 proposal],
    [Seeded random-game sessions across all 8 game types show zero invariant violations over 10.9M applied transitions.], [`H2-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`random-`#sym.zws`invariants-`#sym.zws`01`], [pseudo-random breadth, not adversarial depth; serialisation via UHP GameString only],
    [The Rust and Python plane encoders agree exactly (240 positions, byte-identical planes).], [`H2-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`suite-`#sym.zws`rerun-`#sym.zws`01`], [grid-arm encoder only at that date],
    [A UHP subprocess round-trip costs \~22 µs (negligible against per-decision costs), so the Python↔Rust binding uses subprocess/UHP (no PyO3).], [`H2-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`throughput-`#sym.zws`profile-`#sym.zws`01`; D-010], [one machine (M1 Pro); revisit if Python ever enters a per-move loop],
    [At the measured inference costs (2.62 ms/eval CoreML, 23.5 ms CPU, gen-19 net as workload), 128/32 sims with playout-cap randomization and a 300-ply cap are feasible for this study's compute envelope.], [`H2-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`throughput-`#sym.zws`profile-`#sym.zws`01`; D-011], [historical: proposals later pilot-confirmed and frozen (D-020); costs are net-specific],
    [CoreML inference restored in the Rust pipeline (MLProgram fix): self-play at 128/32 sims costs ≈12 thread-s/game (≈3 s/game wall at 4 threads), vs ≈320 thread-s/game on the CPU fallback at 600/150.], [`H4-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`coreml-`#sym.zws`fix-`#sym.zws`01`], [gen-19 net as workload; small probe counts; re-measured at the pilot],
    [The heuristic baseline defeats legal-random 100--0 (100 paired games, 0 truncations); MCTS-without-network at 6400 sims scores 99.5% vs random and 37.5% vs the heuristic (−89 Elo \[−150, −32\]); a 4×-budget probe reaches 56.2%.], [`H3-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`baselines-`#sym.zws`01`], [pilot volume (100 games/pairing); arena CI unpaired approximation; ordering finding diagnosed, not retuned; population since frozen (D-017)],
    [The MCTS baseline solves all 5 hand-annotated tactical cases at 400, 1600 and 6400 sims, and value signs are pinned under player alternation.], [`H3-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`09-`#sym.zws`baselines-`#sym.zws`01`; `tests/`#sym.zws`tactical_`#sym.zws`positions/`; sign tests in `crates/*/tests`], [5 cases, unreviewed externally (declared limit)],
    [All seven pre-training checks pass as automated tests on real self-play shards: zero illegal policy mass, id↔move identity, correct outcome perspective with truncation distinct, tiny-batch overfit (KL 0.09, argmax 15/15, value 15/15), bitwise save/resume, structurally-off eval noise, eval/training separation by audit.], [`H4-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`10-`#sym.zws`pilot-`#sym.zws`01`; `scripts/`#sym.zws`run_`#sym.zws`h4_`#sym.zws`checks.`#sym.zws`sh`], [overfit criterion is KL to the soft-target entropy floor, not loss→0],
    [One generation of self-play from random init (300 games, 128/32 sims, 1.44M-param grid net) yields a net that beats legal-random 100--0 (28 wins, 2 truncations) while scoring 3.3% vs the heuristic and 3.3% vs 6400-sim MCTS: non-degenerate learning with a data/iteration-gap diagnosis.], [`H4-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`10-`#sym.zws`pilot-`#sym.zws`01`; `data/`#sym.zws`runs/`#sym.zws`pilot0/`#sym.zws`eval/`], [single seed, 30 games/opponent, gen 0 only; not a study result],
    [Gen-0 self-play truncates 56.7% of games at the 300-ply cap (170/300); generation cost ≈12 s/game wall (4 threads) at gen 0, falling toward ≈3 s/game with a trained net at the same budget.], [`H4-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`10-`#sym.zws`pilot-`#sym.zws`01`; `data/`#sym.zws`runs/`#sym.zws`pilot0/`#sym.zws`selfplay/`#sym.zws`gen000-`#sym.zws`manifest.`#sym.zws`json`], [one machine, one seed; rates specific to random-init play],
    [The two arms are capacity-matched to +1.5% (grid 1.44M, graph 1.47M params) behind the identical decoder, and the graph encoder loses no state information vs engine-generated records (property battery P1--P5, 300 real positions, zero illegal policy mass end-to-end).], [`H5-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`10-`#sym.zws`encoders-`#sym.zws`01`; `docs/`#sym.zws`representations/`], [historical: Rust mirror + golden crosscheck landed green the same day (`H5-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`10-`#sym.zws`graph-`#sym.zws`wiring-`#sym.zws`01`)],
    [Best-available-provider inference costs differ ≈1.4× against the graph arm (grid 2.62 ms/eval CoreML vs graph 3.67 ms ORT-CPU), while CPU training throughput favours the graph arm 3.5× and MPS favours the grid arm 2×.], [`H5-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`10-`#sym.zws`encoders-`#sym.zws`01`; table in `comparison-`#sym.zws`controls.`#sym.zws`md`], [one machine; reported, not equalised; feeds the same-wall-clock reading],
    [The Rust and Python graph encoders agree exactly (160 positions across all 8 game types, byte-identical tensors, nightly-pinned), and the graph arm runs end-to-end through the identical Rust MCTS.], [`H5-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`10-`#sym.zws`graph-`#sym.zws`wiring-`#sym.zws`01`; `scripts/`#sym.zws`crosscheck_`#sym.zws`graph.`#sym.zws`py`], [smoke-scale training; strength results belong to the comparison],
    [#strong[H1 is rejected under the pre-registered rule];: under both budget readings the graph arm shows no seed-consistent advantage against the frozen population, and every graph−grid interval excludes a meaningful graph advantage (largest upper bound +0.035).], [`H6-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`19-`#sym.zws`comparison-`#sym.zws`01`; `results/`#sym.zws`comparison/`#sym.zws`results-`#sym.zws`arm-`#sym.zws`difference.`#sym.zws`md`], [3 seeds/arm; one graph architecture at one capacity and budget; early-regime self-play (10 gens)],
    [Arm contrast (seed-mean, bootstrap95 over seeds): vs B-RND −0.175 \[−0.268, −0.007\] (same-examples) and −0.158 \[−0.254, −0.050\] (same-wall-clock); vs B-HEU −0.085 \[−0.143, −0.025\] and −0.072 \[−0.100, −0.028\]; vs B-MCTS +0.005 \[−0.020, +0.035\] and −0.013 \[−0.040, +0.015\].], [`results/`#sym.zws`comparison/`#sym.zws`results-`#sym.zws`*.`#sym.zws`csv`; `H6-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`19-`#sym.zws`comparison-`#sym.zws`01`], [intervals over 3 independent seeds per arm],
    [The graph arm truncates 20--57% of its games vs legal-random at the 300-ply cap (grid 0--1%); the rejection is cap-robust: scoring all truncations as graph wins leaves graph−grid at −0.072/−0.058 vs B-RND.], [`H6-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`19-`#sym.zws`comparison-`#sym.zws`01` (cap-sensitivity bounds); fig4-F1], [bound argument substitutes for a larger-cap re-run (stated)],
    [Measured campaign costs: graph runs averaged 2.0× grid training wall-clock (36.7 vs 18.0 h per 10×500-game run, mean over 5 seeds, self-play + training, evaluation excluded; 3-seed figures were 35.7 vs 18.2 h); at T\* = 18.77 h the graph arm completes 3--6 of 10 generations (4--5 over the original three seeds).], [`data/`#sym.zws`runs/`#sym.zws`cmp-`#sym.zws`*/`#sym.zws`wallclock.`#sym.zws`json`; `results/`#sym.zws`comparison/`#sym.zws`wallclock-`#sym.zws`per-`#sym.zws`run.`#sym.zws`md`; fig2], [one machine; per-arm best available provider (reported); the cost-table generator's divisor defect of 2026-10-09 affected only the previously printed means (30.0/61.2 h), never this ratio],
    [All comparison artifacts were frozen before any comparison run (population D-017, protocol D-020, openings D-025), T\* was computed from grid wall-clocks before any cross-arm number existed, and no frozen artifact was touched.], [D-017/D-020/D-025/D-026; `H6-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`16-`#sym.zws`progress-`#sym.zws`01`, `H6-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`19-`#sym.zws`comparison-`#sym.zws`01`], [none],
    [Ablation A1 (parity): removing geometric edge typing destroys trainability: NaN divergence at generation 0 in 3/3 seeds; typed edges contribute at minimum optimization stability; A1 eval tables are artifacts of a NaN policy and excluded as scores.], [`H7-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`23-`#sym.zws`a1-`#sym.zws`divergence-`#sym.zws`01`; `results/`#sym.zws`ablations/`#sym.zws`README.`#sym.zws`md`], [mechanism (6× gradient scale on the shared matrix) is a grounded hypothesis, not a measured decomposition],
    [Ablation A2: removing the global-pooling bias has no measurable effect: nogpool−full = −0.001 \[−0.170, +0.165\] (B-RND), −0.007 \[−0.043, +0.030\] (B-HEU), −0.013 \[−0.043, +0.013\] (B-MCTS); failure modes unchanged.], [`H7-`#sym.zws`2026-`#sym.zws`10-`#sym.zws`02-`#sym.zws`a2-`#sym.zws`nogpool-`#sym.zws`01`; `results/`#sym.zws`ablations/`#sym.zws`README.`#sym.zws`md`], [3 seeds/cell; 0.10M param difference inherent to the component (reported)],
    [#strong[Final 5-seed analysis (pre-committed, D-031): H1 remains rejected.] Graph−grid contrasts: B-RND −0.169 \[−0.272, −0.062\] / −0.161 \[−0.278, −0.048\]; B-HEU −0.064 \[−0.111, −0.017\] / −0.059 \[−0.087, −0.029\]; B-MCTS −0.009 \[−0.055, +0.028\] / −0.018 \[−0.066, +0.025\] (same-examples / same-wall-clock); largest upper bound +0.028. Supersedes the 3-seed tables as the study's final numbers.], [`H6-`#sym.zws`2026-`#sym.zws`10-`#sym.zws`09-`#sym.zws`5seed-`#sym.zws`final-`#sym.zws`01`; `results/`#sym.zws`comparison/`], [seeds 4--5 collected after the 3-seed analysis (disclosed); T\* fixed at the pre-registered value],
    [A1′ supplement (two-component: untyped edges + grad-clip): trains finite and scores within the full graph arm's band (all diff CIs straddle 0); with A1, the typed relations' measurable contribution at this scale concentrates in optimization stability; it is never attributed to typing alone (clip confound).], [`H7-`#sym.zws`2026-`#sym.zws`10-`#sym.zws`09-`#sym.zws`a1prime-`#sym.zws`01`; `results/`#sym.zws`ablations/`#sym.zws`README.`#sym.zws`md`], [3 vs 5 seeds; wide intervals; confounded by construction],
    [The working methodology (goal-level AI delegation under six human-only gates, file-based state, mechanical verification) caught at least five harness/process defects before they could contaminate results (pipeline deadlock, corpus setup error, eval-harness opponent defect, silent record-loss path, silent NaN divergence), each journaled at detection time.], [`docs/`#sym.zws`methodology-`#sym.zws`log.`#sym.zws`md` (workspace); journals cited per incident in @sec:working-method], [process observations from one study; no counterfactual control],
  )]
  , caption: [The claims--evidence register of this report, reproduced from the repository file with the section column removed. Every claim made in the body corresponds to one row; the limit column states what prevents a broader reading. ]
  , kind: table
  ) <tbl:prov-claims>

== Raw data, identifiers and frozen hashes
<raw-data-identifiers-and-frozen-hashes>
#strong[Location and layout.] Raw records live on disk under `data/runs/` in the study repository; they are not under version control. There is one directory per training run, `cmp-<arm>-s<seed>`, with `<arm>` in {`grid`, `graph`} for the main comparison (seeds 1--5) and in {`graph-untyped`, `graph-nogpool`, `graph-`#sym.zws`untyped-`#sym.zws`clip`} for the ablations A1, A2 and A1′ (seeds 1--3), plus `pilot0/` for the pipeline pilot. Each run directory contains: `selfplay/`#sym.zws`gen00N-`#sym.zws`*.`#sym.zws`bin` (binary record shards of generation N, v3 format, model-stamped) with `gen00N-`#sym.zws`manifest.`#sym.zws`json` (network and its fingerprint, model generation, record version, game type, seed, game count, full and cheap simulation counts, full-move fraction, temperature plies, resignation settings, counts of resigned and truncated games, number of positions, shard list); `checkpoints/`#sym.zws`gen00N/` (`hivenet-e0.pt`, `hivenet-e1.pt`, `train-config.json`) and the exported `gen00N-b1.onnx` used for play; `eval/`#sym.zws`<checkpoint>-`#sym.zws`vs-`#sym.zws`<opponent>.`#sym.zws`csv` with its `.log` for the intermediate (gen004, gen007) and final (gen009) evaluations, and `eval/`#sym.zws`tstar-`#sym.zws`gen00N-`#sym.zws`vs-`#sym.zws`<opponent>.`#sym.zws`{csv,`#sym.zws`log}` for the equal-time cutoff checkpoint; and `wallclock.json`, the per-generation wall-clock in seconds from which every time figure and the cutoff are derived. Campaign-level logs are `data/`#sym.zws`runs/`#sym.zws`campaign.`#sym.zws`log` (main runs, seeds 1--3), `extension.log` (seeds 4--5), `ablations.log` and `tstar-evals.log`. Seed derivation: base seed = 100,000 × seed; generation g uses base seed + g; evaluation network seed 9000 + gen (finals) or 9500 (cutoff sets), opponent seeds 9101 (legal-random) and 9201 (search).

#strong[Volumes.] The main campaign comprised 10 generations × 500 self-play games per run (30,000 self-play games per three-seed arm at the 3-seed stage) and 100 paired games per (checkpoint, opponent) evaluation on the frozen openings; the campaign ran from 2026-09-10 12:42 to 2026-09-17 22:31 for seeds 1--3 (≈163 h of machine time including the cutoff evaluations), with seeds 4--5 collected 2026-09-27 to 2026-10-02. Disk footprint is recorded in the evidence base only as the launch estimates (≈3--5 GB for the main campaign, ≈3--4 GB for the ablations) against 164 GB free at launch with a 20 GB guard; exact per-run sizes were not journaled. Since the deletion recorded in D-024, the study repository is the sole copy of the pre-study material it inherited (the prior-loop checkpoint and its data, 412 MB and 75 MB), which is why those files are protected by the destructive-action gate.

#strong[Frozen artifacts and their hashes.] @tbl:prov-hashes lists every frozen or pinned artifact with the identifier recorded at its freeze. The protocol hash is recorded in the decision log in abbreviated form; the full value was recomputed from the frozen commit while preparing this appendix and is identical to the hash of the current file, confirming that the protocol has not changed since its freeze.

#figure(
  align(center)[#table(
    columns: (46.8%, 12.58%, 29.58%, 11.04%),
    align: (left,left,left,left,),
    table.header([Artifact], [Frozen / pinned on], [Identifier], [Record],),
    table.hline(),
    [Protocol v1.0 (`docs/protocol.md`)], [2026-09-10], [sha256 f340a6b6…aefeb5 at commit 44a74ff (full: f340a6b64db0f5f0bf126ffb​251c3de339450bde192fd54b​719036a8a3aefeb5)], [D-020],
    [Opponent B-RND (`configs/`#sym.zws`baselines/`#sym.zws`random.`#sym.zws`toml`)], [2026-09-09], [sha256 f2fc4a06441d3c1a7922838a​6693dbb48ec54543bc34fd81​4d41c9a742514cd7], [D-017],
    [Opponent B-HEU (`configs/`#sym.zws`baselines/`#sym.zws`heuristic.`#sym.zws`toml`)], [2026-09-09], [sha256 7210a0a349c5bad5dcd2df09​9cc6865ee3cb5d8a2c30e106​ce58137804818999], [D-017],
    [Opponent B-MCTS (`configs/`#sym.zws`baselines/`#sym.zws`mcts-`#sym.zws`nonet.`#sym.zws`toml`)], [2026-09-09], [sha256 3fc8f75cf2b4f21012dd61e9​924408fbfc32c8ea561aa96e​b44f1091ba07364e], [D-017],
    [Heuristic weights (`configs/`#sym.zws`baselines/`#sym.zws`heuristic-`#sym.zws`weights.`#sym.zws`toml`)], [2026-09-09], [sha256 d0602f1895fbed70b6f84ac2​a3eb87bd68e811e53acf24d4​d7814a1495b0b97a; pinned by test `weights_`#sym.zws`pinned_`#sym.zws`for_`#sym.zws`h3_`#sym.zws`baselines`], [D-014, D-017],
    [Engine code at the population freeze], [2026-09-09], [commit b94e7c1], [D-017],
    [Shared openings (`results/`#sym.zws`comparison/`#sym.zws`openings-`#sym.zws`v1.`#sym.zws`txt`, 250 lines)], [2026-09-10], [content sha256 63b318d071dfc3ecfae35856​36c8e6f7327ddc08e7aed86a​466f915f8005af7b; frozen-file sha256 538497390a3787299c67c3ca​138b8feacb369d55dc562881​d1aee45200cbccb2; generator seed 20260910; schedule hash 8cd84b6564440666], [D-025],
    [Evaluation settings (`configs/`#sym.zws`eval-`#sym.zws`settings.`#sym.zws`toml`)], [2026-09-09], [400 simulations, no exploration noise, deterministic argmax, 300-ply cap], [D-019],
    [Comparison matrix (`configs/`#sym.zws`comparison-`#sym.zws`matrix.`#sym.zws`yaml`)], [2026-09-10], [pre-registered sizes and the cutoff rule], [D-026],
    [Equal-time cutoff T\*], [2026-09-16], [18.77 h = median of the three original grid run totals (18.77, 16.73, 19.07 h)], [`H6-`#sym.zws`2026-`#sym.zws`09-`#sym.zws`16-`#sym.zws`progress-`#sym.zws`01`; D-031],
    [Campaign and analysis code], [2026-09-10 → 2026-10-09], [campaign ac58773; analysis 1c65269 (3 seeds), 7db074d (5 seeds); ablations 216fded → bffeea9 (non-finite guard); A1′ queue 1fdd7ec], [journals `H6-…`, `H7-…`],
  )]
  , caption: [Frozen and pinned artifacts of the study with the identifiers recorded at their freeze (hashes, commits, seeds) and the decision-log or journal entry that records them. ]
  , kind: table
  ) <tbl:prov-hashes>

= Glossary
<sec:app-f>
The tables below fix the English terms used in this report, their meaning within the perimeter of the study, and the French equivalent used in the French edition. The French column reproduces the phrasing established in the French chapters; an asterisk marks a composed form, built from established pieces, that the French edition uses for the first time here.

#figure(
  align(center)[#table(
    columns: (24.78%, 45.58%, 29.65%),
    align: (left,left,left,),
    table.header([Term], [Definition], [French equivalent],),
    table.hline(),
    [grid arm / graph arm], [The two compared systems, identical except for the state encoding and the network body reading it.], [bras grille / bras graphe],
    [state encoding], [The function turning a position into the tensors a network reads; pinned byte-for-byte between engine and training code.], [encodage d'état\*],
    [shared action decoder], [The single contract by which both arms emit a policy over the same actions, namely (piece slot, destination) plus pass, with identical legal-set masking and normalisation.], [décodeur d'actions partagé],
    [opponent population], [The three fixed opponents every checkpoint is scored against, frozen on 9 September 2026.], [population d'adversaires],
    [B-RND, legal-random], [Uniform draw over the legal moves; the floor of the population.], [aléatoire légal],
    [B-HEU, heuristic], [Greedy one-ply argmax of a documented fixed-weight evaluation with queen-targeting quiescence.], [heuristique documentée à poids fixes],
    [B-MCTS, search at 6,400 simulations], [PUCT tree search without a network, uniform priors, the handcrafted evaluation as leaf value.], [MCTS sans réseau à 6400 simulations],
    [frozen], [Fixed by a dated approval and never touched afterwards; any later touch would be a new study.], [gelé / gelée],
    [pre-registered rejection rule], [The condition written into the frozen protocol under which the hypothesis is rejected: no seed-consistent graph advantage under both readings, intervals excluding a meaningful advantage.], [règle de rejet pré-enregistrée\*],
    [seed (independent training run)], [One complete training run from a seeded initialisation; the unit of replication and resampling.], [graine (exécution d'entraînement indépendante)],
    [generation], [One cycle of self-play, training and checkpoint export; ten per run.], [génération],
    [checkpoint], [The exported network at the end of a generation; identifiers zero-based (gen000 to gen009).], [point de contrôle],
    [paired colour-swapped games], [Each opening line played once with each colour, so all arms, seeds and opponents face identical schedules.], [parties appariées, à couleurs échangées],
    [pinned evaluation settings], [400 simulations per decision, no exploration noise, deterministic argmax; fixed by file and test.], [réglages d'évaluation épinglés],
  )]
  , caption: [Study-design terms.]
  , kind: table
  ) <tbl:f-design>

#figure(
  align(center)[#table(
    columns: (18.98%, 52.32%, 28.7%),
    align: (left,left,left,),
    table.header([Term], [Definition], [French equivalent],),
    table.hline(),
    [One-Hive rule], [No move may split the hive, including in transit; a piece whose removal would split it is pinned.], [One-Hive (kept in English)],
    [freedom to move], [A sliding piece may only pass through a gap whose two flanking cells are not both occupied.], [liberté de mouvement],
    [gate], [Two occupied cells flanking a step, blocking a slide; above ground level, the beetle gate.], [porte (porte du scarabée)],
    [stacking], [Beetles climb onto pieces, forming stacks; only the top piece acts.], [empilement],
    [stun], [The marker on a piece just thrown by a pillbug, which cannot move next ply; inert in the base game.], [étourdissement],
    [forced pass], [With no legal move a side must pass; pass is legal exactly when no move exists.], [passe forcée],
    [ply], [One move by one side (half-move); the cap is 300 plies.], [pli / demi-coup],
    [opening (frozen line)], [A four-ply prefix played before the agents take over; 250 frozen lines shared by every match.], [ouverture],
  )]
  , caption: [Hive terms.]
  , kind: table
  ) <tbl:f-hive>

#figure(
  align(center)[#table(
    columns: (23.84%, 50.33%, 25.83%),
    align: (left,left,left,),
    table.header([Term], [Definition], [French equivalent],),
    table.hline(),
    [self-play], [Games the current network plays against itself, through the search, to produce training records.], [auto-jeu],
    [Monte-Carlo tree search (MCTS)], [The search of both arms and of B-MCTS; the network supplies priors and a leaf value.], [recherche arborescente Monte-Carlo (MCTS)],
    [PUCT], [The selection rule: maximise Q + c·prior·√N/(1+n), c = 1.4.], [PUCT],
    [policy], [The network's distribution over legal actions, trained towards the recorded visit distribution.], [politique],
    [value], [The network's estimate in \[−1, 1\] of the outcome for the side to move; a three-class head, truncated records excluded.], [valeur],
    [visit distribution], [Normalised root visit counts after a search; the policy target.], [distribution de visites],
    [playout-cap randomization], [A fraction 0.25 of self-play decisions gets 128 simulations and is recorded; the rest get 32 and are not.], [randomisation du plafond de simulations],
    [temperature plies], [The first 12 plies of a self-play game, sampled rather than taken by argmax.], [plis en température],
    [resignation], [A self-play game is abandoned when the value falls below −0.92.], [abandon],
    [resignation audit], [A 10% fraction of self-play games played to the end regardless, to check that resignation hides no wins.], [audit sans abandon],
    [policy top-1], [Training-fit metric: share of records whose policy argmax matches the target's argmax.], [argmax de politique (top-1)\*],
    [value accuracy], [Training-fit metric: share of records whose predicted outcome class is the recorded one.], [exactitude de la valeur\*],
  )]
  , caption: [Search and self-play terms.]
  , kind: table
  ) <tbl:f-selfplay>

#figure(
  align(center)[#table(
    columns: (27.59%, 41.28%, 31.13%),
    align: (left,left,left,),
    table.header([Term], [Definition], [French equivalent],),
    table.hline(),
    [frame (32×32)], [The fixed grid into which the grid arm embeds a position, centred on the bounding box; 77 feature planes.], [cadre 32×32 ; plans de caractéristiques],
    [message passing], [The graph arm's computation: each node updates from its neighbours, layer by layer.], [passage de messages],
    [direction-typed relations], [The six hexagonal directions as edge types, each with its own weights.], [relations d'arêtes typées par direction],
    [global-pooling bias], [A pooled summary of all nodes added back into every node; removed in ablation A2.], [biais de pooling global (biais d'agrégation globale)],
    [capacity-matched], [Near-equal parameter counts: 1.44 M (grid) and 1.47 M (graph), +1.5%.], [à capacité appariée],
    [naive adjacency], [Ablation A1: the six typed edge matrices replaced by one shared matrix.], [adjacence naïve],
    [gradient clipping], [The norm clip at 1.0 added in the A1′ supplement, making it a two-component variant.], [écrêtage de gradient],
  )]
  , caption: [Representation and network terms.]
  , kind: table
  ) <tbl:f-networks>

#figure(
  align(center)[#table(
    columns: (24.72%, 47.9%, 27.37%),
    align: (left,left,left,),
    table.header([Term], [Definition], [French equivalent],),
    table.hline(),
    [truncation (never "draw")], [A game stopped at the 300-ply cap; a fourth outcome, never folded into draws.], [troncature (partie tronquée)],
    [move cap], [The 300-ply limit at which a game is truncated.], [plafond de coups (plafond de 300 demi-coups)],
    [score], [Mean of win 1 / draw 0.5 / loss 0 over the non-truncated games of a (seed, opponent) cell.], [score],
    [truncation rate], [Share of a cell's 100 games that were truncated; always reported beside the score.], [taux de troncature\*],
    [sensitivity score], [The cell's mean over all games with truncations counted 0.5.], [colonne de sensibilité « troncatures à 0.5 »],
    [cap-treatment bounds], [The contrast recomputed with truncations as losses and as wins, bracketing any other cap.], [bornes de traitement du plafond],
    [seed-level mean], [The plain mean of the per-seed cell scores of one arm against one opponent.], [moyenne au niveau des graines],
    [seed-level bootstrap interval], [A 95% percentile bootstrap interval from resampling seeds (never games) 10,000 times.], [intervalle bootstrap sur les graines],
    [percentile interval], [The interval whose ends are the 0.025 and 0.975 quantiles of the sorted resample statistics; no bias correction.], [bootstrap percentile],
    [arm contrast], [The graph-minus-grid difference of seed-level means, with its interval from independently resampled seed sets.], [contraste entre bras],
  )]
  , caption: [Outcome and statistics terms.]
  , kind: table
  ) <tbl:f-statistics>

#figure(
  align(center)[#table(
    columns: (25.17%, 46.58%, 28.26%),
    align: (left,left,left,),
    table.header([Term], [Definition], [French equivalent],),
    table.hline(),
    [budget], [A run's resources in four denominations: wall-clock, hardware, training states, simulations.], [budget (temps mural, matériel, états d'entraînement, simulations)],
    [wall-clock], [Elapsed real time on the study machine, logged per generation; a run's training wall-clock excludes its evaluation games.], [temps mural],
    [same-examples reading], [The comparison at equal self-play budget: both arms' tenth-generation checkpoints after 10 generations × 500 games.], [lecture à exemples égaux],
    [same-wall-clock reading], [The comparison at equal training time: each run's last checkpoint within the equal-time cutoff.], [lecture à temps mural égal],
    [equal-time cutoff], [18.77 h, the median full-run wall-clock of the grid arm's three original runs, fixed by a pre-registered rule on 16 September 2026.], [seuil à temps mural égal],
    [simulations per decision], [The search budget: 128 full / 32 cheap in self-play, 400 in evaluation, 6,400 for B-MCTS.], [simulations par décision],
  )]
  , caption: [Budget terms.]
  , kind: table
  ) <tbl:f-budget>

= Reproduction guide
<sec:app-g>
This is the one place in the report where commands, file names and identifiers appear verbatim, because reproducing the study requires them: what is released, the minimal scenario run in a fresh environment on 9 October 2026, the full command set, the durations to expect, and the identifiers a reproduction must match.

== What is released
<what-is-released>
The release set is the repository `hive-`#sym.zws`graph-`#sym.zws`selfplay` and the records under it. Its access and release tag are fixed at diffusion time; at the time of writing nothing has left the study machine, and the licences of the third-party reference engines used only for rules validation are still under review.

- #strong[Code.] The Rust engine (rules kernel, protocol server, search, arena, self-play workers), the Python training and export code under `python/hivenet/`, the scripts under `scripts/`.
- #strong[Frozen configurations.] `configs/`#sym.zws`comparison-`#sym.zws`matrix.`#sym.zws`yaml`, `configs/`#sym.zws`eval-`#sym.zws`settings.`#sym.zws`toml`, the opponent configurations and heuristic weight file under `configs/`#sym.zws`baselines/`, the ablation specifications under `configs/`#sym.zws`ablations/`.
- #strong[Frozen openings and population manifest.] `results/`#sym.zws`comparison/`#sym.zws`openings-`#sym.zws`v1.`#sym.zws`txt` (250 four-ply lines) and `opponents-`#sym.zws`manifest.`#sym.zws`md`, which records the hashes of @tbl:g-identifiers.
- #strong[Result tables.] `results/`#sym.zws`comparison/`#sym.zws`results-`#sym.zws`same-`#sym.zws`examples.`#sym.zws`{md,`#sym.zws`csv}`, `results-`#sym.zws`same-`#sym.zws`wallclock.`#sym.zws`{md,`#sym.zws`csv}`, `results-`#sym.zws`arm-`#sym.zws`difference.`#sym.zws`md`, `wallclock-`#sym.zws`per-`#sym.zws`run.`#sym.zws`md`; `results/`#sym.zws`ablations/`#sym.zws`README.`#sym.zws`md`.
- #strong[Per-run records];, under `data/`#sym.zws`runs/`#sym.zws`cmp-`#sym.zws`<arm>-`#sym.zws`s<seed>/`: `eval/` (one comma-separated file per checkpoint and opponent, one row per game: `opening_id, a_is_white, score_a, truncated, plies, outcome`, metadata in `#` header lines); `wallclock.json` (seconds per generation); `selfplay/` manifests tying each shard to its generating network, and the shards; `checkpoints/`#sym.zws`gen000-`#sym.zws`b1.`#sym.zws`onnx` to `gen009-b1.onnx`. Tables and figures need only `eval/` and `wallclock.json`; the replay needs one checkpoint.

The third-party engines used in rules validation (Mzinga, nokamute) are not shipped and are not needed: no study number derives from them.

== The minimal fresh-environment scenario
<the-minimal-fresh-environment-scenario>
`scripts/reproduce_minimal.sh <workdir>` performs, from a clean clone plus the shipped records, the smallest end-to-end check that touches every link of the chain: build, play, record, aggregate. It passed on 9 October 2026 and again the same day after a prose fix to the table generator, with an empty numeric difference. Its four steps:

+ #strong[Clone and build.] `git clone` into `<workdir>/clone`, then `cargo build --release -p hive-engine -p hive-arena`; the engine binary must exist afterwards. The inference crate downloads the ONNX Runtime binary at first build, so the first build needs network access.
+ #strong[Ship the records.] Copy `results/`#sym.zws`comparison/`, every run's `eval/` and `wallclock.json`, and the single checkpoint `cmp-`#sym.zws`grid-`#sym.zws`s2/`#sym.zws`checkpoints/`#sym.zws`gen009-`#sym.zws`b1.`#sym.zws`onnx` into the clone, as the release layout would.
+ #strong[Replay one recorded game deterministically.] The game is failure position F2 of the qualitative results: the grid arm's seed-2 final checkpoint against B-HEU on opening line 2, the arm playing Black, lost in 19 plies. The arena plays that opening's colour pair (`--games 2 --depth 1 --seed 1 --threads 1`), the network at 400 simulations with seed 9009 (the final-evaluation rule, 9000 + generation index), B-HEU at depth 1 on one thread; the script asserts that the Black-side row's `score_a`, `truncated` and `plies` equal the shipped row in `cmp-`#sym.zws`grid-`#sym.zws`s2/`#sym.zws`eval/`#sym.zws`gen009-`#sym.zws`vs-`#sym.zws`B-`#sym.zws`HEU.`#sym.zws`csv` and prints `replay matches shipped row: plies 19, score 0`.
+ #strong[Regenerate and compare.] `python3 scripts/make_results.py` (standard-library Python only) rebuilds both reading tables from the shipped records; `cmp` against the shipped `results-`#sym.zws`same-`#sym.zws`examples.`#sym.zws`md` and `results-`#sym.zws`same-`#sym.zws`wallclock.`#sym.zws`md` must report them byte-identical. The script ends with `MINIMAL REPRODUCTION: PASS`.

The scenario verifies that the released code builds from a clean checkout, that a recorded game is replayed exactly by the released checkpoint against the released opponent under the pinned settings, and that the published tables are a pure function of the released records. It does not verify training; that is the full reproduction below.

== Full reproduction commands
<full-reproduction-commands>
```sh
# toolchain: Rust (cargo) and Python 3; the project virtual environment is python/.venv
cargo build --release                      # engine, arena, self-play and fuzz binaries
cargo test                                 # rules kernel: unit tests, perft to depth 5 for all 8 game types, UHP server tests
cargo test --release -p hive-core --test perft_tables -- --ignored   # perft to depth 6

# one training run of the matrix (resumable per generation); repeat for --seed 2 … 5
python3 scripts/run_comparison.py --arm grid  --seed 1 --gens 10 --games 500
python3 scripts/run_comparison.py --arm graph --seed 1 --gens 10 --games 500
# ablations (seeds 1–3): --arm graph-untyped | graph-nogpool | graph-untyped-clip

# equal-time checkpoint evaluations for runs whose cutoff checkpoint is not the final one
bash scripts/tstar_evals.sh                # seeds 1–3
bash scripts/tstar_evals2.sh               # graph seeds 4–5

# regenerate every table and figure from raw per-game records
python3 scripts/make_results.py
python/.venv/bin/python scripts/make_figures.py

# pre-training check battery on any shard set
bash scripts/run_h4_checks.sh '<abs>/gen000-*.bin' '<abs>/gen000-manifest.json'

# fresh-environment minimal reproduction (clone, build, replay, compare)
bash scripts/reproduce_minimal.sh /tmp/repro

# French/English numeric-identity check; report build
python3 scripts/check_fr_numbers.py
python/.venv/bin/python scripts/build_report.py all
```

The training driver is resumable per generation: a re-run skips completed generations and continues with the same learning-rate schedule, and every run writes its generator settings, seeds and model stamps into its manifests. Seeds derive from the run's seed number: base seed = 100,000 × seed, generation $g$ using base seed + $g$; evaluation uses network seed 9000 + generation (final sets) or 9500 (equal-time sets), opponent seeds 9101 (B-RND) and 9201 (B-MCTS).

== Expected durations and disk
<expected-durations-and-disk>
All durations in @tbl:g-durations were measured on the study machine (Apple M1 Pro, 10 cores, 16 GB, macOS 15.3.1) with four worker threads per run and sequential runs; the grid arm's inference runs on CoreML (2.62 ms per evaluation), the graph arm's on CPU (3.67 ms), each the fastest provider measured for that network.

#figure(
  align(center)[#table(
    columns: (61.45%, 38.55%),
    align: (left,right,),
    table.header([Step], [Measured duration],),
    table.hline(),
    [One grid training run (10 generations × 500 games): training wall-clock, evaluation games excluded], [16.7--19.1 h],
    [One graph training run (same budget): training wall-clock, evaluation games excluded], [26.6--49.9 h],
    [All ten main-campaign runs, training wall-clock summed], [273.5 h (grid 90.0 h, graph 183.5 h)],
    [Original six-run campaign (seeds 1--3, both arms, sequential), elapsed], [10--17 September 2026, ≈7.4 days; ≈163 h of machine time],
    [Extension runs (seeds 4--5, both arms), elapsed per run as recorded], [18.0--54.9 h, 27 September to 2 October 2026],
    [One evaluation game at 400 simulations], [≈23--32 s],
    [Equal-time evaluation sets, seeds 1--3 (four checkpoints × three opponents)], [≈11 h, 18 September 2026],
    [Equal-time evaluation sets, graph seeds 4--5 (two checkpoints × three opponents)], [≈6 h, 6 October 2026],
    [Ablation runs A1 / A2 / A1′ (per seed), training wall-clock], [7.61--8.01 h (a divergence symptom) / 32.05--47.44 h / 23.89--30.35 h],
    [Engine build; minimal scenario], [not measured],
  )]
  , caption: [Measured durations of the study's computations on the study machine (Apple M1 Pro, four worker threads per run, sequential runs), as recorded in the run and analysis records; ranges span the runs of the step. Training wall-clock is the sum of a run's per-generation self-play and training seconds, evaluation games excluded; campaign, extension and ablation figures are elapsed times as recorded. A1's short runs reflect its divergence (a NaN policy plays short degenerate games) rather than a lower cost. The engine build and the minimal scenario were not timed.]
  , kind: table
  ) <tbl:g-durations>

Disk: before the campaign the six-run matrix was sized at about 3--5 GB of shards, checkpoints and records, against 164 GB free with a 20 GB guard; mid-campaign the machine reported 200 GB free. The final footprint of the run directories was not recorded.

== Identifiers a reproduction must match
<identifiers-a-reproduction-must-match>
A reproduction is faithful when it uses the frozen artifacts identified below and, for the minimal scenario, reproduces the shipped game row and the byte-identical tables. The frozen experimental constants that every command must leave untouched are tabulated in @sec:app-c: base game with the tournament opening rule, 300-ply cap, 128/32 self-play simulations with full fraction 0.25, 12 temperature plies, resignation at −0.92 with a 10% audit, 400 evaluation simulations without noise, 100 games per opponent, 250 openings, the 18.77 h cutoff, seeds 1--5 per arm.

#figure(
  align(center)[#table(
    columns: (58.28%, 41.72%),
    align: (left,left,),
    table.header([Artifact], [Identifier],),
    table.hline(),
    [Heuristic weight file (`configs/`#sym.zws`baselines/`#sym.zws`heuristic-`#sym.zws`weights.`#sym.zws`toml`), SHA-256], [`d0602f1895fbed70b6f84ac2a3eb87bd`#sym.zws`68e811e53acf24d4d7814a1495b0b97a`],
    [B-RND configuration (`configs/`#sym.zws`baselines/`#sym.zws`random.`#sym.zws`toml`), SHA-256], [`f2fc4a06441d3c1a7922838a6693dbb4`#sym.zws`8ec54543bc34fd814d41c9a742514cd7`],
    [B-HEU configuration (`configs/`#sym.zws`baselines/`#sym.zws`heuristic.`#sym.zws`toml`), SHA-256], [`7210a0a349c5bad5dcd2df099cc6865e`#sym.zws`e3cb5d8a2c30e106ce58137804818999`],
    [B-MCTS configuration (`configs/`#sym.zws`baselines/`#sym.zws`mcts-`#sym.zws`nonet.`#sym.zws`toml`), SHA-256], [`3fc8f75cf2b4f21012dd61e9924408fb`#sym.zws`fc32c8ea561aa96eb44f1091ba07364e`],
    [Frozen openings, content of the 250 lines, SHA-256], [`63b318d071dfc3ecfae3585636c8e6f7`#sym.zws`327ddc08e7aed86a466f915f8005af7b`],
    [Frozen openings, file as frozen, SHA-256], [`538497390a3787299c67c3ca138b8fea`#sym.zws`cb369d55dc562881d1aee45200cbccb2`],
    [Opening/colour schedule of every 100-game match], [`8cd84b6564440666`],
    [Frozen protocol document], [`f340a6b6…aefeb5` (recorded abbreviated), commit `44a74ff`],
    [Engine code at the population freeze], [commit `b94e7c1`],
    [Campaign code (main comparison)], [commit `ac58773`],
    [Ablation code; non-finite-loss guard], [commits `216fded`; `bffeea9`],
    [Analysis code (final five-seed tables)], [commit `7db074d`],
  )]
  , caption: [Identifiers of the frozen artifacts and code states of the study. Hashes are SHA-256 hexadecimal digests of file content as recorded at the freeze; the schedule hash is the digest prefix printed by the analysis tool for the (opening, colour) schedule, identical for every match of the study; commits are abbreviated repository commit identifiers.]
  , kind: table
  ) <tbl:g-identifiers>

#v(2em)
#align(center)[#text(size: 8.5pt, fill: luma(110))[v2.0-draft, 2026-10-09]]
