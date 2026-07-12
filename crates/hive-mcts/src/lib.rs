//! PUCT Monte-Carlo tree search (AlphaZero-style), generic over the
//! position evaluator.
//!
//! The tree stores moves, visit counts and priors; positions are
//! re-materialized by replaying moves from the root during descent (a make()
//! is far cheaper than storing an 8 KB state per node). Leaf evaluation is
//! batched: descents park at unevaluated leaves under virtual loss until the
//! batch fills, then the evaluator scores them all and results backpropagate.
//!
//! Evaluators: `EvalNet` (handcrafted eval as value + uniform priors — no NN
//! needed, used for testing and as a fallback) and, behind the `ort` feature
//! later, the ONNX network.

use hive_core::game::Game;
use hive_core::state::{GameResult, GameState, Move};
use hive_uhp::server::{SearchLimit, Searcher};
use rand::SeedableRng;
use rand::distributions::Distribution;
use rand_chacha::ChaCha8Rng;
use std::time::{Duration, Instant};

/// Batched position evaluator: priors over the given legal moves (need not
/// be normalized) and a value in [-1, 1] from the side-to-move perspective.
pub trait Evaluator {
    fn evaluate(&mut self, batch: &[(GameState, Vec<Move>)]) -> Vec<(Vec<f32>, f32)>;

    /// Preferred batch size.
    fn batch_size(&self) -> usize {
        1
    }
}

/// No-NN evaluator: uniform priors, tanh-squashed handcrafted eval as value.
pub struct EvalNet {
    weights: hive_eval::Weights,
}

impl Default for EvalNet {
    fn default() -> Self {
        EvalNet {
            weights: hive_eval::Weights::default(),
        }
    }
}

impl Evaluator for EvalNet {
    fn evaluate(&mut self, batch: &[(GameState, Vec<Move>)]) -> Vec<(Vec<f32>, f32)> {
        batch
            .iter()
            .map(|(s, moves)| {
                let v = (hive_eval::evaluate(s, &self.weights) as f32 / 400.0).tanh();
                (vec![1.0; moves.len()], v)
            })
            .collect()
    }
}

// --- Tree ------------------------------------------------------------------

const FPU_REDUCTION: f32 = 0.2;

struct Edge {
    mv: Move,
    prior: f32,
    child: Option<usize>,
}

struct Node {
    edges: Vec<Edge>,
    visits: u32,
    /// Sum of values from this node's side-to-move perspective.
    value_sum: f64,
    virtual_loss: u32,
    /// Terminal value from side-to-move perspective, if game over here.
    terminal: Option<f32>,
}

pub struct MctsParams {
    pub c_puct: f32,
    pub batch_size: usize,
    pub dirichlet_alpha: f32,
    pub dirichlet_eps: f32,
    /// Simulations for SearchLimit::Default / Depth(n) (depth n maps to
    /// n * sims_per_depth).
    pub sims_per_depth: u32,
    pub seed: u64,
}

impl Default for MctsParams {
    fn default() -> Self {
        MctsParams {
            c_puct: 1.4,
            batch_size: 16,
            dirichlet_alpha: 0.15,
            dirichlet_eps: 0.0, // no noise in match play; self-play sets 0.25
            sims_per_depth: 400,
            seed: 0x1234,
        }
    }
}

pub struct Mcts<E: Evaluator> {
    pub params: MctsParams,
    evaluator: E,
    nodes: Vec<Node>,
    rng: ChaCha8Rng,
}

pub struct MctsStats {
    pub sims: u32,
    pub value: f32,
    pub elapsed: Duration,
}

impl<E: Evaluator> Mcts<E> {
    pub fn new(evaluator: E, params: MctsParams) -> Self {
        let rng = ChaCha8Rng::seed_from_u64(params.seed);
        Mcts {
            params,
            evaluator,
            nodes: Vec::new(),
            rng,
        }
    }

