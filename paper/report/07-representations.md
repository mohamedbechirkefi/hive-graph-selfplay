# The two state representations and their networks {#sec:representations}

The study's independent variable is the state representation together with the network body that reads it, and nothing else. This chapter specifies both arms as they were run: encodings, networks, the shared action decoder, capacity matching, the cost asymmetries that were measured rather than removed, the tests that pin each encoder, and the ablation variants. `@fig:encodings`{=typst} shows one position under both encodings, `@fig:architectures`{=typst} the two networks, and `@sec:app-b`{=typst} the layer tables, the decoder arithmetic and the record layout.

The two sides do not have the same history. The grid frame, its planes and the convolutional network were built in July 2026 within the engine project and carried the earlier 19-generation self-play demonstration; on 10 September 2026 they were reused unchanged as the baseline representation, with one hardening of the frame's overflow check. Everything on the graph side (encoding, network, tensor builders in both implementation languages, and their tests) was built on 10 September 2026 for this study, against a decoder contract fixed the day before.

<!-- src: state/decisions.md:636-658; docs/inventory.md:17; docs/protocol.md:136-143; journal/2026-09-10-encoders-01.md:1-20 -->

## What varies between the arms, and what provably does not

Both arms share the rules engine, the search, the frozen opponent population and pinned evaluation settings, the record format, the training targets and outcome conventions (truncation a fourth outcome, excluded from the value loss), the action space with its legal-set normalisation, and the training loop (two epochs per generation, batch 256, learning rate 0.02, value-loss weight 0.6, stochastic gradient descent with momentum 0.9 under a cosine schedule). Neither arm was tuned beyond capacity matching. Each shared element is enforced rather than asserted: one decoder contract with identical masking, one record format, a cross-language golden test per encoder, and one Rust Monte-Carlo tree search evaluating both arms through static-shape ONNX exports. What differs is exactly enumerable: the representation, the network body, and their measured hardware interactions.

<!-- src: paper/method-representations.md:8-19; docs/representations/comparison-controls.md:47-55; configs/comparison-matrix.yaml:36-41; python/hivenet/train.py:105-107; python/hivenet/train_graph.py:75-78 -->

### The shared action decoder

A Hive move is uniquely identified by (piece, destination cell): a walk and a throw landing the same piece on the same cell produce identical successor states. The decoder addresses the piece by a side-to-move-relative slot: the mover's 14 pieces in roster order, then the opponent's 14 in slots 14–27 (they exist because the Pillbug expansion moves enemy pieces; in the base game they are never legal). It addresses the destination by a cell of the candidate set, every occupied cell plus the ring of empty cells adjacent to the hive, which contains every legal destination by construction. One extra action, pass, is legal exactly when no move exists. The grid arm materialises this space as a flat vector of 28,673 logits indexed by slot × 1024 + y × 32 + x over its 32 × 32 frame, the last index being pass. The graph arm materialises no such vector: for each legal (slot, destination) pair it computes one logit from the embeddings of the destination node, the piece's source and the slot, and scores a pass row the same way. The action a logit refers to is the identical pair in both arms; this is the pointer-network mechanism (Vinyals et al., 2015) of scoring each element of a variable candidate set and normalising over exactly that set.

<!-- src: docs/action-decoder.md:9-38; paper/annex-architectures.md:58-62; docs/reading/vinyals-2015-pointer-networks.md:14-16 -->

Four properties are shared verbatim. Masking: logits exist only for the legal set the engine generates, the softmax runs over exactly that set, and probability mass on illegal actions is identically zero; the first of the seven automated pre-training checks asserts this through a real forward pass for whichever arm is under test. Order independence: scores attach to (slot, destination) pairs, never to positions in the legal list. Tiebreak: argmax ties break toward the lowest flat index, the grid indexing defining the tiebreak for both arms. Targets: the root visit distribution of the search over the same space, stored as its top 15 (index, visit weight) entries with the total visit count; the value target is a scalar in [−1, 1] from the side to move (win +1, loss −1, draw 0), and truncation contributes no value target in either arm. The contract was fixed on 9 September 2026, before either encoder was built for the study. The rationale is that the confounder is controlled by identity of action space, mask and targets rather than by both arms producing the same tensor; imposing the flat tensor on the graph network would have carried the frame, a grid artefact, into the graph arm.

<!-- src: docs/action-decoder.md:40-87; paper/annex-architectures.md:62-68; state/decisions.md:423-445 -->

## The grid encoding

