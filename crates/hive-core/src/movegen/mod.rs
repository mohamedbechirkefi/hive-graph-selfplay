//! Move generation for all bugs, base + MLP expansions.
//!
//! Conventions matching Mzinga (the perft/fuzzing reference):
//! - the queen may not be placed on either player's first turn;
//! - for identical in-hand bugs only the lowest ordinal is placeable;
//! - if a player has no placement and no movement, the single move `pass`
//!   is generated; a finished game generates no moves.

use crate::board::Board;
use crate::bug::{Bug, PieceId, ROSTER};
use crate::hex::{ALL_DIRS, CENTER, Cell, CellSet, Dir, neighbor, neighbors};
use crate::onehive::{Articulation, articulation_cells};
use crate::state::{GameState, Move};
use smallvec::SmallVec;

pub type MoveList = SmallVec<[Move; 128]>;

/// Board occupancy with one mover lifted off the top of its origin cell.
/// All slide/gate legality is evaluated on this view.
#[derive(Copy, Clone)]
struct Lifted<'a> {
    board: &'a Board,
    origin: Cell,
}

impl Lifted<'_> {
    #[inline]
    fn height(&self, c: Cell) -> u8 {
        let h = self.board.height(c);
        if c == self.origin { h - 1 } else { h }
    }

    #[inline]
    fn occupied(&self, c: Cell) -> bool {
        self.height(c) > 0
    }
}

/// One ground-level slide step (freedom-to-move): the destination must be
/// empty and exactly one of the two cells adjacent to both `from` and the
/// destination must be occupied (0 = would detach, 2 = gate).
#[inline]
fn slide_ok(v: Lifted, from: Cell, d: Dir) -> bool {
    let to = neighbor(from, d);
    if v.occupied(to) {
        return false;
    }
    v.occupied(neighbor(from, d.ccw())) != v.occupied(neighbor(from, d.cw()))
}

/// Height-gate for climbing moves (beetle, ladybug, pillbug throws): a step
/// is blocked iff both common neighbors are strictly higher than both the
/// level the mover starts above (`beneath`) and the destination stack.
#[inline]
fn climb_ok(v: Lifted, from: Cell, d: Dir, beneath: u8, to_height: u8) -> bool {
    let m = beneath.max(to_height);
    !(v.height(neighbor(from, d.ccw())) > m && v.height(neighbor(from, d.cw())) > m)
}

// ---------------------------------------------------------------------------
// Per-bug destination generators. Each takes the lifted view and the mover's
// origin cell and pushes destination cells.

fn queen_dests(v: Lifted, from: Cell, out: &mut Vec<Cell>) {
    for d in ALL_DIRS {
        if slide_ok(v, from, d) {
            out.push(neighbor(from, d));
        }
    }
}

fn ant_dests(v: Lifted, from: Cell, out: &mut Vec<Cell>) {
    let mut visited = CellSet::new();
    visited.insert(from);
    let mut stack: SmallVec<[Cell; 32]> = SmallVec::new();
    stack.push(from);
    while let Some(c) = stack.pop() {
        for d in ALL_DIRS {
            let to = neighbor(c, d);
            if !visited.contains(to) && slide_ok(v, c, d) {
                visited.insert(to);
                out.push(to);
                stack.push(to);
            }
        }
    }
}

fn spider_dests(v: Lifted, from: Cell, out: &mut Vec<Cell>) {
    // Exactly 3 slide steps, never revisiting a cell.
    let mut path: SmallVec<[Cell; 4]> = SmallVec::new();
    path.push(from);
    fn rec(v: Lifted, path: &mut SmallVec<[Cell; 4]>, out: &mut Vec<Cell>) {
        let c = *path.last().unwrap();
        for d in ALL_DIRS {
            let to = neighbor(c, d);
            if path.contains(&to) || !slide_ok(v, c, d) {
                continue;
            }
            if path.len() == 3 {
                out.push(to);
            } else {
                path.push(to);
                rec(v, path, out);
                path.pop();
            }
        }
    }
    rec(v, &mut path, out);
}

fn grasshopper_dests(v: Lifted, from: Cell, out: &mut Vec<Cell>) {
    for d in ALL_DIRS {
        let mut c = neighbor(from, d);
        if !v.occupied(c) {
            continue;
        }
        while v.occupied(c) {
            c = neighbor(c, d);
        }
        out.push(c);
    }
}