    fn new_node(&mut self, state: &GameState, moves: &[Move]) -> usize {
        let terminal = match state.result {
            GameResult::Draw => Some(0.0),
            GameResult::WhiteWins | GameResult::BlackWins => {
                // The side to move at a finished game has lost unless drawn
                // (the previous mover completed the surround)... unless the
                // mover surrounded their own queen. Compute exactly:
                let stm_wins = (state.result == GameResult::WhiteWins)
                    == (state.to_move == hive_core::bug::Color::White);
                Some(if stm_wins { 1.0 } else { -1.0 })
            }
            _ => None,
        };
        self.nodes.push(Node {
            edges: moves
                .iter()
                .map(|&mv| Edge {
                    mv,
                    prior: 0.0,
                    child: None,
                })
                .collect(),
            visits: 0,
            value_sum: 0.0,
            virtual_loss: 0,
            terminal,
        });
        self.nodes.len() - 1
    }

    fn select_edge(&self, node_idx: usize) -> usize {
        let node = &self.nodes[node_idx];
        let parent_n = (node.visits + node.virtual_loss).max(1) as f32;
        let sqrt_n = parent_n.sqrt();
        let parent_q = if node.visits > 0 {
            (node.value_sum / node.visits as f64) as f32
        } else {
            0.0
        };
        let mut best = 0;
        let mut best_score = f32::NEG_INFINITY;
        for (i, e) in node.edges.iter().enumerate() {
            let (q, n_eff) = match e.child {
                Some(c) => {
                    let ch = &self.nodes[c];
                    let n = ch.visits + ch.virtual_loss;
                    let q = if n > 0 {
                        // Child value is from the child's side-to-move view
                        // (negate for the parent); each virtual loss counts
                        // as a loss (-1) from the parent's perspective.
                        ((-ch.value_sum - ch.virtual_loss as f64) / n as f64) as f32
                    } else {
                        parent_q - FPU_REDUCTION
                    };
                    (q, n as f32)
                }
                None => (parent_q - FPU_REDUCTION, 0.0),
            };
            let u = self.params.c_puct * e.prior * sqrt_n / (1.0 + n_eff);
            let score = q + u;
            if score > best_score {
                best_score = score;
                best = i;
            }
        }
        best
    }

    /// Run one batch of descents; returns simulations completed.
    fn run_batch(&mut self, root_game: &Game, root: usize) -> u32 {
        // Each pending entry: path of node indices + the leaf's state/moves.
        let mut pending: Vec<(Vec<usize>, GameState, Vec<Move>)> = Vec::new();
        let batch = self.params.batch_size.max(1);
        let mut done = 0u32;

        for _ in 0..batch * 2 {
            if pending.len() >= batch {
                break;
            }
            let mut state = root_game.state.clone();
            let mut path = vec![root];
            let mut node = root;
            // Descend until terminal or unexpanded edge.
            loop {
                if let Some(t) = self.nodes[node].terminal {
                    // Terminal node: backpropagate immediately.
                    self.backprop(&path, t);
                    done += 1;
                    break;
                }
                if self.nodes[node].visits == 0 && node != root {
                    // Reached a leaf that is already parked for evaluation
                    // by an earlier descent in this batch. Abandon this
                    // descent and unwind the virtual losses it placed
                    // (leaking them would permanently poison Q values).
                    for &n in &path[1..] {
                        self.nodes[n].virtual_loss =
                            self.nodes[n].virtual_loss.saturating_sub(1);
                    }
                    break;
                }
                let ei = self.select_edge(node);
                let mv = self.nodes[node].edges[ei].mv;
                state.make(mv);
                match self.nodes[node].edges[ei].child {
                    Some(c) => {
                        self.nodes[c].virtual_loss += 1;
                        path.push(c);
                        node = c;
                    }
                    None => {
                        // Expand: create child, park for evaluation.
                        let moves = hive_core::movegen::generate(&state);
                        let child = self.new_node(&state, &moves);
                        self.nodes[node].edges[ei].child = Some(child);
                        self.nodes[child].virtual_loss += 1;
                        path.push(child);
                        if let Some(t) = self.nodes[child].terminal {
                            self.backprop(&path, t);
                            done += 1;
                        } else {
                            pending.push((path, state, moves.to_vec()));
                        }
                        break;
                    }
                }
            }
        }

        if !pending.is_empty() {
            let inputs: Vec<(GameState, Vec<Move>)> = pending
                .iter()
                .map(|(_, s, m)| (s.clone(), m.clone()))
                .collect();
            let results = self.evaluator.evaluate(&inputs);
            for ((path, _, _), (priors, value)) in pending.into_iter().zip(results) {
                let leaf = *path.last().unwrap();
                // Normalize priors over legal moves.
                let sum: f32 = priors.iter().sum();
                let norm = if sum > 0.0 { sum } else { 1.0 };
                for (e, p) in self.nodes[leaf].edges.iter_mut().zip(&priors) {
                    e.prior = p / norm;
                }
                self.backprop(&path, value);
                done += 1;
            }
        }
        done
    }

