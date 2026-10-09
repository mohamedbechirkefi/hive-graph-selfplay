# Background: Hive, self-play learning and state representations {#sec:background}

This chapter sets out what the rest of the report takes for granted: the rules of Hive and what makes it awkward for learning machines; the formal objects the study manipulates, including the truncation convention; AlphaZero-style self-play as the system implements it, including a loss that departs from the usual form in two deliberate respects; the two state representations compared; the budget conventions under which they are compared; and the statistics for evaluating agents from a handful of independent training runs.

## The game of Hive {#sec:bg-hive}

Hive, designed by John Yianni and published by Gen42 Games, is a two-player, perfect-information, zero-sum game of alternating moves. It is played without a board: hexagonal tiles are placed on any flat surface, and the tiles in play define the playing surface. In the base game each player owns eleven tiles: one queen bee, two spiders, two beetles, three grasshoppers and three soldier ants. Three further tiles (mosquito, ladybug, pillbug) exist as expansions; the engine used here implements them, but no result in this report involves an expansion.
<!-- src: crates/hive-core/src/bug.rs:71-86; paper/ch2-formalisation.md:9-16; tests/critical_positions/README.md:58 -->

### Placement

Play begins with one player placing a tile and the other joining a tile of their own to it edge to edge. Afterwards, a tile entering play may not touch a tile of the opponent's colour. The queen bee must enter by each player's fourth turn, and no tile may move before its owner's queen is in play. The study adopts the tournament opening rule (no queen on either player's first turn), which is the convention of the Universal Hive Protocol and of both reference engines against which the rules kernel was validated; the publisher's 2010 rulesheet alone would permit a first-turn queen.
<!-- src: paper/annex-corpus.md:9-42; tests/critical_positions/README.md:13-18 -->

### Movement

The queen bee slides one cell. The beetle also moves one cell but may climb on top of the hive; a tile covered by a beetle cannot move, and for placement purposes a stack takes the colour of the beetle on top. The grasshopper does not slide at all: it jumps in a straight line over one or more adjacent tiles to the first empty cell beyond them. The spider slides exactly three cells along the outside of the hive, without backtracking. The soldier ant slides to any reachable cell around the hive. Beetle climbs produce stacks, and a stack's height matters: a tile moving above ground level must also be able to slide, and a *beetle gate* formed by two taller neighbouring stacks blocks it.
<!-- src: paper/annex-corpus.md:44-120 -->

Two global constraints cut across these movements. The **One-Hive rule** requires the tiles in play to remain connected at all times: a tile that is the only link between two parts of the hive may not move, whatever its own movement rule would allow. The **freedom-to-move rule** requires a sliding tile to pass physically between its neighbours: a cell whose two flanking cells are both occupied cannot be slid into or out of. Together they mean that the legal moves of a piece depend on the whole configuration rather than on the piece's neighbourhood alone.
<!-- src: paper/annex-corpus.md:51-57,79-84,135-147 -->

### End of the game

The game ends as soon as a queen bee is surrounded on all six sides by tiles of any colour; its owner loses, even when the owner's own move completed the surround. If one move completes the surround of both queens, the game is drawn; the engine additionally declares a draw on threefold repetition. A player who can neither place nor move must pass, and the opponent moves again.
<!-- src: paper/annex-corpus.md:149-168; tests/critical_positions/README.md:70-75; paper/ch2-formalisation.md:34-36 -->

### Why Hive is hard for machines

Four properties make Hive an unusual object for the methods of `@sec:bg-selfplay`{=typst}, all of which were developed on games with a fixed board.

*Frameless geometry.* There is no board tensor to fill in. A position is a finite connected set of occupied cells of arbitrary shape and extent, plus the empty cells around it; its absolute location and orientation carry no meaning. Any fixed-size array encoding must therefore choose an anchor and a frame, a modelling decision with consequences (`@sec:bg-representations`{=typst}).

