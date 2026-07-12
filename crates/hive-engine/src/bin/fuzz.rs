//! Differential fuzzer: play random games and, after every ply, require that
//! our valid-move set exactly equals a reference UHP engine's (semantically:
//! MoveStrings are parsed into (piece, destination) moves with our own
//! parser, so formatting choices don't matter). Also cross-checks the
//! GameStateString after every move.
//!
//! Usage: fuzz <engine-cmd> [engine-args...] -- [games-per-type] [seed]
//! e.g.   fuzz ./opponents/MzingaEngine -- 50 42
//!        fuzz ./opponents/nokamute uhp -- 50 42

use hive_core::bug::GameType;
use hive_core::game::Game;
use hive_core::notation::{move_from_uhp, move_to_uhp};
use hive_core::state::Move;
use hive_core::zobrist::splitmix64;
use hive_uhp::client::UhpClient;
use std::collections::BTreeSet;
use std::process::exit;

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let split = args.iter().position(|a| a == "--").unwrap_or(args.len());
    let (cmd, rest) = args.split_at(split);
    let rest: Vec<&str> = rest.iter().skip(1).map(|s| s.as_str()).collect();
    if cmd.is_empty() {
        eprintln!("usage: fuzz <engine-cmd> [args...] -- [games-per-type] [seed]");
        exit(2);
    }
    let games_per_type: u32 = rest.first().and_then(|s| s.parse().ok()).unwrap_or(25);
    let seed: u64 = rest.get(1).and_then(|s| s.parse().ok()).unwrap_or(0xFEED);

    let prog = &cmd[0];
    let prog_args: Vec<&str> = cmd[1..].iter().map(|s| s.as_str()).collect();
    let mut engine = UhpClient::spawn(prog, &prog_args).expect("spawn reference engine");
    println!(
        "reference: {}",
        engine.startup.first().cloned().unwrap_or_default()
    );

    let mut positions_checked = 0u64;
    let mut rng = seed;

    for gt in GameType::ALL {
        let gt_name = gt.to_uhp();
        for g in 0..games_per_type {
            let mut game = Game::new(gt);
            engine
                .command(&format!("newgame {gt_name}"))
                .expect("newgame");
            let mut ply = 0;
            loop {
                // 1. Compare valid move sets (semantic).
                let ours: BTreeSet<Move> = game.valid_moves().iter().copied().collect();
                let theirs_raw = engine.valid_moves().expect("validmoves");
                let mut theirs: BTreeSet<Move> = BTreeSet::new();
                for s in &theirs_raw {
                    match move_from_uhp(&game.state, s) {
                        Ok(m) => {
                            theirs.insert(m);
                        }
                        Err(e) => {
                            fail(&game, &format!("cannot parse reference move '{s}': {e}"));
                        }
                    }
                }
                if game.state.result.is_over() {
                    // Mzinga replies `err` on validmoves when the game is
                    // over; our set is empty. Nothing to compare.
                    break;
                }
                if ours != theirs {
                    let missing: Vec<String> =
                        theirs.difference(&ours).map(|m| format!("{m:?}")).collect();
                    let extra: Vec<String> = ours
                        .difference(&theirs)
                        .map(|m| format!("{} ({m:?})", move_to_uhp(&game.state, *m)))
                        .collect();
                    fail(
                        &game,
                        &format!(
                            "validmoves diverge at ply {ply}\n  reference-only: {missing:?}\n  ours-only: {extra:?}\n  reference raw: {theirs_raw:?}"
                        ),
                    );
                }
                positions_checked += 1;
                if ply >= 150 {
                    break;
                }
                // 2. Play the same random move on both.
                rng = splitmix64(rng ^ game.state.hash());
                let mv = *game
                    .valid_moves()
                    .get((rng % ours.len() as u64) as usize)
                    .unwrap();
                let text = move_to_uhp(&game.state, mv);
                game.play(mv).expect("our own move must be legal");
                let reply = engine.command(&format!("play {text}")).expect("play");
                let first = reply.first().cloned().unwrap_or_default();
                if first.starts_with("invalidmove") || first.starts_with("err") {
                    fail(
                        &game,
                        &format!("reference rejected our move '{text}': {first}"),
                    );
                }
                // 3. Compare game state semantically: GameType, result and
                // turn. (Engines normalize MoveStrings differently in their
                // GameString echo, so the move list is not compared as text —
                // step 1's set comparison already validates semantics.)
                let ours_gs = game.game_string();
                let head =
                    |s: &str| -> String { s.split(';').take(3).collect::<Vec<_>>().join(";") };
                if head(&first) != head(&ours_gs) {
                    fail(
                        &game,
                        &format!(
                            "game state diverges after '{text}'\n  ours:   {ours_gs}\n  theirs: {first}"
                        ),
                    );
                }
                ply += 1;
            }
            if g % 10 == 0 {
                eprintln!("[{gt_name}] game {g}, {positions_checked} positions checked");
            }
        }
    }
    println!("PASS: {positions_checked} positions checked against reference");
}

fn fail(game: &Game, msg: &str) -> ! {
    eprintln!("FUZZ FAILURE: {msg}");
    eprintln!("GameString: {}", game.game_string());
    exit(1);
}
