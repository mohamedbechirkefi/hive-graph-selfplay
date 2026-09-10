//! Graph-arm state encoder — the Rust mirror of
//! `python/hivenet/graph_dataset.py::build_graph` (D-022; spec in
//! docs/representations/graph.md). The two builders MUST stay
//! byte-identical on the state tensors and move rows; enforced by
//! `dump_graph` + `scripts/crosscheck_graph.py` (nightly).
//!
//! Nodes are candidate-set cells addressed by their 32x32 FRAME
//! coordinates (occupied first, then 1-ring, each sorted by (y, x));
//! edges use the Python HEX_DELTAS direction order on frame coords:
//! E, NE, NW, W, SW, SE. Overflow panics loudly — never truncates.

use crate::{Frame, rel_piece};
use hive_core::bug::{PIECES_PER_COLOR, PieceId};
use hive_core::onehive::articulation_cells;
use hive_core::state::{GameState, Move};
use std::collections::BTreeMap;

pub const NODE_CAP: usize = 224;
pub const MOVE_CAP: usize = 321;
pub const PASS_SLOT: i64 = 28;
pub const NODE_F: usize = 56;
pub const GLOBAL_F: usize = 23;

/// Python HEX_DELTAS order (graph_dataset.py): E, NE, NW, W, SW, SE.
const DELTAS: [(i32, i32); 6] = [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)];

pub struct GraphTensors {
    pub nodes: Vec<f32>,   // NODE_CAP * NODE_F
    pub nbrs: Vec<i64>,    // NODE_CAP * 6 (NODE_CAP = none)
    pub nmask: Vec<u8>,    // NODE_CAP
    pub glob: Vec<f32>,    // GLOBAL_F
    /// (x, y) -> node index, for move-row construction.
    index: BTreeMap<(i32, i32), usize>,
}

