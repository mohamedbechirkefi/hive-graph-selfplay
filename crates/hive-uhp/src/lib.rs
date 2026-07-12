//! Universal Hive Protocol: engine-side server loop and a client for driving
//! other UHP engines (Mzinga, nokamute) as subprocesses.
//!
//! Protocol reference: github.com/jonthysell/Mzinga/wiki/UniversalHiveProtocol.
//! Every response block is terminated by a line containing exactly `ok`.

pub mod client;
pub mod server;

pub use client::UhpClient;
pub use server::{SearchLimit, Searcher, run_server};
