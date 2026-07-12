//! Board: piece stacks on the wrapping hex grid.

use crate::bug::{Color, NUM_PIECES, PieceId};
use crate::hex::{Cell, NUM_CELLS, neighbors};

pub const IN_HAND: Cell = u16::MAX;

/// Maximum stack height: ground piece + 4 beetles + 2 mosquitoes.
pub const MAX_HEIGHT: usize = 7;

#[derive(Copy, Clone, PartialEq, Eq, Debug)]
pub struct PieceLoc {
    pub cell: Cell,
    /// 0 = ground. Only meaningful when on board.
    pub level: u8,
}

#[derive(Clone)]
pub struct Board {
    /// Top piece of each cell's stack (PieceId.0 + 1; 0 = empty).
    top: Box<[u8; NUM_CELLS]>,
    /// Stack height of each cell.
    height: Box<[u8; NUM_CELLS]>,
    /// Location of every piece (IN_HAND if unplaced).
    loc: [PieceLoc; NUM_PIECES],
}

impl Board {
    pub fn new() -> Board {
        Board {
            top: Box::new([0; NUM_CELLS]),
            height: Box::new([0; NUM_CELLS]),
            loc: [PieceLoc {
                cell: IN_HAND,
                level: 0,
            }; NUM_PIECES],
        }
    }

    #[inline]
    pub fn occupied(&self, c: Cell) -> bool {
        self.height[c as usize] > 0
    }

    #[inline]
    pub fn height(&self, c: Cell) -> u8 {
        self.height[c as usize]
    }

    #[inline]
    pub fn top_piece(&self, c: Cell) -> Option<PieceId> {
        match self.top[c as usize] {
            0 => None,
            v => Some(PieceId(v - 1)),
        }
    }

    #[inline]
    pub fn loc(&self, p: PieceId) -> PieceLoc {
        self.loc[p.0 as usize]
    }

    #[inline]
    pub fn on_board(&self, p: PieceId) -> bool {
        self.loc[p.0 as usize].cell != IN_HAND
    }

    /// Is this piece the top of its stack (i.e. not covered)?
    #[inline]
    pub fn is_top(&self, p: PieceId) -> bool {
        let l = self.loc(p);
        l.cell != IN_HAND && self.top[l.cell as usize] == p.0 + 1
    }

    /// The piece directly under `p` in its stack, if any.
    pub fn piece_under(&self, p: PieceId) -> Option<PieceId> {
        let l = self.loc(p);
        if l.cell == IN_HAND || l.level == 0 {
            return None;
        }
        self.piece_at(l.cell, l.level - 1)
    }

    /// Piece at a specific (cell, level). Linear scan over 28 pieces.
    pub fn piece_at(&self, cell: Cell, level: u8) -> Option<PieceId> {
        self.loc
            .iter()
            .position(|l| l.cell == cell && l.level == level)
            .map(|i| PieceId(i as u8))
    }

    /// Put a piece on top of a cell's stack (placement or landing).
    pub fn put(&mut self, p: PieceId, c: Cell) {
        let h = self.height[c as usize];
        debug_assert!((h as usize) < MAX_HEIGHT);
        self.loc[p.0 as usize] = PieceLoc { cell: c, level: h };
        self.height[c as usize] = h + 1;
        self.top[c as usize] = p.0 + 1;
    }

    /// Lift the top piece of a cell (must be `p`), restoring the piece under
    /// it (if any) as the new top.
    pub fn lift(&mut self, p: PieceId) {
        let l = self.loc(p);
        debug_assert!(self.is_top(p));
        let h = self.height[l.cell as usize];
        self.height[l.cell as usize] = h - 1;
        self.top[l.cell as usize] = if h == 1 {
            0
        } else {
            self.piece_at(l.cell, h - 2).map(|q| q.0 + 1).unwrap_or(0)
        };
        self.loc[p.0 as usize] = PieceLoc {
            cell: IN_HAND,
            level: 0,
        };
    }

    /// Number of occupied cells among a cell's six neighbors.
    #[inline]
    pub fn occupied_neighbor_count(&self, c: Cell) -> u8 {
        neighbors(c).iter().filter(|&&n| self.occupied(n)).count() as u8
    }

    /// True if any neighbor's top piece has the given color.
    #[inline]
    pub fn has_neighbor_top_of_color(&self, c: Cell, color: Color) -> bool {
        neighbors(c)
            .iter()
            .any(|&n| self.top_piece(n).is_some_and(|p| p.color() == color))
    }

    /// All pieces currently on the board.
    pub fn pieces_on_board(&self) -> impl Iterator<Item = PieceId> + '_ {
        (0..NUM_PIECES as u8)
            .map(PieceId)
            .filter(|&p| self.on_board(p))
    }

    /// Any single occupied cell (for graph traversals), if the board is
    /// non-empty.
    pub fn any_occupied_cell(&self) -> Option<Cell> {
        self.loc.iter().find(|l| l.cell != IN_HAND).map(|l| l.cell)
    }

    /// Number of pieces on the board.
    pub fn count_on_board(&self) -> u8 {
        self.loc.iter().filter(|l| l.cell != IN_HAND).count() as u8
    }
}

impl Default for Board {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bug::Color;
    use crate::hex::CENTER;

    #[test]
    fn put_lift_stack() {
        let mut b = Board::new();
        let s = PieceId::new(Color::White, 1); // wS1
        let beetle = PieceId::new(Color::Black, 3); // bB1
        b.put(s, CENTER);
        assert_eq!(b.top_piece(CENTER), Some(s));
        assert_eq!(b.height(CENTER), 1);
        b.put(beetle, CENTER);
        assert_eq!(b.top_piece(CENTER), Some(beetle));
        assert_eq!(b.height(CENTER), 2);
        assert!(!b.is_top(s));
        assert_eq!(b.piece_under(beetle), Some(s));
        b.lift(beetle);
        assert_eq!(b.top_piece(CENTER), Some(s));
        assert!(b.is_top(s));
        assert!(!b.on_board(beetle));
    }
}
