//! Game state: board + turn/rule bookkeeping, moves, make/unmake.

use crate::board::Board;
use crate::bug::{Color, GameType, PieceId};
use crate::hex::{Cell, neighbors};
use crate::zobrist;

#[derive(Copy, Clone, PartialEq, Eq, Debug)]
pub enum GameResult {
    NotStarted,
    InProgress,
    Draw,
    WhiteWins,
    BlackWins,
}

impl GameResult {
    pub fn to_uhp(self) -> &'static str {
        match self {
            GameResult::NotStarted => "NotStarted",
            GameResult::InProgress => "InProgress",
            GameResult::Draw => "Draw",
            GameResult::WhiteWins => "WhiteWins",
            GameResult::BlackWins => "BlackWins",
        }
    }

    pub fn is_over(self) -> bool {
        matches!(
            self,
            GameResult::Draw | GameResult::WhiteWins | GameResult::BlackWins
        )
    }
}

/// A move. `(piece, to)` uniquely identifies any Hive action; whether a piece
/// walked or was thrown by a pillbug to the same destination yields the same
/// successor state (see stun-rule note on `GameState::last_moved`).
#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, Debug, Hash)]
pub enum Move {
    Place { piece: PieceId, to: Cell },
    Move { piece: PieceId, to: Cell },
    Pass,
}

/// Undo record for `unmake`.
#[derive(Copy, Clone, Debug)]
pub struct Undo {
    prev_last_moved: Option<PieceId>,
    prev_result: GameResult,
    prev_hash: u64,
    /// For Move: origin cell and level.
    from: Cell,
    from_level: u8,
}

#[derive(Clone)]
pub struct GameState {
    pub board: Board,
    pub game_type: GameType,
    pub to_move: Color,
    /// Ply counter, 0-based. A player's own turn number is `ply/2 + 1`.
    pub ply: u16,
    /// The piece physically moved (or placed) on the previous ply.
    ///
    /// Stun-rule collapse: the opponent can only have moved *our* piece via a
    /// pillbug throw, so "last_moved is ours" == "we were thrown" == frozen
    /// this turn. For opponent-owned last_moved, walked vs thrown makes no
    /// difference to us (either way our pillbug may not throw it). Hence no
    /// walked/thrown flag is needed and (piece, to) move identity is sound.
    pub last_moved: Option<PieceId>,
    pub result: GameResult,
    hash: u64,
}

impl GameState {
    pub fn new(game_type: GameType) -> GameState {
        let mut s = GameState {
            board: Board::new(),
            game_type,
            to_move: Color::White,
            ply: 0,
            last_moved: None,
            result: GameResult::NotStarted,
            hash: 0,
        };
        s.hash = s.compute_hash();
        s
    }

    /// Full hash recomputation (tests + initialization; make/unmake keeps it
    /// incremental).
    pub fn compute_hash(&self) -> u64 {
        let mut h = zobrist::side_key(self.to_move)
            ^ zobrist::last_moved_key(self.last_moved)
            ^ zobrist::phase_key(self.ply);
        for p in self.board.pieces_on_board() {
            let l = self.board.loc(p);
            h ^= zobrist::piece_key(p, l.cell, l.level);
        }
        h
    }

    #[inline]
    pub fn hash(&self) -> u64 {
        self.hash
    }

    /// Hash for repetition detection: the position hash without the
    /// early-game phase component, so the same arrangement reached at
    /// different plies compares equal. Includes side-to-move and last_moved
    /// (stun rights), analogous to en-passant rights in chess repetition.
    #[inline]
    pub fn repetition_key(&self) -> u64 {
        self.hash ^ zobrist::phase_key(self.ply)
    }

    pub fn queen(&self, color: Color) -> PieceId {
        PieceId::new(color, 0)
    }

    pub fn queen_placed(&self, color: Color) -> bool {
        self.board.on_board(self.queen(color))
    }

    /// The current player's 1-based turn number.
    #[inline]
    pub fn own_turn_number(&self) -> u16 {
        self.ply / 2 + 1
    }

    fn queen_surrounded(&self, color: Color) -> bool {
        let q = self.queen(color);
        if !self.board.on_board(q) {
            return false;
        }
        let cell = self.board.loc(q).cell;
        neighbors(cell).iter().all(|&n| self.board.occupied(n))
    }

    fn update_result(&mut self) {
        let w = self.queen_surrounded(Color::White);
        let b = self.queen_surrounded(Color::Black);
        self.result = match (w, b) {
            (true, true) => GameResult::Draw,
            (true, false) => GameResult::BlackWins,
            (false, true) => GameResult::WhiteWins,
            (false, false) => GameResult::InProgress,
        };
    }

