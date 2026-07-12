//! hive-core: rules kernel for the game of Hive (base + M/L/P expansions).
//!
//! Zero I/O, zero global state. Everything downstream — search, MCTS, UHP,
//! self-play — builds on this crate. Correctness is enforced by perft against
//! Mzinga's published tables and differential fuzzing against reference
//! engines (see tests/).

pub mod board;
pub mod bug;
pub mod canonical;
pub mod game;
pub mod hex;
pub mod movegen;
pub mod notation;
pub mod onehive;
pub mod perft;
pub mod state;
pub mod zobrist;

pub use board::Board;
pub use bug::{Bug, Color, GameType, PieceId};
pub use game::Game;
pub use hex::{Cell, Dir};
pub use movegen::{MoveList, generate};
pub use state::{GameResult, GameState, Move};
