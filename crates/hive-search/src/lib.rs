//! Alpha-beta (PVS) search: iterative deepening, lock-free shared
//! transposition table (lazy SMP), killer/history ordering, late-move
//! reductions, queen-targeting quiescence, repetition-aware.
//!
//! No null-move pruning: Hive's forced-pass states make tempo-based pruning
//! unsound in exactly the positions that matter (queen races).

use hive_core::bug::Color;
use hive_core::game::Game;
use hive_core::hex::{Cell, neighbors};
use hive_core::state::{GameResult, GameState, Move};
use hive_eval::{WIN, WIN_THRESHOLD, Weights, evaluate};
use hive_uhp::server::{SearchLimit, Searcher};
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::time::{Duration, Instant};

const MAX_PLY: usize = 96;
const HIST_MAX: i32 = 1 << 14;
const QDEPTH: i32 = 6;

// --- Move packing ----------------------------------------------------------

fn pack_move(m: Move) -> u32 {
    match m {
        Move::Pass => 0,
        Move::Place { piece, to } => 1 << 30 | (piece.0 as u32) << 12 | to as u32,
        Move::Move { piece, to } => 2 << 30 | (piece.0 as u32) << 12 | to as u32,
    }
}

fn unpack_move(v: u32) -> Move {
    let piece = hive_core::bug::PieceId(((v >> 12) & 0x3F) as u8);
    let to = (v & 0xFFF) as Cell;
    match v >> 30 {
        1 => Move::Place { piece, to },
        2 => Move::Move { piece, to },
        _ => Move::Pass,
    }
}

// --- Lock-free transposition table (XOR-validated, shared by SMP threads) --

#[derive(Copy, Clone)]
struct TtData {
    mv: u32,
    score: i16,
    depth: i8,
    flag: u8, // 1 exact, 2 lower, 3 upper
}

impl TtData {
    fn to_u64(self) -> u64 {
        (self.mv as u64) << 32
            | (self.score as u16 as u64) << 16
            | (self.depth as u8 as u64) << 8
            | self.flag as u64
    }

    fn from_u64(v: u64) -> TtData {
        TtData {
            mv: (v >> 32) as u32,
            score: (v >> 16) as u16 as i16,
            depth: (v >> 8) as u8 as i8,
            flag: v as u8,
        }
    }
}

pub struct Tt {
    entries: Vec<(AtomicU64, AtomicU64)>, // (key ^ data, data)
    mask: usize,
}

impl Tt {
    pub fn new(log2_entries: u32) -> Tt {
        let n = 1usize << log2_entries;
        let mut entries = Vec::with_capacity(n);
        entries.resize_with(n, || (AtomicU64::new(0), AtomicU64::new(0)));
        Tt {
            entries,
            mask: n - 1,
        }
    }

    #[inline]
    fn probe(&self, key: u64) -> Option<TtData> {
        let (k, d) = &self.entries[(key as usize) & self.mask];
        let data = d.load(Ordering::Relaxed);
        if data != 0 && k.load(Ordering::Relaxed) ^ data == key {
            Some(TtData::from_u64(data))
        } else {
            None
        }
    }

    #[inline]
    fn store(&self, key: u64, data: TtData) {
        let slot = &self.entries[(key as usize) & self.mask];
        let old = slot.1.load(Ordering::Relaxed);
        let old_key = slot.0.load(Ordering::Relaxed) ^ old;
        // Depth-preferred for same position; always-replace otherwise.
        if old != 0 && old_key == key && TtData::from_u64(old).depth > data.depth {
            return;
        }
        let v = data.to_u64();
        slot.0.store(key ^ v, Ordering::Relaxed);
        slot.1.store(v, Ordering::Relaxed);
    }
}

// --- Search ----------------------------------------------------------------

pub struct SearchParams {
    pub tt_log2: u32,
    pub max_depth: u32,
    pub default_time: Duration,
    pub threads: u32,
}

