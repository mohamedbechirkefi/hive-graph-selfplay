//! Handcrafted evaluation for Hive.
//!
//! Score convention: centipawn-like units, positive = good for the side to
//! move (negamax). Dominant term is queen safety (liberties around each
//! queen), then piece activity (a pinned or covered piece is nearly dead
//! material), plus small tempo terms. Weights are a starting point for
//! SPSA/self-play tuning; keep them in `Weights` so the tuner can move them.

use hive_core::bug::{Bug, Color};
use hive_core::hex::neighbors;
use hive_core::onehive::articulation_cells;
use hive_core::state::GameState;

pub const WIN: i32 = 30_000;
/// Scores at or beyond this magnitude are mate-like (win/loss), not eval.
pub const WIN_THRESHOLD: i32 = 29_000;

#[derive(Clone, Debug)]
pub struct Weights {
    /// Indexed by number of empty cells around a queen (0..=6).
    pub queen_liberties: [i32; 7],
    /// Per enemy piece adjacent to the queen.
    pub queen_enemy_neighbor: i32,
    /// Per friendly piece adjacent to the queen (crowding: own pieces block
    /// escape squares and can be pinned there).
    pub queen_friendly_neighbor: i32,
    /// Enemy piece sitting on top of the queen (beetle/mosquito).
    pub queen_covered: i32,
    /// Activity value per bug type when free to move.
    pub free: [i32; 8],
    /// Residual value per bug type when pinned/immobile.
    pub pinned: [i32; 8],
    /// Per piece still in hand (placement flexibility/tempo).
    pub reserve: i32,
    /// Own pillbug adjacent to own queen (rescue-throw availability).
    pub pillbug_defends_queen: i32,
}

impl Default for Weights {
    fn default() -> Self {
        Weights {
            queen_liberties: [-2000, -700, -350, -150, -50, 0, 20],
            queen_enemy_neighbor: -90,
            queen_friendly_neighbor: -20,
            queen_covered: -180,
            // Q, S, B, G, A, M, L, P (Bug enum order)
            free: [15, 35, 55, 40, 80, 55, 50, 40],
            pinned: [0, 4, 8, 6, 10, 6, 6, 4],
            reserve: 6,
            pillbug_defends_queen: 40,
        }
    }
}