*Stacking.* Beetles climb, so a cell may carry several tiles, and buried tiles remain relevant: they count toward surrounds and reappear when the beetle leaves.

*Branching and length.* Kampert et al. (2021) measure an average branching factor that stabilises around 60, roughly twice that of chess, and find that full-width search to depth four already costs tens of seconds on a highly optimised engine, so the bottleneck is evaluation quality rather than search speed. Games are long: the longest search-guided game observed while profiling the engine ran 202 plies, and self-play from a randomly initialised network reached the 300-ply cap of `@sec:bg-formal`{=typst} in 56.7% of games.
<!-- src: docs/reading/kampert-2021-mimicking-hive.md:13,24; docs/protocol.md:57-62 -->

*Legality is non-local.* Under the One-Hive and freedom-to-move rules, whether a move exists depends on the global configuration (articulation points of the hive, gates formed by distant stacks) and on empty space. The same authors found no cheap reliable hand-crafted evaluation: the intuitive count of tiles around the enemy queen is actively misleading when weighted heavily. Hence the case for learning the evaluation, and for asking which representation lets a network learn it most efficiently.
<!-- src: docs/reading/kampert-2021-mimicking-hive.md:13,25 -->

## Formalisation used in the study {#sec:bg-formal}

`@tbl:notation`{=typst} collects the symbols used from here on.

A **state** $s$ comprises the tiles in play with their cells and stack levels, the tiles still in hand for each player, the side to move, the ply count, and a marker for the tile moved on the previous ply (relevant only under the pillbug expansion; carried for kernel uniformity and part of the hashed position). The engine exposes $s$ over the Universal Hive Protocol, and its rules correctness was established independently of any learning component (`@sec:engine`{=typst}).
<!-- src: paper/ch2-formalisation.md:20-26 -->

An **action** is a pair $a = (p, d)$ of a piece $p$ and a destination cell $d$, together with one distinguished action, *pass*, which is legal exactly when no move exists. The pair identifies a Hive move uniquely, since the rare cases in which a tile could reach the same cell by two mechanisms produce identical successor states. Pieces are addressed relative to the side to move, so that an action index means the same thing for either colour. The set of legal actions $A(s)$ is produced by the engine's move generator; both learned architectures receive it and normalise their policies over exactly $A(s)$ through a shared decoder (`@sec:bg-representations`{=typst}). The **transition** $s' = T(s, a)$ is the engine's move application.
<!-- src: paper/ch2-formalisation.md:28-34; docs/action-decoder.md:9-22 -->

**Outcomes** are expressed from the perspective of the player to move in the state being scored: a win is $+1$, a loss $-1$, a draw $0$. Because a player can lose by surrounding their own queen, the implementation computes the sign from the result and the side to move rather than assuming that the previous mover won.
<!-- src: docs/action-decoder.md:72-77; crates/hive-mcts/src/lib.rs:136-147 -->

**Experimental truncation.** Self-play and evaluation games are stopped after 300 plies. A game stopped this way is *not* a draw. It forms a fourth outcome class, *truncated*, carried as such through the data format, the training loss (truncated records contribute no value target, `@sec:bg-selfplay`{=typst}), the match runner, every result table (a separate truncation-rate column) and the statistical analysis. The cap was set from measurement, above the longest observed search-guided game, and was frozen with the rest of the protocol on 10 September 2026, before any comparison run. Treating a capped game as a draw would silently teach the value head that long, unresolved games are balanced; keeping truncation separate makes its frequency a reported quantity and lets the sensitivity of every conclusion to the cap be tested (`@sec:bg-evaluation`{=typst}).
<!-- src: docs/protocol.md:3,55-75; paper/ch2-formalisation.md:38-45 -->

