# Architectures, decoder and data formats in detail {#sec:app-b}

This appendix complements `@sec:representations`{=typst} with layer-by-layer tables of the two networks and their ablation variants, the exact arithmetic of the shared action decoder, the tensor interface of the graph arm, the byte layout of the self-play record, and the search settings shared by both arms. Parameter totals are the values measured by the training code's parameter counter and were re-verified for this appendix; per-layer counts were not separately recorded, so the tables give shapes and widths only.

<!-- src: paper/annex-architectures.md:1-6 -->

## HiveNet, the grid network

The input is a tensor of 77 planes × 32 × 32 with float32 values in [0, 1] (`@tbl:grid-planes`{=typst}). The body and heads are listed in `@tbl:hivenet-layers`{=typst}. Hex adjacency on axial coordinates is a 7-cell subset of the 3 × 3 neighbourhood, so the 3 × 3 kernels cover it with two learnable dead corners per kernel.

<!-- src: paper/annex-architectures.md:8-26; python/hivenet/model.py:1-19 -->

| Stage | Operation | Width | Notes |
| --- | --- | --- | --- |
| Input | 77 planes × 32 × 32 | 77 | float32 in [0, 1] |
| Stem | Conv 3 × 3 (no bias), BatchNorm, ReLU | 77 → 96 | padding 1 |
| Block 0 | Conv 3 × 3, BatchNorm, ReLU; Conv 3 × 3, BatchNorm; residual add; ReLU | 96 → 96 | convolutions without bias |
| Block 1 | as block 0 | 96 → 96 | |
| Block 2 | as block 0, plus a global-pooling bias after the second BatchNorm | 96 → 96 | mean ‖ max over the frame (2 × 96) → linear → 96, added per channel |
| Block 3 | as block 0 | 96 → 96 | |
| Block 4 | as block 0 | 96 → 96 | |
| Block 5 | as block 2 | 96 → 96 | global-pooling bias |
| Block 6 | as block 0 | 96 → 96 | |
| Block 7 | as block 0 | 96 → 96 | |
| Pooling | mean over the 32 × 32 frame | 96 | feeds the pass logit and the value head |
| Policy, spatial | Conv 1 × 1 (with bias) | 96 → 28 | flattened to 28 × 1024 = 28,672 logits, index slot × 1024 + y × 32 + x |
| Policy, pass | Linear on the pooled features | 96 → 1 | appended as index 28,672 |
| Value | Linear, ReLU, Linear on the pooled features | 96 → 64 → 3 | win / draw / loss logits from the side to move |
| Total | | | 1.44 M parameters |

Table: HiveNet, the grid arm's network, layer by layer. Blocks are numbered from 0 as in the implementation; the two global-pooling blocks are the ones at one third and two thirds of the depth. Widths are channel counts; the total is the measured parameter count. {#tbl:hivenet-layers}

<!-- src: python/hivenet/model.py:22-83; paper/annex-architectures.md:16-26; docs/action-decoder.md:26-29 -->

## HiveGraphNet, the graph network

The graph arm's network consumes fixed-shape tensors (`@tbl:graph-tensors`{=typst}) built from one record by the Python builder for training and by its Rust mirror for inference. Node and global feature layouts are given in `@tbl:graph-node-features`{=typst} and `@tbl:graph-globals`{=typst}; the body and heads are listed in `@tbl:hivegraphnet-layers`{=typst}, and the ablation variants in `@tbl:graph-variants`{=typst}.

<!-- src: python/hivenet/graph_dataset.py:1-41 -->

| Tensor | Shape | Type | Content |
| --- | --- | --- | --- |
| nodes | 224 × 56 | float32 | node features, zero-padded beyond the real nodes |
| neighbours | 224 × 6 | int64 | index of the neighbour in each hex direction; 224 = none |
| node mask | 224 | bool | 1 for a real node |
| globals | 23 | float32 | global features |
| moves | 321 × 3 | int64 | (slot, destination node, source node) per legal move; source = 224 for placements and pass; the pass row uses slot 28 |
| move mask | 321 | bool | 1 for a legal row |
| target | 321 | float32 | visit distribution over the legal rows (training only) |
| outcome | scalar | int64 | 0 loss / 1 draw / 2 win / 3 truncated, from the side to move (training only) |

