//! Hex grid: 64x64 wrapping axial-coordinate board.
//!
//! Hive positions float in unbounded space; because the hive spans at most 28
//! cells, a 64x64 torus is indistinguishable from an infinite plane for all
//! local queries (adjacency, slides, jumps). Coordinates never renormalize
//! during a game, which keeps Zobrist hashing fully incremental.

pub const GRID_BITS: u16 = 6;
pub const GRID_SIZE: u16 = 1 << GRID_BITS; // 64
pub const GRID_MASK: u16 = GRID_SIZE - 1;
pub const NUM_CELLS: usize = (GRID_SIZE as usize) * (GRID_SIZE as usize);

/// Cell index: r * 64 + q (axial coordinates, pointy-top hexes).
pub type Cell = u16;

/// Center of the grid; canonical location of the first placed piece.
pub const CENTER: Cell = (GRID_SIZE / 2) * GRID_SIZE + GRID_SIZE / 2;

/// The six hex directions in counterclockwise order starting East.
/// Matches UHP BoardSpace markers: E=`ref-`, NE=`ref/`, SE=`ref\`,
/// W=`-ref`, SW=`/ref`, NW=`\ref`.
#[derive(Copy, Clone, PartialEq, Eq, Debug)]
#[repr(u8)]
pub enum Dir {
    E = 0,
    NE = 1,
    NW = 2,
    W = 3,
    SW = 4,
    SE = 5,
}

pub const ALL_DIRS: [Dir; 6] = [Dir::E, Dir::NE, Dir::NW, Dir::W, Dir::SW, Dir::SE];

impl Dir {
    /// Axial deltas (dq, dr) with r increasing "down".
    #[inline]
    pub const fn delta(self) -> (i16, i16) {
        match self {
            Dir::E => (1, 0),
            Dir::NE => (1, -1),
            Dir::NW => (0, -1),
            Dir::W => (-1, 0),
            Dir::SW => (-1, 1),
            Dir::SE => (0, 1),
        }
    }

    #[inline]
    pub const fn opposite(self) -> Dir {
        ALL_DIRS[(self as usize + 3) % 6]
    }

    /// The two directions adjacent to `self` (CCW next / CW prev): the cells
    /// `a + ccw` and `a + cw` are the common neighbors of `a` and `a + self`.
    #[inline]
    pub const fn ccw(self) -> Dir {
        ALL_DIRS[(self as usize + 1) % 6]
    }

    #[inline]
    pub const fn cw(self) -> Dir {
        ALL_DIRS[(self as usize + 5) % 6]
    }

    pub const fn from_index(i: u8) -> Dir {
        ALL_DIRS[i as usize]
    }
}

#[inline]
pub const fn cell_q(c: Cell) -> u16 {
    c & GRID_MASK
}

#[inline]
pub const fn cell_r(c: Cell) -> u16 {
    c >> GRID_BITS
}

#[inline]
pub const fn make_cell(q: u16, r: u16) -> Cell {
    ((r & GRID_MASK) << GRID_BITS) | (q & GRID_MASK)
}

/// Neighbor cell in the given direction, wrapping on the torus.
#[inline]
pub const fn neighbor(c: Cell, d: Dir) -> Cell {
    let (dq, dr) = d.delta();
    let q = (cell_q(c) as i16 + dq) as u16 & GRID_MASK;
    let r = (cell_r(c) as i16 + dr) as u16 & GRID_MASK;
    make_cell(q, r)
}

/// All six neighbors of a cell, indexed by `Dir as usize`.
#[inline]
pub fn neighbors(c: Cell) -> [Cell; 6] {
    [
        neighbor(c, Dir::E),
        neighbor(c, Dir::NE),
        neighbor(c, Dir::NW),
        neighbor(c, Dir::W),
        neighbor(c, Dir::SW),
        neighbor(c, Dir::SE),
    ]
}

/// A bitset over the 4096 grid cells.
#[derive(Clone)]
pub struct CellSet {
    words: [u64; NUM_CELLS / 64],
}

impl CellSet {
    #[inline]
    pub fn new() -> Self {
        CellSet {
            words: [0; NUM_CELLS / 64],
        }
    }

    #[inline]
    pub fn insert(&mut self, c: Cell) {
        self.words[(c >> 6) as usize] |= 1u64 << (c & 63);
    }

    #[inline]
    pub fn remove(&mut self, c: Cell) {
        self.words[(c >> 6) as usize] &= !(1u64 << (c & 63));
    }

    #[inline]
    pub fn contains(&self, c: Cell) -> bool {
        self.words[(c >> 6) as usize] & (1u64 << (c & 63)) != 0
    }

    #[inline]
    pub fn clear(&mut self) {
        self.words = [0; NUM_CELLS / 64];
    }
}

impl Default for CellSet {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn neighbor_roundtrip() {
        for d in ALL_DIRS {
            assert_eq!(neighbor(neighbor(CENTER, d), d.opposite()), CENTER);
        }
    }

    #[test]
    fn common_neighbors_are_shared() {
        // For adjacent cells a and b = a + d, the cells a+d.ccw() and a+d.cw()
        // must be adjacent to both a and b.
        for d in ALL_DIRS {
            let a = CENTER;
            let b = neighbor(a, d);
            for n in [neighbor(a, d.ccw()), neighbor(a, d.cw())] {
                assert!(neighbors(a).contains(&n));
                assert!(neighbors(b).contains(&n));
            }
        }
    }

    #[test]
    fn six_distinct_neighbors() {
        let ns = neighbors(CENTER);
        for i in 0..6 {
            for j in (i + 1)..6 {
                assert_ne!(ns[i], ns[j]);
            }
        }
    }
}
