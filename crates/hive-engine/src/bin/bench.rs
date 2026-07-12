//! Search benchmark: fixed midgame positions, reports depth/nodes/nps.

use hive_core::game::Game;
use hive_search::{AlphaBeta, SearchParams};
use hive_uhp::server::SearchLimit;
use std::time::Duration;

/// Deterministic pseudo-random positions: (name, game type, plies, seed).
const POSITIONS: &[(&str, &str, u32, u64)] = &[
    ("opening-base", "Base", 8, 42),
    ("midgame-base", "Base", 16, 7),
    ("opening-mlp", "Base+MLP", 8, 42),
    ("midgame-mlp", "Base+MLP", 18, 1234),
];

fn build(gt: &str, plies: u32, mut seed: u64) -> Game {
    let mut game = Game::from_uhp(gt).unwrap();
    for _ in 0..plies {
        if game.state.result.is_over() {
            break;
        }
        let moves = game.valid_moves();
        seed = hive_core::zobrist::splitmix64(seed ^ game.state.hash());
        let mv = moves[(seed % moves.len() as u64) as usize];
        game.play(mv).unwrap();
    }
    game
}

fn main() {
    let seconds: u64 = std::env::args()
        .nth(1)
        .and_then(|s| s.parse().ok())
        .unwrap_or(3);
    for &(name, gt, plies, seed) in POSITIONS {
        let game = build(gt, plies, seed);
        let mut ab = AlphaBeta::new(SearchParams::default());
        let (mv, stats) = ab.search(&game, SearchLimit::Time(Duration::from_secs(seconds)));
        println!(
            "{name}: depth {:2}  score {:6}  nodes {:>10}  {:.2} Mnps  best {}",
            stats.depth,
            stats.score,
            stats.nodes,
            stats.nodes as f64 / stats.elapsed.as_secs_f64() / 1e6,
            hive_core::notation::move_to_uhp(&game.state, mv),
        );
    }
}
