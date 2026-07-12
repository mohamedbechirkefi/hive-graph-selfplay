//! The shipped UHP engine binary.
//!
//! Backends: `--random` for the M2 placeholder, alpha-beta (default).
//! MCTS+NN arrives in M6 behind the same interface.

use hive_search::{AlphaBeta, SearchParams};
use hive_uhp::server::{RandomSearcher, Searcher, run_server};
use std::io::{BufReader, stdin, stdout};

fn main() -> std::io::Result<()> {
    let random = std::env::args().any(|a| a == "--random");
    let mut params = SearchParams::default();
    if let Ok(t) = std::env::var("HIVE_THREADS")
        && let Ok(t) = t.parse()
    {
        params.threads = t;
    }
    let mut searcher: Box<dyn Searcher> = if random {
        Box::new(RandomSearcher)
    } else {
        Box::new(AlphaBeta::new(params))
    };
    run_server(BufReader::new(stdin()), stdout().lock(), searcher.as_mut())
}
