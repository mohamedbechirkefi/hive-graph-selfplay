//! AlphaZero-style self-play generator: NN-guided MCTS games producing v2
//! records (visit-distribution policy targets).
//!
//! KataGo-style economies: playout-cap randomization (a fraction of moves
//! get full simulations and are recorded; the rest use cheap sims and are
//! not), Dirichlet root noise, temperature sampling for early moves, and
//! resignation with a no-resign audit fraction.
//!
//! Usage:
//!   selfplay-mcts --net models/hivenet-b32.onnx --games 2000 \
//!       --out data/rl/gen001 [--threads 8] [--sims-full 600] [--sims-cheap 150]
//!       [--full-frac 0.25] [--temp-plies 12] [--resign 0.92] [--no-resign-frac 0.1]
//!       [--gametype Base] [--seed 1] [--cpu]

use hive_core::bug::{Color, GameType};
use hive_core::game::Game;
use hive_core::state::{GameResult, Move};
use hive_core::zobrist::splitmix64;
use hive_mcts::{Mcts, MctsParams, OrtEvaluator};
use hive_nn::{RECORD_V2_SIZE, V2_MAGIC, encode_record_v2};
use hive_uhp::server::SearchLimit;
use std::io::Write;
use std::sync::atomic::{AtomicU64, Ordering};

struct Config {
    net: String,
    games: u64,
    threads: u32,
    sims_full: u32,
    sims_cheap: u32,
    full_frac: f64,
    temp_plies: u16,
    resign: f32,
    no_resign_frac: f64,
    game_type: GameType,
    seed: u64,
    out: String,
    coreml: bool,
}

fn parse_args() -> Config {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let mut cfg = Config {
        net: String::new(),
        games: 100,
        threads: 8,
        sims_full: 600,
        sims_cheap: 150,
        full_frac: 0.25,
        temp_plies: 12,
        resign: 0.92,
        no_resign_frac: 0.1,
        game_type: GameType::BASE,
        seed: 0xA1FA,
        out: "data/rl/gen".to_string(),
        coreml: true,
    };
    let mut it = args.iter();
    while let Some(a) = it.next() {
        match a.as_str() {
            "--net" => cfg.net = it.next().unwrap().clone(),
            "--games" => cfg.games = it.next().unwrap().parse().unwrap(),
            "--threads" => cfg.threads = it.next().unwrap().parse().unwrap(),
            "--sims-full" => cfg.sims_full = it.next().unwrap().parse().unwrap(),
            "--sims-cheap" => cfg.sims_cheap = it.next().unwrap().parse().unwrap(),
            "--full-frac" => cfg.full_frac = it.next().unwrap().parse().unwrap(),
            "--temp-plies" => cfg.temp_plies = it.next().unwrap().parse().unwrap(),
            "--resign" => cfg.resign = it.next().unwrap().parse().unwrap(),
            "--no-resign-frac" => cfg.no_resign_frac = it.next().unwrap().parse().unwrap(),
            "--gametype" => {
                cfg.game_type = GameType::from_uhp(it.next().unwrap()).expect("bad game type")
            }
            "--seed" => cfg.seed = it.next().unwrap().parse().unwrap(),
            "--out" => cfg.out = it.next().unwrap().clone(),
            "--cpu" => cfg.coreml = false,
            other => panic!("unknown arg {other}"),
        }
    }
    assert!(!cfg.net.is_empty(), "--net is required");
    cfg
}

/// Sample an index from visit counts with temperature 1 (proportional).
fn sample_visits(dist: &[(Move, u32)], rng: &mut u64) -> Move {
    let total: u64 = dist.iter().map(|&(_, n)| n as u64).sum();
    if total == 0 {
        return dist[0].0;
    }
    *rng = splitmix64(*rng);
    let mut t = *rng % total;
    for &(mv, n) in dist {
        if (n as u64) > t {
            return mv;
        }
        t -= n as u64;
    }
    dist.last().unwrap().0
}

