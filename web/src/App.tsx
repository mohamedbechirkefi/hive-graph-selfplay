import React, { useEffect, useState } from 'react'
import Board3D from './components/Board3D'
import Sidebar from './components/Sidebar'
import { useGameStore } from './store/gameStore'
import { api } from './utils/api'
import './App.css'

function App() {
  const [loading, setLoading] = useState(true)
  const [apiConnected, setApiConnected] = useState(false)
  const setGameId = useGameStore((state) => state.setGameId)
  const setGameState = useGameStore((state) => state.setGameState)
  const setPredictions = useGameStore((state) => state.setPredictions)
  const gameId = useGameStore((state) => state.gameId)

  // Check API and initialize
  useEffect(() => {
    const init = async () => {
      try {
        const connected = await api.healthCheck()
        setApiConnected(connected)

        if (connected) {
          const gameState = await api.newGame()
          setGameId(gameState.game_id)
          setGameState(gameState)

          // Get predictions
          const predictions = await api.predictMove(gameState.game_id)
          setPredictions(
            predictions.top_moves.map(([move, prob]) => ({
              move,
              probability: prob,
            }))
          )
        }
      } catch (error) {
        console.error('Failed to initialize game:', error)
      } finally {
        setLoading(false)
      }
    }

    init()
  }, [setGameId, setGameState, setPredictions])

  return (
    <div className="app">
      <Board3D />
      <Sidebar />

      {/* Status overlay */}
      {loading && (
        <div className="overlay">
          <div className="spinner"></div>
          <p>Initializing...</p>
        </div>
      )}

      {!apiConnected && !loading && (
        <div className="error-overlay">
          <p>Failed to connect to API</p>
          <p style={{ fontSize: '0.875rem', marginTop: '0.5rem' }}>
            Make sure the backend is running on port 3000
          </p>
        </div>
      )}

      {/* Controls */}
      <div className="controls">
        <button onClick={() => window.location.reload()}>New Game</button>
      </div>
    </div>
  )
}

export default App
