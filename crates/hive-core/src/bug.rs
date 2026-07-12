//! Bug types, colors, piece identities, and game-type (expansion) flags.

#[derive(Copy, Clone, PartialEq, Eq, Debug, Hash)]
#[repr(u8)]
pub enum Color {
    White = 0,
    Black = 1,
}

impl Color {
    #[inline]
    pub const fn other(self) -> Color {
        match self {
            Color::White => Color::Black,
            Color::Black => Color::White,
        }
    }

    pub const fn letter(self) -> char {
        match self {
            Color::White => 'w',
            Color::Black => 'b',
        }
    }
}

#[derive(Copy, Clone, PartialEq, Eq, Debug, Hash)]
#[repr(u8)]
pub enum Bug {
    Queen = 0,
    Spider = 1,
    Beetle = 2,
    Grasshopper = 3,
    Ant = 4,
    Mosquito = 5,
    Ladybug = 6,
    Pillbug = 7,
}

impl Bug {
    pub const fn letter(self) -> char {
        match self {
            Bug::Queen => 'Q',
            Bug::Spider => 'S',
            Bug::Beetle => 'B',
            Bug::Grasshopper => 'G',
            Bug::Ant => 'A',
            Bug::Mosquito => 'M',
            Bug::Ladybug => 'L',
            Bug::Pillbug => 'P',
        }
    }

    pub const fn from_letter(c: char) -> Option<Bug> {
        match c {
            'Q' => Some(Bug::Queen),
            'S' => Some(Bug::Spider),
            'B' => Some(Bug::Beetle),
            'G' => Some(Bug::Grasshopper),
            'A' => Some(Bug::Ant),
            'M' => Some(Bug::Mosquito),
            'L' => Some(Bug::Ladybug),
            'P' => Some(Bug::Pillbug),
            _ => None,
        }
    }
}

/// Per-color piece roster: (bug, ordinal 1-based). 14 pieces per color.
/// Order groups same-bug pieces so `lowest unplaced ordinal` scans are easy.
pub const ROSTER: [(Bug, u8); PIECES_PER_COLOR] = [
    (Bug::Queen, 1),
    (Bug::Spider, 1),
    (Bug::Spider, 2),
    (Bug::Beetle, 1),
    (Bug::Beetle, 2),
    (Bug::Grasshopper, 1),
    (Bug::Grasshopper, 2),
    (Bug::Grasshopper, 3),
    (Bug::Ant, 1),
    (Bug::Ant, 2),
    (Bug::Ant, 3),
    (Bug::Mosquito, 1),
    (Bug::Ladybug, 1),
    (Bug::Pillbug, 1),
];

pub const PIECES_PER_COLOR: usize = 14;
pub const NUM_PIECES: usize = 2 * PIECES_PER_COLOR;

/// Piece identity: 0..14 white (roster order), 14..28 black.
#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, Debug, Hash)]
pub struct PieceId(pub u8);

impl PieceId {
    #[inline]
    pub const fn new(color: Color, roster_index: u8) -> PieceId {
        PieceId(color as u8 * PIECES_PER_COLOR as u8 + roster_index)
    }

    #[inline]
    pub const fn color(self) -> Color {
        if self.0 < PIECES_PER_COLOR as u8 {
            Color::White
        } else {
            Color::Black
        }
    }

    #[inline]
    pub const fn roster_index(self) -> u8 {
        self.0 % PIECES_PER_COLOR as u8
    }

    #[inline]
    pub const fn bug(self) -> Bug {
        ROSTER[self.roster_index() as usize].0
    }

    #[inline]
    pub const fn ordinal(self) -> u8 {
        ROSTER[self.roster_index() as usize].1
    }

    /// UHP piece name, e.g. "wS1", "bQ", "wM". Singleton bugs carry no number.
    pub fn name(self) -> String {
        let (bug, n) = ROSTER[self.roster_index() as usize];
        let singleton = matches!(
            bug,
            Bug::Queen | Bug::Mosquito | Bug::Ladybug | Bug::Pillbug
        );
        if singleton {
            format!("{}{}", self.color().letter(), bug.letter())
        } else {
            format!("{}{}{}", self.color().letter(), bug.letter(), n)
        }
    }

