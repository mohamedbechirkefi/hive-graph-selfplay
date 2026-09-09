use axum::{
    routing::{get, post},
    Router,
};
use hive_core::GameState;
use serde::{Deserialize, Serialize};
use std::sync::{Arc, RwLock};
use tower_http::cors::CorsLayer;

pub mod models;
pub mod handlers;

use handlers::*;

#[derive(Clone)]
pub struct AppState {
    pub games: Arc<RwLock<std::collections::HashMap<String, GameState>>>,
}

impl AppState {
    pub fn new() -> Self {
        Self {
            games: Arc::new(RwLock::new(std::collections::HashMap::new())),
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Piece {
    pub id: String,
    pub bug_type: String,
    pub player: String,
    pub q: i32,
    pub r: i32,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct GameResponse {
    pub game_id: String,
    pub ply: u16,
    pub pieces: Vec<Piece>,
    pub valid_moves: Vec<String>,
    pub game_over: bool,
    pub winner: Option<String>,
    pub white_to_move: bool,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct MoveRequest {
    pub game_id: String,
    pub mv: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct MoveResponse {
    pub success: bool,
    pub fen: String,
    pub valid_moves: Vec<String>,
    pub game_over: bool,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct PredictionResponse {
    pub top_moves: Vec<(String, f32)>, // (move, probability)
}

pub fn create_router() -> Router {
    let state = AppState::new();

    Router::new()
        .route("/api/game/new", post(new_game))
        .route("/api/game/:game_id", get(get_game))
        .route("/api/game/:game_id/move", post(make_move))
        .route("/api/game/:game_id/predict", post(predict_move))
        .route("/api/health", get(health_check))
        .layer(CorsLayer::permissive())
        .with_state(state)
}

async fn health_check() -> &'static str {
    "OK"
}

pub async fn run_server(port: u16) {
    let router = create_router();
    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{}", port))
        .await
        .expect("Failed to bind");

    tracing::info!("Server running on port {}", port);

    axum::serve(listener, router)
        .await
        .expect("Server error");
}
