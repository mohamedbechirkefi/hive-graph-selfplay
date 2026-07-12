//! Perft: legal-move-path counting, matching Mzinga's conventions
//! (documented on the Mzinga Perft wiki page) so its published tables serve
//! as ground truth.

use crate::movegen::generate;
use crate::state::GameState;

pub fn perft(s: &mut GameState, depth: u32) -> u64 {
    if depth == 0 {
        return 1;
    }
    let moves = generate(s);
    if depth == 1 {
        return moves.len() as u64;
    }
    let mut total = 0;
    for &mv in moves.iter() {
        let undo = s.make(mv);
        total += perft(s, depth - 1);
        s.unmake(mv, undo);
    }
    total
}

/// Per-root-move breakdown for divide-and-conquer debugging against a
/// reference engine.
pub fn perft_divide(s: &mut GameState, depth: u32) -> Vec<(crate::state::Move, u64)> {
    let moves = generate(s);
    let mut out = Vec::with_capacity(moves.len());
    for &mv in moves.iter() {
        let undo = s.make(mv);
        let n = if depth <= 1 { 1 } else { perft(s, depth - 1) };
        s.unmake(mv, undo);
        out.push((mv, n));
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bug::GameType;

    /// Shallow depths of the Mzinga wiki Base table; deep depths live in the
    /// integration test / nightly suite.
    #[test]
    fn base_shallow() {
        let mut s = GameState::new(GameType::BASE);
        assert_eq!(perft(&mut s, 1), 4);
        assert_eq!(perft(&mut s, 2), 96);
        assert_eq!(perft(&mut s, 3), 1_440);
        assert_eq!(perft(&mut s, 4), 21_600);
        assert_eq!(perft(&mut s, 5), 516_240);
    }
}
