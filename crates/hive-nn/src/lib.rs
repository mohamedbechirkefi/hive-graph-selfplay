//! Neural-network interface: board -> input frame/planes, move -> policy
//! index, and the compact training-record format shared with Python.
//!
//! # Frame
//! Positions are embedded in a fixed 32x32 axial frame. Coordinates are
//! unwrapped from the torus by BFS (so wrapping can't split the hive) and
//! translated so the bounding-box center lands at (16,16). A 28-piece hive
//! spans at most 28 cells per axis and every legal destination is adjacent
//! to the hive, so everything fits with margin. No symmetry canonicalization
//! in v1 — the 12 hex symmetries are applied as training-time augmentation.
//!
//! # Policy space
//! `(piece, destination)` uniquely identifies any Hive move (walk-vs-throw
//! collisions produce identical successor states). Index layout:
//! `rel_piece * 1024 + y * 32 + x`, with `rel_piece` 0..14 = side-to-move's
//! pieces (roster order), 14..28 = opponent's (pillbug throws move enemy
//! pieces). Pass = 28672. POLICY_SIZE = 28673.
//!
//! # Compact record (112 bytes, little-endian) — must match python/hivenet/dataset.py
//! ```text
//!  0..84   28 x (x u8, y u8, level u8), absolute PieceId order; x=255 in hand
//!  84      side to move (0 white, 1 black)
//!  85      last-moved piece (absolute PieceId, 255 = none)  [stun state]
//!  86      ply (clamped 255)
//!  87      game type bits (1=M, 2=L, 4=P)
//!  88,89   queen liberties (side to move, opponent)
//!  90,91   reserve counts (side to move, opponent)
//!  92..96  pinned-piece bitmask u32 (bit = absolute PieceId)
//!  96,97   policy target u16 (played move, frame coords)
//!  98      WDL outcome from side-to-move perspective (0 L, 1 D, 2 W)
//!  99      record version (0 = v1 one-hot policy)
//!  100..112 reserved (zero)
//! ```
//!
//! # Record v2 (176 bytes): AlphaZero-style soft policy targets
//! Same first 112 bytes with version byte 2, then the root visit
//! distribution from MCTS: 15 x (policy index u16, visit weight u16),
//! then u32 total stored visits. Files of v2 records begin with the
//! 16-byte magic header `HIVEREC2????????` (8 magic + 8 reserved).

pub mod graph;

use hive_core::bug::{Color, PIECES_PER_COLOR, PieceId};
use hive_core::hex::{ALL_DIRS, Cell, neighbor, neighbors};
use hive_core::onehive::articulation_cells;
use hive_core::state::{GameState, Move};

pub const FRAME: usize = 32;
pub const PLANES: usize = 77;
pub const POLICY_PASS: usize = 28 * FRAME * FRAME;
pub const POLICY_SIZE: usize = POLICY_PASS + 1;
pub const RECORD_SIZE: usize = 112;
pub const RECORD_V2_SIZE: usize = 176;
pub const RECORD_V2_TOPK: usize = 15;
pub const V2_MAGIC: &[u8; 8] = b"HIVEREC2";

// --- Record v3 (H4 task 2; docs/action-decoder.md §4) ---------------------
// Layout: bytes 0..100 as v1 with version byte 99 = 3; 100..104 model
// generation u32 LE; 104..108 model config/net hash u32 LE (0 = unstamped);
// 108..112 reserved; 112..176 visit distribution exactly as v2;
// 176..178 legal-move count u16 (LEGAL_OVERFLOW = list unavailable);
// 178..818 legal policy indices u16 × LEGAL_CAP (unused slots zero).
// WDL byte 98 gains value 3 = truncated (D-008) alongside 0 L / 1 D / 2 W.
pub const RECORD_V3_LEGAL_CAP: usize = 320; // max observed branching 213
pub const RECORD_V3_SIZE: usize = RECORD_V2_SIZE + 2 + RECORD_V3_LEGAL_CAP * 2;
pub const V3_MAGIC: &[u8; 8] = b"HIVEREC3";
pub const WDL_TRUNCATED: u8 = 3;
pub const LEGAL_OVERFLOW: u16 = 0xFFFF;