fn beetle_dests(v: Lifted, from: Cell, out: &mut Vec<Cell>) {
    let beneath = v.height(from); // stack under the beetle after lifting
    for d in ALL_DIRS {
        let to = neighbor(from, d);
        let to_h = v.height(to);
        let ok = if beneath == 0 && to_h == 0 {
            // Ground-to-ground: ordinary slide (gate + stay-connected).
            slide_ok(v, from, d)
        } else {
            climb_ok(v, from, d, beneath, to_h)
        };
        if ok {
            out.push(to);
        }
    }
}

fn ladybug_dests(v: Lifted, from: Cell, out: &mut Vec<Cell>) {
    // Step 1: climb onto an adjacent occupied cell.
    for d1 in ALL_DIRS {
        let n1 = neighbor(from, d1);
        let h1 = v.height(n1);
        if h1 == 0 || !climb_ok(v, from, d1, 0, h1) {
            continue;
        }
        // Step 2: move on top to another adjacent occupied cell.
        for d2 in ALL_DIRS {
            let n2 = neighbor(n1, d2);
            let h2 = v.height(n2);
            if n2 == from || n2 == n1 || h2 == 0 || !climb_ok(v, n1, d2, h1, h2) {
                continue;
            }
            // Step 3: drop down to an adjacent empty cell.
            for d3 in ALL_DIRS {
                let dest = neighbor(n2, d3);
                if dest == from || v.occupied(dest) || !climb_ok(v, n2, d3, h2, 0) {
                    continue;
                }
                out.push(dest);
            }
        }
    }
}

fn dests_for_bug(bug: Bug, v: Lifted, from: Cell, on_stack: bool, out: &mut Vec<Cell>) {
    if on_stack {
        // Any bug on top of the hive (beetle, or mosquito that climbed as a
        // beetle) moves exactly as a beetle.
        beetle_dests(v, from, out);
        return;
    }
    match bug {
        Bug::Queen | Bug::Pillbug => queen_dests(v, from, out),
        Bug::Ant => ant_dests(v, from, out),
        Bug::Spider => spider_dests(v, from, out),
        Bug::Grasshopper => grasshopper_dests(v, from, out),
        Bug::Beetle => beetle_dests(v, from, out),
        Bug::Ladybug => ladybug_dests(v, from, out),
        Bug::Mosquito => unreachable!("mosquito handled by caller"),
    }
}

// ---------------------------------------------------------------------------
// Pillbug ability.

