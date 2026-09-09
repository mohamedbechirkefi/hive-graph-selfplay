export interface GameState {
  game_id: string
  ply: number
  pieces: Piece[]
  valid_moves: string[]
  game_over: boolean
  winner: string | null
  white_to_move: boolean
}

export interface Piece {
  id: string
  bug_type: string
  player: string
  q: number
  r: number
}

export interface Move {
  move: string
  probability: number
}

export interface PredictionResponse {
  top_moves: Array<[string, number]>
}

export interface GameStats {
  total_moves: number
  current_eval: number
  positions_seen: number
}

export interface Piece {
  id: string
  type: 'ant' | 'bee' | 'beetle' | 'grasshopper' | 'spider' | 'mosquito' | 'ladybug' | 'pillbug'
  player: 'white' | 'black'
  position: [number, number]
}

export interface HexCell {
  q: number
  r: number
  s: number
  pieces: Piece[]
}
