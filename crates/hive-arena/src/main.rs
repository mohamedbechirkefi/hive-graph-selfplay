//! UHP-vs-UHP match runner.
//!
//! Plays paired games (same random opening, colors swapped) between two UHP
//! engines, refereed by our own rules core: every bestmove reply is validated
//! against hive-core's move generation, results are adjudicated from the
//! game state (plus a ply cap), and a W/D/L + Elo summary is printed.
//!
//! Usage:
//!   hive-arena [--games N] [--movetime SECS | --depth D] [--gametype GT]
//!              [--openings PLIES] [--seed S] [--threads T] [--pgn FILE]
//!              -- <engine A cmd...> -- <engine B cmd...>

use hive_core::bug::GameType;
use hive_core::game::Game;
use hive_core::state::GameResult;
use hive_core::zobrist::splitmix64;
use hive_uhp::client::UhpClient;
use std::io::Write as _;
use std::sync::Mutex;
use std::sync::atomic::{AtomicUsize, Ordering};

#[derive(Clone)]
struct Config {
    games: u32,
    movetime: u64,
    depth: Option<u32>,
    game_type: GameType,
    opening_plies: u32,
    seed: u64,
    threads: u32,
    pgn: Option<String>,
    engine_a: Vec<String>,
    engine_b: Vec<String>,
}

fn parse_args() -> Config {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let mut cfg = Config {
        games: 20,
        movetime: 1,
        depth: None,
        game_type: GameType::BASE,
        opening_plies: 4,
        seed: 0xA1FA,
        threads: 4,
        pgn: None,
        engine_a: vec![],
        engine_b: vec![],
    };
    let mut it = args.iter().peekable();
    let mut engines: Vec<Vec<String>> = vec![];
    while let Some(a) = it.next() {
        match a.as_str() {
            "--games" => cfg.games = it.next().unwrap().parse().unwrap(),
            "--movetime" => cfg.movetime = it.next().unwrap().parse().unwrap(),
            "--depth" => cfg.depth = Some(it.next().unwrap().parse().unwrap()),
            "--gametype" => {
                cfg.game_type = GameType::from_uhp(it.next().unwrap()).expect("bad game type")
            }
            "--openings" => cfg.opening_plies = it.next().unwrap().parse().unwrap(),
            "--seed" => cfg.seed = it.next().unwrap().parse().unwrap(),
            "--threads" => cfg.threads = it.next().unwrap().parse().unwrap(),
            "--pgn" => cfg.pgn = Some(it.next().unwrap().clone()),
            "--" => {
                let mut cmd = vec![];
                while let Some(x) = it.peek() {
                    if x.as_str() == "--" {
                        break;
                    }
                    cmd.push(it.next().unwrap().clone());
                }
                engines.push(cmd);
            }
            other => panic!("unknown arg {other}"),
        }
    }
    assert_eq!(engines.len(), 2, "need two engine commands separated by --");
    cfg.engine_a = engines[0].clone();
    cfg.engine_b = engines[1].clone();
    cfg
}

/// Generate a legal random opening of `plies` moves as MoveStrings.
fn random_opening(gt: GameType, plies: u32, seed: u64) -> Vec<String> {
    let mut game = Game::new(gt);
    let mut rng = seed;
    let mut out = vec![];
    for _ in 0..plies {
        let moves = game.valid_moves();
        rng = splitmix64(rng ^ game.state.hash());
        let mv = moves[(rng % moves.len() as u64) as usize];
        out.push(hive_core::notation::move_to_uhp(&game.state, mv));
        game.play(mv).unwrap();
        if game.state.result.is_over() {
            break;
        }
    }
    out
}

/// Result of one game from engine A's perspective: 1.0 / 0.5 / 0.0.
struct GameOutcome {
    score_a: f64,
    plies: usize,
    reason: String,
    game_string: String,
}