/// Mapping from grid cells to frame coordinates for one position.
pub struct Frame {
    /// (cell, x, y) for occupied cells and their 1-ring (every possible
    /// move destination).
    map: Vec<(Cell, u8, u8)>,
}

impl Frame {
    /// Build the frame for a state. Works for the empty board too (first
    /// move goes to the frame center).
    pub fn new(s: &GameState) -> Frame {
        let b = &s.board;
        let Some(root) = b.any_occupied_cell() else {
            return Frame {
                map: vec![(hive_core::hex::CENTER, 16, 16)],
            };
        };
        // BFS-unwrap occupied cells.
        let mut occ: Vec<(Cell, i32, i32)> = vec![(root, 0, 0)];
        let mut queue = vec![(root, 0i32, 0i32)];
        while let Some((c, q, r)) = queue.pop() {
            for d in ALL_DIRS {
                let n = neighbor(c, d);
                if !b.occupied(n) || occ.iter().any(|&(sc, _, _)| sc == n) {
                    continue;
                }
                let (dq, dr) = d.delta();
                let e = (n, q + dq as i32, r + dr as i32);
                occ.push(e);
                queue.push((e.0, e.1, e.2));
            }
        }
        // Add the 1-ring of empty neighbors.
        let mut all = occ.clone();
        for &(c, q, r) in &occ {
            for d in ALL_DIRS {
                let n = neighbor(c, d);
                if all.iter().any(|&(sc, _, _)| sc == n) {
                    continue;
                }
                let (dq, dr) = d.delta();
                all.push((n, q + dq as i32, r + dr as i32));
            }
        }
        // Center the OCCUPIED bounding box at (16,16); the ring then fits in
        // 0..32 because hive spans <= 28 per axis.
        let min_q = occ.iter().map(|t| t.1).min().unwrap();
        let max_q = occ.iter().map(|t| t.1).max().unwrap();
        let min_r = occ.iter().map(|t| t.2).min().unwrap();
        let max_r = occ.iter().map(|t| t.2).max().unwrap();
        let off_q = 16 - (min_q + max_q) / 2;
        let off_r = 16 - (min_r + max_r) / 2;
        let map = all
            .into_iter()
            .map(|(c, q, r)| {
                let x = q + off_q;
                let y = r + off_r;
                // Overflow policy (H5 task 2): a 28-piece hive spans at most
                // 28 cells per axis after BFS-unwrap, so bbox-centering the
                // occupied cells leaves the 1-ring within 0..32 by
                // construction. This is an always-on assert, NOT a
                // debug_assert: no piece or candidate cell may ever vanish
                // or alias silently in release builds (docs/representations/
                // grid.md).
                assert!(
                    (0..FRAME as i32).contains(&x) && (0..FRAME as i32).contains(&y),
                    "frame overflow: cell {c:?} maps to ({x},{y}) outside {FRAME}x{FRAME}"
                );
                (c, x as u8, y as u8)
            })
            .collect();
        Frame { map }
    }

    /// Frame coordinates of a cell (occupied or adjacent to the hive).
    pub fn xy(&self, cell: Cell) -> Option<(u8, u8)> {
        self.map
            .iter()
            .find(|&&(c, _, _)| c == cell)
            .map(|&(_, x, y)| (x, y))
    }

    /// Inverse lookup: the cell at frame coordinates (x, y), if any cell of
    /// the candidate set (occupied + 1-ring) maps there.
    pub fn cell(&self, x: u8, y: u8) -> Option<Cell> {
        self.map
            .iter()
            .find(|&&(_, cx, cy)| cx == x && cy == y)
            .map(|&(c, _, _)| c)
    }
}

/// Side-to-move-relative piece slot: own pieces 0..14, opponent 14..28.
#[inline]
pub fn rel_piece(stm: Color, p: PieceId) -> usize {
    let own = p.color() == stm;
    (if own { 0 } else { PIECES_PER_COLOR }) + p.roster_index() as usize
}