#[allow(clippy::too_many_lines)]
fn main() {
    let cfg = parse_args();
    if let Some(dir) = std::path::Path::new(&cfg.out).parent() {
        std::fs::create_dir_all(dir).expect("create output dir");
    }
    let games_done = AtomicU64::new(0);
    let positions = AtomicU64::new(0);
    let resigns = AtomicU64::new(0);
    let start = std::time::Instant::now();

    std::thread::scope(|scope| {
        for t in 0..cfg.threads {
            let cfg = &cfg;
            let games_done = &games_done;
            let positions = &positions;
            let resigns = &resigns;
            scope.spawn(move || {
                let eval = OrtEvaluator::new(&cfg.net, cfg.coreml)
                    .unwrap_or_else(|e| panic!("load net: {e}"));
                let mut mcts = Mcts::new(
                    eval,
                    MctsParams {
                        dirichlet_eps: 0.25,
                        batch_size: 16,
                        seed: cfg.seed ^ (t as u64) << 48,
                        ..Default::default()
                    },
                );
                let shard_path = format!("{}-{:03}.bin", cfg.out, t);
                let mut out = std::io::BufWriter::new(
                    std::fs::File::create(&shard_path).expect("create shard"),
                );
                out.write_all(V2_MAGIC).unwrap();
                out.write_all(&[0u8; 8]).unwrap();

                loop {
                    let g = games_done.fetch_add(1, Ordering::Relaxed);
                    if g >= cfg.games {
                        break;
                    }
                    let mut rng = splitmix64(cfg.seed ^ (g + 1).wrapping_mul(0x9E3779B9));
                    let mut game = Game::new(cfg.game_type);
                    let allow_resign = {
                        rng = splitmix64(rng);
                        (rng as f64 / u64::MAX as f64) >= cfg.no_resign_frac
                    };
                    // (stm, state, played, dist) for recorded (full-sim) moves.
                    let mut recorded: Vec<(
                        Color,
                        hive_core::state::GameState,
                        Move,
                        Vec<(Move, u32)>,
                    )> = vec![];
                    let mut resigned: Option<Color> = None;

                    while !game.state.result.is_over() && game.move_count() < 300 {
                        rng = splitmix64(rng);
                        let full = (rng as f64 / u64::MAX as f64) < cfg.full_frac;
                        let sims = if full { cfg.sims_full } else { cfg.sims_cheap };
                        // SearchLimit::Depth(d) runs d * sims_per_depth sims;
                        // configure 1:1 via sims_per_depth.
                        mcts.params.sims_per_depth = sims;
                        let (best, dist, stats) =
                            mcts.search(&game, SearchLimit::Depth(1));

                        if allow_resign && stats.value < -cfg.resign {
                            resigned = Some(game.state.to_move);
                            resigns.fetch_add(1, Ordering::Relaxed);
                            break;
                        }

                        let mv = if game.state.ply < cfg.temp_plies {
                            sample_visits(&dist, &mut rng)
                        } else {
                            best
                        };
                        if full {
                            recorded.push((
                                game.state.to_move,
                                game.state.clone(),
                                mv,
                                dist.clone(),
                            ));
                        }
                        game.play(mv).expect("mcts must return legal moves");
                    }

                    let result = match resigned {
                        Some(Color::White) => GameResult::BlackWins,
                        Some(Color::Black) => GameResult::WhiteWins,
                        None if game.state.result.is_over() => game.state.result,
                        None => GameResult::Draw, // ply cap
                    };
                    for (stm, state, mv, dist) in &recorded {
                        let wdl = match result {
                            GameResult::WhiteWins => {
                                if *stm == Color::White { 2 } else { 0 }
                            }
                            GameResult::BlackWins => {
                                if *stm == Color::Black { 2 } else { 0 }
                            }
                            _ => 1,
                        };
                        let rec: [u8; RECORD_V2_SIZE] =
                            encode_record_v2(state, *mv, wdl, dist);
                        out.write_all(&rec).unwrap();
                    }
                    positions.fetch_add(recorded.len() as u64, Ordering::Relaxed);
                    if g % 20 == 0 {
                        eprintln!(
                            "game {g}/{}: {result:?} in {} plies | {} recorded positions | {:.1} games/min",
                            cfg.games,
                            game.move_count(),
                            positions.load(Ordering::Relaxed),
                            (g + 1) as f64 / start.elapsed().as_secs_f64() * 60.0,
                        );
                    }
                }
                out.flush().unwrap();
            });
        }
    });

    println!(
        "done: {} games ({} resigned), {} recorded positions, {:.0}s -> {}-*.bin",
        cfg.games,
        resigns.load(Ordering::Relaxed),
        positions.load(Ordering::Relaxed),
        start.elapsed().as_secs_f64(),
        cfg.out
    );
}