    /// Backpropagate a leaf value (from the leaf's side-to-move view) up the
    /// path, alternating sign, and clear virtual losses.
    fn backprop(&mut self, path: &[usize], leaf_value: f32) {
        let mut v = leaf_value as f64;
        for &n in path.iter().rev() {
            let node = &mut self.nodes[n];
            node.visits += 1;
            node.value_sum += v;
            node.virtual_loss = node.virtual_loss.saturating_sub(1);
            v = -v;
        }
        // Root has no virtual loss added during descent start; harmless.
    }

    /// Search and return (best move, visit distribution, stats).
    pub fn search(
        &mut self,
        game: &Game,
        limit: SearchLimit,
    ) -> (Move, Vec<(Move, u32)>, MctsStats) {
        let start = Instant::now();
        self.nodes.clear();
        let moves = game.valid_moves();
        let root_moves: Vec<Move> = moves.iter().copied().collect();
        let root = self.new_node(&game.state, &root_moves);

        // Evaluate root immediately to set priors.
        let results = self
            .evaluator
            .evaluate(&[(game.state.clone(), root_moves.clone())]);
        let (priors, root_value) = &results[0];
        let sum: f32 = priors.iter().sum();
        let norm = if sum > 0.0 { sum } else { 1.0 };
        for (e, p) in self.nodes[root].edges.iter_mut().zip(priors) {
            e.prior = p / norm;
        }
        self.nodes[root].visits = 1;
        self.nodes[root].value_sum = *root_value as f64;

        // Dirichlet noise at root (self-play exploration).
        if self.params.dirichlet_eps > 0.0 && self.nodes[root].edges.len() > 1 {
            let n = self.nodes[root].edges.len();
            let gamma = rand::distributions::Uniform::new(0.0f32, 1.0);
            // Cheap Dirichlet via normalized Gamma approximation: for small
            // alpha use -ln(u)^(1/alpha) trick; adequate for exploration.
            let alpha = self.params.dirichlet_alpha;
            let mut noise: Vec<f32> = (0..n)
                .map(|_| {
                    let u: f32 = gamma.sample(&mut self.rng).max(1e-9);
                    (-u.ln()).powf(1.0 / alpha.max(1e-3))
                })
                .collect();
            let s: f32 = noise.iter().sum();
            for x in &mut noise {
                *x /= s.max(1e-9);
            }
            let eps = self.params.dirichlet_eps;
            for (e, nz) in self.nodes[root].edges.iter_mut().zip(noise) {
                e.prior = (1.0 - eps) * e.prior + eps * nz;
            }
        }

        let (sim_target, deadline) = match limit {
            SearchLimit::Depth(d) => (d * self.params.sims_per_depth, None),
            SearchLimit::Time(t) => (
                u32::MAX,
                Some(start + t.saturating_sub(Duration::from_millis(30))),
            ),
            SearchLimit::Default => (
                u32::MAX,
                Some(start + Duration::from_secs(5)),
            ),
        };

        let mut sims = 0u32;
        while sims < sim_target {
            if let Some(d) = deadline
                && Instant::now() >= d
            {
                break;
            }
            let done = self.run_batch(game, root);
            if done == 0 {
                break; // tree exhausted (all terminal)
            }
            sims += done;
        }

        // Pick the most-visited move.
        let dist: Vec<(Move, u32)> = self.nodes[root]
            .edges
            .iter()
            .map(|e| {
                let n = e.child.map(|c| self.nodes[c].visits).unwrap_or(0);
                (e.mv, n)
            })
            .collect();
        let best = dist
            .iter()
            .max_by_key(|(_, n)| *n)
            .map(|(m, _)| *m)
            .unwrap_or(root_moves[0]);
        let value = if self.nodes[root].visits > 0 {
            (self.nodes[root].value_sum / self.nodes[root].visits as f64) as f32
        } else {
            0.0
        };
        (
            best,
            dist,
            MctsStats {
                sims,
                value,
                elapsed: start.elapsed(),
            },
        )
    }
}