/// Policy index of a move in this position's frame.
pub fn policy_index(s: &GameState, frame: &Frame, mv: Move) -> Option<usize> {
    match mv {
        Move::Pass => Some(POLICY_PASS),
        Move::Place { piece, to } | Move::Move { piece, to } => {
            let (x, y) = frame.xy(to)?;
            Some(rel_piece(s.to_move, piece) * FRAME * FRAME + y as usize * FRAME + x as usize)
        }
    }
}

/// Inverse of `policy_index` for this position's frame (H4 check 2):
/// recovers the (piece, destination) move a policy id denotes. Returns the
/// move as `Place`/`Move` according to whether the piece is on the board —
/// the same rule the notation layer uses.
pub fn policy_index_to_move(s: &GameState, frame: &Frame, idx: usize) -> Option<Move> {
    if idx == POLICY_PASS {
        return Some(Move::Pass);
    }
    if idx >= POLICY_SIZE {
        return None;
    }
    let slot = idx / (FRAME * FRAME);
    let rest = idx % (FRAME * FRAME);
    let (y, x) = ((rest / FRAME) as u8, (rest % FRAME) as u8);
    let color = if slot < PIECES_PER_COLOR {
        s.to_move
    } else {
        s.to_move.other()
    };
    let piece = PieceId::new(color, (slot % PIECES_PER_COLOR) as u8);
    let to = frame.cell(x, y)?;
    Some(if s.board.on_board(piece) {
        Move::Move { piece, to }
    } else {
        Move::Place { piece, to }
    })
}

/// WDL byte from the game result, for the given side to move (H4 check 3;
/// D-008: a truncated game is value 3, never a draw).
pub fn wdl_from_result(
    result: hive_core::state::GameResult,
    stm: Color,
    truncated: bool,
) -> u8 {
    use hive_core::state::GameResult;
    if truncated {
        return WDL_TRUNCATED;
    }
    match result {
        GameResult::WhiteWins => {
            if stm == Color::White { 2 } else { 0 }
        }
        GameResult::BlackWins => {
            if stm == Color::Black { 2 } else { 0 }
        }
        _ => 1,
    }
}

/// Encode a training record. `wdl` is from the side-to-move perspective.
pub fn encode_record(s: &GameState, played: Move, wdl: u8) -> [u8; RECORD_SIZE] {
    let frame = Frame::new(s);
    let b = &s.board;
    let mut rec = [0u8; RECORD_SIZE];

    for i in 0..28u8 {
        let p = PieceId(i);
        let base = i as usize * 3;
        if b.on_board(p) {
            let loc = b.loc(p);
            let (x, y) = frame.xy(loc.cell).expect("occupied cell in frame");
            rec[base] = x;
            rec[base + 1] = y;
            rec[base + 2] = loc.level;
        } else {
            rec[base] = 255;
        }
    }
    rec[84] = s.to_move as u8;
    rec[85] = s.last_moved.map(|p| p.0).unwrap_or(255);
    rec[86] = s.ply.min(255) as u8;
    rec[87] = (s.game_type.mosquito as u8)
        | (s.game_type.ladybug as u8) << 1
        | (s.game_type.pillbug as u8) << 2;
    for (slot, color) in [(88usize, s.to_move), (89, s.to_move.other())] {
        let q = s.queen(color);
        rec[slot] = if b.on_board(q) {
            neighbors(b.loc(q).cell)
                .iter()
                .filter(|&&n| !b.occupied(n))
                .count() as u8
        } else {
            255
        };
    }
    for (slot, color) in [(90usize, s.to_move), (91, s.to_move.other())] {
        rec[slot] = (0..PIECES_PER_COLOR as u8)
            .map(|i| PieceId::new(color, i))
            .filter(|&p| s.game_type.includes(p.bug()) && !b.on_board(p))
            .count() as u8;
    }
    let art = articulation_cells(b);
    let mut pinned: u32 = 0;
    for p in b.pieces_on_board() {
        let loc = b.loc(p);
        if b.is_top(p) && loc.level == 0 && art.contains(loc.cell) {
            pinned |= 1 << p.0;
        }
    }
    rec[92..96].copy_from_slice(&pinned.to_le_bytes());
    let pol = policy_index(s, &frame, played).expect("played move must encode") as u16;
    rec[96..98].copy_from_slice(&pol.to_le_bytes());
    rec[98] = wdl;
    rec
}

