//! H3 task 4 (plan ch. 5): MCTS root values keep the side-to-move
//! perspective under player alternation — a winning MOVER sees a strongly
//! positive root value whether the mover is White or Black.
//!
//! Positions are the hand-annotated tactical cases T001/T002
//! (tests/tactical_positions/cases/, derived from the rules, never from
//! the search under test).

use hive_core::game::Game;
use hive_core::state::GameResult;
use hive_mcts::{EvalNet, Mcts, MctsParams};
use hive_uhp::server::SearchLimit;

const T001: &[&str] = &[
    "wS1", "bS1 wS1-", "wQ -wS1", "bQ bS1-", "wG1 -wQ", "bG1 bQ-",
    "wA1 -wG1", "bG2 bQ/", "wA2 -wA1", "bB1 \\bQ", "wA3 -wA2", "bA1 bS1\\",
];

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

fn assert_winning_mover_value(moves: &[&str], winner: GameResult) {
    let mut g = build(moves);
    let mut mcts = Mcts::new(
        EvalNet::default(),
        MctsParams {
            sims_per_depth: 3200,
            seed: 1,
            ..Default::default()
        },
    );
    let (mv, _dist, stats) = mcts.search(&g, SearchLimit::Depth(1));
    assert!(
        stats.value > 0.5,
        "winning mover's root value must be strongly positive, got {}",
        stats.value
    );
    g.play(mv).expect("searcher move must be legal");
    assert_eq!(
        g.state.result, winner,
        "playing the MCTS move must end the game for the mover"
    );
}

#[test]
fn white_mover_sees_positive_value_on_win_in_one() {
    assert_winning_mover_value(T001, GameResult::WhiteWins);
}

#[test]
fn black_mover_sees_positive_value_on_win_in_one() {
    assert_winning_mover_value(T002, GameResult::BlackWins);
}

/// H4 check 6: the evaluation code path applies no exploration noise —
/// MctsParams::default() (what match play / bestmove uses) has Dirichlet
/// noise off, and eval settings are pinned in configs/eval-settings.toml
/// (D-019). Self-play opts in explicitly (selfplay_mcts sets 0.25).
#[test]
fn eval_defaults_carry_no_exploration_noise() {
    let p = MctsParams::default();
    assert_eq!(
        p.dirichlet_eps, 0.0,
        "match-play/eval default must have no Dirichlet noise"
    );
}
