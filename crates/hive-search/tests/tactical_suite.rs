//! Tactical regression suite: every fixture is a position where a forced
//! win was previously proven. The engine must keep finding it.
//!
//! Fixture format (tests/tactical_suite/suite.txt, repo root):
//!   GameString|ExpectedWinner
//! Regenerate/extend with: ./target/release/mine 50 5 <seed> [gametype]

use hive_core::game::Game;
use hive_eval::WIN_THRESHOLD;
use hive_search::{AlphaBeta, SearchParams};
use hive_uhp::server::SearchLimit;
use std::time::Duration;

fn suite_path() -> std::path::PathBuf {
    std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../../tests/tactical_suite/suite.txt")
}

#[test]
fn solves_tactical_suite() {
    let Ok(data) = std::fs::read_to_string(suite_path()) else {
        eprintln!("no tactical suite yet — run the miner first; skipping");
        return;
    };
    let mut total = 0;
    let mut solved = 0;
    for line in data.lines() {
        let line = line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        let (gs, _winner) = line.split_once('|').expect("bad fixture line");
        let game = Game::from_uhp(gs).expect("fixture must replay");
        let mut ab = AlphaBeta::new(SearchParams {
            threads: 2,
            tt_log2: 20,
            ..Default::default()
        });
        let (_, stats) = ab.search(&game, SearchLimit::Time(Duration::from_secs(2)));
        total += 1;
        if stats.score >= WIN_THRESHOLD {
            solved += 1;
        } else {
            eprintln!("UNSOLVED ({}): {gs}", stats.score);
        }
    }
    if total > 0 {
        let pct = solved * 100 / total;
        eprintln!("tactical suite: {solved}/{total} ({pct}%)");
        assert!(pct >= 90, "tactical suite regression: {solved}/{total}");
    }
}
