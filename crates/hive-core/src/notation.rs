//! UHP BoardSpace notation: MoveStrings and GameStrings.
//!
//! MoveString forms (see Mzinga wiki, UniversalHiveProtocol):
//!   `wS1`        first placement of the game (canonical origin)
//!   `bA1 wS1-`   destination is East of wS1        (suffix -)
//!   `bA1 wS1/`   ... North-East                    (suffix /)
//!   `bA1 wS1\`   ... South-East                    (suffix \)
//!   `bA1 -wS1`   ... West                          (prefix -)
//!   `bA1 /wS1`   ... South-West                    (prefix /)
//!   `bA1 \wS1`   ... North-West                    (prefix \)
//!   `wB1 wS1`    land on top of wS1's stack (no marker)
//!   `pass`
//!
//! Whether a MoveString is a placement or a movement is implied by whether
//! the named piece is already on the board. Pillbug throws use the ordinary
//! form naming the thrown piece.

use crate::bug::PieceId;
use crate::hex::{ALL_DIRS, CENTER, Cell, Dir, neighbor};
use crate::state::{GameState, Move};

fn dir_to_dest(d: Dir) -> (bool, char) {
    // (marker_is_suffix, marker_char): dest = ref + d
    match d {
        Dir::E => (true, '-'),
        Dir::NE => (true, '/'),
        Dir::SE => (true, '\\'),
        Dir::W => (false, '-'),
        Dir::SW => (false, '/'),
        Dir::NW => (false, '\\'),
    }
}

fn marker_to_dir(suffix: bool, ch: char) -> Option<Dir> {
    Some(match (suffix, ch) {
        (true, '-') => Dir::E,
        (true, '/') => Dir::NE,
        (true, '\\') => Dir::SE,
        (false, '-') => Dir::W,
        (false, '/') => Dir::SW,
        (false, '\\') => Dir::NW,
        _ => return None,
    })
}

/// Format a move as a UHP MoveString, given the position BEFORE the move.
pub fn move_to_uhp(s: &GameState, mv: Move) -> String {
    let b = &s.board;
    match mv {
        Move::Pass => "pass".to_string(),
        Move::Place { piece, to } | Move::Move { piece, to } => {
            let moving = matches!(mv, Move::Move { .. });
            if b.count_on_board() == 0 {
                return piece.name();
            }
            // Landing on a stack: reference its current top.
            if let Some(top) = b.top_piece(to) {
                debug_assert_ne!(top, piece);
                return format!("{} {}", piece.name(), top.name());
            }
            // Ground destination: reference the top of any adjacent occupied
            // cell, evaluated with the mover lifted.
            let origin = if moving {
                Some(b.loc(piece).cell)
            } else {
                None
            };
            for d in ALL_DIRS {
                let n = neighbor(to, d);
                let reference = if Some(n) == origin {
                    if b.height(n) > 1 {
                        b.piece_under(piece)
                    } else {
                        None
                    }
                } else {
                    b.top_piece(n)
                };
                if let Some(r) = reference {
                    // dest is in direction d.opposite() from the reference.
                    let (suffix, ch) = dir_to_dest(d.opposite());
                    return if suffix {
                        format!("{} {}{}", piece.name(), r.name(), ch)
                    } else {
                        format!("{} {}{}", piece.name(), ch, r.name())
                    };
                }
            }
            unreachable!("legal move destination must touch the hive");
        }
    }
}

/// Parse a UHP MoveString in the given position. Returns the move without
/// validating full legality (callers check membership in generated moves).
pub fn move_from_uhp(s: &GameState, text: &str) -> Result<Move, String> {
    let text = text.trim();
    if text.eq_ignore_ascii_case("pass") {
        return Ok(Move::Pass);
    }
    let mut parts = text.split_whitespace();
    let piece = parts
        .next()
        .and_then(PieceId::parse)
        .ok_or_else(|| format!("bad piece in MoveString '{text}'"))?;
    let dest: Cell = match parts.next() {
        None => {
            if s.board.count_on_board() != 0 {
                return Err(format!(
                    "bare MoveString '{text}' only legal as the first move"
                ));
            }
            CENTER
        }
        Some(refpart) => {
            let first = refpart.chars().next().unwrap();
            let last = refpart.chars().last().unwrap();
            let (dir, refname) = if matches!(first, '-' | '/' | '\\') {
                (Some(marker_to_dir(false, first).unwrap()), &refpart[1..])
            } else if matches!(last, '-' | '/' | '\\') {
                (
                    Some(marker_to_dir(true, last).unwrap()),
                    &refpart[..refpart.len() - 1],
                )
            } else {
                (None, refpart)
            };
            let reference = PieceId::parse(refname)
                .ok_or_else(|| format!("bad reference piece in '{text}'"))?;
            if !s.board.on_board(reference) {
                return Err(format!("reference piece {refname} not on board"));
            }
            let ref_cell = s.board.loc(reference).cell;
            match dir {
                Some(d) => neighbor(ref_cell, d),
                None => ref_cell, // land on top of the reference stack
            }
        }
    };
    if parts.next().is_some() {
        return Err(format!("trailing tokens in MoveString '{text}'"));
    }
    Ok(if s.board.on_board(piece) {
        Move::Move { piece, to: dest }
    } else {
        Move::Place { piece, to: dest }
    })
}

/// Reference-piece sanity: a formatted move must parse back to itself.
#[cfg(test)]
mod tests {
    use super::*;
    use crate::bug::GameType;
    use crate::movegen::generate;

    #[test]
    fn roundtrip_over_random_games() {
        // Walk pseudo-random games in every game type; every generated move
        // must round-trip through its MoveString.
        for gt in GameType::ALL {
            let mut s = GameState::new(gt);
            let mut seed = 0xC0FFEEu64 ^ ((gt.to_uhp().len() as u64) << 32);
            for _ in 0..80 {
                let moves = generate(&s);
                if moves.is_empty() {
                    break;
                }
                for &m in moves.iter() {
                    let text = move_to_uhp(&s, m);
                    let back = move_from_uhp(&s, &text)
                        .unwrap_or_else(|e| panic!("failed to parse own MoveString '{text}': {e}"));
                    assert_eq!(back, m, "roundtrip failed for '{text}'");
                }
                seed = crate::zobrist::splitmix64(seed);
                let m = moves[(seed % moves.len() as u64) as usize];
                s.make(m);
            }
        }
    }

    #[test]
    fn first_move_is_bare_name() {
        let s = GameState::new(GameType::BASE);
        let mv = Move::Place {
            piece: PieceId::parse("wS1").unwrap(),
            to: CENTER,
        };
        assert_eq!(move_to_uhp(&s, mv), "wS1");
    }

    #[test]
    fn directional_markers() {
        let mut s = GameState::new(GameType::BASE);
        s.make(Move::Place {
            piece: PieceId::parse("wS1").unwrap(),
            to: CENTER,
        });
        for (d, expect) in [
            (Dir::E, "bS1 wS1-"),
            (Dir::NE, "bS1 wS1/"),
            (Dir::SE, "bS1 wS1\\"),
            (Dir::W, "bS1 -wS1"),
            (Dir::SW, "bS1 /wS1"),
            (Dir::NW, "bS1 \\wS1"),
        ] {
            let mv = Move::Place {
                piece: PieceId::parse("bS1").unwrap(),
                to: neighbor(CENTER, d),
            };
            assert_eq!(move_to_uhp(&s, mv), expect);
            assert_eq!(move_from_uhp(&s, expect).unwrap(), mv);
        }
    }
}
