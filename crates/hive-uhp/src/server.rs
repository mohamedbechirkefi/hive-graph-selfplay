//! UHP engine-side server loop, generic over the search backend.

use hive_core::game::Game;
use hive_core::notation::move_to_uhp;
use hive_core::state::Move;
use std::io::{BufRead, Write};
use std::time::Duration;

#[derive(Copy, Clone, Debug)]
pub enum SearchLimit {
    Depth(u32),
    Time(Duration),
    /// Neither given: engine's own discretion.
    Default,
}

/// A search backend: given a game, produce the best move. Implementations
/// live in hive-search / hive-mcts; hive-uhp stays algorithm-agnostic.
pub trait Searcher {
    fn best_move(&mut self, game: &Game, limit: SearchLimit) -> Move;

    /// Engine identifier for the `info` line.
    fn name(&self) -> String {
        "HiveMind v0.1.0".to_string()
    }
}

fn parse_time(s: &str) -> Option<Duration> {
    // hh:mm:ss
    let parts: Vec<&str> = s.split(':').collect();
    if parts.len() != 3 {
        return None;
    }
    let h: u64 = parts[0].parse().ok()?;
    let m: u64 = parts[1].parse().ok()?;
    let sec: u64 = parts[2].parse().ok()?;
    Some(Duration::from_secs(h * 3600 + m * 60 + sec))
}

/// Run the UHP loop until EOF or `exit`. Generic over I/O for testability.
pub fn run_server<R: BufRead, W: Write>(
    input: R,
    mut out: W,
    searcher: &mut dyn Searcher,
) -> std::io::Result<()> {
    let mut game: Option<Game> = None;

    let info = |out: &mut W, searcher: &dyn Searcher| -> std::io::Result<()> {
        writeln!(out, "id {}", searcher.name())?;
        writeln!(out, "Mosquito;Ladybug;Pillbug")?;
        Ok(())
    };

    // UHP engines announce themselves on startup.
    info(&mut out, searcher)?;
    writeln!(out, "ok")?;
    out.flush()?;

    for line in input.lines() {
        let line = line?;
        let line = line.trim();
        if line.is_empty() {
            continue;
        }
        let (cmd, args) = match line.split_once(' ') {
            Some((c, a)) => (c, a.trim()),
            None => (line, ""),
        };

        match cmd {
            "exit" => {
                writeln!(out, "ok")?;
                out.flush()?;
                break;
            }
            "info" => info(&mut out, searcher)?,
            "options" => { /* no options yet: empty response */ }
            "newgame" => match Game::from_uhp(args) {
                Ok(g) => {
                    writeln!(out, "{}", g.game_string())?;
                    game = Some(g);
                }
                Err(e) => writeln!(out, "err {e}")?,
            },
            "play" | "pass" => {
                let text = if cmd == "pass" { "pass" } else { args };
                match game.as_mut() {
                    None => writeln!(out, "err no game in progress; use newgame")?,
                    Some(g) => match g.play_uhp(text) {
                        Ok(()) => writeln!(out, "{}", g.game_string())?,
                        Err(e) => writeln!(out, "invalidmove {e}")?,
                    },
                }
            }
            "validmoves" => match game.as_ref() {
                None => writeln!(out, "err no game in progress; use newgame")?,
                Some(g) => {
                    let moves = g.valid_moves();
                    let strings: Vec<String> =
                        moves.iter().map(|&m| move_to_uhp(&g.state, m)).collect();
                    writeln!(out, "{}", strings.join(";"))?;
                }
            },
            "bestmove" => match game.as_ref() {
                None => writeln!(out, "err no game in progress; use newgame")?,
                Some(g) => {
                    if g.state.result.is_over() {
                        writeln!(out, "err game is over")?;
                    } else {
                        let limit = match args.split_once(' ') {
                            Some(("depth", d)) => d
                                .parse()
                                .map(SearchLimit::Depth)
                                .unwrap_or(SearchLimit::Default),
                            Some(("time", t)) => parse_time(t)
                                .map(SearchLimit::Time)
                                .unwrap_or(SearchLimit::Default),
                            _ => SearchLimit::Default,
                        };
                        let mv = searcher.best_move(g, limit);
                        writeln!(out, "{}", move_to_uhp(&g.state, mv))?;
                    }
                }
            },
            "undo" => {
                let n: usize = if args.is_empty() {
                    1
                } else {
                    args.parse().unwrap_or(0)
                };
                match game.as_mut() {
                    None => writeln!(out, "err no game in progress; use newgame")?,
                    Some(g) => match if n == 0 {
                        Err("bad undo count".to_string())
                    } else {
                        g.undo(n)
                    } {
                        Ok(()) => writeln!(out, "{}", g.game_string())?,
                        Err(e) => writeln!(out, "err {e}")?,
                    },
                }
            }
            other => writeln!(out, "err unknown command '{other}'")?,
        }
        writeln!(out, "ok")?;
        out.flush()?;
    }
    Ok(())
}