/// Encode a v2 record with the MCTS root visit distribution as the policy
/// target. `played` is the move actually chosen (may differ from argmax
/// under temperature sampling); `dist` is (move, visits) over root children.
pub fn encode_record_v2(
    s: &GameState,
    played: Move,
    wdl: u8,
    dist: &[(Move, u32)],
) -> [u8; RECORD_V2_SIZE] {
    let base = encode_record(s, played, wdl);
    let mut rec = [0u8; RECORD_V2_SIZE];
    rec[..RECORD_SIZE].copy_from_slice(&base);
    rec[99] = 2;
    let frame = Frame::new(s);
    fill_dist_block(s, &frame, dist, &mut rec[RECORD_SIZE..RECORD_V2_SIZE]);
    rec
}

/// Write the top-K visit distribution into a 64-byte block
/// (15 × (idx u16, weight u16) + total u32) — shared by v2 and v3.
fn fill_dist_block(s: &GameState, frame: &Frame, dist: &[(Move, u32)], out: &mut [u8]) {
    debug_assert_eq!(out.len(), RECORD_V2_SIZE - RECORD_SIZE);
    let mut sorted: Vec<(Move, u32)> = dist.iter().copied().filter(|&(_, n)| n > 0).collect();
    sorted.sort_by_key(|&(_, n)| std::cmp::Reverse(n));
    sorted.truncate(RECORD_V2_TOPK);
    let mut total: u32 = 0;
    for (slot, &(mv, n)) in sorted.iter().enumerate() {
        let idx = policy_index(s, frame, mv).expect("legal move must encode") as u16;
        let w = n.min(u16::MAX as u32) as u16;
        let off = slot * 4;
        out[off..off + 2].copy_from_slice(&idx.to_le_bytes());
        out[off + 2..off + 4].copy_from_slice(&w.to_le_bytes());
        total += w as u32;
    }
    let n = out.len();
    out[n - 4..].copy_from_slice(&total.to_le_bytes());
}

/// Encode a v3 record (H4 task 2): v2 content + model stamp + the legal
/// policy-index list that lets training mask the softmax to legal actions
/// (docs/action-decoder.md §3-4). `model` = (generation, config/net hash);
/// (0, 0) marks an unstamped record.
pub fn encode_record_v3(
    s: &GameState,
    played: Move,
    wdl: u8,
    dist: &[(Move, u32)],
    legal: &[Move],
    model: (u32, u32),
) -> [u8; RECORD_V3_SIZE] {
    let base = encode_record(s, played, wdl);
    let mut rec = [0u8; RECORD_V3_SIZE];
    rec[..RECORD_SIZE].copy_from_slice(&base);
    rec[99] = 3;
    rec[100..104].copy_from_slice(&model.0.to_le_bytes());
    rec[104..108].copy_from_slice(&model.1.to_le_bytes());
    let frame = Frame::new(s);
    fill_dist_block(s, &frame, dist, &mut rec[RECORD_SIZE..RECORD_V2_SIZE]);

    let count_off = RECORD_V2_SIZE;
    let list_off = RECORD_V2_SIZE + 2;
    if legal.len() > RECORD_V3_LEGAL_CAP {
        rec[count_off..count_off + 2].copy_from_slice(&LEGAL_OVERFLOW.to_le_bytes());
    } else {
        rec[count_off..count_off + 2].copy_from_slice(&(legal.len() as u16).to_le_bytes());
        for (i, &mv) in legal.iter().enumerate() {
            let idx = policy_index(s, &frame, mv).expect("legal move must encode") as u16;
            let off = list_off + i * 2;
            rec[off..off + 2].copy_from_slice(&idx.to_le_bytes());
        }
    }
    rec
}

