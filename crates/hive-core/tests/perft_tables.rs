//! Perft validation against Mzinga's published tables (all 8 game types).
//!
//! Default run covers depths <= 5 (a few seconds). Depth 6 runs when
//! `HIVE_PERFT_DEEP=1` is set (or via `cargo test -- --ignored`); deeper
//! depths are the perft binary's job (parallel).

use hive_core::bug::GameType;
use hive_core::perft::perft;
use hive_core::state::GameState;

pub const TABLES: [(&str, [u64; 10]); 8] = [
    (
        "Base",
        [
            1,
            4,
            96,
            1440,
            21600,
            516240,
            12219480,
            181641900,
            2657392800,
            99376027356,
        ],
    ),
    (
        "Base+M",
        [
            1,
            5,
            150,
            2610,
            45414,
            1252800,
            34233432,
            527164524,
            8000790798,
            341738424810,
        ],
    ),
    (
        "Base+L",
        [
            1,
            5,
            150,
            2610,
            45414,
            1252800,
            34233672,
            529630188,
            8072006754,
            345842146422,
        ],
    ),
    (
        "Base+P",
        [
            1,
            5,
            150,
            2610,
            45414,
            1255932,
            34395984,
            532753872,
            8134286034,
            346017781674,
        ],
    ),
    (
        "Base+ML",
        [
            1,
            6,
            216,
            4320,
            86400,
            2725920,
            85201200,
            1357078404,
            21314716308,
            1036739513856,
        ],
    ),
    (
        "Base+MP",
        [
            1,
            6,
            216,
            4320,
            86400,
            2730888,
            85492248,
            1363837116,
            21467457180,
            1038414757560,
        ],
    ),
    (
        "Base+LP",
        [
            1,
            6,
            216,
            4320,
            86400,
            2730240,
            85457136,
            1366372440,
            21547245672,
            1043459509212,
        ],
    ),
    (
        "Base+MLP",
        [
            1,
            7,
            294,
            6678,
            151686,
            5427108,
            192353904,
            3151035948,
            50945151390,
            2784830280258,
        ],
    ),
];

fn run_to_depth(max_depth: u32) {
    for (name, table) in TABLES {
        let gt = GameType::from_uhp(name).unwrap();
        let mut s = GameState::new(gt);
        for (depth, &expect) in table.iter().enumerate().take(max_depth as usize + 1) {
            let got = perft(&mut s, depth as u32);
            assert_eq!(
                got, expect,
                "perft mismatch: {} depth {}: got {} expected {}",
                name, depth, got, expect
            );
        }
    }
}

#[test]
fn perft_all_types_to_depth_5() {
    run_to_depth(5);
}

#[test]
#[ignore = "slow; run with --ignored or HIVE_PERFT_DEEP=1"]
fn perft_all_types_to_depth_6() {
    run_to_depth(6);
}

#[test]
fn perft_depth_6_if_requested() {
    if std::env::var("HIVE_PERFT_DEEP").as_deref() == Ok("1") {
        run_to_depth(6);
    }
}