### Frame, anchoring and overflow

The engine's board is a 64 × 64 wrapping byte grid (a torus) with absolute axial coordinates. For encoding, a position is unwrapped from the torus by breadth-first search from an arbitrary occupied cell (wrapping cannot split the hive, which is connected by rule) and translated so that the centre of the occupied bounding box lands at (16, 16) of a fixed 32 × 32 frame. Hex adjacency on axial coordinates is a 7-cell subset of the 3 × 3 neighbourhood, so ordinary 3 × 3 convolutions cover it, the two non-neighbour corners of each kernel becoming learnable dead weights. Anchoring is by bounding-box centre only: no rotation or reflection canonicalisation, and no symmetry augmentation (see the end of this chapter).

<!-- src: docs/representations/grid.md:8-20; python/hivenet/model.py:7-9 -->

A 28-piece hive spans at most 28 cells per axis after unwrapping, so the occupied box plus the full ring of candidate destinations fits the frame with margin, by construction. The argument is also enforced at run time: the frame constructor carries an always-on assertion, present in release builds, so that any cell mapping outside the frame stops the program loudly and no piece or destination can vanish or alias silently. Until 10 September 2026 this was a debug-only assertion compiled out of release builds, a silent-corruption hazard that the overflow review closed. Extremal tests place all 28 pieces in a straight line along each axis and prove that every occupied and ring cell maps without aliasing; a long random-game drift test covers ordinary play.

<!-- src: docs/representations/grid.md:22-36; state/decisions.md:641-647; journal/2026-09-10-encoders-01.md:24-27 -->

### The 77 feature planes

| Planes | Content |
| --- | --- |
| 0–63 | Piece planes: owner (mover = 0, opponent = offset 32) + bug type (8 types: Q, S, B, G, A, M, L, P) × 4 + min(stack level, 3); owner, type and height are encoded jointly, one plane per combination |
| 64 | One-hive-pinned top pieces (articulation cells of the hive) |
| 65 | Cell of the last-moved piece (stun-relevant state) |
| 66 | Legal placement cells for the side to move |
| 67 | Legal placement cells for the opponent |
| 68 | Side to move is white (constant plane) |
| 69, 70 | Queen liberties (mover, opponent) / 6 (constant planes; 0 if the queen is unplaced) |
| 71 | Ply / 100 (constant plane) |
| 72–74 | Game-type bits M, L, P (constant planes) |
| 75, 76 | Reserve counts (mover, opponent) / 14 (constant planes) |