| Symbol | Meaning |
| --- | --- |
| $s$, $s'$ | a game state and its successor |
| $A(s)$ | the set of legal actions in $s$ (moves, plus pass when no move exists) |
| $a = (p, d)$ | an action: piece $p$ to destination cell $d$ |
| $T(s, a)$ | the transition (the engine's move application) |
| $z \in \{+1, 0, -1\}$ | terminal outcome from the mover's perspective: win, draw, loss |
| truncated | fourth outcome class: game stopped at the 300-ply cap; never a draw |
| $p_\theta(a \mid s)$, $v_\theta(s)$ | network policy over $A(s)$ and network value in $[-1, 1]$ |
| $P(s,a)$, $N(s,a)$, $Q(s,a)$ | prior, visit count and mean value of a search edge |
| $N(s)$ | visit count of the node $s$ |
| $c$ | exploration constant of the selection rule (1.4) |
| $\varepsilon$, $\alpha$ | root-noise mixing weight (0.25 in self-play, 0 in evaluation) and concentration (0.15) |
| $\pi(a \mid s)$ | recorded root visit distribution; the policy target |
| $\lambda_v$ | weight of the value loss (0.6) |
| $h_i$, $h_i'$ | embedding of graph node $i$ before and after a message-passing layer |
| $n_i(d)$ | the neighbour of node $i$ in hexagonal direction $d \in \{1, \dots, 6\}$ |
| $W_{\mathrm{self}}$, $W_d$, $b$ | self-weight, direction-typed weights and bias of a message-passing layer |
| score | mean of win $= 1$, draw $= 0.5$, loss $= 0$ over non-truncated evaluation games |
| seed | one independent training run; the unit of analysis |

Table: Notation used in this report. {#tbl:notation}

<!-- src: paper/ch2-formalisation.md:47-66; crates/hive-mcts/src/lib.rs:98-109; docs/representations/graph.md:94-99; docs/protocol.md:79-83 -->

## Self-play learning in the AlphaZero family {#sec:bg-selfplay}

### Policy-value network and search

AlphaZero (Silver et al., 2018) learns to play from the rules alone. A single network with parameters $\theta$ maps a state to a policy $p_\theta(\cdot \mid s)$ over actions and a value $v_\theta(s)$ estimating the outcome for the player to move. The network does not play directly: it guides a Monte-Carlo tree search, and the search, which is stronger than the raw network, generates the games on which the network is then trained. Silver et al. ran 800 simulations per move during self-play and reached superhuman strength in chess, shogi and Go with thousands of specialised accelerators and a single training run per game; the study described here keeps the algorithmic core and changes the scale, the game and the statistics.
<!-- src: docs/reading/silver-2017-alphazero.md:25-32,39-51 -->

Search proceeds by repeated descents from the root. At a node $s$ the implementation selects the edge maximising

$$ Q(s,a) + c \, P(s,a) \, \frac{\sqrt{N(s)}}{1 + N(s,a)} $$
{#eq:puct}

with $c = 1.4$, which is the PUCT rule of Silver et al. Here $P(s,a)$ is the network prior, normalised over $A(s)$; $N(s,a)$ the number of visits through the edge; $N(s)$ the parent's visit count, taken as at least one; and $Q(s,a)$ the mean of the values backed up through the edge from the parent's point of view (the child's values are negated, its side to move being the opponent). Two implementation details matter for reproducibility. Leaf evaluations are batched: a descent that reaches an unevaluated leaf waits for the batch to fill, and meanwhile a *virtual loss* (one extra visit counted as a loss in both $Q$ and $N$) is placed on every edge of its path, so that concurrent descents spread out. And an edge whose child has never been visited takes $Q(s,a) = Q(s) - 0.2$, where $Q(s)$ is the parent's own mean value: a *first-play urgency* reduction that discourages opening every child before deepening the promising ones. A new leaf is scored by the network; its value is backed up along the path with alternating sign, and terminal nodes back up their exact outcome. When the simulation budget is spent, the search returns the most-visited root move and the vector of root visit counts.
<!-- src: crates/hive-mcts/src/lib.rs:69,98-109,165-201,285-297,373-386 -->

### Exploration in self-play

Two devices make self-play games diverse. At the root, the priors are mixed with noise, $P(s,a) \leftarrow (1 - \varepsilon)\, P(s,a) + \varepsilon\, \eta_a$, with $\varepsilon = 0.25$ and $\eta$ a random vector drawn once per search from an approximate Dirichlet distribution of concentration $\alpha = 0.15$ (approximated in the implementation by normalised transformed uniform draws rather than exact Gamma variates). Silver et al. scaled $\alpha$ to each game's typical number of legal moves ($0.3$ for chess, $0.15$ for shogi, $0.03$ for Go); the value used here is their shogi setting. For the first 12 plies of a game the move actually played is sampled in proportion to the root visit counts (temperature one); thereafter the most-visited move is played. Evaluation games apply none of this: $\varepsilon = 0$, no temperature, the most-visited move always played, at 400 simulations per decision, enforced by test and pinned by configuration.
<!-- src: crates/hive-mcts/src/lib.rs:324-345; crates/hive-selfplay/src/bin/selfplay_mcts.rs:90-105,164-172,216-220; docs/reading/silver-2017-alphazero.md:70; configs/eval-settings.toml:11-14 -->

### Training targets and the loss as implemented

Every recorded decision yields a training example: the state, the root visit distribution $\pi(\cdot \mid s)$ (the fifteen most-visited actions, renormalised), the legal set $A(s)$, and the game's eventual outcome $z$ from that state's mover's perspective, or else the marker *truncated*. The policy target is the search distribution rather than the move played, because the search improves on the network's prior and the network is trained to predict that improvement.
<!-- src: python/hivenet/dataset.py:36,117-125; docs/action-decoder.md:54-57 -->

Both arms minimise the same loss. For a mini-batch of $B$ records let $K \subseteq \{1, \dots, B\}$ be the records whose outcome is a win, draw or loss, and let $q_\theta(\cdot \mid s)$ be the three-way softmax of the value head over those three classes. Then

$$ \mathcal{L}(\theta) = -\frac{1}{B} \sum_{b=1}^{B} \sum_{a \in A(s_b)} \pi(a \mid s_b)\, \log p_\theta(a \mid s_b) \; - \; \lambda_v\, \frac{1}{|K|} \sum_{b \in K} \log q_\theta(z_b \mid s_b), \qquad \lambda_v = 0.6 . $$
{#eq:loss}

The first term is the cross-entropy between the recorded visit distribution and the network policy, where $p_\theta(\cdot \mid s)$ is a softmax over *exactly* the legal set (the grid arm sets every illegal logit to a large negative constant before the softmax; the graph arm produces logits for legal candidates only), so that illegal actions carry identically zero mass in both arms and training uses the normalisation that search uses. The second term is the cross-entropy of the three-class outcome, averaged over the $|K|$ non-truncated records only (a batch without any contributes nothing) and down-weighted by $\lambda_v = 0.6$. The two departures from a plain joint policy-value loss are the legal masking, which removes a confound between the arms (the grid arm's 28,673-way head would otherwise spend capacity suppressing indices that are never legal), and the exclusion of truncated games from the value target, the training-side half of the truncation convention.
<!-- src: python/hivenet/train.py:40-51,152-154; python/hivenet/train_graph.py:29-30,119-121; docs/action-decoder.md:27-29,40-47 -->

### Economies for small budgets

The cost of self-play is dominated by search. Wu (2020) showed in the KataGo project that an AlphaZero-style pipeline can be made far more sample-efficient by a handful of representation-agnostic changes. The one adopted here, identically for both arms, is **playout-cap randomization**: the value head needs many games while the policy head needs deep searches, so most decisions are searched cheaply and not recorded, and a minority receive a full search and become training examples. Wu used full searches of 600–1,000 visits on about a quarter of turns and fast searches of 100–200 visits otherwise; the study uses 128 and 32 simulations and records one decision in four, values that were measured on the study machine, as the protocol chapter explains. Self-play also ends a game by **resignation** when the root value falls below $-0.92$, recording a loss for the resigning side; in 10% of games, chosen before the first move, resignation is disabled so that the rate at which a "lost" position would in fact have been saved can be audited, a standard safeguard of self-play pipelines.
<!-- src: docs/reading/wu-2020-katago.md:20-23,63-64; crates/hive-selfplay/src/bin/selfplay_mcts.rs:187-190,200-214,236-240; paper/annex-architectures.md:87-92; docs/protocol.md:112-116 -->

## State representations {#sec:bg-representations}

Everything above is indifferent to how a state is handed to the network, which is the variable of this study. `@fig:encodings`{=typst} shows one position under the two encodings compared.

![A five-tile Hive position under the two encodings compared in this study. Left, the grid arm's view: the position embedded in a fixed 32×32 frame of hexagonal cells (drawn for orientation), each frame cell carrying 77 feature values, so that tiles appear as activations at frame coordinates. Right, the graph arm's view: the cell graph over the candidate set, in which occupied cells (filled, labelled by colour and tile) and every empty cell adjacent to the hive (open circles), together the set of all legal destinations, are joined by edges typed with the six hexagonal directions. Both views derive from the same engine state without loss; only the structure offered to the network differs.](figures/fig3-encodings.png){#fig:encodings width=90%}

<!-- src: docs/representations/grid.md:9-16,38; docs/representations/graph.md:19-56 -->

### Stacked planes for convolutional networks

The canonical encoding of the AlphaZero family is a stack of binary or scalar planes over the board array, read by a residual convolutional network, which convolution makes translation-equivariant, with a receptive field that widens with depth. Silver et al. used more than a hundred planes over the 8×8 chess board and 17 planes for Go, and expressed the policy itself as spatial planes. The encoding presupposes a fixed array. For Hive one must manufacture it: the grid arm unwraps the engine's board, stored on a wrapping torus, by breadth-first traversal from any occupied cell, translates the position so that the centre of its bounding box lands on the centre of a 32×32 frame, and writes 77 planes: piece planes indexed by owner, bug type and stack level; planes for pinned tiles, the last-moved tile and both sides' legal placement regions; and constant planes for the side to move, queen liberties, ply and reserves. On axial coordinates the six hexagonal neighbours of a cell are a subset of its 3×3 square neighbourhood, so ordinary 3×3 convolutions cover hexagonal adjacency, two corner weights never meeting a neighbour. The frame is sized so that any base-game position and its ring of candidate cells fit by construction, and the encoder asserts this on every call. No rotation or reflection canonicalisation is applied: the frame fixes translation but not orientation.
<!-- src: docs/reading/silver-2017-alphazero.md:19-24; docs/representations/grid.md:9-52 -->

### Graphs and message passing

The alternative is to hand the network the adjacency structure itself. A graph neural network computes each node's embedding from the node's own features and its neighbours' embeddings, with weights shared across all nodes and all graphs. In the neighbourhood-aggregation scheme of Hamilton et al. (2017), layer $k$ computes $h_v^{k} = \sigma\big(W \cdot [\,h_v^{k-1} \,;\, \mathrm{AGG}(\{h_u^{k-1} : u \in \mathcal{N}(v)\})\,]\big)$ for every node $v$, where AGG is a permutation-invariant function of the neighbour set. Because the weights belong to the layer and not to the node, one trained network embeds a graph of any size or shape. This is the inductive property that a frameless, variable-size Hive position calls for, and that the grid arm's fixed frame only approximates. Plain neighbourhood aggregation ignores edge semantics: a neighbour is a neighbour. In Hive the *direction* of a neighbour matters (a grasshopper jumps along a line; a gate is formed by the two cells flanking one direction), so the graph arm uses **direction-typed relations**, one weight matrix per hexagonal direction. Its message-passing layer updates the embedding of cell $i$ as

$$ h_i' = \mathrm{ReLU}\Big( h_i + W_{\mathrm{self}}\, h_i + b + \sum_{d=1}^{6} W_d\, h_{n_i(d)} \Big), $$
{#eq:mp}

where $n_i(d)$ is the neighbour of $i$ in direction $d$ (the term vanishes when no such neighbour exists within the candidate set), $W_{\mathrm{self}}$ and $b$ are the self-transformation and its bias, the six $W_d$ are the direction-typed matrices, and the leading $h_i$ is a residual connection. Nodes are the cells of the candidate set, that is, every occupied cell and every empty cell adjacent to the hive, so that each legal destination, including the empty ones, is a first-class object the policy can score; a graph over pieces alone would have nothing to attach a destination to. Tiles are not separate nodes: a cell's features describe its whole stack level by level, so stacking enters as node content rather than graph structure. Global information (side to move, ply, queen liberties, reserves by bug type) enters as a vector broadcast to every node at input and concatenated to the pooled representation at the heads. Because message passing propagates one hop per layer while queen safety depends on the whole hive, every third layer also adds a **global-pooling bias**, after the global-pooling device of Wu (2020): the mean and maximum of the node embeddings, passed through a linear map and added to every node. The value head reads a masked mean-and-max pooling of the final embeddings; the policy head scores each legal (piece, destination) pair from the destination node's embedding, the moving piece's current node (or a learned vector for placements from hand) and an embedding of the piece slot.
<!-- src: docs/reading/hamilton-2017-graphsage.md:8,13-14,24; docs/representations/graph.md:17-65,94-108; python/hivenet/graph_model.py:20-50,80-97 -->

### What a graph network does and does not provide

A graph encoding grants no invariance for free. The encoding is coordinate-free: no absolute coordinate appears anywhere, so questions of anchoring do not arise. Message passing with direction-typed edges is nevertheless *not* rotation-invariant (rotating the hive permutes the relation types), receptive fields are limited by depth, and no rule of Hive is known to the network. Legality is supplied per position by the engine through the shared decoder's legal mask, identically for both arms, and neither network ever computes it. Any invariance claim about the learned function must be measured, not assumed. Conversely, the grid arm is not without global context: two of its residual blocks also carry a global-pooling bias, so the two arms differ in how adjacency is presented rather than in whether they can see the whole position.
<!-- src: docs/representations/graph.md:8-15,67-83; docs/representations/grid.md:65-71; docs/reading/wu-2020-katago.md:66 -->

## Compute budgets and the two readings {#sec:bg-budgets}

"At comparable budget" is the clause that gives the research question its meaning, and it is ambiguous. The large self-play papers state budgets in hardware terms. Silver et al. report accelerator counts and wall-clock for a single run per game, with generation and training hardware accounted separately, which permits no cost-normalised comparison between architectures. Wu (2020) instead reports hardware type and count, wall-clock, self-play games and training samples, and plots strength against cumulative cost rather than iterations. Jones (2021), training AlphaZero-style agents on Hex at a deliberately small-laboratory scale, measures budgets in FLOP-seconds, GPU-hours and samples, draws *compute frontiers* (the best strength attainable per unit of compute), and finds that training and test-time compute trade against each other: about ten times more training compute replaced about fifteen times more search at constant strength. Hence an evaluation must fix the search budget identically across arms, or it confounds representation quality with search.
<!-- src: docs/reading/silver-2017-alphazero.md:28-32,69; docs/reading/wu-2020-katago.md:24-27,69; docs/reading/jones-2021-scaling.md:19-22,57-60 -->

The study therefore accounts every run in four denominations, namely wall-clock, hardware (machine, cores, accelerator), number of training states consumed, and simulations per decision, and reads the comparison under two equalisations. Under the **same-examples reading** both arms train on the same number of self-play states, generated with the same simulation budget per decision, and the question is which representation extracts more from each example. Under the **same-wall-clock reading** both arms receive the same number of hours on the same machine, and the question is which representation delivers more strength per hour. The two readings can disagree: a graph network that is better per example but slower per example (in self-play inference, in training, or both) can win the first and lose the second. Neither is privileged; both are reported side by side, the cost asymmetry between the arms measured on the study machine and charged rather than equalised away, and both use the same evaluation search budget.
<!-- src: docs/protocol.md:97-120; paper/ch5-protocol.md:25-30 -->

## Evaluating agents at small scale {#sec:bg-evaluation}

Measuring the strength of a learned Hive agent raises three questions: against whom, with what score, and with what notion of uncertainty.

*Against whom.* Hive has no public ladder of reference networks of the kind KataGo was measured against, and no perfect player to anchor a rating scale as MoHex anchors Jones's Hex experiments; win rate against a random player saturates and cannot separate decent agents (Kampert et al., 2021). The study therefore evaluates against a **fixed opponent population** of three agents, frozen on 9 September 2026 before any training run and never retuned, re-versioned or extended afterwards: B-RND, uniform among legal moves; B-HEU, a greedy agent over a documented hand-crafted evaluation with hash-pinned weights; and B-MCTS, the same tree search as the learned agents but with uniform priors and the hand-crafted evaluation as leaf value, at 6,400 simulations per decision. No checkpoint of either arm belongs to the population, so no arm is scored against itself. Every match plays paired games from the same pre-drawn openings with colours swapped, so that all arms, seeds and opponents face identical opening and colour schedules. Elo-style ratings, where printed, are descriptive, relative to this population, and never a headline number.
<!-- src: docs/reading/wu-2020-katago.md:70; docs/reading/jones-2021-scaling.md:36-39; docs/reading/kampert-2021-mimicking-hive.md:13; docs/baselines.md:9-58,89-97; docs/protocol.md:85-95 -->

*With what score.* The primary metric is the mean **score** against the population, with a win counting 1, a draw 0.5 and a loss 0, computed over non-truncated games only. Truncated games are excluded from the mean and reported as a separate **truncation rate** in every table; a sensitivity column additionally scores truncations as 0.5, and bracketing treatments (truncations as losses, truncations as wins) bound what any alternative cap could change. If the direction of a conclusion changes with the cap, that fragility is itself a reported finding.
<!-- src: docs/protocol.md:66-83; paper/ch5-protocol.md:45-49 -->

*With what uncertainty.* Agarwal et al. (2021) showed that deep reinforcement learning results from a handful of training runs are routinely over-read: conclusions from point estimates reverse under interval analysis, and uncertainty is badly underestimated below about ten runs. Their remedy, interval estimates from a stratified bootstrap over runs rather than bare means, is adopted with the adaptation they note for a single task: stratification collapses to a bootstrap over seeds. The **seed**, one independent training run, is the unit of analysis. Evaluation games are first aggregated to one score per (seed, opponent) cell; an arm's mean and interval then come from a percentile bootstrap over the seed-level scores, with 10,000 resamples and the 0.025 and 0.975 quantiles as the 95% interval, and the graph-minus-grid contrast resamples both arms' seed sets independently. Games are never pooled as independent observations: thousands of games from one model measure that model precisely but say nothing about the variability between training runs, which is what the comparison is about.
<!-- src: docs/reading/agarwal-2021-precipice.md:21-32,54-61; docs/protocol.md:122-132; scripts/make_results.py:79-94; paper/ch5-protocol.md:49-53 -->

These conventions (frozen opponents, a score that keeps truncation visible, the seed as the unit, intervals over seeds) were fixed in the protocol before any comparison run existed. `@sec:protocol`{=typst} states them in full, with the number of seeds, the pre-registered rejection rule and the equal-time cutoff.
<!-- src: docs/protocol.md:3-11 -->
