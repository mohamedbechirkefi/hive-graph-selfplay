# Annex A: Hand-annotated position corpora

Every expectation below was written by hand from the publisher's rules BEFORE any engine run (oracle-before-output); the engine run that followed is journaled, and the single disagreement found was resolved against the corpus (a One-Hive transit error in a setup sequence), with the engine vindicated. These renderings are generated from the executable case files by `scripts/make_annex_corpus.py`, so the tests and the annex cannot drift apart.

## A.1 Critical rules corpus (30 cases, H2)

Rules-correctness cases: placement, sliding/freedom to move, gates, stacking, One-Hive, terminal states, forced pass, and kernel-guard Pillbug stun cases.

### C001: Queen Bee may not be placed on the first turn (tournament rule)

- **Rule:** Tournament opening rule (*Tournament variant of the official rules (README source 4); Gen42 2010 rulesheet p. 3 alone would allow it*)
- **Setup:** ``
- **Expectation:** move_illegal `{'move': 'wQ'}`
- **Hand-written justification:** The 2010 base rulesheet says the Queen 'can be placed at any time from your first to your fourth turn' (p. 3), but the tournament variant (adopted by UHP and both reference engines, and the convention this study fixes) forbids placing the Queen Bee on either player's first turn. White's first move 'wQ' must therefore be rejected.

### C002: Queen must be placed on the fourth turn if not placed before

- **Rule:** Placing your Queen Bee (*Gen42 Hive rulesheet p. 3*)
- **Setup:** `wS1;bS1 wS1-;wG1 -wS1;bG1 bS1-;wA1 -wG1;bA1 bG1-`
- **Expectation:** all_moves_place `{'piece': 'wQ'}`
- **Hand-written justification:** 'You must place your Queen Bee on your fourth turn if you have not placed it before.' (p. 3). It is White's fourth turn and wQ is still in hand, so every legal move must be a placement of wQ. (Movement moves are additionally excluded by the Moving rule, p. 3: no moving before the queen is placed.) Setup legality: each white placement touches only white pieces, each black placement only black (Placing, p. 2).

### C003: No piece may move before that player's queen is placed

- **Rule:** Moving (*Gen42 Hive rulesheet p. 3*)
- **Setup:** `wS1;bS1 wS1-`
- **Expectation:** all_moves_are_placements
- **Hand-written justification:** 'Once your Queen Bee has been placed (but not before), you can decide whether to use each turn after that to place another tile or to move one of the pieces that have already been placed.' (p. 3). White's queen is unplaced on turn 2, so wS1 must have no movement moves; only placements are offered.

### C004: After the first pieces, placements may not touch the opponent's colour

- **Rule:** Placing (*Gen42 Hive rulesheet p. 2*)
- **Setup:** `wG1;bS1 wG1/`
- **Expectation:** moves_for_piece `{'piece': 'wB1', 'moves': ['wB1 wG1\\', 'wB1 /wG1', 'wB1 -wG1']}`
- **Hand-written justification:** '…with the exception of the first piece placed by each player, pieces may not be placed next to a piece of the opponent's colour.' (p. 2). wG1 sits at the origin with bS1 to its north-east. Of wG1's five empty neighbours (E, SE, SW, W, NW), the E and NW cells each also touch bS1 (they are the two cells adjacent to both wG1 and its NE neighbour), so a new white piece may go only SE, SW or W of wG1. Expected wB1 placements: exactly those three cells. Hand geometry: axial E=(1,0), NE=(1,-1); neighbours of NE-cell (1,-1) include (1,0)=E-of-origin and (0,-1)=NW-of-origin.

### C005: Second player's first piece joins the first piece (may touch enemy)

- **Rule:** Playing the Game / Placing (*Gen42 Hive rulesheet pp. 2-3*)
- **Setup:** `wS1`
- **Expectation:** moves_for_piece `{'piece': 'bG1', 'moves': ['bG1 wS1-', 'bG1 wS1/', 'bG1 wS1\\', 'bG1 -wS1', 'bG1 /wS1', 'bG1 \\wS1']}`
- **Hand-written justification:** 'Play begins with one player placing a piece from their hand in the centre of the table and the next player joining one of their own pieces to it edge to edge.' (p. 2). This is the first-piece exception to the own-colour placing rule. Black's first piece must join wS1 edge to edge, so bG1 may be placed on any of the six cells adjacent to wS1, and nowhere else.