fn play_game(cfg: &Config, a_is_white: bool, opening: &[String]) -> Result<GameOutcome, String> {
    let spawn = |cmd: &[String]| -> Result<UhpClient, String> {
        let args: Vec<&str> = cmd[1..].iter().map(|s| s.as_str()).collect();
        UhpClient::spawn(&cmd[0], &args).map_err(|e| format!("spawn {}: {e}", cmd[0]))
    };
    let mut white = spawn(if a_is_white {
        &cfg.engine_a
    } else {
        &cfg.engine_b
    })?;
    let mut black = spawn(if a_is_white {
        &cfg.engine_b
    } else {
        &cfg.engine_a
    })?;

    let mut referee = Game::new(cfg.game_type);
    let gt = cfg.game_type.to_uhp();
    white
        .command(&format!("newgame {gt}"))
        .map_err(|e| e.to_string())?;
    black
        .command(&format!("newgame {gt}"))
        .map_err(|e| e.to_string())?;
    for text in opening {
        referee
            .play_uhp(text)
            .map_err(|e| format!("bad opening: {e}"))?;
        white
            .command(&format!("play {text}"))
            .map_err(|e| e.to_string())?;
        black
            .command(&format!("play {text}"))
            .map_err(|e| e.to_string())?;
    }

    let bestmove_cmd = match cfg.depth {
        Some(d) => format!("bestmove depth {d}"),
        None => {
            let t = cfg.movetime;
            format!(
                "bestmove time {:02}:{:02}:{:02}",
                t / 3600,
                (t % 3600) / 60,
                t % 60
            )
        }
    };

    let max_plies = 300;
    loop {
        if referee.state.result.is_over() {
            break;
        }
        if referee.move_count() >= max_plies {
            return Ok(GameOutcome {
                score_a: 0.5,
                plies: referee.move_count(),
                reason: "ply-cap draw".into(),
                game_string: referee.game_string(),
            });
        }
        let white_to_move = referee.state.to_move == hive_core::bug::Color::White;
        let mover = if white_to_move {
            &mut white
        } else {
            &mut black
        };
        let reply = mover.command(&bestmove_cmd).map_err(|e| e.to_string())?;
        let mv_text = reply
            .first()
            .cloned()
            .ok_or_else(|| "empty bestmove reply".to_string())?;
        if mv_text.starts_with("err") {
            return Err(format!("engine error: {mv_text}"));
        }
        // Referee validates; an illegal reply forfeits the game.
        if let Err(e) = referee.play_uhp(&mv_text) {
            let loser_is_a = white_to_move == a_is_white;
            return Ok(GameOutcome {
                score_a: if loser_is_a { 0.0 } else { 1.0 },
                plies: referee.move_count(),
                reason: format!("illegal move '{mv_text}' ({e}) — forfeit"),
                game_string: referee.game_string(),
            });
        }
        white
            .command(&format!("play {mv_text}"))
            .map_err(|e| e.to_string())?;
        black
            .command(&format!("play {mv_text}"))
            .map_err(|e| e.to_string())?;
    }

    let score_a = match referee.state.result {
        GameResult::WhiteWins => {
            if a_is_white {
                1.0
            } else {
                0.0
            }
        }
        GameResult::BlackWins => {
            if a_is_white {
                0.0
            } else {
                1.0
            }
        }
        _ => 0.5,
    };
    Ok(GameOutcome {
        score_a,
        plies: referee.move_count(),
        reason: format!("{:?}", referee.state.result),
        game_string: referee.game_string(),
    })
}

fn elo_diff(p: f64) -> f64 {
    -400.0 * ((1.0 / p.clamp(1e-6, 1.0 - 1e-6)) - 1.0).log10()
}

fn main() {
    let cfg = parse_args();
    println!(
        "arena: {} games, {} vs {}, type {}, {} opening plies, {}",
        cfg.games,
        cfg.engine_a.join(" "),
        cfg.engine_b.join(" "),
        cfg.game_type.to_uhp(),
        cfg.opening_plies,
        match cfg.depth {
            Some(d) => format!("depth {d}"),
            None => format!("movetime {}s", cfg.movetime),
        }
    );

    let pairs = cfg.games.div_ceil(2);
    let next_pair = AtomicUsize::new(0);
    let results: Mutex<Vec<(f64, usize, String)>> = Mutex::new(vec![]);
    let pgn_log: Mutex<Vec<String>> = Mutex::new(vec![]);

    std::thread::scope(|scope| {
        for _ in 0..cfg.threads {
            scope.spawn(|| {
                loop {
                    let pair = next_pair.fetch_add(1, Ordering::Relaxed);
                    if pair >= pairs as usize {
                        break;
                    }
                    let opening = random_opening(
                        cfg.game_type,
                        cfg.opening_plies,
                        splitmix64(cfg.seed ^ (pair as u64) << 20),
                    );
                    for a_is_white in [true, false] {
                        match play_game(&cfg, a_is_white, &opening) {
                            Ok(o) => {
                                let mut r = results.lock().unwrap();
                                r.push((o.score_a, o.plies, o.reason.clone()));
                                let n = r.len();
                                let sum: f64 = r.iter().map(|(s, _, _)| s).sum();
                                drop(r);
                                eprintln!(
                                    "game {n}: A[{}] {} in {} plies ({}) | A score {:.1}/{}",
                                    if a_is_white { "W" } else { "B" },
                                    o.score_a,
                                    o.plies,
                                    o.reason,
                                    sum,
                                    n
                                );
                                pgn_log.lock().unwrap().push(o.game_string);
                            }
                            Err(e) => eprintln!("game error (skipped): {e}"),
                        }
                    }
                }
            });
        }
    });

    let results = results.into_inner().unwrap();
    let n = results.len() as f64;
    if n == 0.0 {
        eprintln!("no games completed");
        return;
    }
    let wins = results.iter().filter(|(s, _, _)| *s == 1.0).count();
    let draws = results.iter().filter(|(s, _, _)| *s == 0.5).count();
    let losses = results.len() - wins - draws;
    let p = results.iter().map(|(s, _, _)| s).sum::<f64>() / n;
    // 95% CI on the score via normal approximation.
    let var: f64 = results
        .iter()
        .map(|(s, _, _)| (s - p) * (s - p))
        .sum::<f64>()
        / n;
    let se = (var / n).sqrt();
    println!(
        "\n=== A vs B: +{wins} ={draws} -{losses}  score {:.1}%",
        p * 100.0
    );
    println!(
        "Elo diff: {:+.0} [{:+.0}, {:+.0}] (95%)",
        elo_diff(p),
        elo_diff((p - 1.96 * se).max(0.001)),
        elo_diff((p + 1.96 * se).min(0.999))
    );

    if let Some(path) = &cfg.pgn {
        let mut f = std::fs::File::create(path).expect("create pgn file");
        for gs in pgn_log.into_inner().unwrap() {
            writeln!(f, "{gs}").unwrap();
        }
        println!("game records written to {path}");
    }
}
