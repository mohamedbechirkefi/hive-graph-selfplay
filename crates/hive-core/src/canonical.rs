//! Position canonicalization under the 12 hex-grid symmetries (6 rotations
//! x optional reflection) plus translation.
//!
//! Search never needs this (absolute-coordinate hashing is sound inside a
//! game); it exists for the NN input frame, opening-book keys, and replay
//! deduplication.

use crate::bug::PieceId;
use crate::hex::{ALL_DIRS, Cell, neighbor};
use crate::state::GameState;
use crate::zobrist::splitmix64;

/// Rotate axial coords 60 degrees counterclockwise.
#[inline]
fn rot60(q: i32, r: i32) -> (i32, i32) {
    (-r, q + r)
}

/// Reflect across the q-axis.
#[inline]
fn reflect(q: i32, r: i32) -> (i32, i32) {
    (q + r, -r)
}

/// Apply symmetry #k (0..12): k%6 rotations, k>=6 adds reflection first.
#[inline]
pub fn apply_symmetry(k: usize, mut q: i32, mut r: i32) -> (i32, i32) {
    if k >= 6 {
        (q, r) = reflect(q, r);
    }
    for _ in 0..(k % 6) {
        (q, r) = rot60(q, r);
    }
    (q, r)
}

/// Unwrapped (piece, q, r, level) list: coordinates relative to the first
/// occupied cell, reconstructed by BFS so torus wrapping cannot produce
/// coordinates 64 apart for adjacent cells.
fn unwrap_board(s: &GameState) -> Vec<(PieceId, i32, i32, u8)> {
    let b = &s.board;
    let mut out = Vec::with_capacity(28);
    let Some(root) = b.any_occupied_cell() else {
        return out;
    };
    // BFS over occupied cells assigning unwrapped coordinates.
    let mut seen: Vec<(Cell, i32, i32)> = vec![(root, 0, 0)];
    let mut queue = vec![(root, 0i32, 0i32)];
    while let Some((c, q, r)) = queue.pop() {
        for d in ALL_DIRS {
            let n = neighbor(c, d);
            if !b.occupied(n) || seen.iter().any(|&(sc, _, _)| sc == n) {
                continue;
            }
            let (dq, dr) = d.delta();
            let nq = q + dq as i32;
            let nr = r + dr as i32;
            seen.push((n, nq, nr));
            queue.push((n, nq, nr));
        }
    }
    for p in b.pieces_on_board() {
        let loc = b.loc(p);
        let &(_, q, r) = seen
            .iter()
            .find(|&&(sc, _, _)| sc == loc.cell)
            .expect("hive is connected");
        out.push((p, q, r, loc.level));
    }
    out
}

/// Canonical hash: minimum over the 12 symmetries of a translation-
/// normalized position fingerprint. Includes side-to-move and the stunned
/// piece (last_moved), which affect the legal move set.
pub fn canonical_hash(s: &GameState) -> u64 {
    let pieces = unwrap_board(s);
    if pieces.is_empty() {
        return splitmix64(s.to_move as u64);
    }
    let mut best = u64::MAX;
    for k in 0..12 {
        let mut transformed: Vec<(u8, i32, i32, u8)> = pieces
            .iter()
            .map(|&(p, q, r, lvl)| {
                let (tq, tr) = apply_symmetry(k, q, r);
                (p.0, tq, tr, lvl)
            })
            .collect();
        // Translation-normalize to the bounding-box minimum.
        let min_q = transformed.iter().map(|t| t.1).min().unwrap();
        let min_r = transformed.iter().map(|t| t.2).min().unwrap();
        for t in &mut transformed {
            t.1 -= min_q;
            t.2 -= min_r;
        }
        transformed.sort_unstable();
        let mut h = splitmix64(s.to_move as u64 ^ 0xD1CE);
        h ^= crate::zobrist::last_moved_key(s.last_moved);
        for (p, q, r, lvl) in transformed {
            h = splitmix64(
                h ^ ((p as u64) << 40 | (lvl as u64) << 32 | (q as u64) << 16 | r as u64),
            );
        }
        best = best.min(h);
    }
    best
}

