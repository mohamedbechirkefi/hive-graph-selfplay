//! The shipped UHP engine binary.
//!
//! Backends:
//!   (default)         alpha-beta (PVS + lazy SMP), threads via HIVE_THREADS
//!   --mcts            PUCT MCTS with the handcrafted-eval evaluator
//!   --mcts --net P    PUCT MCTS with the trained network (ONNX; CoreML EP,
//!                     pass --cpu to force the CPU provider)
//!   --mcts --graph-net P  PUCT MCTS with the GRAPH-arm network (ONNX,
//!                     CPU provider - faster than CoreML for this net)
//!   --random          uniform legal-random baseline
//!   --seed N          RNG seed (random move choice / MCTS tie-breaking)
//!   --sims N          MCTS sims per depth unit (`bestmove depth 1` = N sims)

use hive_mcts::{EvalNet, GraphOrtEvaluator, Mcts, MctsParams, OrtEvaluator};
use hive_search::{AlphaBeta, SearchParams};
use hive_uhp::server::{RandomSearcher, Searcher, run_server};
use std::io::{BufReader, stdin, stdout};

fn arg_u64(args: &[String], name: &str) -> Option<u64> {
    args.iter()
        .position(|a| a == name)
        .and_then(|i| args.get(i + 1))
        .and_then(|v| v.parse().ok())
}

fn main() -> std::io::Result<()> {
    let args: Vec<String> = std::env::args().collect();
    let net_path = args
        .iter()
        .position(|a| a == "--net")
        .and_then(|i| args.get(i + 1).cloned());
    let seed = arg_u64(&args, "--seed");
    let sims = arg_u64(&args, "--sims");
    let mcts_params = || {
        let mut p = MctsParams::default();
        if let Some(s) = seed {
            p.seed = s;
        }
        if let Some(n) = sims {
            p.sims_per_depth = n as u32;
        }
        p
    };
    let graph_net = args
        .iter()
        .position(|a| a == "--graph-net")
        .and_then(|i| args.get(i + 1).cloned());
    let mut searcher: Box<dyn Searcher> = if args.iter().any(|a| a == "--random") {
        Box::new(RandomSearcher::new(seed.unwrap_or(0)))
    } else if args.iter().any(|a| a == "--mcts") {
        if let Some(path) = graph_net {
            let eval = GraphOrtEvaluator::new(&path)
                .unwrap_or_else(|e| panic!("failed to load graph network: {e}"));
            return run_server(
                BufReader::new(stdin()),
                stdout().lock(),
                &mut Mcts::new(eval, mcts_params()),
            );
        }
        match net_path {
            Some(path) => {
                let coreml = !args.iter().any(|a| a == "--cpu");
                let eval = OrtEvaluator::new(&path, coreml)
                    .unwrap_or_else(|e| panic!("failed to load network: {e}"));
                Box::new(Mcts::new(eval, mcts_params()))
            }
            None => Box::new(Mcts::new(EvalNet::default(), mcts_params())),
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
