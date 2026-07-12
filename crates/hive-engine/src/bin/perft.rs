//! Parallel perft: root-splits across threads for deep validation runs.
//!
//! Usage: perft [game-type] [max-depth]   e.g. `perft Base+MLP 7`

use hive_core::bug::GameType;
use hive_core::perft::{perft, perft_divide};
use hive_core::state::GameState;
use std::time::Instant;

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let gt = args
        .first()
        .map(|s| GameType::from_uhp(s).expect("bad game type"))
        .unwrap_or(GameType::BASE);
    let max_depth: u32 = args.get(1).and_then(|s| s.parse().ok()).unwrap_or(6);

    for depth in 1..=max_depth {
        let start = Instant::now();
        let total: u64 = if depth <= 3 {
            let mut s = GameState::new(gt);
            perft(&mut s, depth)
        } else {
            // Split at depth 2 and distribute across threads.
            let mut s = GameState::new(gt);
            let mut jobs: Vec<GameState> = vec![];
            for (mv1, _) in perft_divide(&mut s, 1) {
                let u1 = s.make(mv1);
                for (mv2, _) in perft_divide(&mut s, 1) {
                    let u2 = s.make(mv2);
                    jobs.push(s.clone());
                    s.unmake(mv2, u2);
                }
                s.unmake(mv1, u1);
            }
            let n_threads = std::thread::available_parallelism()
                .map(|n| n.get())
                .unwrap_or(8);
            let next = std::sync::atomic::AtomicUsize::new(0);
            let sum = std::sync::atomic::AtomicU64::new(0);
            std::thread::scope(|scope| {
                for _ in 0..n_threads {
                    scope.spawn(|| {
                        loop {
                            let i = next.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
                            if i >= jobs.len() {
                                break;
                            }
                            let mut st = jobs[i].clone();
                            let n = perft(&mut st, depth - 2);
                            sum.fetch_add(n, std::sync::atomic::Ordering::Relaxed);
                        }
                    });
                }
            });
            sum.into_inner()
        };
        let dt = start.elapsed();
        println!(
            "{} perft({}) = {:>16}   {:>8.2?}  ({:.1} MN/s)",
            gt.to_uhp(),
            depth,
            total,
            dt,
            total as f64 / dt.as_secs_f64() / 1e6
        );
    }
}
