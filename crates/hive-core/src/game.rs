//! Game wrapper: a GameState plus move history, supporting UHP GameStrings
//! and undo.

use crate::bug::{Color, GameType};
use crate::movegen::{MoveList, generate};
use crate::notation::{move_from_uhp, move_to_uhp};
use crate::state::{GameState, Move, Undo};

pub struct Game {
    pub state: GameState,
    history: Vec<(Move, Undo, String)>,
    /// Repetition keys of every position since the start (index 0 =
    /// initial position); drives the threefold-repetition draw rule.
    rep_keys: Vec<u64>,
}

impl Game {
    pub fn new(game_type: GameType) -> Game {
        let state = GameState::new(game_type);
        let rep_keys = vec![state.repetition_key()];
        Game {
            state,
            history: Vec::new(),
            rep_keys,
        }
    }

    /// Parse `newgame` arguments: empty (Base), a GameTypeString, or a full
    /// GameString whose moves are replayed with validation.
    pub fn from_uhp(arg: &str) -> Result<Game, String> {
        let arg = arg.trim();
        if arg.is_empty() {
            return Ok(Game::new(GameType::BASE));
        }
        let parts: Vec<&str> = arg.split(';').collect();
        let gt = GameType::from_uhp(parts[0])
            .ok_or_else(|| format!("unknown GameTypeString '{}'", parts[0]))?;
        let mut game = Game::new(gt);
        // Full GameString: GameType;GameState;Turn;move;move;...
        if parts.len() > 3 {
            for text in &parts[3..] {
                game.play_uhp(text)?;
            }
        }
        Ok(game)
    }

    pub fn valid_moves(&self) -> MoveList {
        generate(&self.state)
    }

    /// Play a move, validating legality.
    pub fn play(&mut self, mv: Move) -> Result<(), String> {
        if !self.valid_moves().contains(&mv) {
            return Err(format!("illegal move {mv:?}"));
        }
        let text = move_to_uhp(&self.state, mv);
        let undo = self.state.make(mv);
        self.history.push((mv, undo, text));
        self.after_make();
        Ok(())
    }

    pub fn play_uhp(&mut self, text: &str) -> Result<(), String> {
        let mv = move_from_uhp(&self.state, text)?;
        if !self.valid_moves().contains(&mv) {
            return Err(format!("illegal move '{}'", text.trim()));
        }
        let undo = self.state.make(mv);
        self.history.push((mv, undo, text.trim().to_string()));
        self.after_make();
        Ok(())
    }

    /// Threefold repetition: if the just-reached position is its third
    /// occurrence, the game is a draw (unless already decided by surround).
    fn after_make(&mut self) {
        let key = self.state.repetition_key();
        if !self.state.result.is_over() && self.rep_keys.iter().filter(|&&k| k == key).count() >= 2
        {
            self.state.result = crate::state::GameResult::Draw;
        }
        self.rep_keys.push(key);
    }

    pub fn undo(&mut self, count: usize) -> Result<(), String> {
        if count > self.history.len() {
            return Err(format!(
                "cannot undo {count} moves, only {} played",
                self.history.len()
            ));
        }
        for _ in 0..count {
            let (mv, undo, _) = self.history.pop().unwrap();
            self.state.unmake(mv, undo);
            self.rep_keys.pop();
        }
        Ok(())
    }

    pub fn move_count(&self) -> usize {
        self.history.len()
    }

    /// Repetition keys of all positions so far (for search repetition
    /// detection seeded with real game history).
    pub fn repetition_keys(&self) -> &[u64] {
        &self.rep_keys
    }

    /// UHP TurnString, e.g. "White[1]".
    pub fn turn_string(&self) -> String {
        let color = match self.state.to_move {
            Color::White => "White",
            Color::Black => "Black",
        };
        format!("{}[{}]", color, self.state.own_turn_number())
    }

    /// Full UHP GameString.
    pub fn game_string(&self) -> String {
        let mut s = format!(
            "{};{};{}",
            self.state.game_type.to_uhp(),
            self.state.result.to_uhp(),
            self.turn_string()
        );
        for (_, _, text) in &self.history {
            s.push(';');
            s.push_str(text);
        }
        s
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn game_string_roundtrip() {
        let mut g = Game::from_uhp("Base+MLP").unwrap();
        for text in ["wS1", "bS1 wS1-", "wQ \\wS1", "bQ bS1-"] {
            g.play_uhp(text).unwrap();
        }
        let gs = g.game_string();
        assert!(gs.starts_with("Base+MLP;InProgress;White[3];wS1;"));
        let g2 = Game::from_uhp(&gs).unwrap();
        assert_eq!(g2.game_string(), gs);
        assert_eq!(g2.state.hash(), g.state.hash());
    }

    #[test]
    fn undo_restores() {
        let mut g = Game::from_uhp("Base").unwrap();
        let h0 = g.state.hash();
        g.play_uhp("wS1").unwrap();
        g.play_uhp("bS1 wS1-").unwrap();
        g.undo(2).unwrap();
        assert_eq!(g.state.hash(), h0);
        assert_eq!(g.move_count(), 0);
        assert!(g.undo(1).is_err());
    }

    #[test]
    fn rejects_illegal() {
        let mut g = Game::from_uhp("Base").unwrap();
        // Queen may not be placed on turn 1.
        assert!(g.play_uhp("wQ").is_err());
        // Base game has no mosquito.
        assert!(g.play_uhp("wM").is_err());
    }
}