/// Full input planes for inference: (77, 32, 32) row-major f32, exactly
/// mirroring `python/hivenet/dataset.py::decode_planes` (goldens enforced by
/// the dump-planes bin + scripts/crosscheck_planes.sh).
pub fn planes(s: &GameState) -> Vec<f32> {
    let frame = Frame::new(s);
    let b = &s.board;
    let mut pl = vec![0f32; PLANES * FRAME * FRAME];
    let mut set = |plane: usize, x: u8, y: u8, v: f32| {
        pl[plane * FRAME * FRAME + y as usize * FRAME + x as usize] = v;
    };
    let fill = |pl: &mut Vec<f32>, plane: usize, v: f32| {
        pl[plane * FRAME * FRAME..(plane + 1) * FRAME * FRAME].fill(v);
    };

    let art = articulation_cells(b);
    for i in 0..28u8 {
        let p = PieceId(i);
        if !b.on_board(p) {
            continue;
        }
        let loc = b.loc(p);
        let (x, y) = frame.xy(loc.cell).expect("occupied cell in frame");
        let own = (p.color() == s.to_move) as usize;
        let plane = (1 - own) * 32 + p.bug() as usize * 4 + (loc.level as usize).min(3);
        set(plane, x, y, 1.0);
        if b.is_top(p) && loc.level == 0 && art.contains(loc.cell) {
            set(64, x, y, 1.0);
        }
    }
    if let Some(lm) = s.last_moved
        && b.on_board(lm)
    {
        let (x, y) = frame.xy(b.loc(lm).cell).unwrap();
        set(65, x, y, 1.0);
    }

    // Placement planes: empty cells adjacent to >=1 own top and 0 enemy tops
    // (same simplified rule as the Python decoder — early-game special cases
    // intentionally ignored on both sides).
    for (plane, color) in [(66usize, s.to_move), (67, s.to_move.other())] {
        for &(cell, x, y) in &frame.map {
            if b.occupied(cell) {
                continue;
            }
            let mut own_adj = false;
            let mut enemy_adj = false;
            for n in neighbors(cell) {
                if let Some(t) = b.top_piece(n) {
                    if t.color() == color {
                        own_adj = true;
                    } else {
                        enemy_adj = true;
                    }
                }
            }
            if own_adj && !enemy_adj {
                set(plane, x, y, 1.0);
            }
        }
    }

    fill(&mut pl, 68, if s.to_move == Color::White { 1.0 } else { 0.0 });
    for (plane, color) in [(69usize, s.to_move), (70, s.to_move.other())] {
        let q = s.queen(color);
        let v = if b.on_board(q) {
            neighbors(b.loc(q).cell)
                .iter()
                .filter(|&&n| !b.occupied(n))
                .count() as f32
                / 6.0
        } else {
            0.0
        };
        fill(&mut pl, plane, v);
    }
    fill(&mut pl, 71, s.ply.min(255) as f32 / 100.0);
    fill(&mut pl, 72, s.game_type.mosquito as u8 as f32);
    fill(&mut pl, 73, s.game_type.ladybug as u8 as f32);
    fill(&mut pl, 74, s.game_type.pillbug as u8 as f32);
    for (plane, color) in [(75usize, s.to_move), (76, s.to_move.other())] {
        let n = (0..PIECES_PER_COLOR as u8)
            .map(|i| PieceId::new(color, i))
            .filter(|&p| s.game_type.includes(p.bug()) && !b.on_board(p))
            .count() as f32;
        fill(&mut pl, plane, n / 14.0);
    }
    pl
}

#[cfg(test)]
mod tests {
    use super::*;
    use hive_core::bug::GameType;
    use hive_core::game::Game;
    use hive_core::movegen::generate;
    use hive_core::zobrist::splitmix64;
    use std::collections::HashSet;

