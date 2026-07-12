//! Zobrist hashing via a mixing function instead of lookup tables.
//!
//! A full table would be 28 pieces x 4096 cells x 7 levels of u64 (~6 MB);
//! splitmix64 over a packed key gives equivalent statistical quality at ~2ns
//! per key with zero memory. Hashes use absolute grid coordinates: the board
//! never renormalizes mid-game, so translation symmetry is irrelevant inside
//! a search tree (canonicalization for NN/book use lives in `canonical.rs`).

use crate::bug::{Color, PieceId};
use crate::hex::Cell;

#[inline]
pub const fn splitmix64(mut z: u64) -> u64 {
    z = z.wrapping_add(0x9E3779B97F4A7C15);
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

/// Key for a piece occupying (cell, level).
#[inline]
pub const fn piece_key(p: PieceId, cell: Cell, level: u8) -> u64 {
    splitmix64((p.0 as u64) << 32 | (level as u64) << 16 | cell as u64)
}

/// Key for the side to move (XORed in when Black is to move).
#[inline]
pub const fn side_key(c: Color) -> u64 {
    match c {
        Color::White => 0,
        Color::Black => splitmix64(0xC0FFEE),
    }
}

/// Key for the last-moved piece (pillbug stun state). `None` contributes 0.
#[inline]
pub const fn last_moved_key(p: Option<PieceId>) -> u64 {
    match p {
        None => 0,
        Some(p) => splitmix64(0xBEEF_0000 | p.0 as u64),
    }
}

/// Early-game phase key: placement legality depends on the turn number until
/// both queens are down (turn-1 queen ban, queen-by-4 rule), so positions
/// reached at different early plies must hash differently. Clamped so that
/// past ply 8 all positions with identical material hash identically.
#[inline]
pub const fn phase_key(ply: u16) -> u64 {
    let clamped = if ply > 8 { 8 } else { ply };
    splitmix64(0x00FA_CADE_0000 | clamped as u64)
}