impl Default for SearchParams {
    fn default() -> Self {
        SearchParams {
            tt_log2: 23, // 128 MB
            max_depth: 64,
            default_time: Duration::from_secs(5),
            threads: std::thread::available_parallelism()
                .map(|n| (n.get() as u32).saturating_sub(2).max(1))
                .unwrap_or(4),
        }
    }
}

#[derive(Default, Clone, Debug)]
pub struct Stats {
    pub depth: u32,
    pub score: i32,
    pub nodes: u64,
    pub elapsed: Duration,
    pub pv_move: Option<Move>,
}

/// Per-thread search worker.
struct Worker {
    tt: Arc<Tt>,
    stop: Arc<AtomicBool>,
    node_counter: Arc<AtomicU64>,
    weights: Weights,
    killers: [[u32; 2]; MAX_PLY],
    history: Vec<i32>, // [piece(32)][cell(4096)]
    rep_stack: Vec<u64>,
    nodes: u64,
    deadline: Option<Instant>,
    is_main: bool,
}

impl Worker {
    fn new(
        tt: Arc<Tt>,
        stop: Arc<AtomicBool>,
        node_counter: Arc<AtomicU64>,
        is_main: bool,
    ) -> Worker {
        Worker {
            tt,
            stop,
            node_counter,
            weights: Weights::default(),
            killers: [[0; 2]; MAX_PLY],
            history: vec![0; 32 * 4096],
            rep_stack: Vec::with_capacity(256),
            nodes: 0,
            deadline: None,
            is_main,
        }
    }

    #[inline]
    fn hist_idx(m: Move) -> Option<usize> {
        match m {
            Move::Move { piece, to } | Move::Place { piece, to } => {
                Some((piece.0 as usize) << 12 | to as usize)
            }
            Move::Pass => None,
        }
    }

    #[inline]
    fn bump_node(&mut self) {
        self.nodes += 1;
        if self.nodes.is_multiple_of(4096) {
            self.node_counter.fetch_add(4096, Ordering::Relaxed);
            if self.stop.load(Ordering::Relaxed) {
                return;
            }
            if self.is_main
                && let Some(d) = self.deadline
                && Instant::now() >= d
            {
                self.stop.store(true, Ordering::Relaxed);
            }
        }
    }

    #[inline]
    fn stopped(&self) -> bool {
        self.stop.load(Ordering::Relaxed)
    }

    fn terminal_score(s: &GameState, ply: i32) -> i32 {
        match s.result {
            GameResult::Draw => 0,
            GameResult::WhiteWins => {
                if s.to_move == Color::White {
                    WIN - ply
                } else {
                    -(WIN - ply)
                }
            }
            GameResult::BlackWins => {
                if s.to_move == Color::Black {
                    WIN - ply
                } else {
                    -(WIN - ply)
                }
            }
            _ => unreachable!(),
        }
    }

    /// Quiescence: stand pat, then only moves that land on or beside the
    /// enemy queen (the forcing moves of Hive).
    fn qsearch(
        &mut self,
        s: &mut GameState,
        ply: usize,
        mut alpha: i32,
        beta: i32,
        qdepth: i32,
    ) -> i32 {
        self.bump_node();
        if s.result.is_over() {
            return Self::terminal_score(s, ply as i32);
        }
        let stand = evaluate(s, &self.weights);
        if qdepth <= 0 || ply >= MAX_PLY - 1 || self.stopped() {
            return stand;
        }
        if stand >= beta {
            return stand;
        }
        if stand > alpha {
            alpha = stand;
        }

        let enemy_queen = s.queen(s.to_move.other());
        if !s.board.on_board(enemy_queen) {
            return alpha;
        }
        let qc = s.board.loc(enemy_queen).cell;
        let qn = neighbors(qc);

        let moves = hive_core::movegen::generate(s);
        let mut best = stand;
        for &mv in moves.iter() {
            let loud = match mv {
                Move::Move { to, .. } | Move::Place { to, .. } => to == qc || qn.contains(&to),
                Move::Pass => false,
            };
            if !loud {
                continue;
            }
            let undo = s.make(mv);
            let score = -self.qsearch(s, ply + 1, -beta, -alpha, qdepth - 1);
            s.unmake(mv, undo);
            if score > best {
                best = score;
            }
            if score > alpha {
                alpha = score;
            }
            if alpha >= beta {
                break;
            }
        }
        best
    }