    fn random_game_positions(gt: GameType, plies: u32, mut seed: u64) -> Vec<GameState> {
        let mut g = Game::new(gt);
        let mut out = vec![g.state.clone()];
        for _ in 0..plies {
            if g.state.result.is_over() {
                break;
            }
            let moves = g.valid_moves();
            seed = splitmix64(seed ^ g.state.hash());
            g.play(moves[(seed % moves.len() as u64) as usize]).unwrap();
            out.push(g.state.clone());
        }
        out
    }

    /// The load-bearing property: across many random positions, every legal
    /// move maps to a distinct in-range policy index.
    #[test]
    fn policy_indices_unique_and_in_range() {
        for gt in GameType::ALL {
            for seed in 0..20 {
                for s in random_game_positions(gt, 40, seed) {
                    if s.result.is_over() {
                        continue;
                    }
                    let frame = Frame::new(&s);
                    let moves = generate(&s);
                    let mut seen = HashSet::new();
                    for &mv in moves.iter() {
                        let idx = policy_index(&s, &frame, mv)
                            .unwrap_or_else(|| panic!("unencodable move {mv:?}"));
                        assert!(idx < POLICY_SIZE);
                        assert!(
                            seen.insert(idx),
                            "policy collision at index {idx} ({mv:?}) in {gt:?}"
                        );
                    }
                }
            }
        }
    }

    /// H4 check 2: encode(move) -> id -> decode(id) is the identity on all
    /// legal moves across many random positions and every game type.
    #[test]
    fn policy_index_roundtrips_to_move() {
        for gt in GameType::ALL {
            for seed in 0..10 {
                for s in random_game_positions(gt, 60, 0xC2 + seed) {
                    if s.result.is_over() {
                        continue;
                    }
                    let frame = Frame::new(&s);
                    for &mv in generate(&s).iter() {
                        let idx = policy_index(&s, &frame, mv).expect("encodable");
                        let back = policy_index_to_move(&s, &frame, idx)
                            .unwrap_or_else(|| panic!("undecodable index {idx}"));
                        assert_eq!(back, mv, "roundtrip failed in {gt:?} at idx {idx}");
                    }
                }
            }
        }
    }

    /// H4 check 3 + D-008: WDL is from the mover's perspective and a
    /// truncated game is value 3, never a draw.
    #[test]
    fn wdl_perspective_and_truncation() {
        use hive_core::state::GameResult;
        for (result, white, black) in [
            (GameResult::WhiteWins, 2, 0),
            (GameResult::BlackWins, 0, 2),
            (GameResult::Draw, 1, 1),
        ] {
            assert_eq!(wdl_from_result(result, Color::White, false), white);
            assert_eq!(wdl_from_result(result, Color::Black, false), black);
            assert_eq!(wdl_from_result(result, Color::White, true), WDL_TRUNCATED);
            assert_eq!(wdl_from_result(result, Color::Black, true), WDL_TRUNCATED);
        }
    }

    /// v3 layout: version byte, model stamp, dist block at the v2 offsets,
    /// and a legal list that matches the generator exactly.
    #[test]
    fn record_v3_layout_and_legal_list() {
        let mut s = GameState::new(GameType::BASE);
        for name in ["wS1", "bS1", "wQ", "bQ"] {
            let moves = generate(&s);
            let target = hive_core::bug::PieceId::parse(name).unwrap();
            let mv = *moves
                .iter()
                .find(|m| matches!(m, Move::Place { piece, .. } if *piece == target))
                .expect("placement available");
            s.make(mv);
        }
        let legal = generate(&s);
        let played = legal[0];
        let dist: Vec<(Move, u32)> = legal.iter().map(|&m| (m, 7)).collect();
        let rec = encode_record_v3(&s, played, WDL_TRUNCATED, &dist, &legal, (5, 0xABCD));
        assert_eq!(rec[99], 3);
        assert_eq!(rec[98], WDL_TRUNCATED);
        assert_eq!(u32::from_le_bytes(rec[100..104].try_into().unwrap()), 5);
        assert_eq!(u32::from_le_bytes(rec[104..108].try_into().unwrap()), 0xABCD);
        let count =
            u16::from_le_bytes(rec[RECORD_V2_SIZE..RECORD_V2_SIZE + 2].try_into().unwrap());
        assert_eq!(count as usize, legal.len());
        let frame = Frame::new(&s);
        for (i, &mv) in legal.iter().enumerate() {
            let off = RECORD_V2_SIZE + 2 + i * 2;
            let idx = u16::from_le_bytes(rec[off..off + 2].try_into().unwrap());
            assert_eq!(idx as usize, policy_index(&s, &frame, mv).unwrap());
        }
        // The dist block sits at the v2 offsets with a valid total.
        let total =
            u32::from_le_bytes(rec[RECORD_V2_SIZE - 4..RECORD_V2_SIZE].try_into().unwrap());
        assert_eq!(total, 7 * legal.len().min(RECORD_V2_TOPK) as u32);
    }