/// Throws by a (possibly mosquito-copied) pillbug standing at `thrower_cell`.
/// The thrower itself may be pinned by the one-hive rule and still throw.
fn pillbug_throws(s: &GameState, art: &Articulation, thrower_cell: Cell, moves: &mut MoveList) {
    let b = &s.board;
    let thrower_h = b.height(thrower_cell);
    for td in ALL_DIRS {
        let t = neighbor(thrower_cell, td);
        // Target: an unstacked piece that isn't stunned-protected or pinned.
        if b.height(t) != 1 {
            continue;
        }
        let target = b.top_piece(t).unwrap();
        if Some(target) == s.last_moved || art.contains(t) {
            continue;
        }
        let v = Lifted {
            board: b,
            origin: t,
        };
        // Up-leg: target (ground) climbs onto the thrower's stack.
        let up_dir = ALL_DIRS
            .into_iter()
            .find(|&d| neighbor(t, d) == thrower_cell)
            .unwrap();
        if !climb_ok(v, t, up_dir, 0, thrower_h) {
            continue;
        }
        // Down-leg: from atop the thrower to any adjacent empty cell.
        for dd in ALL_DIRS {
            let dest = neighbor(thrower_cell, dd);
            if dest == t || v.occupied(dest) {
                continue;
            }
            if climb_ok(v, thrower_cell, dd, thrower_h, 0) {
                moves.push(Move::Move {
                    piece: target,
                    to: dest,
                });
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Placement.

fn placements(s: &GameState, moves: &mut MoveList) {
    let b = &s.board;
    let me = s.to_move;

    // Candidate cells.
    let mut cells: SmallVec<[Cell; 32]> = SmallVec::new();
    match s.ply {
        0 => cells.push(CENTER),
        1 => {
            let first = b.any_occupied_cell().unwrap();
            cells.extend_from_slice(&neighbors(first));
        }
        _ => {
            let mut seen = CellSet::new();
            for p in b.pieces_on_board() {
                if p.color() != me || !b.is_top(p) {
                    continue;
                }
                for n in neighbors(b.loc(p).cell) {
                    if b.occupied(n) || seen.contains(n) {
                        continue;
                    }
                    seen.insert(n);
                    if !b.has_neighbor_top_of_color(n, me.other()) {
                        cells.push(n);
                    }
                }
            }
        }
    }
    if cells.is_empty() {
        return;
    }

    // Placeable pieces: lowest unplaced ordinal per bug type.
    let mut pieces: SmallVec<[PieceId; 8]> = SmallVec::new();
    let own_turn = s.own_turn_number();
    let queen = s.queen(me);
    if own_turn == 4 && !s.queen_placed(me) {
        pieces.push(queen);
    } else {
        let mut prev_bug: Option<Bug> = None;
        for (i, &(bug, _)) in ROSTER.iter().enumerate() {
            let p = PieceId::new(me, i as u8);
            let first_of_bug = prev_bug != Some(bug);
            prev_bug = Some(bug);
            if !s.game_type.includes(bug) || b.on_board(p) {
                continue;
            }
            if bug == Bug::Queen && own_turn == 1 {
                continue;
            }
            // Only the lowest unplaced ordinal of each bug is placeable.
            if !first_of_bug && !b.on_board(PieceId(p.0 - 1)) {
                continue;
            }
            pieces.push(p);
        }
    }

    for &p in &pieces {
        for &c in &cells {
            moves.push(Move::Place { piece: p, to: c });
        }
    }
}

// ---------------------------------------------------------------------------
// Top level.

pub fn generate(s: &GameState) -> MoveList {
    let mut moves = MoveList::new();
    if s.result.is_over() {
        return moves;
    }

    placements(s, &mut moves);

    if s.queen_placed(s.to_move) {
        let art = articulation_cells(&s.board);
        let mut dests: Vec<Cell> = Vec::with_capacity(32);

        for p in s.board.pieces_on_board() {
            if p.color() != s.to_move || !s.board.is_top(p) || s.stunned(p) {
                continue;
            }
            let loc = s.board.loc(p);
            let on_stack = loc.level > 0;
            // One-hive: a lone ground piece on a cut vertex may not move.
            if !on_stack && art.contains(loc.cell) {
                // ...but a pinned pillbug (or mosquito copying one) may still
                // use the throw ability, handled below.
            } else {
                dests.clear();
                let v = Lifted {
                    board: &s.board,
                    origin: loc.cell,
                };
                match p.bug() {
                    Bug::Mosquito => {
                        if on_stack {
                            beetle_dests(v, loc.cell, &mut dests);
                        } else {
                            let mut copied: SmallVec<[Bug; 8]> = SmallVec::new();
                            for n in neighbors(loc.cell) {
                                if let Some(t) = s.board.top_piece(n) {
                                    let bug = t.bug();
                                    if bug != Bug::Mosquito && !copied.contains(&bug) {
                                        copied.push(bug);
                                    }
                                }
                            }
                            for bug in copied {
                                dests_for_bug(bug, v, loc.cell, false, &mut dests);
                            }
                        }
                    }
                    bug => dests_for_bug(bug, v, loc.cell, on_stack, &mut dests),
                }
                for &to in dests.iter() {
                    if to != loc.cell {
                        moves.push(Move::Move { piece: p, to });
                    }
                }
            }

            // Pillbug throw ability (works even when the thrower is pinned,
            // but not when covered or stunned — both already filtered).
            if !on_stack {
                let is_thrower = match p.bug() {
                    Bug::Pillbug => true,
                    Bug::Mosquito => neighbors(loc.cell).iter().any(|&n| {
                        s.board
                            .top_piece(n)
                            .is_some_and(|t| t.bug() == Bug::Pillbug)
                    }),
                    _ => false,
                };
                if is_thrower {
                    pillbug_throws(s, &art, loc.cell, &mut moves);
                }
            }
        }
    }

    // Dedup: mosquito multi-copy, ladybug multi-path, walk-vs-throw overlaps.
    moves.sort_unstable();
    moves.dedup();

    if moves.is_empty() {
        moves.push(Move::Pass);
    }
    moves
}

#[cfg(test)]
mod tests;
