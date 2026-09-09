use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::Json,
};
use hive_core::{GameState, GameType, generate, notation, Color, hex};
use uuid::Uuid;

use crate::{AppState, GameResponse, MoveRequest, MoveResponse, PredictionResponse, Piece};

pub async fn new_game(
    State(state): State<AppState>,
) -> Json<GameResponse> {
    let game_id = Uuid::new_v4().to_string();
    let game_state = GameState::new(GameType::BASE);

    {
        let mut games = state.games.write().unwrap();
        games.insert(game_id.clone(), game_state.clone());
    }

    Json(game_response(game_id, &game_state))
}

pub async fn get_game(
    Path(game_id): Path<String>,
    State(state): State<AppState>,
) -> Result<Json<GameResponse>, StatusCode> {
    let games = state.games.read().unwrap();
    let game_state = games
        .get(&game_id)
        .ok_or(StatusCode::NOT_FOUND)?
        .clone();

    Ok(Json(game_response(game_id, &game_state)))
}

pub async fn make_move(
    Path(game_id): Path<String>,
    State(state): State<AppState>,
    Json(request): Json<MoveRequest>,
) -> Result<Json<MoveResponse>, StatusCode> {
    let mut games = state.games.write().unwrap();
    let game_state = games
        .get_mut(&game_id)
        .ok_or(StatusCode::NOT_FOUND)?;

    // Parse move from UHP notation
    let mv = notation::move_from_uhp(&game_state, &request.mv)
        .map_err(|_| StatusCode::BAD_REQUEST)?;

    game_state.make(mv);

    let new_move_list = generate(&game_state);
    let moves: Vec<String> = new_move_list.iter()
        .map(|m| notation::move_to_uhp(&game_state, *m))
        .collect();

    Ok(Json(MoveResponse {
        success: true,
        fen: format!("ply: {}", game_state.ply),
        valid_moves: moves,
        game_over: game_state.result.is_over(),
    }))
}

pub async fn predict_move(
    Path(game_id): Path<String>,
    State(state): State<AppState>,
) -> Result<Json<PredictionResponse>, StatusCode> {
    let games = state.games.read().unwrap();
    let _game_state = games
        .get(&game_id)
        .ok_or(StatusCode::NOT_FOUND)?;

    // TODO: Integrate model inference here
    Ok(Json(PredictionResponse {
        top_moves: vec![
            ("pass".to_string(), 0.5),
            ("ant a2-a1".to_string(), 0.3),
        ],
    }))
}

fn extract_pieces(game_state: &GameState) -> Vec<Piece> {
    let mut pieces = Vec::new();

    for piece_id in game_state.board.pieces_on_board() {
        let loc = game_state.board.loc(piece_id);
        let player_str = if piece_id.color() == Color::White { "white" } else { "black" };
        let bug_type = match piece_id.bug() {
            hive_core::Bug::Queen => "queen",
            hive_core::Bug::Spider => "spider",
            hive_core::Bug::Beetle => "beetle",
            hive_core::Bug::Grasshopper => "grasshopper",
            hive_core::Bug::Ant => "ant",
            hive_core::Bug::Mosquito => "mosquito",
            hive_core::Bug::Ladybug => "ladybug",
            hive_core::Bug::Pillbug => "pillbug",
        };

        pieces.push(Piece {
            id: piece_id.name(),
            bug_type: bug_type.to_string(),
            player: player_str.to_string(),
            q: hex::cell_q(loc.cell) as i32,
            r: hex::cell_r(loc.cell) as i32,
        });
    }

    pieces
}

fn game_response(game_id: String, game_state: &GameState) -> GameResponse {
    let move_list = generate(&game_state);
    let moves: Vec<String> = move_list.iter()
        .map(|m| notation::move_to_uhp(&game_state, *m))
        .collect();

    GameResponse {
        game_id,
        ply: game_state.ply,
        pieces: extract_pieces(&game_state),
        valid_moves: moves,
        game_over: game_state.result.is_over(),
        winner: None,
        white_to_move: game_state.to_move == Color::White,
    }
}
