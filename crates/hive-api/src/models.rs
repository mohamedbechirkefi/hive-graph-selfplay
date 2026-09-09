use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct GameState {
    pub game_id: String,
    pub fen: String,
    pub move_history: Vec<String>,
    pub valid_moves: Vec<String>,
    pub game_over: bool,
    pub winner: Option<String>,
    pub turn: u32,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct MoveStats {
    pub move_notation: String,
    pub eval: f32,
    pub win_rate: f32,
    pub visits: u32,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct GameStats {
    pub total_moves: u32,
    pub current_eval: f32,
    pub positions_seen: u32,
}
