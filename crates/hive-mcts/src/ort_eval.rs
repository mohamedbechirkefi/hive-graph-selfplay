//! ONNX Runtime evaluator: runs the trained HiveNet (fixed-shape export)
//! with the CoreML execution provider (CPU fallback).
//!
//! The model's batch dimension is read from its input shape; smaller
//! batches are zero-padded. Use the b1 export for match play (one eval per
//! bestmove step at the root plus tree batches) and a b32/b128 export for
//! self-play throughput.

use crate::Evaluator;
use hive_core::state::{GameState, Move};
use hive_nn::{FRAME, PLANES, planes, policy_index};
use ort::session::Session;
use ort::value::Tensor;

pub struct OrtEvaluator {
    session: Session,
    model_batch: usize,
}

impl OrtEvaluator {
    /// Load a fixed-shape ONNX export. `use_coreml` enables the CoreML EP
    /// (recommended on Apple Silicon; ~10x CPU throughput).
    pub fn new(path: &str, use_coreml: bool) -> Result<OrtEvaluator, String> {
        let mut builder = Session::builder().map_err(|e| e.to_string())?;
        if use_coreml {
            builder = builder
                .with_execution_providers([
                    ort::execution_providers::CoreMLExecutionProvider::default().build(),
                ])
                .map_err(|e| e.to_string())?;
        }
        let session = builder
            .commit_from_file(path)
            .map_err(|e| format!("load {path}: {e}"))?;
        let model_batch = session
            .inputs()
            .first()
            .and_then(|o| o.dtype().tensor_shape())
            .and_then(|s| s.iter().next().copied())
            .filter(|&d| d > 0)
            .unwrap_or(1) as usize;
        Ok(OrtEvaluator {
            session,
            model_batch,
        })
    }
}

impl Evaluator for OrtEvaluator {
    fn batch_size(&self) -> usize {
        self.model_batch
    }

    fn evaluate(&mut self, batch: &[(GameState, Vec<Move>)]) -> Vec<(Vec<f32>, f32)> {
        let mut out = Vec::with_capacity(batch.len());
        let plane_len = PLANES * FRAME * FRAME;

        for chunk in batch.chunks(self.model_batch) {
            let mut input = vec![0f32; self.model_batch * plane_len];
            for (i, (state, _)) in chunk.iter().enumerate() {
                input[i * plane_len..(i + 1) * plane_len].copy_from_slice(&planes(state));
            }
            let tensor = Tensor::from_array((
                [
                    self.model_batch,
                    PLANES,
                    FRAME,
                    FRAME,
                ],
                input,
            ))
            .expect("build input tensor");
            let outputs = self
                .session
                .run(ort::inputs!["planes" => tensor])
                .expect("onnx inference");
            let (_, policy) = outputs["policy"]
                .try_extract_tensor::<f32>()
                .expect("policy output");
            let (_, value) = outputs["value"]
                .try_extract_tensor::<f32>()
                .expect("value output");

            for (i, (state, moves)) in chunk.iter().enumerate() {
                let p_row = &policy[i * hive_nn::POLICY_SIZE..(i + 1) * hive_nn::POLICY_SIZE];
                let frame = hive_nn::Frame::new(state);
                // Gather legal-move logits, softmax over the legal subset.
                let logits: Vec<f32> = moves
                    .iter()
                    .map(|&mv| {
                        policy_index(state, &frame, mv)
                            .map(|idx| p_row[idx])
                            .unwrap_or(f32::NEG_INFINITY)
                    })
                    .collect();
                let max = logits.iter().copied().fold(f32::NEG_INFINITY, f32::max);
                let exps: Vec<f32> = logits.iter().map(|&l| (l - max).exp()).collect();
                let sum: f32 = exps.iter().sum::<f32>().max(1e-9);
                let priors: Vec<f32> = exps.iter().map(|&e| e / sum).collect();

                // WDL softmax -> scalar value = P(win) - P(loss).
                let v_row = &value[i * 3..(i + 1) * 3];
                let vmax = v_row.iter().copied().fold(f32::NEG_INFINITY, f32::max);
                let ve: Vec<f32> = v_row.iter().map(|&l| (l - vmax).exp()).collect();
                let vs: f32 = ve.iter().sum();
                let val = (ve[2] - ve[0]) / vs.max(1e-9);
                out.push((priors, val));
            }
        }
        out
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{Mcts, MctsParams};
    use hive_core::game::Game;
    use hive_uhp::server::SearchLimit;

    /// Needs a trained export; run with:
    ///   HIVE_ONNX=models/hivenet-e3-b1.onnx cargo test -p hive-mcts --release -- --ignored
    #[test]
    #[ignore = "requires an ONNX model (set HIVE_ONNX)"]
    fn nn_mcts_plays_legal_moves() {
        let path = std::env::var("HIVE_ONNX").expect("set HIVE_ONNX to a model path");
        let eval = OrtEvaluator::new(&path, false).expect("load model");
        let mut game = Game::from_uhp("Base").unwrap();
        for m in ["wS1", "bS1 wS1-", "wQ -wS1", "bQ bS1-"] {
            game.play_uhp(m).unwrap();
        }
        let mut mcts = Mcts::new(eval, MctsParams::default());
        let (mv, dist, stats) = mcts.search(&game, SearchLimit::Depth(1));
        assert!(game.valid_moves().contains(&mv));
        assert!(stats.sims >= 300, "sims {}", stats.sims);
        assert!(dist.iter().any(|(_, n)| *n > 0));
    }
}