/// Uniform-over-legal-moves searcher. Deterministic given (seed, game
/// history): the internal state advances per query, mixed with the position
/// hash, so distinct seeds give distinct games while identical seeds replay
/// identically (H3 baseline requirement).
pub struct RandomSearcher {
    state: u64,
}

impl Default for RandomSearcher {
    fn default() -> Self {
        RandomSearcher::new(0)
    }
}

impl RandomSearcher {
    pub fn new(seed: u64) -> Self {
        RandomSearcher {
            state: hive_core::zobrist::splitmix64(seed),
        }
    }
}

impl Searcher for RandomSearcher {
    fn best_move(&mut self, game: &Game, _limit: SearchLimit) -> Move {
        let moves = game.valid_moves();
        self.state = hive_core::zobrist::splitmix64(self.state ^ game.state.hash());
        moves[(self.state % moves.len() as u64) as usize]
    }

    fn name(&self) -> String {
        "HiveMind v0.1.0-random".to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;

    fn run(script: &str) -> String {
        let mut out = Vec::new();
        let mut searcher = RandomSearcher::default();
        run_server(Cursor::new(script.to_string()), &mut out, &mut searcher).unwrap();
        String::from_utf8(out).unwrap()
    }

    #[test]
    fn info_and_newgame() {
        let out = run("info\nnewgame Base+MLP\nvalidmoves\nexit\n");
        assert!(out.starts_with("id HiveMind"));
        assert!(out.contains("Mosquito;Ladybug;Pillbug"));
        assert!(out.contains("Base+MLP;NotStarted;White[1]"));
        // 7 opening moves, semicolon-separated.
        let vm_line = out
            .lines()
            .find(|l| l.contains("wS1") && l.contains(';'))
            .expect("validmoves line");
        assert_eq!(vm_line.split(';').count(), 7);
        // Every response block ends with ok.
        assert!(out.trim_end().ends_with("ok"));
    }

    #[test]
    fn play_and_undo() {
        let out = run("newgame Base\nplay wS1\nplay bG1 wS1-\nundo 2\nexit\n");
        assert!(out.contains("Base;InProgress;Black[1];wS1"));
        assert!(out.contains("Base;InProgress;White[2];wS1;bG1 wS1-"));
        // After undo 2 we are back at the start.
        assert!(out.contains("Base;NotStarted;White[1]\n"));
    }

    #[test]
    fn invalid_move_reply() {
        let out = run("newgame Base\nplay wQ\nexit\n");
        assert!(out.contains("invalidmove"));
    }

    #[test]
    fn bestmove_returns_legal_move() {
        let out = run("newgame Base\nbestmove depth 1\nexit\n");
        // The reply line before "ok" must be a parsable move like "wS1".
        let lines: Vec<&str> = out.lines().collect();
        let idx = lines
            .iter()
            .position(|l| l.starts_with("Base;NotStarted"))
            .unwrap();
        // next non-ok line is the bestmove reply
        let reply = lines[idx + 2];
        assert!(
            ["wS1", "wB1", "wG1", "wA1"].contains(&reply),
            "unexpected bestmove reply: {reply}"
        );
    }
}
