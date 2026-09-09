//! H3 task 4 (plan ch. 5): terminal values are correct for the player
//! considered, from both colours' perspectives. The searcher must score a
//! mate-in-1 position at/above the mate threshold for the MOVER — whether
//! the mover is White or Black — and the mating move must actually end the
//! game with the mover winning.
//!
//! Positions are the hand-annotated tactical cases T001/T002
//! (tests/tactical_positions/cases/, derived from the rules, never from
//! this searcher).

use hive_core::game::Game;
use hive_core::state::GameResult;
use hive_eval::WIN_THRESHOLD;
use hive_search::{AlphaBeta, SearchParams};
use hive_uhp::server::SearchLimit;

/// T001: white to move, black queen at 5/6 — White mates in 1.
const T001: &[&str] = &[
    "wS1", "bS1 wS1-", "wQ -wS1", "bQ bS1-", "wG1 -wQ", "bG1 bQ-",
    "wA1 -wG1", "bG2 bQ/", "wA2 -wA1", "bB1 \\bQ", "wA3 -wA2", "bA1 bS1\\",
];

/// T002: black to move, white queen at 5/6 — Black mates in 1.
const T002: &[&str] = &[
    "wS1", "bS1 -wS1", "wQ wS1-", "bQ -bS1", "wG1 wQ-", "bG1 -bQ",
    "wG2 wQ/", "bG2 -bG1", "wB1 \\wQ", "bA1 -bG2", "wA1 wS1\\", "bA2 -bA1",
    "wA2 wG1-",
];

fn build(moves: &[&str]) -> Game {
    let mut g = Game::new(hive_core::bug::GameType::BASE);
    for m in moves {
        g.play_uhp(m).unwrap_or_else(|e| panic!("setup {m}: {e}"));
    }
    g
}

fn assert_mate_found(moves: &[&str], winner: GameResult) {
    let mut g = build(moves);
    let mut ab = AlphaBeta::new(SearchParams {
        threads: 1,
        tt_log2: 18,
        ..Default::default()
    });
    let (mv, stats) = ab.search(&g, SearchLimit::Depth(2));
    assert!(
        stats.score >= WIN_THRESHOLD,
        "mover must see the mate as a positive mate-like score, got {}",
        stats.score
    );
    g.play(mv).expect("searcher move must be legal");
    assert_eq!(
        g.state.result, winner,
        "playing the searcher's move must end the game for the mover"
    );
}

#[test]
fn white_mate_in_one_scores_positive_for_white() {
    assert_mate_found(T001, GameResult::WhiteWins);
}

#[test]
fn black_mate_in_one_scores_positive_for_black() {
    assert_mate_found(T002, GameResult::BlackWins);
}
