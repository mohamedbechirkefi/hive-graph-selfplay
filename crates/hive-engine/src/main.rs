//! The shipped UHP engine binary.
//!
//! Backends:
//!   (default)         alpha-beta (PVS + lazy SMP), threads via HIVE_THREADS
//!   --mcts            PUCT MCTS with the handcrafted-eval evaluator
//!   --mcts --net P    PUCT MCTS with the trained network (ONNX; CoreML EP,
//!                     pass --cpu to force the CPU provider)
//!   --random          M2 placeholder / weakest baseline

use hive_mcts::{EvalNet, Mcts, MctsParams, OrtEvaluator};
use hive_search::{AlphaBeta, SearchParams};
use hive_uhp::server::{RandomSearcher, Searcher, run_server};
use std::io::{BufReader, stdin, stdout};

fn main() -> std::io::Result<()> {
    let args: Vec<String> = std::env::args().collect();
    let net_path = args
        .iter()
        .position(|a| a == "--net")
        .and_then(|i| args.get(i + 1).cloned());
    let mut searcher: Box<dyn Searcher> = if args.iter().any(|a| a == "--random") {
        Box::new(RandomSearcher)
    } else if args.iter().any(|a| a == "--mcts") {
        match net_path {
            Some(path) => {
                let coreml = !args.iter().any(|a| a == "--cpu");
                let eval = OrtEvaluator::new(&path, coreml)
                    .unwrap_or_else(|e| panic!("failed to load network: {e}"));
                Box::new(Mcts::new(eval, MctsParams::default()))
            }
            None => Box::new(Mcts::new(EvalNet::default(), MctsParams::default())),
        }
    } else {
        let mut params = SearchParams::default();
        if let Ok(t) = std::env::var("HIVE_THREADS")
            && let Ok(t) = t.parse()
        {
            params.threads = t;
        }
        Box::new(AlphaBeta::new(params))
    };
    run_server(BufReader::new(stdin()), stdout().lock(), searcher.as_mut())
}