    /// Parse a UHP piece name ("wS1", "bQ", "wM"...). Accepts an optional
    /// explicit "1" on singleton bugs.
    pub fn parse(s: &str) -> Option<PieceId> {
        let mut chars = s.chars();
        let color = match chars.next()? {
            'w' | 'W' => Color::White,
            'b' | 'B' => Color::Black,
            _ => return None,
        };
        let bug = Bug::from_letter(chars.next()?.to_ascii_uppercase())?;
        let rest = chars.as_str();
        let ordinal: u8 = if rest.is_empty() {
            1
        } else {
            rest.parse().ok()?
        };
        ROSTER
            .iter()
            .position(|&(b, n)| b == bug && n == ordinal)
            .map(|i| PieceId::new(color, i as u8))
    }
}

/// Which expansion bugs are in play. All 8 UHP game types.
#[derive(Copy, Clone, PartialEq, Eq, Debug, Default)]
pub struct GameType {
    pub mosquito: bool,
    pub ladybug: bool,
    pub pillbug: bool,
}

impl GameType {
    pub const BASE: GameType = GameType {
        mosquito: false,
        ladybug: false,
        pillbug: false,
    };
    pub const MLP: GameType = GameType {
        mosquito: true,
        ladybug: true,
        pillbug: true,
    };

    #[inline]
    pub fn includes(&self, bug: Bug) -> bool {
        match bug {
            Bug::Mosquito => self.mosquito,
            Bug::Ladybug => self.ladybug,
            Bug::Pillbug => self.pillbug,
            _ => true,
        }
    }

    /// UHP GameTypeString, e.g. "Base", "Base+MLP".
    pub fn to_uhp(&self) -> String {
        let mut s = String::from("Base");
        if self.mosquito || self.ladybug || self.pillbug {
            s.push('+');
            if self.mosquito {
                s.push('M');
            }
            if self.ladybug {
                s.push('L');
            }
            if self.pillbug {
                s.push('P');
            }
        }
        s
    }

    pub fn from_uhp(s: &str) -> Option<GameType> {
        let s = s.trim();
        if !s.starts_with("Base") {
            return None;
        }
        let rest = &s[4..];
        let mut gt = GameType::BASE;
        if rest.is_empty() {
            return Some(gt);
        }
        let ext = rest.strip_prefix('+')?;
        for c in ext.chars() {
            match c.to_ascii_uppercase() {
                'M' => gt.mosquito = true,
                'L' => gt.ladybug = true,
                'P' => gt.pillbug = true,
                _ => return None,
            }
        }
        Some(gt)
    }

    pub const ALL: [GameType; 8] = [
        GameType {
            mosquito: false,
            ladybug: false,
            pillbug: false,
        },
        GameType {
            mosquito: true,
            ladybug: false,
            pillbug: false,
        },
        GameType {
            mosquito: false,
            ladybug: true,
            pillbug: false,
        },
        GameType {
            mosquito: false,
            ladybug: false,
            pillbug: true,
        },
        GameType {
            mosquito: true,
            ladybug: true,
            pillbug: false,
        },
        GameType {
            mosquito: true,
            ladybug: false,
            pillbug: true,
        },
        GameType {
            mosquito: false,
            ladybug: true,
            pillbug: true,
        },
        GameType {
            mosquito: true,
            ladybug: true,
            pillbug: true,
        },
    ];
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn piece_name_roundtrip() {
        for i in 0..NUM_PIECES as u8 {
            let p = PieceId(i);
            assert_eq!(PieceId::parse(&p.name()), Some(p), "piece {}", p.name());
        }
    }

    #[test]
    fn game_type_roundtrip() {
        for gt in GameType::ALL {
            assert_eq!(GameType::from_uhp(&gt.to_uhp()), Some(gt));
        }
        assert_eq!(GameType::from_uhp("Base+MLP"), Some(GameType::MLP));
        assert_eq!(GameType::from_uhp("banana"), None);
    }

    #[test]
    fn queen_indices() {
        assert_eq!(PieceId::new(Color::White, 0).bug(), Bug::Queen);
        assert_eq!(PieceId::new(Color::Black, 0).name(), "bQ");
    }
}