    /// Score all moves for ordering. Higher = earlier.
    fn order_moves(&self, s: &GameState, moves: &mut [Move], tt_move: Option<Move>, ply: usize) {
        let enemy_queen_cell = {
            let q = s.queen(s.to_move.other());
            s.board.on_board(q).then(|| s.board.loc(q).cell)
        };
        let mut keys: Vec<i32> = Vec::with_capacity(moves.len());
        for &m in moves.iter() {
            let mut sc = 0;
            if Some(m) == tt_move {
                sc = 1 << 24;
            } else {
                if let Move::Move { to, .. } | Move::Place { to, .. } = m
                    && let Some(qc) = enemy_queen_cell
                {
                    if to == qc {
                        sc += 1 << 20;
                    } else if neighbors(qc).contains(&to) {
                        sc += 1 << 18;
                    }
                }
                let packed = pack_move(m);
                if self.killers[ply][0] == packed {
                    sc += 1 << 14;
                } else if self.killers[ply][1] == packed {
                    sc += (1 << 14) - 1;
                }
                if let Some(h) = Self::hist_idx(m) {
                    sc += self.history[h];
                }
            }
            keys.push(sc);
        }
        // Insertion sort by key desc (move lists are small and mostly sorted
        // after the first few hot moves).
        for i in 1..moves.len() {
            let (k, m) = (keys[i], moves[i]);
            let mut j = i;
            while j > 0 && keys[j - 1] < k {
                keys[j] = keys[j - 1];
                moves[j] = moves[j - 1];
                j -= 1;
            }
            keys[j] = k;
            moves[j] = m;
        }
    }

    fn negamax(
        &mut self,
        s: &mut GameState,
        depth: i32,
        ply: usize,
        mut alpha: i32,
        beta: i32,
    ) -> i32 {
        self.bump_node();
        if self.stopped() {
            return alpha;
        }
        if s.result.is_over() {
            return Self::terminal_score(s, ply as i32);
        }

        // Repetition: any prior occurrence on the path = draw score. (The
        // real threefold rule is enforced at the Game level; in-search this
        // steers correctly around shuffles.)
        let rep_key = s.repetition_key();
        if ply > 0 && self.rep_stack.iter().rev().skip(1).any(|&k| k == rep_key) {
            return 0;
        }

        if depth <= 0 || ply >= MAX_PLY - 1 {
            return self.qsearch(s, ply, alpha, beta, QDEPTH);
        }

        let key = s.hash();
        let mut tt_move = None;
        if let Some(e) = self.tt.probe(key) {
            let tt_score = unadjust_mate(e.score as i32, ply as i32);
            if e.depth as i32 >= depth {
                match e.flag {
                    1 => return tt_score,
                    2 if tt_score >= beta => return tt_score,
                    3 if tt_score <= alpha => return tt_score,
                    _ => {}
                }
            }
            tt_move = Some(unpack_move(e.mv));
        }

        let mut moves = hive_core::movegen::generate(s);
        debug_assert!(!moves.is_empty());
        self.order_moves(s, &mut moves, tt_move, ply);

        let orig_alpha = alpha;
        let mut best_score = -WIN - 1;
        let mut best_move = moves[0];

        for (i, &mv) in moves.iter().enumerate() {
            let undo = s.make(mv);
            self.rep_stack.push(s.repetition_key());

            let mut score;
            if i == 0 {
                score = -self.negamax(s, depth - 1, ply + 1, -beta, -alpha);
            } else {
                let mut reduction = 0;
                if depth >= 3 && i >= 4 {
                    reduction = 1 + (i >= 12) as i32;
                }
                score = -self.negamax(s, depth - 1 - reduction, ply + 1, -alpha - 1, -alpha);
                if score > alpha && reduction > 0 {
                    score = -self.negamax(s, depth - 1, ply + 1, -alpha - 1, -alpha);
                }
                if score > alpha && score < beta {
                    score = -self.negamax(s, depth - 1, ply + 1, -beta, -alpha);
                }
            }

            self.rep_stack.pop();
            s.unmake(mv, undo);

            if self.stopped() {
                return alpha;
            }
            if score > best_score {
                best_score = score;
                best_move = mv;
            }
            if score > alpha {
                alpha = score;
            }
            if alpha >= beta {
                let packed = pack_move(mv);
                if self.killers[ply][0] != packed {
                    self.killers[ply][1] = self.killers[ply][0];
                    self.killers[ply][0] = packed;
                }
                if let Some(h) = Self::hist_idx(mv) {
                    self.history[h] = (self.history[h] + depth * depth).min(HIST_MAX);
                }
                break;
            }
        }

        let flag = if best_score <= orig_alpha {
            3
        } else if best_score >= beta {
            2
        } else {
            1
        };
        self.tt.store(
            key,
            TtData {
                mv: pack_move(best_move),
                score: adjust_mate(best_score, ply as i32).clamp(i16::MIN as i32, i16::MAX as i32)
                    as i16,
                depth: depth as i8,
                flag,
            },
        );
        best_score
    }

