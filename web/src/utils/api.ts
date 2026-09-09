import axios from 'axios'
import { GameState, PredictionResponse } from '../types'

const API_BASE = '/api'

const client = axios.create({
  baseURL: API_BASE,
  headers: {
    'Content-Type': 'application/json',
  },
})

export const api = {
  // Game endpoints
  newGame: async (): Promise<GameState> => {
    const { data } = await client.post('/game/new')
    return data
  },

  getGame: async (gameId: string): Promise<GameState> => {
    const { data } = await client.get(`/game/${gameId}`)
    return data
  },

  makeMove: async (gameId: string, move: string) => {
    const { data } = await client.post(`/game/${gameId}/move`, { game_id: gameId, mv: move })
    return data
  },

  predictMove: async (gameId: string): Promise<PredictionResponse> => {
    const { data } = await client.post(`/game/${gameId}/predict`)
    return data
  },

  healthCheck: async (): Promise<boolean> => {
    try {
      const { data } = await client.get('/health')
      return data === 'OK'
    } catch {
      return false
    }
  },
}
