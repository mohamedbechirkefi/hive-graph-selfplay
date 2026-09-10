//! ONNX evaluator for the GRAPH arm (D-022c): builds the cell-graph
//! tensors per position with the crosschecked `hive_nn::graph` encoder,
//! runs the exported HiveGraphNet (static shapes), and returns priors
//! over the caller's move list plus the P(win)−P(loss) scalar value —
//! the identical output contract as the grid arm's `OrtEvaluator`.

use crate::Evaluator;
use hive_core::state::{GameState, Move};
use hive_nn::Frame;
use hive_nn::graph::{GLOBAL_F, MOVE_CAP, NODE_CAP, NODE_F, graph_moves, graph_state};
use ort::session::Session;
use ort::value::Tensor;

pub struct GraphOrtEvaluator {
    session: Session,
}

impl GraphOrtEvaluator {
    /// Load a fixed-shape HiveGraphNet ONNX export (batch 1). CoreML is
    /// measurably SLOWER than CPU for this gather-heavy net
    /// (docs/representations/comparison-controls.md), so the CPU provider
    /// is used unconditionally.
    pub fn new(path: &str) -> Result<GraphOrtEvaluator, String> {
        let session = Session::builder()
            .map_err(|e| e.to_string())?
            .commit_from_file(path)
            .map_err(|e| format!("load {path}: {e}"))?;
        Ok(GraphOrtEvaluator { session })
    }
}

impl Evaluator for GraphOrtEvaluator {
    fn evaluate(&mut self, batch: &[(GameState, Vec<Move>)]) -> Vec<(Vec<f32>, f32)> {
        let mut out = Vec::with_capacity(batch.len());
        for (state, moves) in batch {
            let g = graph_state(state);
            let frame = Frame::new(state);
            let (rows, mmask) = graph_moves(state, &frame, &g, moves);

            let nodes = Tensor::from_array(([1usize, NODE_CAP, NODE_F], g.nodes.clone()))
                .expect("nodes tensor");
            let nbrs = Tensor::from_array(([1usize, NODE_CAP, 6], g.nbrs.clone()))
                .expect("nbrs tensor");
            let nmask_b: Vec<bool> = g.nmask.iter().map(|&v| v != 0).collect();
            let nmask =
                Tensor::from_array(([1usize, NODE_CAP], nmask_b)).expect("nmask tensor");
            let glob = Tensor::from_array(([1usize, GLOBAL_F], g.glob.clone()))
                .expect("glob tensor");
            let mv = Tensor::from_array(([1usize, MOVE_CAP, 3], rows)).expect("moves tensor");
            let mmask_b: Vec<bool> = mmask.iter().map(|&v| v != 0).collect();
            let mm = Tensor::from_array(([1usize, MOVE_CAP], mmask_b)).expect("mmask tensor");

            let outputs = self
                .session
                .run(ort::inputs![
                    "nodes" => nodes, "nbrs" => nbrs, "nmask" => nmask,
                    "glob" => glob, "moves" => mv, "mmask" => mm
                ])
                .expect("graph onnx inference");
            let (_, logits) = outputs["policy"]
                .try_extract_tensor::<f32>()
                .expect("policy output");
            let (_, value) = outputs["value"]
                .try_extract_tensor::<f32>()
                .expect("value output");

            // Softmax over the caller's legal rows (rows k < moves.len()).
            let n = moves.len();
            let max = logits[..n].iter().copied().fold(f32::NEG_INFINITY, f32::max);
            let exps: Vec<f32> = logits[..n].iter().map(|&l| (l - max).exp()).collect();
            let sum: f32 = exps.iter().sum::<f32>().max(1e-9);
            let priors: Vec<f32> = exps.iter().map(|&e| e / sum).collect();

            let vmax = value[..3].iter().copied().fold(f32::NEG_INFINITY, f32::max);
            let ve: Vec<f32> = value[..3].iter().map(|&l| (l - vmax).exp()).collect();
            let vs: f32 = ve.iter().sum();
            let val = (ve[2] - ve[0]) / vs.max(1e-9);
            out.push((priors, val));
        }
        out
    }
}
