//! Golden-test helper: for N pseudo-random positions, write each compact
//! record followed by its full Rust-encoded planes (f32 LE). The Python side
//! (scripts/crosscheck_planes.py) re-decodes the record and asserts equality.

use hive_core::bug::GameType;
use hive_core::game::Game;
use hive_core::zobrist::splitmix64;
use hive_nn::{encode_record, planes};
use std::io::Write;

fn main() {
    let out_path = std::env::args().nth(1).unwrap_or("/tmp/hive_planes.bin".into());
    let mut out = std::io::BufWriter::new(std::fs::File::create(&out_path).unwrap());
    let mut count = 0u32;
    for (gi, gt) in GameType::ALL.iter().enumerate() {
        let mut g = Game::new(*gt);
        let mut seed = 0xABCDu64 ^ ((gi as u64) << 40);
        for _ in 0..30 {
            if g.state.result.is_over() {
                break;
            }
            let moves = g.valid_moves();
            seed = splitmix64(seed ^ g.state.hash());
            let mv = moves[(seed % moves.len() as u64) as usize];
            let rec = encode_record(&g.state, mv, 1);
            out.write_all(&rec).unwrap();
            for v in planes(&g.state) {
                out.write_all(&v.to_le_bytes()).unwrap();
            }
            count += 1;
            g.play(mv).unwrap();
        }
    }
    out.flush().unwrap();
    eprintln!("wrote {count} (record, planes) pairs to {out_path}");
}