    pub fn make(&mut self, mv: Move) -> Undo {
        let undo = Undo {
            prev_last_moved: self.last_moved,
            prev_result: self.result,
            prev_hash: self.hash,
            from: 0,
            from_level: 0,
        };
        let mut undo = undo;

        self.hash ^= zobrist::side_key(self.to_move)
            ^ zobrist::last_moved_key(self.last_moved)
            ^ zobrist::phase_key(self.ply);

        match mv {
            Move::Place { piece, to } => {
                self.board.put(piece, to);
                let l = self.board.loc(piece);
                self.hash ^= zobrist::piece_key(piece, l.cell, l.level);
                // NOTE: placement sets last_moved, i.e. a just-placed piece
                // may not be thrown by a pillbug next turn (Mzinga
                // convention; verified against perft tables / fuzzing).
                self.last_moved = Some(piece);
            }
            Move::Move { piece, to } => {
                let l = self.board.loc(piece);
                undo.from = l.cell;
                undo.from_level = l.level;
                self.hash ^= zobrist::piece_key(piece, l.cell, l.level);
                self.board.lift(piece);
                self.board.put(piece, to);
                let nl = self.board.loc(piece);
                self.hash ^= zobrist::piece_key(piece, nl.cell, nl.level);
                self.last_moved = Some(piece);
            }
            Move::Pass => {
                self.last_moved = None;
            }
        }

        self.to_move = self.to_move.other();
        self.ply += 1;
        self.hash ^= zobrist::side_key(self.to_move)
            ^ zobrist::last_moved_key(self.last_moved)
            ^ zobrist::phase_key(self.ply);
        self.update_result();
        undo
    }

    pub fn unmake(&mut self, mv: Move, undo: Undo) {
        self.to_move = self.to_move.other();
        self.ply -= 1;
        match mv {
            Move::Place { piece, .. } => {
                self.board.lift(piece);
            }
            Move::Move { piece, .. } => {
                self.board.lift(piece);
                // Restore to original cell/level: pieces only ever sit on top
                // when placed via put(), and level is height at put time, so
                // putting back onto `from` restores `from_level` exactly.
                debug_assert_eq!(self.board.height(undo.from), undo.from_level);
                self.board.put(piece, undo.from);
            }
            Move::Pass => {}
        }
        self.last_moved = undo.prev_last_moved;
        self.result = undo.prev_result;
        self.hash = undo.prev_hash;
    }

    /// Is the given own piece frozen by the pillbug stun rule? (It was
    /// physically moved by the opponent's pillbug on the previous ply.)
    #[inline]
    pub fn stunned(&self, p: PieceId) -> bool {
        self.last_moved == Some(p) && p.color() == self.to_move
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::hex::{CENTER, Dir, neighbor};

    #[test]
    fn make_unmake_restores_hash() {
        let mut s = GameState::new(GameType::BASE);
        let h0 = s.hash();
        let wS1 = PieceId::parse("wS1").unwrap();
        let bS1 = PieceId::parse("bS1").unwrap();
        let m1 = Move::Place {
            piece: wS1,
            to: CENTER,
        };
        let u1 = s.make(m1);
        assert_eq!(s.hash(), s.compute_hash());
        let m2 = Move::Place {
            piece: bS1,
            to: neighbor(CENTER, Dir::E),
        };
        let u2 = s.make(m2);
        assert_eq!(s.hash(), s.compute_hash());
        s.unmake(m2, u2);
        s.unmake(m1, u1);
        assert_eq!(s.hash(), h0);
        assert_eq!(s.hash(), s.compute_hash());
        assert_eq!(s.board.count_on_board(), 0);
    }

    #[test]
    fn surround_detection() {
        let mut s = GameState::new(GameType::BASE);
        // Place black queen at center, surround with 6 white pieces.
        s.make(Move::Place {
            piece: PieceId::parse("wQ").unwrap(),
            to: neighbor(CENTER, Dir::E),
        });
        s.make(Move::Place {
            piece: PieceId::parse("bQ").unwrap(),
            to: CENTER,
        });
        for (i, name) in ["wS1", "wS2", "wB1", "wB2", "wG1"].iter().enumerate() {
            let d = crate::hex::ALL_DIRS[i + 1];
            s.make(Move::Place {
                piece: PieceId::parse(name).unwrap(),
                to: neighbor(CENTER, d),
            });
            // Black passes conceptually; we just alternate with junk placements
            // far away is not legal, so directly test via repeated make of
            // moves — this test drives the board, not legality.
            s.make(Move::Pass);
        }
        assert_eq!(s.result, GameResult::WhiteWins);
    }
}