    fn iterate(&mut self, game: &Game, max_depth: u32, hard_deadline: Option<Instant>) -> Stats {
        self.rep_stack.clear();
        self.rep_stack.extend_from_slice(game.repetition_keys());
        for h in self.history.iter_mut() {
            *h /= 8;
        }
        let mut s = game.state.clone();
        let moves = hive_core::movegen::generate(&s);
        let mut best = moves[0];
        let mut stats = Stats::default();
        let mut prev_score = 0i32;

        for depth in 1..=max_depth {
            let iter_start = Instant::now();

            // Aspiration windows from depth 4 on: try a narrow window around
            // the previous score, widening on fail.
            let score = if depth >= 4 {
                let mut delta = 60;
                loop {
                    let alpha = (prev_score - delta).max(-WIN - 1);
                    let beta = (prev_score + delta).min(WIN + 1);
                    let sc = self.negamax(&mut s, depth as i32, 0, alpha, beta);
                    if self.stopped() || (sc > alpha && sc < beta) {
                        break sc;
                    }
                    delta *= 4;
                    if delta > 2000 {
                        break self.negamax(&mut s, depth as i32, 0, -WIN - 1, WIN + 1);
                    }
                }
            } else {
                self.negamax(&mut s, depth as i32, 0, -WIN - 1, WIN + 1)
            };
            if self.stopped() {
                break;
            }
            prev_score = score;
            if let Some(e) = self.tt.probe(s.hash()) {
                best = unpack_move(e.mv);
            }
            stats = Stats {
                depth,
                score,
                nodes: 0,
                elapsed: Duration::ZERO,
                pv_move: Some(best),
            };
            if score.abs() >= WIN_THRESHOLD {
                break;
            }
            // Adaptive time management (main thread only): don't start an
            // iteration that will likely blow the deadline. Deeper
            // iterations cost ~2-4x the previous one; require room for 2x.
            if self.is_main
                && let Some(hd) = hard_deadline
            {
                let last_iter = iter_start.elapsed();
                if Instant::now() + last_iter * 2 >= hd {
                    break;
                }
            }
        }
        stats
    }
}

/// Public engine: owns the shared TT and drives N lazy-SMP workers.
pub struct AlphaBeta {
    tt: Arc<Tt>,
    params: SearchParams,
    pub last_stats: Stats,
}

impl AlphaBeta {
    pub fn new(params: SearchParams) -> AlphaBeta {
        AlphaBeta {
            tt: Arc::new(Tt::new(params.tt_log2)),
            params,
            last_stats: Stats::default(),
        }
    }