/// Build the state tensors for a position (mirrors Python exactly).
pub fn graph_state(s: &GameState) -> GraphTensors {
    let b = &s.board;
    let frame = Frame::new(s);
    let stm = s.to_move;

    // Stacks keyed by frame coords, pids sorted by level.
    let mut stacks: BTreeMap<(i32, i32), Vec<PieceId>> = BTreeMap::new();
    for p in b.pieces_on_board() {
        let (x, y) = frame.xy(b.loc(p).cell).expect("occupied cell in frame");
        stacks.entry((x as i32, y as i32)).or_default().push(p);
    }
    for pids in stacks.values_mut() {
        pids.sort_by_key(|&p| b.loc(p).level);
    }

    // Candidate cells: occupied sorted by (y, x), then ring sorted by (y, x).
    let mut occupied: Vec<(i32, i32)> = stacks.keys().copied().collect();
    occupied.sort_by_key(|&(x, y)| (y, x));
    let mut ring: Vec<(i32, i32)> = Vec::new();
    for &(x, y) in &occupied {
        for (dx, dy) in DELTAS {
            let n = (x + dx, y + dy);
            if !stacks.contains_key(&n) && !ring.contains(&n) {
                ring.push(n);
            }
        }
    }
    ring.sort_by_key(|&(x, y)| (y, x));
    let mut cells: Vec<(i32, i32)> = occupied.iter().chain(ring.iter()).copied().collect();
    if cells.is_empty() {
        cells.push((16, 16)); // empty board: canonical first cell
    }
    assert!(
        cells.len() <= NODE_CAP,
        "graph overflow: candidate set {} exceeds NODE_CAP {NODE_CAP}",
        cells.len()
    );
    let index: BTreeMap<(i32, i32), usize> =
        cells.iter().enumerate().map(|(i, &c)| (c, i)).collect();

    // Placement legality per colour (Python's simplified rule).
    let top_color = |c: &(i32, i32)| stacks.get(c).map(|p| p[p.len() - 1].color() as usize);
    let placeable = |color: usize, c: &(i32, i32)| -> bool {
        if stacks.contains_key(c) {
            return false;
        }
        let mut own = false;
        for (dx, dy) in DELTAS {
            match top_color(&(c.0 + dx, c.1 + dy)) {
                Some(tc) if tc == color => own = true,
                Some(_) => return false,
                None => {}
            }
        }
        own
    };

    let art = articulation_cells(b);
    let stm_idx = stm as usize;
    let mut nodes = vec![0f32; NODE_CAP * NODE_F];
    let mut nbrs = vec![NODE_CAP as i64; NODE_CAP * 6];
    let mut nmask = vec![0u8; NODE_CAP];
    for (&c, &i) in &index {
        nmask[i] = 1;
        let row = &mut nodes[i * NODE_F..(i + 1) * NODE_F];
        let empty_pids: Vec<PieceId> = Vec::new();
        let pids = stacks.get(&c).unwrap_or(&empty_pids);
        for (lvl, &p) in pids.iter().take(5).enumerate() {
            let base = lvl * 10;
            row[base] = 1.0;
            row[base + 1] = if p.color() as usize == stm_idx { 1.0 } else { 0.0 };
            row[base + 2 + p.bug() as usize] = 1.0;
        }
        row[50] = pids.len() as f32 / 5.0;
        row[51] = if pids.is_empty() { 1.0 } else { 0.0 };
        if let Some(&top) = pids.last() {
            let loc = b.loc(top);
            if loc.level == 0 && art.contains(loc.cell) {
                row[52] = 1.0;
            }
            if s.last_moved == Some(top) {
                row[53] = 1.0;
            }
        }
        row[54] = if placeable(stm_idx, &c) { 1.0 } else { 0.0 };
        row[55] = if placeable(1 - stm_idx, &c) { 1.0 } else { 0.0 };
        for (d, (dx, dy)) in DELTAS.iter().enumerate() {
            if let Some(&j) = index.get(&(c.0 + dx, c.1 + dy)) {
                nbrs[i * 6 + d] = j as i64;
            }
        }
    }

    let mut glob = vec![0f32; GLOBAL_F];
    glob[0] = if stm_idx == 0 { 1.0 } else { 0.0 };
    glob[1] = s.ply.min(255) as f32 / 100.0;
    for (slot, color) in [(2usize, stm), (3, stm.other())] {
        let q = s.queen(color);
        if b.on_board(q) {
            let libs = hive_core::hex::neighbors(b.loc(q).cell)
                .iter()
                .filter(|&&n| !b.occupied(n))
                .count();
            glob[slot] = libs as f32 / 6.0;
        }
    }
    for (off, color) in [(4usize, stm), (12, stm.other())] {
        for ri in 0..PIECES_PER_COLOR as u8 {
            let p = PieceId::new(color, ri);
            if !b.on_board(p) {
                glob[off + p.bug() as usize] += 1.0 / 3.0;
            }
        }
    }
    glob[20] = s.game_type.mosquito as u8 as f32;
    glob[21] = s.game_type.ladybug as u8 as f32;
    glob[22] = s.game_type.pillbug as u8 as f32;

    GraphTensors { nodes, nbrs, nmask, glob, index }
}

/// Move rows for the decoder head, in the given move order:
/// [rel_piece slot, dest node, src node]; src/absent = NODE_CAP.
pub fn graph_moves(
    s: &GameState,
    frame: &Frame,
    g: &GraphTensors,
    moves: &[Move],
) -> (Vec<i64>, Vec<u8>) {
    assert!(moves.len() <= MOVE_CAP, "graph overflow: {} legal moves", moves.len());
    let mut rows = vec![NODE_CAP as i64; MOVE_CAP * 3];
    let mut mask = vec![0u8; MOVE_CAP];
    for (k, &mv) in moves.iter().enumerate() {
        mask[k] = 1;
        let row = &mut rows[k * 3..k * 3 + 3];
        match mv {
            Move::Pass => row[0] = PASS_SLOT,
            Move::Place { piece, to } | Move::Move { piece, to } => {
                row[0] = rel_piece(s.to_move, piece) as i64;
                let (x, y) = frame.xy(to).expect("destination in frame");
                row[1] = g.index[&(x as i32, y as i32)] as i64;
                if s.board.on_board(piece) {
                    let (sx, sy) = frame.xy(s.board.loc(piece).cell).expect("src in frame");
                    row[2] = g.index[&(sx as i32, sy as i32)] as i64;
                }
            }
        }
    }
    (rows, mask)
}