Table: Tensor interface of the graph arm, per position. Capacities: 224 nodes (occupied cells plus the empty ring) and 321 move rows (320 legal moves, the record's cap, plus one pass row); exceeding either capacity raises an error rather than truncating. Node order is deterministic: occupied cells first, then ring cells, each sorted by (y, x) in frame coordinates. {#tbl:graph-tensors}

<!-- src: python/hivenet/graph_dataset.py:9-41,52-71 -->

| Stage | Operation | Width | Notes |
| --- | --- | --- | --- |
| Input | node features ‖ broadcast globals | 56 + 23 | per node |
| Input linear | Linear | 56 + 23 → 152 | masked to real nodes; a zero row at index 224 stands in for absent neighbours |
| Layer 0 | relational layer: $W_{\mathrm{self}}$ (with bias) + six $W_d$ (no bias); residual; ReLU; mask | 152 → 152 | `@eq:relayer`{=typst} |
| Layer 1 | as layer 0 | 152 → 152 | |
| Layer 2 | as layer 0, plus a global-pooling bias inside the non-linearity | 152 → 152 | masked mean ‖ masked max (2 × 152) → linear → 152, added to every node |
| Layer 3 | as layer 0 | 152 → 152 | |
| Layer 4 | as layer 0 | 152 → 152 | |
| Layer 5 | as layer 2 | 152 → 152 | global-pooling bias |
| Layer 6 | as layer 0 | 152 → 152 | |
| Layer 7 | as layer 0 | 152 → 152 | |
| Readout | masked mean ‖ masked max over the real nodes | 2 × 152 | |
| Value | Linear, ReLU, Linear on readout ‖ globals | 2 × 152 + 23 → 64 → 3 | win / draw / loss logits from the side to move |
| Slot embedding | embedding table | 28 piece slots + pass → 32 | |
| Reserve vector | learned vector | 152 | source embedding for placements and for the pass row |
| Policy | Linear, ReLU, Linear per move row on destination ‖ source ‖ slot | 2 × 152 + 32 → 128 → 1 | illegal rows filled with a large negative constant before the softmax |
| Total | | | 1.47 M parameters |

Table: HiveGraphNet, the graph arm's network, layer by layer. Layers are numbered from 0 as in the implementation; the pooling layers are every third layer. Widths are channel counts; the total is the measured parameter count. {#tbl:hivegraphnet-layers}

<!-- src: python/hivenet/graph_model.py:20-98; paper/annex-architectures.md:28-52 -->

| Variant | Difference from the full graph arm | Parameters |
| --- | --- | ---: |
| Full graph arm | none | 1.47 M |
| Untyped edges | one shared matrix for the six directions, in every layer | 0.54 M |
| No global pooling | no pooling bias in any layer | 1.37 M |
| Untyped edges + gradient clipping (supplement) | one shared matrix for the six directions, plus a global gradient-norm clip of 1.0 during training (a two-component difference) | 0.54 M |

Table: The graph-network variants used in the ablations, with their measured parameter counts in millions. The encoder, the decoder, the training settings, the budgets and the evaluation settings are identical across variants; only the named component changes. {#tbl:graph-variants}

<!-- src: paper/annex-architectures.md:54-56; configs/ablations/A1-edge-typing.md; configs/ablations/A2-global-pooling.md; configs/ablations/A1prime-edge-typing-clipped.md; python/hivenet/train_graph.py:54-55,131-132 -->

## The shared action decoder in detail

**Slots.** A piece is addressed by a side-to-move-relative slot (`@tbl:decoder-slots`{=typst}): the mover's pieces in roster order, then the opponent's. In the base game, which has 11 pieces per side, only the mover's first 11 slots can ever be legal; the expansion slots and all opponent slots exist for kernel uniformity (the Pillbug expansion moves enemy pieces) and remain inert. Bug types are coded 0–7 in the order Q, S, B, G, A, M, L, P; this code indexes the piece planes of the grid encoding (bug type × 4) and the one-hot block of the graph encoding.

<!-- src: docs/action-decoder.md:15-18; python/hivenet/dataset.py:46-48; paper/ch2-formalisation.md:11-12 -->

| Slot | Mover's piece | Slot | Opponent's piece |
| --- | --- | --- | --- |
| 0 | Queen | 14 | Queen |
| 1–2 | Spiders | 15–16 | Spiders |
| 3–4 | Beetles | 17–18 | Beetles |
| 5–7 | Grasshoppers | 19–21 | Grasshoppers |
| 8–10 | Ants | 22–24 | Ants |
| 11 | Mosquito | 25 | Mosquito |
| 12 | Ladybug | 26 | Ladybug |
| 13 | Pillbug | 27 | Pillbug |

Table: Piece slots of the shared action decoder. Slot 28 is the pass slot in the graph arm's move rows; the grid arm's pass is flat index 28,672. {#tbl:decoder-slots}

<!-- src: python/hivenet/dataset.py:46-48; python/hivenet/graph_dataset.py:37-39; docs/action-decoder.md:26-29 -->

**Flat index (grid arm).** With $(x, y)$ the destination's frame coordinates, the policy index is $\text{slot} \times 1024 + y \times 32 + x$; pass is index 28,672 and the vector has 28,673 entries. The same index is what records store, for the played move and for every entry of the visit distribution and of the legal list.

**Per-candidate rows (graph arm).** Each legal index from the record is decoded into a move row: slot = index div 1024; remainder = index mod 1024; $x$ = remainder mod 32, $y$ = remainder div 32; the destination node is the index of cell $(x, y)$ in the candidate-set ordering; the source node is the standing node of the piece if it is on the board, and the reserve sentinel 224 otherwise; the pass index becomes the row (28, 224, 224). The identity encode → index → decode on all legal moves across game types is the second of the seven automated pre-training checks.

<!-- src: python/hivenet/graph_dataset.py:129-152; docs/action-decoder.md:26-35,52-60 -->

**Shared properties.** Masking: the softmax runs over exactly the legal set (plus pass when legal), implemented as a fill of illegal entries with a large negative constant in both training loops and as a softmax over the legal rows in both inference evaluators; the first automated check asserts zero illegal mass through a real forward pass. Order independence: scores attach to (slot, destination) pairs, never to list positions. Tiebreak: argmax ties break toward the lowest flat index in both arms. Targets: the top 15 (index, visit weight) entries of the root visit distribution, normalised over their support; when every stored weight is zero the target falls back to the played move. Value: a win/draw/loss head trained with truncated records excluded; the search consumes P(win) − P(loss) from the side to move, with terminal values +1, −1 and 0.

<!-- src: docs/action-decoder.md:40-77; python/hivenet/train.py:40-43; python/hivenet/dataset.py:117-130; python/hivenet/graph_dataset.py:154-164; journal/2026-09-10-graph-wiring-01.md:27-32 -->

## Record format

Self-play positions are written as fixed-size little-endian records in shards that begin with a 16-byte header (8 magic bytes identifying the format version, 8 reserved). The format evolved in three versions: 112 bytes with a one-hot played-move target; 176 bytes adding the top-15 visit distribution; and the study's 818-byte version 3 adding the generating-model stamp and the legal-move index list, which is what enables legal-masked training in both arms. Only version-3 records are study inputs. `@tbl:record-layout`{=typst} gives the layout.

<!-- src: python/hivenet/dataset.py:3-15,34-42,67-80; paper/annex-architectures.md:70-83 -->

| Bytes | Field | Encoding |
| --- | --- | --- |
| 0–83 | 28 pieces × (x, y, level) | one byte each, frame coordinates, absolute piece order; x = 255 means in hand |
| 84 | side to move | 0 white, 1 black |
| 85 | last-moved piece | piece id; 255 = none (stun state) |
| 86 | ply | clamped at 255 |
| 87 | game-type bits | 1 = M, 2 = L, 4 = P |
| 88, 89 | queen liberties (mover, opponent) | 255 = queen not placed |
| 90, 91 | reserve counts (mover, opponent) | |
| 92–95 | one-hive-pinned bitmask | 32-bit, one bit per piece id |
| 96–97 | played-move policy index | 16-bit flat index |
| 98 | outcome from the mover's perspective | 0 loss / 1 draw / 2 win / 3 truncated (never a draw) |
| 99 | record version | 3 |
| 100–107 | generating-model stamp | generation (32-bit) then network hash (32-bit); 0 = unstamped |
| up to 112 | reserved | zero |
| 112–175 | root visit distribution | 15 × (policy index 16-bit, visit weight 16-bit), then total stored visits (32-bit) |
| 176–177 | legal-move count | 16-bit; 0xFFFF = list unavailable (overflow) |
| 178–817 | legal policy-index list | 16-bit × 320 (cap; measured maximum branching 213); unused slots zero |

Table: Byte layout of the version-3 self-play record (818 bytes, little-endian). "Mover" is the side to move at the recorded position. {#tbl:record-layout}

<!-- src: paper/annex-architectures.md:70-83; python/hivenet/dataset.py:3-15,34-42,83-104; docs/action-decoder.md:52-68 -->

Both arms read the same record. The grid arm decodes the 77 planes from it; the graph arm builds the cell graph from it; both take their policy target from bytes 112–175, their legal mask from bytes 176–817, and their outcome from byte 98. The Rust writer and the Python readers of the planes and of the graph tensors are pinned byte-identical by the nightly cross-language golden tests over 240 and 160 positions respectively.

<!-- src: paper/annex-architectures.md:80-83; python/hivenet/dataset.py:114-136; python/hivenet/graph_dataset.py:44-47 -->

## Search settings

| Setting | Self-play (training data) | Independent evaluation |
| --- | --- | --- |
| Search | PUCT Monte-Carlo tree search, c = 1.4, batched leaf evaluation, terminal values backed up exactly | same |
| Simulations per decision | 128 on 25 % of decisions (recorded), 32 on the other 75 % (unrecorded); playout-cap randomization | 400 |
| Dirichlet root noise | ε = 0.25 | 0 (the code default, asserted by a test; the engine binary exposes no noise flag) |
| Move selection | temperature sampling for the first 12 plies, then argmax | deterministic argmax |
| Resignation | below −0.92, with 10 % of games never resigning (audit) | not part of the pinned settings |
| Ply cap | 300; a capped game is recorded as truncated, never as a draw | 300; truncation reported separately |
| Openings | none | 4 opening plies, paired colour-swapped, shared opening identifiers across all runs and arms |
| Inference provider | each arm's best: CoreML for the grid arm, CPU for the graph arm | same |

Table: Search settings shared by both arms. Self-play settings come from the frozen protocol; evaluation settings were pinned by configuration on 9 September 2026, before any training run, and any later change would count as a new study. {#tbl:search-settings}

<!-- src: paper/annex-architectures.md:85-92; configs/eval-settings.toml; configs/comparison-matrix.yaml:25-33; state/decisions.md:565-587; docs/representations/comparison-controls.md:19-32 -->

The exploration machinery is structurally confined to self-play: the evaluation path's defaults carry ε = 0 and no temperature, a test asserts those defaults, and the engine binary exposes no flag to enable noise, so the evaluation route cannot opt into it. Self-play opts into noise explicitly. The two paths therefore differ by construction rather than by convention.

<!-- src: configs/eval-settings.toml:6-9; state/decisions.md:572-582 -->