/// Translate every piece of a board-in-progress by a wrapped offset — a test
/// helper to verify translation invariance without replaying moves.
#[cfg(test)]
fn translated_clone(s: &GameState, dq: u16, dr: u16) -> GameState {
    use crate::hex::{GRID_MASK, cell_q, cell_r, make_cell};
    let mut t = s.clone();
    t.board = crate::board::Board::new();
    // Re-put pieces bottom-up per cell so stack order is preserved.
    let b = &s.board;
    let mut cells: Vec<Cell> = b.pieces_on_board().map(|p| b.loc(p).cell).collect();
    cells.sort_unstable();
    cells.dedup();
    for &c in &cells {
        let nc = make_cell((cell_q(c) + dq) & GRID_MASK, (cell_r(c) + dr) & GRID_MASK);
        for lvl in 0..b.height(c) {
            let p = b.piece_at(c, lvl).unwrap();
            t.board.put(p, nc);
        }
    }
    t
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bug::GameType;
    use crate::game::Game;
    use crate::movegen::generate;

    fn random_position(gt: GameType, plies: u32, mut seed: u64) -> GameState {
        let mut g = Game::new(gt);
        for _ in 0..plies {
            if g.state.result.is_over() {
                break;
            }
            let moves = g.valid_moves();
            seed = splitmix64(seed ^ g.state.hash());
            g.play(moves[(seed % moves.len() as u64) as usize]).unwrap();
        }
        g.state.clone()
    }

    #[test]
    fn translation_invariant() {
        for seed in 0..10 {
            let s = random_position(GameType::MLP, 14, seed);
            let h = canonical_hash(&s);
            for (dq, dr) in [(1, 0), (7, 3), (60, 60), (0, 13)] {
                let t = translated_clone(&s, dq, dr);
                assert_eq!(canonical_hash(&t), h, "seed {seed} offset {dq},{dr}");
            }
        }
    }

    #[test]
    fn symmetry_group_closure() {
        // Applying any symmetry to all coordinates must not change the hash
        // (rebuild a board with rotated coordinates).
        for seed in 0..6 {
            let s = random_position(GameType::BASE, 12, seed + 100);
            let h = canonical_hash(&s);
            for k in 1..12 {
                let mut t = s.clone();
                t.board = crate::board::Board::new();
                let pieces = unwrap_board(&s);
                let mut by_cell: Vec<(i32, i32, u8, PieceId)> = pieces
                    .iter()
                    .map(|&(p, q, r, lvl)| {
                        let (tq, tr) = apply_symmetry(k, q, r);
                        (tq, tr, lvl, p)
                    })
                    .collect();
                // Sort by level so stacks rebuild bottom-up.
                by_cell.sort_by_key(|&(_, _, lvl, _)| lvl);
                for (q, r, _, p) in by_cell {
                    let cell =
                        crate::hex::make_cell((q.rem_euclid(64)) as u16, (r.rem_euclid(64)) as u16);
                    t.board.put(p, cell);
                }
                assert_eq!(canonical_hash(&t), h, "seed {seed} symmetry {k}");
            }
        }
    }

    #[test]
    fn distinguishes_different_positions() {
        let a = random_position(GameType::BASE, 12, 1);
        let b = random_position(GameType::BASE, 12, 2);
        assert_ne!(canonical_hash(&a), canonical_hash(&b));
    }

    #[test]
    fn rotating_a_game_keeps_movecount() {
        // Sanity: symmetry transforms preserve adjacency (movegen agrees).
        let s = random_position(GameType::BASE, 10, 5);
        let t = translated_clone(&s, 5, 9);
        assert_eq!(generate(&s).len(), generate(&t).len());
    }
}