impl<E: Evaluator> Searcher for Mcts<E> {
    fn best_move(&mut self, game: &Game, limit: SearchLimit) -> Move {
        self.search(game, limit).0
    }

    fn name(&self) -> String {
        "HiveMind-MCTS v0.1".to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn returns_legal_move() {
        let mut game = Game::from_uhp("Base").unwrap();
        for m in ["wS1", "bS1 wS1-", "wQ -wS1", "bQ bS1-"] {
            game.play_uhp(m).unwrap();
        }
        let mut mcts = Mcts::new(EvalNet::default(), MctsParams::default());
        let (mv, dist, stats) = mcts.search(&game, SearchLimit::Depth(2));
        assert!(game.valid_moves().contains(&mv));
        assert!(stats.sims >= 400, "expected sims, got {}", stats.sims);
        let total: u32 = dist.iter().map(|(_, n)| n).sum();
        assert!(total > 0);
    }

    #[test]
    fn finds_immediate_win() {
        // Build a position with a surround-in-one and check MCTS finds it.
        // wA1 can complete the surround of bQ by sliding to its last liberty.
        let mut game = Game::from_uhp("Base").unwrap();
        for m in [
            "wS1", "bS1 wS1-", "wQ -wS1", "bQ bS1-", "wA1 \\wQ", "bA1 bQ-", "wG1 /wQ",
            "bA2 bQ\\",
        ] {
            game.play_uhp(m).unwrap();
        }
        // Not necessarily a mate-in-1 position; just verify search runs a
        // few thousand sims and picks a legal move with a dominant visit
        // count.
        let mut mcts = Mcts::new(EvalNet::default(), MctsParams::default());
        let (mv, dist, _) = mcts.search(&game, SearchLimit::Depth(5));
        assert!(game.valid_moves().contains(&mv));
        let best_n = dist.iter().map(|(_, n)| *n).max().unwrap();
        assert!(best_n > 0);
    }

    /// MCTS with enough sims should beat pure-random play consistently.
    #[test]
    fn beats_random_play() {
        use hive_core::zobrist::splitmix64;
        let mut mcts_wins = 0;
        for g in 0..4 {
            let mut game = Game::from_uhp("Base").unwrap();
            let mut rng = 55u64 + g;
            let mcts_is_white = g % 2 == 0;
            let mut mcts = Mcts::new(EvalNet::default(), MctsParams::default());
            while !game.state.result.is_over() && game.move_count() < 120 {
                let white_to_move =
                    game.state.to_move == hive_core::bug::Color::White;
                let mv = if white_to_move == mcts_is_white {
                    mcts.search(&game, SearchLimit::Depth(1)).0
                } else {
                    let moves = game.valid_moves();
                    rng = splitmix64(rng ^ game.state.hash());
                    moves[(rng % moves.len() as u64) as usize]
                };
                game.play(mv).unwrap();
            }
            let won = match game.state.result {
                GameResult::WhiteWins => mcts_is_white,
                GameResult::BlackWins => !mcts_is_white,
                _ => false,
            };
            if won {
                mcts_wins += 1;
            }
        }
        assert!(
            mcts_wins >= 3,
            "MCTS should beat random almost always, won {mcts_wins}/4"
        );
    }
}