    pub fn search(&mut self, game: &Game, limit: SearchLimit) -> (Move, Stats) {
        let start = Instant::now();
        let (max_depth, time_budget) = match limit {
            SearchLimit::Depth(d) => (d.min(self.params.max_depth), None),
            SearchLimit::Time(t) => (self.params.max_depth, Some(t)),
            SearchLimit::Default => (self.params.max_depth, Some(self.params.default_time)),
        };
        let deadline = time_budget.map(|t| start + t.saturating_sub(Duration::from_millis(30)));

        let moves = game.valid_moves();
        if moves.len() == 1 {
            let stats = Stats {
                pv_move: Some(moves[0]),
                ..Default::default()
            };
            self.last_stats = stats.clone();
            return (moves[0], stats);
        }

        let stop = Arc::new(AtomicBool::new(false));
        let node_counter = Arc::new(AtomicU64::new(0));
        // With a pure depth limit there is no deadline: helpers must not
        // outlive the main thread's iteration, so they get the same max
        // depth and stop when main sets the flag.
        let n_helpers = self.params.threads.saturating_sub(1);

        let mut main_stats = Stats::default();
        std::thread::scope(|scope| {
            for i in 0..n_helpers {
                let tt = self.tt.clone();
                let stop = stop.clone();
                let nc = node_counter.clone();
                let helper_depth = max_depth;
                scope.spawn(move || {
                    let mut w = Worker::new(tt, stop, nc, false);
                    // Stagger helper start depths to diversify the tree.
                    let _ = i;
                    w.iterate(game, helper_depth, None);
                });
            }
            let mut main = Worker::new(self.tt.clone(), stop.clone(), node_counter.clone(), true);
            main.deadline = deadline;
            main_stats = main.iterate(game, max_depth, deadline);
            node_counter.fetch_add(main.nodes % 4096, Ordering::Relaxed);
            stop.store(true, Ordering::Relaxed);
        });

        let best = main_stats.pv_move.unwrap_or(moves[0]);
        let stats = Stats {
            nodes: node_counter.load(Ordering::Relaxed),
            elapsed: start.elapsed(),
            ..main_stats
        };
        self.last_stats = stats.clone();
        (best, stats)
    }
}

fn adjust_mate(score: i32, ply: i32) -> i32 {
    if score >= WIN_THRESHOLD {
        score + ply
    } else if score <= -WIN_THRESHOLD {
        score - ply
    } else {
        score
    }
}

fn unadjust_mate(score: i32, ply: i32) -> i32 {
    if score >= WIN_THRESHOLD {
        score - ply
    } else if score <= -WIN_THRESHOLD {
        score + ply
    } else {
        score
    }
}

impl Searcher for AlphaBeta {
    fn best_move(&mut self, game: &Game, limit: SearchLimit) -> Move {
        self.search(game, limit).0
    }

    fn name(&self) -> String {
        "HiveMind v0.2.0".to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn single_thread_params() -> SearchParams {
        SearchParams {
            threads: 1,
            ..Default::default()
        }
    }

    #[test]
    fn finds_opening_move() {
        let game = Game::from_uhp("Base").unwrap();
        let mut ab = AlphaBeta::new(single_thread_params());
        let (mv, _) = ab.search(&game, SearchLimit::Depth(4));
        assert!(matches!(mv, Move::Place { .. }));
    }

    #[test]
    fn returns_legal_moves_midgame() {
        let mut game = Game::from_uhp("Base").unwrap();
        for m in ["wS1", "bS1 wS1-", "wQ -wS1", "bQ bS1-"] {
            game.play_uhp(m).unwrap();
        }
        let mut ab = AlphaBeta::new(single_thread_params());
        let (mv, _) = ab.search(&game, SearchLimit::Depth(5));
        assert!(game.valid_moves().contains(&mv));
    }

    #[test]
    fn smp_returns_legal_move() {
        let mut game = Game::from_uhp("Base+MLP").unwrap();
        for m in ["wG1", "bG1 wG1-", "wQ -wG1", "bQ bG1-", "wA1 \\wQ"] {
            game.play_uhp(m).unwrap();
        }
        let mut ab = AlphaBeta::new(SearchParams::default());
        let (mv, stats) = ab.search(&game, SearchLimit::Time(Duration::from_millis(500)));
        assert!(game.valid_moves().contains(&mv));
        assert!(stats.depth >= 3, "should reach depth 3+ in 500ms");
    }
}