pub fn evaluate(s: &GameState, w: &Weights) -> i32 {
    let b = &s.board;
    let art = articulation_cells(b);

    let mut score = [0i32; 2]; // white, black

    for color in [Color::White, Color::Black] {
        let ci = color as usize;
        let queen = s.queen(color);

        // --- Queen safety ---
        if b.on_board(queen) {
            let qloc = b.loc(queen);
            let mut libs = 0;
            let mut friendly = 0;
            let mut enemy = 0;
            for n in neighbors(qloc.cell) {
                match b.top_piece(n) {
                    None => libs += 1,
                    Some(p) if p.color() == color => friendly += 1,
                    Some(_) => enemy += 1,
                }
            }
            score[ci] += w.queen_liberties[libs as usize];
            score[ci] += enemy * w.queen_enemy_neighbor;
            score[ci] += friendly * w.queen_friendly_neighbor;
            if !b.is_top(queen) {
                // Someone is on top of the queen; if it's an enemy piece the
                // queen's cell also counts as enemy-controlled.
                if b.top_piece(qloc.cell).is_some_and(|p| p.color() != color) {
                    score[ci] += w.queen_covered;
                }
            }
        }

        // --- Piece activity ---
        for p in b.pieces_on_board() {
            if p.color() != color {
                continue;
            }
            let bug = p.bug() as usize;
            let loc = b.loc(p);
            if !b.is_top(p) {
                // Buried under a stack: dead material.
                continue;
            }
            let free = if loc.level > 0 {
                true // on top of the hive: never one-hive-pinned
            } else {
                !art.contains(loc.cell)
            };
            score[ci] += if free && !s.stunned(p) {
                w.free[bug]
            } else {
                w.pinned[bug]
            };
            if p.bug() == Bug::Pillbug && b.on_board(queen) {
                let qcell = b.loc(queen).cell;
                if neighbors(loc.cell).contains(&qcell) {
                    score[ci] += w.pillbug_defends_queen;
                }
            }
        }

        // --- Reserve tempo ---
        let in_hand = (0..hive_core::bug::PIECES_PER_COLOR as u8)
            .map(|i| hive_core::bug::PieceId::new(color, i))
            .filter(|&p| s.game_type.includes(p.bug()) && !b.on_board(p))
            .count() as i32;
        score[ci] += in_hand * w.reserve;
    }

    let diff = score[0] - score[1];
    match s.to_move {
        Color::White => diff,
        Color::Black => -diff,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use hive_core::bug::GameType;
    use hive_core::hex::{CENTER, Dir, neighbor};
    use hive_core::state::Move;

    #[test]
    fn symmetric_start_is_zero() {
        let s = GameState::new(GameType::MLP);
        assert_eq!(evaluate(&s, &Weights::default()), 0);
    }

    /// Plan ch. 5 / H3 task 4: the value must flip perspective consistently
    /// as the player to move alternates — negamax identity: the same board
    /// evaluated with the side to move flipped is exactly negated.
    #[test]
    fn value_negates_under_player_alternation() {
        let w = Weights::default();
        let mut s = GameState::new(GameType::BASE);
        for (name, cell) in [
            ("wS1", CENTER),
            ("bS1", neighbor(CENTER, Dir::E)),
            ("wQ", neighbor(CENTER, Dir::W)),
            ("bQ", neighbor(neighbor(CENTER, Dir::E), Dir::E)),
        ] {
            s.make(Move::Place {
                piece: hive_core::bug::PieceId::parse(name).unwrap(),
                to: cell,
            });
        }
        // Make it asymmetric: black pieces crowd the white queen.
        s.board.put(
            hive_core::bug::PieceId::parse("bA1").unwrap(),
            neighbor(neighbor(CENTER, Dir::W), Dir::W),
        );
        s.board.put(
            hive_core::bug::PieceId::parse("bA2").unwrap(),
            neighbor(neighbor(CENTER, Dir::W), Dir::NW),
        );
        // Clear the stun state: last_moved interacts with to_move by design
        // (a piece just thrown by the enemy pillbug is frozen for its owner,
        // and both fields are part of the hashed position), so the pure
        // alternation identity holds over (board, to_move) with no pending
        // stun.
        s.last_moved = None;
        s.to_move = Color::White;
        let as_white = evaluate(&s, &w);
        s.to_move = Color::Black;
        let as_black = evaluate(&s, &w);
        assert_ne!(as_white, 0, "asymmetric position must not evaluate to 0");
        assert_eq!(
            as_white, -as_black,
            "eval must negate when the player to move flips"
        );
    }

    #[test]
    fn crowded_queen_is_bad() {
        let mut s = GameState::new(GameType::BASE);
        let w = Weights::default();
        // wS1, bS1, wQ, bQ then two black pieces near white queen.
        for (name, cell) in [
            ("wS1", CENTER),
            ("bS1", neighbor(CENTER, Dir::E)),
            ("wQ", neighbor(CENTER, Dir::W)),
            ("bQ", neighbor(neighbor(CENTER, Dir::E), Dir::E)),
        ] {
            s.make(Move::Place {
                piece: hive_core::bug::PieceId::parse(name).unwrap(),
                to: cell,
            });
        }
        // White to move; symmetric-ish position. Now surround white queen a
        // bit: pretend black ants land next to wQ.
        let before = evaluate(&s, &w);
        s.board.put(
            hive_core::bug::PieceId::parse("bA1").unwrap(),
            neighbor(neighbor(CENTER, Dir::W), Dir::W),
        );
        let after = evaluate(&s, &w);
        assert!(
            after < before,
            "enemy piece next to our queen must lower our eval ({before} -> {after})"
        );
    }
}
