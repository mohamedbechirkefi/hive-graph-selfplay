//! Tactical-suite miner: fast engine self-play from random openings; the
//! first position of each game where a fixed-depth search proves a forced
//! win is recorded as `GameString|expected-winner`. These fixtures become
//! the tactical regression suite (search must keep solving them).
//!
//! Usage: mine [count] [depth] [seed] [gametype]   (defaults: 50 5 1 Base)

use hive_core::bug::{Color, GameType};
use hive_core::game::Game;
use hive_core::zobrist::splitmix64;
use hive_eval::WIN_THRESHOLD;
use hive_search::{AlphaBeta, SearchParams};
use hive_uhp::server::SearchLimit;

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let want: usize = args.first().and_then(|s| s.parse().ok()).unwrap_or(50);
    let depth: u32 = args.get(1).and_then(|s| s.parse().ok()).unwrap_or(5);
    let seed0: u64 = args.get(2).and_then(|s| s.parse().ok()).unwrap_or(1);
    let gt = args
        .get(3)
        .map(|s| GameType::from_uhp(s).expect("bad game type"))
        .unwrap_or(GameType::BASE);

    let params = SearchParams {
        threads: 1,
        tt_log2: 20,
        ..Default::default()
    };
    let mut found = 0usize;
    let mut game_no = 0u64;
    while found < want {
        game_no += 1;
        let mut rng = splitmix64(seed0 ^ game_no.wrapping_mul(0x9E37));
        let mut game = Game::new(gt);
        // Random opening for diversity.
        for _ in 0..6 {
            let moves = game.valid_moves();
            rng = splitmix64(rng ^ game.state.hash());
            game.play(moves[(rng % moves.len() as u64) as usize])
                .unwrap();
        }
        let mut ab = AlphaBeta::new(SearchParams {
            threads: 1,
            tt_log2: 20,
            ..Default::default()
        });
        let _ = &params;
        let mut recorded = false;
        while !game.state.result.is_over() && game.move_count() < 120 {
            let (mv, stats) = ab.search(&game, SearchLimit::Depth(depth));
            if !recorded && stats.score >= WIN_THRESHOLD {
                let winner = match game.state.to_move {
                    Color::White => "WhiteWins",
                    Color::Black => "BlackWins",
                };
                println!("{}|{}", game.game_string(), winner);
                found += 1;
                recorded = true; // one fixture per game, keep positions diverse
            }
            game.play(mv).unwrap();
        }
        eprintln!(
            "game {game_no}: {} plies, {:?} — {found}/{want} fixtures",
            game.move_count(),
            game.state.result
        );
    }
}
