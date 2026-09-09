import { create } from 'zustand'
import { GameState, Move } from '../types'

interface GameStore {
  gameId: string | null
  gameState: GameState | null
  predictions: Move[]
  moveHistory: string[]
  selectedMove: string | null
  stats: {
    totalMoves: number
    currentEval: number
    whiteWins: number
    blackWins: number
    draws: number
  }

  setGameId: (id: string) => void
  setGameState: (state: GameState) => void
  setPredictions: (predictions: Move[]) => void
  addMove: (move: string) => void
  setSelectedMove: (move: string | null) => void
  updateStats: (stats: Partial<GameStore['stats']>) => void
  reset: () => void
}

const initialState = {
  gameId: null,
  gameState: null,
  predictions: [],
  moveHistory: [],
  selectedMove: null,
  stats: {
    totalMoves: 0,
    currentEval: 0,
    whiteWins: 0,
    blackWins: 0,
    draws: 0,
  },
}

export const useGameStore = create<GameStore>((set) => ({
  ...initialState,

  setGameId: (id: string) => set({ gameId: id }),

  setGameState: (gameState: GameState) => set({ gameState }),

  setPredictions: (predictions: Move[]) => set({ predictions }),

  addMove: (move: string) =>
    set((state) => ({
      moveHistory: [...state.moveHistory, move],
    })),

  setSelectedMove: (selectedMove: string | null) => set({ selectedMove }),

  updateStats: (stats) =>
    set((state) => ({
      stats: { ...state.stats, ...stats },
    })),

  reset: () => set(initialState),
}))