Table: The 77 input planes of the grid encoding. Each plane is a 32 × 32 float32 map with values in [0, 1]; a "constant" plane broadcasts one scalar over the whole frame. Owner is side-to-move-relative, matching the decoder's slots and the value head's perspective. {#tbl:grid-planes}

The joint piece planes record, per cell, who owns the piece at each stack level, what it is and how high it sits, levels 3 and above merged. The placement planes follow the standard adjacency rule (an empty cell adjacent to at least one of the player's top pieces and none of the opponent's) without the opening-turn exceptions; they are hints only, since legality itself is supplied to both arms by the engine's mask. The graph encoder uses the same simplified rule.

<!-- src: docs/representations/grid.md:38-54; python/hivenet/dataset.py:17-27,171-183; journal/2026-09-10-graph-wiring-01.md:22-25 -->

### The grid network

HiveNet is a residual convolutional network in the style of KataGo (Wu, 2020), sized at 96 channels and 8 residual blocks. A 3 × 3 convolutional stem takes the 77 planes to 96 channels (batch normalisation, ReLU); each residual block applies two 3 × 3 convolutions with batch normalisation, a residual addition and a ReLU; blocks 2 and 5 (counting from 0) add a global-pooling bias before the residual addition: the channel-wise mean and maximum over the frame are concatenated, passed through a linear layer and added back per channel. This injects a global signal twice, queen safety being a global property. The policy head is a 1 × 1 convolution to 28 piece-slot planes, flattened to 28,672 spatial logits, plus a pass logit from the mean-pooled features: 28,673 outputs. The value head maps the mean-pooled features through a 64-unit hidden layer to three logits (win, draw, loss from the side to move). The network has 1.44 M parameters, counted by the training code.

<!-- src: paper/annex-architectures.md:8-26; python/hivenet/model.py:53-83; docs/representations/comparison-controls.md:14-17; docs/reading/wu-2020-katago.md -->

## The graph encoding

### Nodes, pieces and destinations

The graph encoding is coordinate-free: no absolute coordinate appears in it. Its nodes are the cells of the candidate set (every occupied cell and every empty cell adjacent to the hive), which is exactly the decoder's destination universe, so every scorable destination is a first-class node. The choice follows from the rules: Hive's destinations and sliding constraints are properties of empty space, and a graph over occupied cells alone would have nothing to score for most moves. Keller et al. (2023) reached the analogous conclusion for Hex, whose formulation keeps only empty cells as nodes, and a pointer-style decoder can only point at elements that exist (Vinyals et al., 2015). An explicit occupancy feature distinguishes empty candidates from occupied nodes. Pieces are not separate nodes: since the decoder addresses a move as (slot, destination cell), a piece's identity enters the policy through its slot embedding and its location through the node it stands on; cell nodes carry the full stack composition level by level, so no piece information is lost and the graph stays half the size it would have with piece nodes. This is a documented design choice.

<!-- src: docs/representations/graph.md:17-35; docs/reading/keller-2023-graphdqn-hex.md:35-36; docs/reading/vinyals-2015-pointer-networks.md:14 -->

### Node features, typed relations and global features

| Features | Content |
| --- | --- |
| 0–49 | Five stack levels (0–4), ten features each: present bit, owner-is-mover bit, bug-type one-hot over the 8 types |
| 50 | Stack height / 5 |
| 51 | Empty-candidate bit (1 for an empty ring cell) |
| 52 | One-hive-pinned bit (the top piece is an articulation point of the hive) |
| 53 | Last-moved bit (stun-relevant) |
| 54 | Legal-placement bit for the side to move |
| 55 | Legal-placement bit for the opponent |

Table: The 56 node features of the graph encoding, one vector per candidate-set cell. Stacking is represented level by level up to height 5 (heights above 5 cannot occur in the base game; the height scalar still records them). Owner is side-to-move-relative. {#tbl:graph-node-features}

Edges are the directed adjacencies between candidate-set cells, typed by the six hex directions (east, north-east, north-west, west, south-west, south-east), stored as a neighbour-index tensor (per node, the index of its neighbour in each direction, with a sentinel for none) and realised in the network as six relation-specific weight matrices. The reverse of direction d is (d + 3) mod 6, a symmetry the property tests check. Adjacency to cells outside the candidate set is excluded: those cells are empty and not adjacent to the hive, so they cannot influence legality or value.

<!-- src: docs/representations/graph.md:48-56; journal/2026-09-10-encoders-01.md:31-34; python/hivenet/dataset.py:50-51 -->

| Features | Content |
| --- | --- |
| 0 | Side to move is white |
| 1 | Ply / 100 |
| 2, 3 | Queen liberties (mover, opponent) / 6; 0 if the queen is unplaced |
| 4–11 | Mover's reserve count per bug type / 3 (8 types) |
| 12–19 | Opponent's reserve count per bug type / 3 (8 types) |
| 20–22 | Game-type bits M, L, P |

Table: The 23 global features of the graph encoding. The vector is concatenated to every node's input and again to the pooled representation in the value head. {#tbl:graph-globals}

Reserves enter per bug type because placement legality and material planning depend on which bugs remain in hand; the grid arm carries the two totals as constant planes and can recover per-type counts from its piece planes, so neither arm receives information the other cannot reconstruct.

<!-- src: docs/representations/graph.md:58-65; python/hivenet/graph_dataset.py:113-127 -->

### Fixed capacities and loud overflow

The tensors have fixed shapes, 224 nodes and 321 move rows (320 legal moves, the record's cap, plus one pass row), and, like the frame, an always-on overflow check: a position exceeding either capacity fails loudly rather than silently. Measured maxima over 300 real self-play records were 67 nodes and 124 legal moves, well under capacity. Fixed shapes keep the ONNX export static, so the graph arm runs under the same Rust search and inference path as the grid arm; dynamic shapes would have forced a different inference route and a per-arm asymmetry where the design must be identical.

<!-- src: docs/representations/graph.md:85-92; journal/2026-09-10-encoders-01.md:42-45; python/hivenet/graph_dataset.py:36-41; state/decisions.md:674-677 -->

### Coverage of the engine's state, and what the network is not given

| State component (influences legality or outcome) | Graph element |
| --- | --- |
| Piece positions, owners, types | node stack-level features |
| Stacking (beetle climbs, buried pieces) | per-level features and height |
| Empty candidate destinations | empty-candidate nodes |
| Adjacency geometry and directions | typed edges (6 directions) |
| One-hive pins | pinned bit (engine-computed articulation) |
| Stun state (last-moved piece) | last-moved bit |
| Side to move | mover-relative features and global bit |
| Queen placement deadline | ply global and reserve features |
| Reserves | per-type global counts |
| Game type | global bits |
| Placement legality regions | placement bits (engine-derived rule) |
| Move legality itself | excluded: supplied per position by the engine through the decoder's legal mask, identically to the grid arm; the network never computes legality |
| Absolute board coordinates | excluded: coordinate-free by design, so anchoring questions do not arise |

Table: Coverage map from the components of the engine's game state to the elements of the graph encoding. The last two rows state what is deliberately absent. {#tbl:graph-coverage}

No invariance and no rule is granted for free. The encoding contains no absolute coordinates, but the learned function is not thereby translation- or rotation-invariant: message passing with direction-typed relations is not rotation-invariant, receptive fields are limited by depth (one hop per layer), and no rule of Hive is known to the network; legality arrives from the engine through the mask, for both arms alike. The protocol treats any invariance as a question to be measured rather than presumed, and this chapter asserts none.

<!-- src: docs/representations/graph.md:7-15,67-83; docs/protocol.md:41-44 -->

### The graph network

HiveGraphNet begins with a linear layer from each node's 56 features, concatenated with the 23 globals, to 152 channels, masked to real nodes; a zero row at index 224 stands in for absent neighbours. Eight relational message-passing layers follow, each computing

$$ h'_i = \mathrm{ReLU}\!\left(h_i + W_{\mathrm{self}}\, h_i + b + \sum_{d=1}^{6} W_d\, h_{n_i(d)}\right) $$
{#eq:relayer}

where $n_i(d)$ is the neighbour of node $i$ in direction $d$ (the zero row when absent), $W_{\mathrm{self}}$ carries the bias $b$, and the six $W_d$ are the direction-typed matrices without bias; the output is masked to real nodes. Layers 2 and 5 (counting from 0), that is every third layer, add a global-pooling bias inside the non-linearity: the masked mean and masked maximum over the real nodes are concatenated, passed through a linear layer and added to every node. Message passing alone is limited by depth, whereas queen safety is a global property.

<!-- src: python/hivenet/graph_model.py:20-64; paper/annex-architectures.md:38-44 -->

The value head concatenates the masked mean, the masked maximum and the global vector and maps them through a 64-unit hidden layer to the same three win/draw/loss logits as the grid arm. The policy head is the decoder's per-candidate scorer: for each legal (slot, destination) row it concatenates the destination node's embedding, a source embedding and a 32-dimensional slot embedding and maps them through a 128-unit hidden layer to one logit; the source embedding is the piece's standing node for a movement and a learned reserve vector for a placement. The pass row is scored by the same scorer from the pass-slot embedding, the reserve vector and the zero row; it is a learned constant and immaterial, because pass is legal only when no move exists and then wins the softmax alone. Illegal rows are masked before the softmax, which runs over the legal rows in the loss and in the inference evaluator exactly as the grid arm's masked softmax. The network has 1.47 M parameters, +1.5 % relative to the grid network. It is an inductive message-passing encoder in the sense of Hamilton et al. (2017), extended with relation-specific weights per direction over exact neighbourhoods of degree at most six, which is exactly what the protocol prescribes.

<!-- src: python/hivenet/graph_model.py:65-98; paper/annex-architectures.md:46-52; docs/representations/comparison-controls.md:14-17; docs/reading/hamilton-2017-graphsage.md:14-16; docs/protocol.md:138-143 -->

![Block diagrams of the two networks. Left, HiveNet (grid arm): 3 × 3 convolutional stem, 8 residual blocks of 96 channels with a global-pooling bias in blocks 2 and 5, a flat 28,673-way policy head and a 3-way value head, 1.44 M parameters in total. Right, HiveGraphNet (graph arm): input linear layer to 152 channels, 8 relational message-passing layers with six direction-typed matrices and a global-pooling bias every third layer, a per-candidate policy scorer over destination, source and slot embeddings, and a masked mean‖max value head, 1.47 M parameters in total. Both networks feed the shared action decoder; only the encoder and the body differ.](figures/fig9-architectures.png){#fig:architectures width=90%}

<!-- src: paper/annex-architectures.md:8-52; docs/representations/comparison-controls.md:14-17 -->

## Capacity matching and measured cost asymmetries

Capacity was matched by sizing the graph network's width and depth (152 channels, 8 layers) to the grid network's parameter count (96 channels, 8 blocks): 1.47 M against 1.44 M, +1.5 %, reported. What could not be matched is the cost of running each network on the study machine, where the two representations interact with the hardware in opposite ways.

<!-- src: docs/representations/comparison-controls.md:12-17; journal/2026-09-10-encoders-01.md:46 -->

| Inference path | Grid (HiveNet) | Graph (HiveGraphNet) |
| --- | ---: | ---: |
| PyTorch, CPU | 11.03 ms | 10.51 ms |
| ONNX inference, CPU provider | 23.5 ms | 3.67 ms |
| ONNX inference, CoreML provider | 2.62 ms | 9.84 ms |
| Best available provider | 2.62 ms (CoreML) | 3.67 ms (CPU) |

Table: Inference cost per position evaluation at batch size 1 for the two networks, measured on 10 September 2026 on the study machine (Apple M1 Pro, 10 cores, 16 GB, macOS 15.3.1). Milliseconds per evaluation; one measurement configuration, no interval. {#tbl:inference-cost}

The convolutional network runs fastest on the CoreML accelerator; the graph network runs fastest on the CPU, because under CoreML only 147 of its 287 operators are supported, the gather-heavy operations fall back across 15 partitions, and the accelerator path ends up slower than the CPU path. At each arm's best provider the per-evaluation cost ratio is ≈1.4× against the graph arm. Self-play and evaluation therefore ran each arm on its best provider through the same search.

<!-- src: docs/representations/comparison-controls.md:19-32; journal/2026-09-10-encoders-01.md:47-54 -->

| Training path | Grid (HiveNet) | Graph (HiveGraphNet) |
| --- | ---: | ---: |
| PyTorch, CPU, forward only | 138 pos/s | 478 pos/s |
| PyTorch, MPS, forward + backward | 274 pos/s | 138 pos/s |

Table: Training throughput at batch size 128 under matched conditions for the two networks, in positions per second, same machine and date as the inference table. The study trains on the MPS path. {#tbl:training-throughput}

Training shows the reverse pattern: on the CPU the graph network is ~3.5× faster per position, on the MPS path used for training ~2× slower, gather and scatter dominating there. Training is a minor share of a generation's wall-clock either way (in the pilot, ≈3.5 min of training against ≈60 min of self-play for a generation-0 generation), so the inference asymmetry drives the campaign-level cost difference. The figures are single-machine and single-configuration, exclude the graph dataloader's Python build cost, and the MPS numbers are a plain forward-and-backward pass without the optimizer step. These asymmetries are reported rather than equalised. They are genuine interactions between a representation and the hardware, and equalising them, whether by throttling the grid arm or by forcing the graph arm onto a slower provider, would manufacture a parity that no user of either representation would experience. The protocol instead reads the comparison twice: under the same-examples reading the asymmetries are irrelevant, both arms playing the same number of games with the same generator settings; under the same-wall-clock reading each arm is charged its true cost on this machine. The campaign-level consequence is reported with the cost results.

<!-- src: docs/representations/comparison-controls.md:28-44; journal/2026-09-10-encoders-01.md:50-51,60-65; paper/method-representations.md:55-65; docs/protocol.md:103-110 -->

## Pinning the encoders: golden and property tests

Each encoder exists twice, in Rust inside the engine and the search and in Python inside the training loop, and agreement between the two is proven rather than assumed. For the grid arm the Rust encoder and the Python decoder are byte-identical by contract, enforced by a nightly golden crosscheck over 240 positions; after the assertion hardening the crosscheck passed and the interface crate's suite stood at 7/7 including the new extremal tests; any later change must keep it green or be recorded as a finding.

<!-- src: docs/representations/grid.md:56-63; journal/2026-09-10-encoders-01.md:39-41 -->

For the graph arm, training builds the tensors in Python from the engine-generated (and themselves crosschecked) records. A property battery over 300 real records passed in full: no information loss (every piece, stack level, reserve count, stun state and turn datum in the record appears in the tensors); capacities respected, with an overflow probe raising loudly; edge symmetry; legal-move tensor validity with every stored target inside the legal list; and zero illegal probability mass through a real forward pass. One builder fix was needed: the empty board at ply 0 has an empty candidate set, and the builder now mirrors the frame's canonical first cell, (16, 16). The Rust builder used at inference mirrors the Python builder (same cell ordering, feature layout, direction order, simplified placement rule and loud overflow), and a golden crosscheck over 160 pseudo-random positions across all 8 game types found 160/160 exactly equal on its first run; it runs nightly beside the plane crosscheck. The graph evaluator inside the search builds tensors and move rows in the search's move order, runs the static-shape export on the CPU provider, applies the softmax over the legal rows and converts the three-way output to P(win) − P(loss), which is the grid evaluator's output contract.

<!-- src: journal/2026-09-10-encoders-01.md:28-45; journal/2026-09-10-graph-wiring-01.md:22-32; python/hivenet/graph_dataset.py:69 -->

A wiring validation (two epochs on the generation-0 pilot data, one seed) ran at 194 positions per second on MPS, dataloader included, with a validation policy top-1 of 4.7 % and a value accuracy of 40.4 %, the same profile as the grid arm on the identical data (4–5 %, ~43 %); a smoke match of 6 games at 200 simulations against the legal-random opponent gave 2 wins, 0 losses and 4 truncations with no illegal reply. These figures establish only that the wiring is sound; they are not a comparison result.

<!-- src: journal/2026-09-10-graph-wiring-01.md:36-47,54-57 -->

## The two ablation variants

| Variant | Single component changed | Parameters |
| --- | --- | ---: |
| Full graph arm (reference) | none | 1.47 M |
| Untyped edges ("naive adjacency") | the six direction-typed matrices replaced by one shared matrix | 0.54 M |
| No global pooling | the global-pooling bias removed from every layer | 1.37 M |

Table: The graph-arm ablation variants. Each differs from the full graph arm in exactly one network component; the encoder, the decoder, the training settings, the budgets, the evaluation settings, the opponents and the openings are identical. Parameters in millions, measured by the training code's parameter counter. {#tbl:ablation-variants}

The parameter differences are inherent to the removed components and are reported rather than equalised; widening the untyped network to compensate would change a second component. The naive-adjacency variant is the ablation the research plan called for; it tests the premise, written into the protocol before any run, that a naive adjacency graph may not suffice. The no-global-pooling variant was substituted on 19 September 2026 for the planned augmentation-removal ablation, which had nothing to remove once augmentation was excluded from the full method; it was chosen because the main comparison's mechanism signal (the graph arm's relative strength sat in its value head while its policy stayed locally weak) made the pooled signal the sharpest remaining single-component question. A supplementary two-component variant, untyped edges plus a global gradient-norm clip of 1.0, was approved on 26 September 2026 after the untyped variant proved untrainable at parity settings, diverging to non-finite values in generation 0 in 3 of 3 seeds; its numbers are labelled as a two-component difference wherever they appear and nothing it shows is attributed to edge typing alone. Outcomes are reported with the ablation results.

<!-- src: configs/ablations/A1-edge-typing.md; configs/ablations/A2-global-pooling.md; configs/ablations/A1prime-edge-typing-clipped.md; state/decisions.md:856-877,917-934; results/ablations/README.md -->

## Symmetry augmentation: excluded by decision

Neither arm trains with symmetry augmentation, by a decision of 10 September 2026 taken before any comparison run. Exclusion makes the identical-data rule trivially true: implementing the hex symmetries consistently across two representations (rotations and reflections of the frame on one side, permutations of the direction types on the other) is subtle, and an asymmetry there would contaminate the main comparison. It also keeps the secondary symmetry question separable as an additive ablation, and it matches the characterised baseline: the earlier pipeline had documented a 12-fold augmentation as an intention but never implemented it. The frozen protocol never specified augmentation; both arms therefore see each position in whatever orientation the game produced.

<!-- src: state/decisions.md:700-722; paper/method-representations.md:67-72 -->

## Limits of what this chapter establishes

This chapter establishes the identity of everything except the representation; it says nothing about the merit of either representation. The cost figures come from one machine in one configuration; another accelerator could reverse the inference asymmetry. The capacity match, to +1.5 %, is a match of parameter counts rather than of compute. The graph arm is one point in a large design space (cell nodes, six direction types, a pooled bias every third layer, a per-candidate scorer), and the study compares one grid network with one graph network at one capacity and budget; nothing here says another graph design would behave the same. Finally, the hex symmetries are neither canonicalised nor augmented in either arm, so any symmetry-related difference between the arms is a property of the learned functions rather than of the encodings.

<!-- src: paper/method-representations.md:74-79; docs/representations/comparison-controls.md:12-17 -->
