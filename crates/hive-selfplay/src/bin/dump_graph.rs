//! Golden-test helper for the graph arm (D-022c): for N pseudo-random
//! positions, write the v3 record followed by the Rust-encoded graph
//! tensors. scripts/crosscheck_graph.py rebuilds the graph from the record
//! with the Python builder and asserts exact equality.
//!
//! Per position, little-endian:
//!   v3 record (818 B, one-hot dist on the played move)
//!   nodes  NODE_CAP*NODE_F f32
//!   nbrs   NODE_CAP*6      i64
//!   nmask  NODE_CAP        u8
//!   glob   GLOBAL_F        f32
//!   moves  MOVE_CAP*3      i64
//!   mmask  MOVE_CAP        u8

use hive_core::bug::GameType;
use hive_core::game::Game;
use hive_core::zobrist::splitmix64;
use hive_nn::graph::{graph_moves, graph_state};
use hive_nn::{Frame, encode_record_v3};
use std::io::Write;

fn main() {
    let out_path = std::env::args().nth(1).unwrap_or("/tmp/hive_graph.bin".into());
    let mut out = std::io::BufWriter::new(std::fs::File::create(&out_path).unwrap());
    let mut count = 0u32;
    for (gi, gt) in GameType::ALL.iter().enumerate() {
        let mut g = Game::new(*gt);
        let mut seed = 0x6EA9u64 ^ ((gi as u64) << 40);
        for _ in 0..20 {
            if g.state.result.is_over() {
                break;
            }
            let moves = g.valid_moves();
            seed = splitmix64(seed ^ g.state.hash());
            let mv = moves[(seed % moves.len() as u64) as usize];
            let legal: Vec<_> = moves.iter().copied().collect();
            let rec = encode_record_v3(&g.state, mv, 1, &[(mv, 1)], &legal, (0, 0));
            out.write_all(&rec).unwrap();

            let gt_tensors = graph_state(&g.state);
            let frame = Frame::new(&g.state);
            let (rows, mmask) = graph_moves(&g.state, &frame, &gt_tensors, &legal);
            for v in &gt_tensors.nodes {
                out.write_all(&v.to_le_bytes()).unwrap();
            }
            for v in &gt_tensors.nbrs {
                out.write_all(&v.to_le_bytes()).unwrap();
            }
            out.write_all(&gt_tensors.nmask).unwrap();
            for v in &gt_tensors.glob {
                out.write_all(&v.to_le_bytes()).unwrap();
            }
            for v in &rows {
                out.write_all(&v.to_le_bytes()).unwrap();
            }
            out.write_all(&mmask).unwrap();
            count += 1;
            g.play(mv).unwrap();
        }
    }
    out.flush().unwrap();
    eprintln!("wrote {count} (record, graph) pairs to {out_path}");
}