    /// H5 task 2 (overflow policy): the theoretical worst case — all 28
    /// pieces in a straight line along each axis — fits the 32x32 frame
    /// with its full 1-ring, every cell maps, and no two cells alias to
    /// the same frame coordinate (the torus wrap must never fold two
    /// distinct cells together). The in-frame assert is always-on, so a
    /// future regression fails loudly instead of dropping pieces.
    #[test]
    fn frame_extremal_line_positions_fit_without_aliasing() {
        use hive_core::hex::{CENTER, Dir};
        for dir in [Dir::E, Dir::SE, Dir::NE] {
            let mut s = GameState::new(GameType::MLP);
            let mut cell = CENTER;
            for i in 0..28u8 {
                s.board.put(PieceId(i), cell);
                cell = neighbor(cell, dir);
            }
            let frame = Frame::new(&s);
            let mut seen = HashSet::new();
            let mut check = |c| {
                let (x, y) = frame
                    .xy(c)
                    .unwrap_or_else(|| panic!("cell {c:?} missing from frame ({dir:?})"));
                assert!(
                    seen.insert((x, y)),
                    "aliasing: two cells map to ({x},{y}) in {dir:?} line"
                );
            };
            let mut cell = CENTER;
            for _ in 0..28 {
                check(cell);
                cell = neighbor(cell, dir);
            }
            // The full 1-ring must map too (candidate destinations).
            let mut cell = CENTER;
            for _ in 0..28 {
                for d in ALL_DIRS {
                    let n = neighbor(cell, d);
                    if !s.board.occupied(n) && frame.xy(n).is_none() {
                        panic!("ring cell {n:?} missing from frame ({dir:?})");
                    }
                }
                cell = neighbor(cell, dir);
            }
        }
    }

    /// Every occupied cell and every legal destination must sit inside the
    /// 32x32 frame — across long games (drifting hives) too.
    #[test]
    fn frame_never_overflows() {
        for seed in 0..10 {
            for s in random_game_positions(GameType::MLP, 120, 777 + seed) {
                let frame = Frame::new(&s);
                for &mv in generate(&s).iter() {
                    if let Move::Place { to, .. } | Move::Move { to, .. } = mv {
                        let (x, y) = frame.xy(to).expect("destination in frame");
                        assert!((x as usize) < FRAME && (y as usize) < FRAME);
                    }
                }
            }
        }
    }

    #[test]
    fn record_roundtrip_basics() {
        let mut g = Game::from_uhp("Base+MLP").unwrap();
        for m in ["wS1", "bS1 wS1-", "wQ -wS1", "bQ bS1-"] {
            g.play_uhp(m).unwrap();
        }
        let mv = g.valid_moves()[0];
        let rec = encode_record(&g.state, mv, 2);
        assert_eq!(rec[84], 0); // white to move
        assert_eq!(rec[87], 0b111); // MLP
        assert_eq!(rec[98], 2);
        // wS1 (PieceId roster index 1) is on board: x != 255.
        let ws1 = PieceId::parse("wS1").unwrap();
        assert_ne!(rec[ws1.0 as usize * 3], 255);
        // An in-hand piece: wA1.
        let wa1 = PieceId::parse("wA1").unwrap();
        assert_eq!(rec[wa1.0 as usize * 3], 255);
    }
}
