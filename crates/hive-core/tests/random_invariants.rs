//! Seeded random-game invariant sessions (H2 task 5, plan ch. 4).
//!
//! Walks seeded pseudo-random games in every game type and checks, after
//! every transition:
//!   1. apply accepts every generated move (play + undo over the full move
//!      list — "no generator move rejected by apply"), and undo restores
//!      the exact GameString;
//!   2. one-hive connectivity: the occupied cells always form one hive;
//!   3. serialise -> deserialise: rebuilding the game from its GameString
//!      reproduces the GameString (turn + result included) and the exact
//!      valid-move set;
//!   4. a position with no legal moves accepts "pass" while in progress.
//!
//! On failure the panic message carries (game type, seed, game, ply) and
//! the GameString — archive any such case as a permanent regression test.

use hive_core::hex::{ALL_DIRS, neighbor};
use hive_core::notation::move_to_uhp;
use hive_core::state::Move;
use hive_core::zobrist::splitmix64;
use hive_core::{Board, Game, GameType};

fn hive_connected(board: &Board) -> bool {
    let cells: Vec<_> = {
        let mut v: Vec<_> = board
            .pieces_on_board()
            .map(|p| board.loc(p).cell)
            .collect();
        v.sort();
        v.dedup();
        v
    };
    let Some(&start) = cells.first() else {
        return true;
    };
    let mut seen = vec![start];
    let mut stack = vec![start];
    while let Some(c) = stack.pop() {
        for d in ALL_DIRS {
            let n = neighbor(c, d);
            if cells.contains(&n) && !seen.contains(&n) {
                seen.push(n);
                stack.push(n);
            }
        }
    }
    seen.len() == cells.len()
}

fn uhp_move_set(g: &Game) -> Vec<String> {
    let mut v: Vec<String> = g
        .valid_moves()
        .iter()
        .map(|&m| move_to_uhp(&g.state, m))
        .collect();
    v.sort();
    v
}

fn run_session(gt: GameType, games: u32, max_plies: u32, base_seed: u64) -> (u64, u64) {
    let mut seed = base_seed ^ ((gt.to_uhp().len() as u64) << 40);
    let (mut plies_played, mut moves_checked) = (0u64, 0u64);
    for game_idx in 0..games {
        let mut g = Game::new(gt);
        for ply in 0..max_plies {
            if g.state.result.is_over() {
                break;
            }
            let before = g.game_string();
            let ctx = format!(
                "gt={} seed={base_seed:#x} game={game_idx} ply={ply} gs='{before}'",
                gt.to_uhp()
            );
            let ctx = || ctx.clone();
            let moves = g.valid_moves();

            // 1. apply accepts every generated move; undo restores the state.
            for &m in moves.iter() {
                g.play(m)
                    .unwrap_or_else(|e| panic!("apply rejected generated move: {e} [{}]", ctx()));
                assert!(
                    hive_connected(&g.state.board),
                    "one-hive violated after {m:?} [{}]",
                    ctx()
                );
                g.undo(1).unwrap_or_else(|e| panic!("undo failed: {e} [{}]", ctx()));
                moves_checked += 1;
            }
            assert_eq!(g.game_string(), before, "undo did not restore [{}]", ctx());

            // 3. serialise -> deserialise preserves position, result, moves.
            let rebuilt = Game::from_uhp(&before)
                .unwrap_or_else(|e| panic!("GameString rejected on reload: {e} [{}]", ctx()));
            assert_eq!(rebuilt.game_string(), before, "GameString drift [{}]", ctx());
            assert_eq!(
                uhp_move_set(&rebuilt),
                uhp_move_set(&g),
                "valid-move set drift after reload [{}]",
                ctx()
            );

            // Advance: random move, or pass when none exists (4.).
            if moves.is_empty() {
                g.play(Move::Pass)
                    .unwrap_or_else(|e| panic!("pass rejected with no moves: {e} [{}]", ctx()));
            } else {
                seed = splitmix64(seed);
                let m = moves[(seed % moves.len() as u64) as usize];
                g.play(m).unwrap();
            }
            assert!(hive_connected(&g.state.board), "one-hive violated [{}]", ctx());
            plies_played += 1;
        }
    }
    (plies_played, moves_checked)
}

#[test]
fn random_invariant_sessions() {
    let mut totals = (0u64, 0u64);
    for gt in GameType::ALL {
        let (p, m) = run_session(gt, 4, 150, 0x2026_0909);
        totals.0 += p;
        totals.1 += m;
    }
    println!(
        "random invariants: {} plies, {} generated moves applied+undone, 0 violations",
        totals.0, totals.1
    );
}

/// Deep session for nightly.sh: `cargo test --release -p hive-core \
/// --test random_invariants -- --ignored`.
#[test]
#[ignore]
fn random_invariant_sessions_deep() {
    let mut totals = (0u64, 0u64);
    for gt in GameType::ALL {
        for round in 0u64..3 {
            let (p, m) = run_session(gt, 20, 400, 0x2026_0909 + round);
            totals.0 += p;
            totals.1 += m;
        }
    }
    println!(
        "deep random invariants: {} plies, {} generated moves applied+undone, 0 violations",
        totals.0, totals.1
    );
}
