//! Supervised-bootstrap data generator: alpha-beta self-play games recorded
//! as compact training records (see hive-nn docs for the format).
//!
//! Games start with random opening plies for diversity; positions from the
//! opening phase are NOT recorded (their moves are random, not teacher
//! moves). Policy target = the searcher's move, value target = final game
//! outcome from the side-to-move's perspective.
//!
//! Usage:
//!   selfplay --games 1000 --movetime-ms 100 --out data/selfplay/run1 \
//!            [--gametype Base+MLP] [--threads 12] [--seed 7] [--openings 6]

use hive_core::bug::GameType;
use hive_core::game::Game;
use hive_core::state::GameResult;
use hive_core::zobrist::splitmix64;
use hive_nn::{RECORD_SIZE, encode_record, wdl_from_result};
use hive_search::{AlphaBeta, SearchParams};
use hive_uhp::server::SearchLimit;
use std::io::Write;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Duration;

struct Config {
    games: u64,
    movetime: Duration,
    depth: Option<u32>,
    game_type: GameType,
    threads: u32,
    seed: u64,
    openings: u32,
    out: String,
}

fn parse_args() -> Config {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let mut cfg = Config {
        games: 100,
        movetime: Duration::from_millis(100),
        depth: None,
        game_type: GameType::BASE,
        threads: 10,
        seed: 0x5EED,
        openings: 6,
        out: "data/selfplay/run".to_string(),
    };
    let mut it = args.iter();
    while let Some(a) = it.next() {
        match a.as_str() {
            "--games" => cfg.games = it.next().unwrap().parse().unwrap(),
            "--movetime-ms" => {
                cfg.movetime = Duration::from_millis(it.next().unwrap().parse().unwrap())
            }
            "--depth" => cfg.depth = Some(it.next().unwrap().parse().unwrap()),
            "--gametype" => {
                cfg.game_type = GameType::from_uhp(it.next().unwrap()).expect("bad game type")
            }
            "--threads" => cfg.threads = it.next().unwrap().parse().unwrap(),
            "--seed" => cfg.seed = it.next().unwrap().parse().unwrap(),
            "--openings" => cfg.openings = it.next().unwrap().parse().unwrap(),
            "--out" => cfg.out = it.next().unwrap().clone(),
            other => panic!("unknown arg {other}"),
        }
    }
    cfg
}

fn play_one_game(cfg: &Config, seed: u64, ab: &mut AlphaBeta) -> (Vec<[u8; RECORD_SIZE]>, GameResult, usize, bool) {
    let mut game = Game::new(cfg.game_type);
    let mut rng = seed;
    for _ in 0..cfg.openings {
        if game.state.result.is_over() {
            break;
        }
        let moves = game.valid_moves();
        rng = splitmix64(rng ^ game.state.hash());
        game.play(moves[(rng % moves.len() as u64) as usize]).unwrap();
    }
    let limit = match cfg.depth {
        Some(d) => SearchLimit::Depth(d),
        None => SearchLimit::Time(cfg.movetime),
    };
    // (state snapshot side-to-move, record without wdl) pairs, filled in
    // after the outcome is known.
    let mut pending: Vec<(hive_core::bug::Color, hive_core::state::GameState, hive_core::state::Move)> = vec![];
    while !game.state.result.is_over() && game.move_count() < 300 {
        let (mv, _) = ab.search(&game, limit);
        pending.push((game.state.to_move, game.state.clone(), mv));
        game.play(mv).expect("searcher must return legal moves");
    }
    // Ply-cap games are truncated, not drawn (invariant 7 / D-008):
    // their records carry WDL = 3.
    let truncated = game.move_count() >= 300 && !game.state.result.is_over();
    let result = game.state.result;
    let records = pending
        .into_iter()
        .map(|(stm, state, mv)| {
            encode_record(&state, mv, wdl_from_result(result, stm, truncated))
        })
        .collect();
    (records, result, game.move_count(), truncated)
}

fn main() {
    let cfg = parse_args();
    if let Some(dir) = std::path::Path::new(&cfg.out).parent() {
        std::fs::create_dir_all(dir).expect("create output dir");
    }
    let games_done = AtomicU64::new(0);
    let positions = AtomicU64::new(0);
    let wins = [AtomicU64::new(0), AtomicU64::new(0), AtomicU64::new(0), AtomicU64::new(0)]; // W/D/B/Truncated
    let start = std::time::Instant::now();

    std::thread::scope(|scope| {
        for t in 0..cfg.threads {
            let cfg = &cfg;
            let games_done = &games_done;
            let positions = &positions;
            let wins = &wins;
            scope.spawn(move || {
                let shard_path = format!("{}-{:03}.bin", cfg.out, t);
                let mut out = std::io::BufWriter::new(
                    std::fs::File::create(&shard_path).expect("create shard"),
                );
                let mut ab = AlphaBeta::new(SearchParams {
                    threads: 1,
                    tt_log2: 20,
                    ..Default::default()
                });
                loop {
                    let g = games_done.fetch_add(1, Ordering::Relaxed);
                    if g >= cfg.games {
                        break;
                    }
                    let seed = splitmix64(cfg.seed ^ (g + 1).wrapping_mul(0x9E3779B9));
                    let (records, result, plies, truncated) = play_one_game(cfg, seed, &mut ab);
                    for r in &records {
                        out.write_all(r).expect("write record");
                    }
                    positions.fetch_add(records.len() as u64, Ordering::Relaxed);
                    let wi = if truncated {
                        3
                    } else {
                        match result {
                            GameResult::WhiteWins => 0,
                            GameResult::Draw => 1,
                            _ => 2,
                        }
                    };
                    wins[wi].fetch_add(1, Ordering::Relaxed);
                    if g % 50 == 0 {
                        let n = positions.load(Ordering::Relaxed);
                        eprintln!(
                            "game {g}/{}: {plies} plies {} | {n} positions | {:.1} games/min",
                            cfg.games,
                            if truncated { "Truncated".to_string() } else { format!("{result:?}") },
                            (g + 1) as f64 / start.elapsed().as_secs_f64() * 60.0
                        );
                    }
                }
                out.flush().unwrap();
            });
        }
    });

    println!(
        "done: {} games ({} W / {} D / {} B / {} truncated), {} positions, {:.0}s -> shards {}-*.bin",
        cfg.games,
        wins[0].load(Ordering::Relaxed),
        wins[1].load(Ordering::Relaxed),
        wins[2].load(Ordering::Relaxed),
        wins[3].load(Ordering::Relaxed),
        positions.load(Ordering::Relaxed),
        start.elapsed().as_secs_f64(),
        cfg.out
    );
}