### C006: Queen at the hive tip: exactly the two slides that keep contact

- **Rule:** Queen Bee / Freedom to Move / One Hive (contact) (*Gen42 Hive rulesheet pp. 4, 9, 10*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-`
- **Expectation:** moves_for_piece `{'piece': 'wQ', 'moves': ['wQ \\wS1', 'wQ /wS1']}`
- **Hand-written justification:** The Queen 'can move only one space per turn' (p. 4) in a sliding movement (p. 10), and 'all pieces must always touch at least one other piece' (p. 3 NB). wQ sits at the west tip of a straight line of four. Of its five empty neighbours, only the two cells that are also adjacent to its neighbour wS1 (the cells NW and SW of wS1) keep contact with the hive after the slide; the three cells further west touch nothing once the queen leaves. Neither destination is gated (each slide's two flanking cells are one occupied, one empty). Expected: exactly those two moves.

### C007: Ant enclosed in a pocket: only exit is a gate, so it cannot move

- **Rule:** Freedom to Move (*Gen42 Hive rulesheet p. 10*)
- **Setup:** `wA1;bS1 wA1-;wQ \wA1;bQ bS1-;wG1 -wA1;bB1 bQ/;wS1 /wA1;bB1 bS1/;wB1 \wQ;bB1 wA1/`
- **Expectation:** moves_for_piece `{'piece': 'wA1', 'moves': []}`
- **Hand-written justification:** 'If a piece is surrounded to the point that it can no longer physically slide out of its position, it may not be moved.' (p. 10). Five of the ant's six neighbours are occupied. The only empty neighbour (SE of the ant) is flanked by bS1 (E of the ant) and wS1 (SW of the ant) - the two cells adjacent to both the ant and that space - so the ant cannot physically slide into it. Removing the ant would NOT split the hive (the ring bB1-wQ-wG1-wS1 plus bS1 stays connected), so the block is purely freedom-to-move, not One Hive. The Ant, normally the most mobile piece, has zero legal moves.

### C008: Spider moves exactly three spaces along the hive edge - two destinations

- **Rule:** Spider (*Gen42 Hive rulesheet p. 7*)
- **Setup:** `wG1;bS1 wG1-;wQ -wG1;bQ bS1-;wS1 \wQ;bG1 bQ-`
- **Expectation:** moves_for_piece `{'piece': 'wS1', 'moves': ['wS1 bS1/', 'wS1 wQ\\']}`
- **Hand-written justification:** 'The Spider moves three spaces per turn - no more, no less. It must move in a direct path and cannot backtrack on itself. It may only move around pieces that it is in direct contact with on each step.' (p. 7). The hive minus the spider is a straight five-piece line whose boundary is a single 14-cell ring with no gates; each ring cell touches the line, and cells off the ring touch nothing (excluded by the contact requirement). From its ring position the spider therefore has exactly two three-step walks - three cells clockwise and three cells anticlockwise: the cell NE of bS1, and the cell SE of wQ. One- and two-step stops are excluded ('no less'), backtracking is excluded.

### C009: Grasshopper: jumps only along occupied rows, no one-space slides

- **Rule:** Grasshopper (*Gen42 Hive rulesheet p. 6*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 \wS1;bG1 bQ-`
- **Expectation:** moves_for_piece `{'piece': 'wG1', 'moves': ['wG1 wS1\\', 'wG1 /wQ']}`
- **Hand-written justification:** 'It jumps from its space over any number of pieces (but at least one) to the next unoccupied space along a straight row of joined pieces.' (p. 6). The grasshopper touches occupied cells in exactly two of its six directions: SE (over wS1, landing in the next space, SE of wS1) and SW (over wQ, landing SW of wQ). In the other four directions the adjacent cell is empty, and a jump 'over at least one' piece is impossible - in particular the four adjacent empty cells are NOT destinations: the grasshopper 'does not move around the outside of the Hive like the other creatures'. Expected: exactly the two landing cells.

### C010: Grasshopper jumps a full five-piece row to the first empty space

- **Rule:** Grasshopper (*Gen42 Hive rulesheet p. 6*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 -wQ;bG1 bQ-`
- **Expectation:** moves_for_piece `{'piece': 'wG1', 'moves': ['wG1 bG1-']}`
- **Hand-written justification:** '…over any number of pieces (but at least one) to the next unoccupied space along a straight row of joined pieces.' (p. 6). Due east the grasshopper faces the unbroken row wQ, wS1, bS1, bQ, bG1; the first unoccupied space beyond it is the cell E of bG1 - the single destination. It must land there, not earlier (every nearer cell in the row is occupied). In all five other directions the adjacent cell is empty, so no jump exists. The grasshopper is a leaf of the hive, so One Hive does not restrict it.

### C011: Queen's only open neighbour is behind a gate: zero moves

- **Rule:** Freedom to Move (*Gen42 Hive rulesheet p. 10*)
- **Setup:** `wS1;bS1 -wS1;wB1 wS1/;bQ -bS1;wQ wB1-;bG1 \bQ;wS2 wQ/;bA1 /bQ;wG1 -wS2;bS2 /bS1;wA1 wS2\;bB1 \bG1;wG2 wQ\;bG2 \bB1`
- **Expectation:** moves_for_piece `{'piece': 'wQ', 'moves': []}`
- **Hand-written justification:** 'Similarly, no piece may move into a space that it cannot physically slide into.' (p. 10). Five of the queen's six neighbours are white pieces; the sixth (the cell W of wG2, equally SE of wB1) is empty, but the two cells adjacent to both the queen and that space are wG2 and wB1 - both occupied - so the queen cannot physically slide in. Removing the queen leaves the white horseshoe wS1-wB1-wG1-wS2-wA1-wG2 connected (and the black chain hangs off wS1 via bS1), so One Hive would allow the move; the block is purely Freedom to Move. Expected: the queen has no legal move.

### C012: Ant reaches every cell of the hive perimeter (13 destinations)

- **Rule:** Soldier Ant / Freedom to Move (*Gen42 Hive rulesheet pp. 8, 10*)
- **Setup:** `wG1;bS1 wG1-;wQ -wG1;bQ bS1-;wA1 \wQ;bG1 bQ-`
- **Expectation:** moves_for_piece `{'piece': 'wA1', 'moves': ['wA1 -wQ', 'wA1 \\wG1', 'wA1 \\bS1', 'wA1 \\bQ', 'wA1 \\bG1', 'wA1 bG1/', 'wA1 bG1-', 'wA1 bG1\\', 'wA1 bQ\\', 'wA1 bS1\\', 'wA1 wG1\\', 'wA1 wQ\\', 'wA1 /wQ']}`
- **Hand-written justification:** 'The Soldier Ant can move from its position to any other position around the Hive provided the restrictions are adhered to.' (p. 8). The hive minus the ant is a straight five-piece line; its boundary is a single 14-cell ring with no gates (every slide step is flanked by one line cell and one empty cell), and every ring cell touches the line. The ant starts on the ring at the cell NW of wQ, so it can stop on any of the other 13 ring cells: the west cap (W of wQ), the five north-shoulder cells (NW of each line piece plus NE of bG1), the east cap (E of bG1), and the six south-shoulder cells (SE of each line piece plus SW of wQ). Cells off the ring touch no piece and are excluded (p. 3 NB: pieces must always touch at least one other piece).

### C013: Beetle on the ground: two slides and two climbs

- **Rule:** Beetle (*Gen42 Hive rulesheet pp. 4-5, 10*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bG1 bQ-`
- **Expectation:** moves_for_piece `{'piece': 'wB1', 'moves': ['wB1 wS1', 'wB1 wQ', 'wB1 \\bS1', 'wB1 \\wQ']}`
- **Hand-written justification:** 'The Beetle, like the Queen Bee, moves only one space per turn. Unlike any other creature though, it can also move on top of the Hive.' (p. 4). From (NW of wS1) the beetle may climb onto either adjacent piece - wS1 or wQ - or slide along the ground to the two empty cells that keep contact with the hive: NW of bS1 (touching wS1 and bS1) and NW of wQ (touching wQ). The two remaining empty neighbours touch no piece after the beetle lifts, so they are excluded (p. 3 NB). No gate blocks any of the four moves (each is flanked by at most one occupied cell, and for the climbs the flanking stacks are not taller than the destination). Exactly four moves - matching the rulesheet's own beetle example count.

### C014: Beetle on top of the hive: all six neighbouring cells

- **Rule:** Beetle (*Gen42 Hive rulesheet p. 5; beetle-gate ruling, World Hive Tournaments Rules FAQ*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bG1 bQ-;wB1 wS1;bA1 bG1-`
- **Expectation:** moves_for_piece `{'piece': 'wB1', 'moves': ['wB1 bS1', 'wB1 wQ', 'wB1 \\wS1', 'wB1 \\bS1', 'wB1 wS1\\', 'wB1 wQ\\']}`
- **Hand-written justification:** 'From its position on top of the Hive, the Beetle can move from tile to tile across the top of the Hive. It can also drop into spaces that are surrounded and therefore not accessible to most other creatures.' (p. 5). Sitting on wS1, the beetle may move to every one of the six neighbouring cells: across onto bS1 or wQ (both height-1 stacks), or drop to any of the four empty cells around wS1 - each of which still touches wS1 itself, so contact holds. No pair of flanking stacks is taller than both origin (height 1 under the beetle) and destination, so no beetle gate applies (FAQ). One Hive cannot be violated: wS1 stays where it is. Exactly six destinations.

### C015: Beetle gate: drop between two height-2 stacks is blocked

- **Rule:** Freedom to Move above ground level (beetle gate) (*World Hive Tournaments Rules FAQ; Gen42 Hive rulesheet p. 10*)
- **Setup:** `wS1;bG1 wS1/;wQ /wS1;bQ bG1/;wG1 wS1\;bB1 bQ/;wB1 -wS1;bB1 bQ;wB2 /wQ;bB1 bG1;wB1 wS1;bQ bB1-;wB2 wQ;bQ bB1/;wB2 wG1;bA1 bQ/`
- **Expectation:** move_illegal `{'move': 'wB1 bB1\\'}`
- **Hand-written justification:** 'When a piece climbs up or down the hive, or moves staying on top of the hive, it must be able to slide according to the freedom to move rule which applies to higher levels than the ground. If two stacks form a gate above the ground level (we call it beetle gate), pieces won't be able to slide through.' (WHT Rules FAQ). wB1 sits on wS1 (its own level: on top of a height-1 piece); the target cell SE of the bB1 stack is empty (height 0). The two cells adjacent to both origin and target carry the stacks bG1+bB1 and wG1+wB2, both height 2 - strictly taller than both the origin without the beetle (1) and the destination (0) - so the beetle cannot slide down between them. The drop must be rejected. (One Hive would allow it: wS1 stays in place; contact holds via the flanking stacks.)

### C016: A piece with a beetle on top of it cannot move

- **Rule:** Beetle (stack immobility) (*Gen42 Hive rulesheet p. 5*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bG1 bQ-;wB1 wS1;bA1 bG1-`
- **Expectation:** move_illegal `{'move': 'wS1 bS1\\'}`
- **Hand-written justification:** 'A piece with a beetle on top of it is unable to move' (p. 5). wS1 lies under wB1, so any attempt to move wS1 - here a spider move towards the cell SE of bS1 - must be rejected, regardless of whether the path would otherwise be legal for a spider.

### C017: Stack takes the beetle's colour: white may place beside a covered black queen

- **Rule:** Beetle (stack colour) / Placing (*Gen42 Hive rulesheet pp. 2, 5*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bA1 bS1\;wB1 \bS1;bG1 bA1\;wB1 \bQ;bG2 bG1\;wB1 bQ;bB1 bG2\`
- **Expectation:** move_legal `{'move': 'wG1 wB1-'}`
- **Hand-written justification:** '…for the purposes of the placing rules on p. 2, the stack takes on the colour of the Beetle.' (p. 5). White's beetle sits on the black queen at the east end of the hive. The cell E of that stack touches no other piece, so a white placement there is adjacent only to a stack whose colour is - by the rule - white. Placing wG1 there must be accepted. (Without the stack-colour rule the cell would be adjacent to a black piece and the placement would be illegal, p. 2.)

### C018: Stack takes the beetle's colour: black may NOT place beside its own covered queen

- **Rule:** Beetle (stack colour) / Placing (*Gen42 Hive rulesheet pp. 2, 5*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bA1 bS1\;wB1 \bS1;bG1 bA1\;wB1 \bQ;bG2 bG1\;wB1 bQ;bB1 bG2\;wG1 -wQ`
- **Expectation:** move_illegal `{'move': 'bB2 wB1-'}`
- **Hand-written justification:** Mirror of C017: the stack bQ+wB1 counts as WHITE ('the stack takes on the colour of the Beetle', p. 5). The cell E of the stack touches only that stack, so for black it is adjacent to a white piece and 'pieces may not be placed next to a piece of the opponent's colour' (p. 2). Black's attempt to place bB2 there must be rejected - even though the buried piece is black's own queen.

### C019: One Hive: the only connection between two parts may not move

- **Rule:** One Hive rule (*Gen42 Hive rulesheet pp. 3, 9*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-`
- **Expectation:** moves_for_piece `{'piece': 'wS1', 'moves': []}`
- **Hand-written justification:** 'All pieces must always touch at least one other piece. If a piece is the only connection between two parts of the Hive, it may not be moved.' (p. 3 NB); 'The pieces in play must be linked at all times. At no time can you leave a piece stranded (not joined to the Hive) or separate the Hive in two.' (p. 9). wS1 is the interior link between wQ on one side and bS1-bQ on the other: lifting it splits the hive, so the spider has no legal move at all - every destination, however valid as spider movement, is excluded by One Hive.

### C020: Ring: a piece on a closed loop may move (not a cut point); the ring's eye is gated

- **Rule:** One Hive rule / Freedom to Move (*Gen42 Hive rulesheet pp. 9, 10*)
- **Setup:** `wS1;bS1 -wS1;wG1 wS1/;bQ -bS1;wQ wS1\;bG1 -bQ;wG2 wG1-;bG2 -bG1;wA1 wQ-;bA1 -bG2;wS2 wG2\;bB1 -bA1`
- **Expectation:** moves_for_piece `{'piece': 'wQ', 'moves': ['wQ /wS1', 'wQ /wA1']}`
- **Hand-written justification:** The six white pieces form a closed ring, so removing wQ leaves the other five connected around the loop (and the black tail hangs off wS1): One Hive permits the queen to move. Sliding one space (p. 4), the queen has three empty neighbours: the ring's eye and two outside cells. The eye is flanked by wS1 and wA1 - both occupied - so the queen 'may not move into a space that it cannot physically slide into' (p. 10). The two outside cells (SW of wS1, which touches wS1 and bS1; and SW of wA1, which touches wA1) are unobstructed slides keeping contact. Expected: exactly those two destinations.

### C021: Game ends when a queen is fully surrounded - even by its own colour

- **Rule:** The Object of Hive / The End of the Game (*Gen42 Hive rulesheet pp. 1, 11*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 -wQ;bG1 bQ-;wA1 -wG1;bG2 bQ/;wA2 -wA1;bB1 \bQ;wA3 -wA2;bA1 bS1\;wS2 -wA3;bA2 bQ\`
- **Expectation:** game_over `{'state': 'WhiteWins'}`
- **Hand-written justification:** 'The pieces surrounding the Queen Bee can be made up of a mixture of both your pieces and your opponent's.' (p. 1). 'The game ends as soon as one Queen Bee is completely surrounded by pieces of any colour. The person whose Queen Bee is surrounded loses the game.' (p. 11). Black's final placement (bA2, SE of its own queen) fills the sixth and last cell around bQ. The surrounding pieces are all black - irrelevant per p. 1 - and it is Black's own move that completes the surround: Black loses, the GameString state must read WhiteWins immediately after that move.

### C022: One move surrounds both queens simultaneously: draw

- **Rule:** The End of the Game (*Gen42 Hive rulesheet p. 11*)
- **Setup:** `wS1;bS1 wS1/;wQ wS1\;bB1 bS1-;wA1 -wQ;bQ bB1\;wS2 /wQ;bQ /bB1;wG1 -wS2;bQ wQ-;wB1 -wA1;bA1 bQ\;wG1 wS2-;bG1 \bS1;wB1 \wA1;bA2 bQ-;wB1 \wS1;bA3 bB1\;wG2 -wB1;bG1 bS1\`
- **Expectation:** game_over `{'state': 'Draw'}`
- **Hand-written justification:** 'The person whose Queen Bee is surrounded loses the game, unless the last piece to surround their Queen Bee also completes the surrounding of the other Queen Bee. In that case the game is drawn.' (p. 11). Before Black's last move, each queen has exactly one empty neighbour - the same cell (1,0), adjacent to both queens (the queens sit side by side, wQ NE-shoulder wS1, bQ beside it). Black's grasshopper at (1,-2) jumps SE over bS1 into that cell, filling the sixth neighbour of both queens with a single piece: the game must end as a Draw, not a win for either side.

### C023: A player who can neither place nor move must pass

- **Rule:** Unable to move or place (*Gen42 Hive rulesheet pp. 2, 5, 10, 11*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bQ bS1/;wA1 /wQ;bQ bS1-;wB1 \bS1;bQ bS1/;wB1 bS1;bQ wB1-;wA1 /bQ;bQ wB1/;wA2 /wQ;bQ wB1-;wA2 bQ\;bQ wB1/;wA3 /wQ;bQ wB1-;wA3 bQ-;bQ wB1/;wG1 /wB1;bQ wB1-;wG1 wB1/`
- **Expectation:** must_pass
- **Hand-written justification:** 'If a player can neither place a new piece or move an existing piece, the turn passes to their opponent who then takes their turn again.' (p. 11). After White's final move Black has: bS1 under wB1 - 'a piece with a beetle on top of it is unable to move' (p. 5), and the stack counts as white for placing (p. 5); and bQ, whose five neighbours are the stack, wG1, wA1, wA2 and wA3, with its single empty neighbour reachable only between wG1 and wA3 - a gate the queen 'cannot physically slide into' (p. 10). No placement is possible either: the only cell adjacent to a black-topped piece is that same gated cell, which also touches white pieces (p. 2). Black is not lost - bQ has an empty neighbour, so it is not surrounded - but must pass.

### C024: Pillbug special ability: moving an adjacent friendly piece (kernel guard)

- **Rule:** Pillbug special ability (*Gen42 Pillbug rulesheet (English section)*)
- **Setup:** `wP;bS1 wP-;wQ -wP;bQ bS1-`
- **Expectation:** move_legal `{'move': 'wQ wP\\'}`
- **Hand-written justification:** 'The special ability allows the Pillbug to move an adjacent piece (friend or enemy) two spaces; up onto itself and then down into another empty space adjacent to itself.' (Pillbug rulesheet). wQ is adjacent to wP; the target cell SE of wP is empty and adjacent to wP. None of the four exceptions applies: wQ was not just moved by the other player (Black's last move was placing bQ), wQ is not in a stack, removing wQ does not split the hive (it is a leaf), and no stacked pieces form a gap on the up-and-over path. NOTE: this is a variant-tagged kernel-guard case (protocol §2) - the study variant is base game; Pillbug cases only protect the shared rules kernel.

### C025: A piece just moved by the enemy pillbug is stunned for one turn (kernel guard)

- **Rule:** Pillbug special ability (immobility of the moved piece) (*Gen42 Pillbug rulesheet (English section); World Hive Tournaments Rules FAQ*)
- **Setup:** `wS1;bP wS1-;wQ -wS1;bQ bP-;wA1 \wQ;bG1 bQ-;wA1 \bP;bG1 -wQ;wG1 -wA1;wA1 bP\`
- **Expectation:** move_illegal `{'move': 'wA1 bP/'}`
- **Hand-written justification:** 'Furthermore, any piece moved by the Pillbug may not be moved at all (directly or via Pillbug action) on the next player's turn.' (Pillbug rulesheet); FAQ: 'any piece that just moved, in the turn of the other player immediately after is unable to: move, be moved or use the pillbug's ability.' Black's pillbug just threw wA1 up over itself and down to the cell SE of bP (a legal use: wA1 last moved two plies earlier, so the just-moved exception did not block the throw; removing it kept the hive whole since wG1 also touches wS1 and wQ). On White's very next turn the thrown ant is stunned: the attempted ant move to NE of bP must be rejected. Variant-tagged kernel-guard case (protocol §2).

### C026: Pillbug may not move the piece the opponent just moved (kernel guard)

- **Rule:** Pillbug special ability (exceptions) (*Gen42 Pillbug rulesheet (English section)*)
- **Setup:** `wS1;bP wS1-;wQ -wS1;bQ bP-;wA1 \wQ;bG1 bQ-;wA1 \bP`
- **Expectation:** move_illegal `{'move': 'wA1 bP\\'}`
- **Hand-written justification:** 'The Pillbug may not move the piece which was just moved by the other player.' (Pillbug rulesheet, first exception). White's ant moved to the cell NW of bP on the immediately preceding ply; Black's attempt to use the pillbug's ability on that same ant - throwing it to SE of bP - must be rejected. (The identical throw becomes legal two plies later, which is case C025's setup.) Variant-tagged kernel-guard case (protocol §2).

### C027: One Hive binds even the grasshopper: a cut-point cannot jump

- **Rule:** One Hive rule / Grasshopper (*Gen42 Hive rulesheet pp. 3, 6, 9*)
- **Setup:** `wG1;bS1 wG1-;wQ -wG1;bQ bS1-`
- **Expectation:** moves_for_piece `{'piece': 'wG1', 'moves': []}`
- **Hand-written justification:** The grasshopper is exempt from the sliding restriction (p. 10: it 'can jump into or out of a space'), but not from One Hive: 'If a piece is the only connection between two parts of the Hive, it may not be moved.' (p. 3 NB). wG1 sits between wQ and the black pair; lifting it for any jump splits the hive in two, so despite having jump lines in both E and W directions the grasshopper has no legal move.

### C028: A beetle cannot be PLACED directly on top of the hive

- **Rule:** Beetle (placement NB) (*Gen42 Hive rulesheet p. 5*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-`
- **Expectation:** move_illegal `{'move': 'wB1 wS1'}`
- **Hand-written justification:** 'When it is first placed, the Beetle is placed in the same way as all the other pieces. It cannot be placed directly on top of the Hive, even though it can be moved there later.' (p. 5 NB). wB1 is still in hand; the attempt to introduce it on top of wS1 must be rejected. (C013/C014 verify that the same beetle may climb there by a move once placed.)

### C029: Spider may not stop after one step ('no more, no less')

- **Rule:** Spider (*Gen42 Hive rulesheet p. 7*)
- **Setup:** `wG1;bS1 wG1-;wQ -wG1;bQ bS1-;wS1 \wQ;bG1 bQ-`
- **Expectation:** move_illegal `{'move': 'wS1 \\wG1'}`
- **Hand-written justification:** 'The Spider moves three spaces per turn - no more, no less.' (p. 7). The cell NW of wG1 is exactly one sliding step from the spider's position, and no legal three-step non-backtracking path ends there (the two three-step walks end NE of bS1 and SE of wQ - case C008); a path through that cell passes it at step one and may not stop. The one-step move must be rejected.

### C030: Queen between two pieces: two slides along the shoulder

- **Rule:** Queen Bee / One Hive / Freedom to Move (*Gen42 Hive rulesheet pp. 4, 9, 10*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bG1 bQ-`
- **Expectation:** moves_for_piece `{'piece': 'wQ', 'moves': ['wQ -wB1', 'wQ /wS1']}`
- **Hand-written justification:** The queen touches wS1 (E) and wB1 (NE). Removing her keeps the hive whole (wB1 still touches wS1), so One Hive allows a move. One-space slides (p. 4): of her four empty neighbours, only the cell W of wB1 (keeping contact with wB1) and the cell SW of wS1 (keeping contact with wS1) still touch the hive after she lifts; the two far-western cells touch nothing and are excluded (p. 3 NB). Neither slide is gated (each flanked by exactly one occupied cell). Expected: exactly those two destinations.

## A.2 Tactical verification set (5 cases, H3)

Search-correctness cases: mate-in-1 by walk and by jump from both colours, and self-surround avoidance; solved 5/5 by the MCTS baseline at 400, 1600 and 6400 simulations.

### T001: White mates in 1: occupy the black queen's last liberty (SE of bQ)

- **Rule:** The End of the Game (*Gen42 Hive rulesheet pp. 1, 11*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 -wQ;bG1 bQ-;wA1 -wG1;bG2 bQ/;wA2 -wA1;bB1 \bQ;wA3 -wA2;bA1 bS1\`
- **Expectation:** bestmove_to_cell `{'target': 'bQ\\'}`
- **Hand-written justification:** The black queen has exactly one empty neighbour, the cell SE of bQ. Any white piece landing there completes the surround and wins immediately ('the game ends as soon as one Queen Bee is completely surrounded by pieces of any colour', p. 11; mixture of colours allowed, p. 1). The cell is reachable: a white ant can walk the south perimeter in one move (entry past bA1 is not gated), so a winning move exists. No other single move ends the game. The searcher must play onto that cell.

### T002: Black mates in 1: occupy the white queen's last liberty (SE of wQ)

- **Rule:** The End of the Game (*Gen42 Hive rulesheet pp. 1, 11*)
- **Setup:** `wS1;bS1 -wS1;wQ wS1-;bQ -bS1;wG1 wQ-;bG1 -bQ;wG2 wQ/;bG2 -bG1;wB1 \wQ;bA1 -bG2;wA1 wS1\;bA2 -bA1;wA2 wG1-`
- **Expectation:** bestmove_to_cell `{'target': 'wQ\\'}`
- **Hand-written justification:** Mirror of T001 with the colours exchanged and black to move. This pair is the player-alternation check at the move level: the winning pattern must be found from both sides. The white queen's only empty neighbour is the cell SE of wQ; a black ant reaches it along the south perimeter (route via SE of bS1's column: the step into the cell is flanked by the occupied wA1 cell, so contact holds and no gate blocks). Landing there completes the surround: Black wins (p. 11).

### T003: White mates in 1 by grasshopper jump over four pieces (E of bQ)

- **Rule:** Grasshopper / The End of the Game (*Gen42 Hive rulesheet pp. 6, 11*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 -wQ;bG1 bQ/;wA1 \wQ;bB1 \bQ;wA2 \wA1;bA1 bS1\;wA3 \wA2;bA2 bQ\`
- **Expectation:** bestmove_to_cell `{'target': 'bQ-'}`
- **Hand-written justification:** The black queen's only empty neighbour is the cell E of bQ. Due east from wG1 at the west cap runs the unbroken occupied row wQ, wS1, bS1, bQ; the next unoccupied space along that row is exactly the winning cell, so the grasshopper jumps over four pieces and completes the surround (p. 6: 'over any number of pieces … to the next unoccupied space along a straight row of joined pieces'; p. 11: surround ends the game). White ants can also walk in around the perimeter; the expectation is the destination cell, whichever piece the searcher sends.

### T004: Black mates in 1 by grasshopper jump over four pieces (W of wQ)

- **Rule:** Grasshopper / The End of the Game (*Gen42 Hive rulesheet pp. 6, 11*)
- **Setup:** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 \wQ;bG1 bQ-;wG2 \wS1;bA1 bQ\;wA1 wQ\;bA2 bA1\;wA2 /wQ;bA3 bA2\;wB1 \wG1`
- **Expectation:** bestmove_to_cell `{'target': '-wQ'}`
- **Hand-written justification:** Alternation mirror of T003 with black jumping. The white queen's neighbours: E wS1, NW wG1 (placed NW of wQ), NE wG2 (placed NW of wS1 = NE of wQ), SE wA1, SW wA2. Five are occupied; only W of wQ is empty. Due east of that gap runs the unbroken row wQ, wS1, bS1, bQ with bG1 at the east cap (3,0): from bG1 the next unoccupied space westward along the row is exactly the gap, so the grasshopper jumps over four pieces and completes the surround (pp. 6, 11). Black's southern tail (bA1..bA3 SE of bG1) keeps black's earlier placements legal and away from white.

### T005: Do not fill your own queen's last liberty

- **Rule:** The End of the Game (*Gen42 Hive rulesheet p. 11*)
- **Setup:** `wS1;bS1 -wS1;wQ wS1-;bQ -bS1;wG1 wQ-;bG1 -bQ;wG2 wQ/;bG2 -bG1;wB1 \wQ;bA1 -bG2;wA1 wS1\;bA2 -bA1`
- **Expectation:** bestmove_avoid_cell `{'target': 'wQ\\'}`
- **Hand-written justification:** The cell SE of wQ is the white queen's last liberty. White placing or moving any piece there completes the surround of White's own queen: 'the person whose Queen Bee is surrounded loses the game' (p. 11) regardless of who supplied the sixth piece. The placement is perfectly legal (the cell touches only white pieces), so only search judgment prevents it. Any move except one landing on that cell passes; the searcher must not play into it. (This does not assert White survives long-term, since black threatens the same cell; it asserts only that the immediate self-kill is avoided.)

