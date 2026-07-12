//! One-hive rule: a ground-level piece may be lifted iff its cell is not an
//! articulation point (cut vertex) of the occupied-cell graph. Stacked cells
//! keep their node when the top piece leaves, so tops of stacks are exempt.

use crate::board::Board;
use crate::hex::{Cell, neighbors};

const MAX_NODES: usize = 32;

/// Articulation cells of the current occupied-cell graph, as a sorted list.
/// (At most 28 occupied cells, so a tiny Vec beats a 4096-bit set.)
pub struct Articulation {
    cells: [Cell; MAX_NODES],
    len: usize,
}

impl Articulation {
    #[inline]
    pub fn contains(&self, c: Cell) -> bool {
        self.cells[..self.len].contains(&c)
    }
}

struct Dfs<'a> {
    board: &'a Board,
    cells: Vec<Cell>,
    disc: Vec<u32>,
    low: Vec<u32>,
    timer: u32,
    result: Articulation,
}

impl Dfs<'_> {
    fn index_of(&self, c: Cell) -> usize {
        self.cells.iter().position(|&x| x == c).unwrap()
    }

    fn visit(&mut self, u: usize, parent: Option<usize>) {
        self.timer += 1;
        self.disc[u] = self.timer;
        self.low[u] = self.timer;
        let mut children = 0u32;
        let mut is_articulation = false;

        for n in neighbors(self.cells[u]) {
            if !self.board.occupied(n) {
                continue;
            }
            let v = self.index_of(n);
            if self.disc[v] == 0 {
                children += 1;
                self.visit(v, Some(u));
                self.low[u] = self.low[u].min(self.low[v]);
                if parent.is_some() && self.low[v] >= self.disc[u] {
                    is_articulation = true;
                }
            } else if Some(v) != parent {
                self.low[u] = self.low[u].min(self.disc[v]);
            }
        }
        if parent.is_none() && children > 1 {
            is_articulation = true;
        }
        if is_articulation {
            self.result.cells[self.result.len] = self.cells[u];
            self.result.len += 1;
        }
    }
}

/// Compute articulation cells of the occupied-cell graph.
pub fn articulation_cells(board: &Board) -> Articulation {
    let cells: Vec<Cell> = {
        let mut v: Vec<Cell> = board.pieces_on_board().map(|p| board.loc(p).cell).collect();
        v.sort_unstable();
        v.dedup();
        v
    };
    let n = cells.len();
    let mut dfs = Dfs {
        board,
        disc: vec![0; n],
        low: vec![0; n],
        timer: 0,
        cells,
        result: Articulation {
            cells: [0; MAX_NODES],
            len: 0,
        },
    };
    if n > 0 {
        dfs.visit(0, None);
        debug_assert!(dfs.disc.iter().all(|&d| d != 0), "hive must be connected");
    }
    dfs.result
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bug::{Color, PieceId};
    use crate::hex::{CENTER, Dir, neighbor};

    #[test]
    fn line_of_three_middle_is_cut() {
        let mut b = Board::new();
        let a = CENTER;
        let m = neighbor(a, Dir::E);
        let c = neighbor(m, Dir::E);
        b.put(PieceId::new(Color::White, 1), a);
        b.put(PieceId::new(Color::White, 2), m);
        b.put(PieceId::new(Color::Black, 1), c);
        let art = articulation_cells(&b);
        assert!(!art.contains(a));
        assert!(art.contains(m));
        assert!(!art.contains(c));
    }

    #[test]
    fn ring_has_no_cut() {
        let mut b = Board::new();
        // 6 pieces in a ring around an empty center.
        for (i, d) in crate::hex::ALL_DIRS.iter().enumerate() {
            b.put(PieceId(i as u8 + 1), neighbor(CENTER, *d));
        }
        let art = articulation_cells(&b);
        for d in crate::hex::ALL_DIRS {
            assert!(!art.contains(neighbor(CENTER, d)));
        }
    }
}
