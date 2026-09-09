import React from 'react'
import { useGameStore } from '../store/gameStore'
import styles from './Sidebar.module.css'

export const Sidebar: React.FC = () => {
  const stats = useGameStore((state) => state.stats)
  const moveHistory = useGameStore((state) => state.moveHistory)
  const predictions = useGameStore((state) => state.predictions)

  return (
    <div className={styles.sidebar}>
      {/* Stats Section */}
      <div className={styles.section}>
        <h3 className={styles.title}>Stats</h3>
        <div className={styles.stat}>
          <span className={styles.label}>Total Moves</span>
          <span className={styles.value}>{stats.totalMoves}</span>
        </div>
        <div className={styles.stat}>
          <span className={styles.label}>Evaluation</span>
          <span className={styles.value}>
            {stats.currentEval > 0 ? '+' : ''}{stats.currentEval.toFixed(2)}
          </span>
        </div>
      </div>

      {/* ELO Section */}
      <div className={styles.section}>
        <h3 className={styles.title}>ELO Rating</h3>
        <div className={styles.stat}>
          <span className={styles.label}>Player</span>
          <span className={styles.value}>1200</span>
        </div>
        <div className={styles.stat}>
          <span className={styles.label}>AI</span>
          <span className={styles.value}>2400+</span>
        </div>
      </div>

      {/* Move Predictions */}
      <div className={styles.section}>
        <h3 className={styles.title}>Top Moves</h3>
        <div className={styles.predictions}>
          {predictions.slice(0, 5).map((pred, idx) => (
            <div key={idx} className={styles.prediction}>
              <span className={styles.move}>{pred.move}</span>
              <span className={styles.probability}>
                {(pred.probability * 100).toFixed(1)}%
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* Move History */}
      <div className={styles.section}>
        <h3 className={styles.title}>History</h3>
        <div className={styles.history}>
          {moveHistory.length === 0 ? (
            <p className={styles.empty}>No moves yet</p>
          ) : (
            moveHistory.map((move, idx) => (
              <div key={idx} className={styles.move}>
                {idx + 1}. {move}
              </div>
            ))
          )}
        </div>
      </div>

      {/* Match Stats */}
      <div className={styles.section}>
        <h3 className={styles.title}>Record</h3>
        <div className={styles.record}>
          <div className={styles.recordStat}>
            <span className={styles.label}>Wins</span>
            <span className={styles.value} style={{ color: '#10b981' }}>
              {stats.whiteWins}
            </span>
          </div>
          <div className={styles.recordStat}>
            <span className={styles.label}>Losses</span>
            <span className={styles.value} style={{ color: '#ef4444' }}>
              {stats.blackWins}
            </span>
          </div>
          <div className={styles.recordStat}>
            <span className={styles.label}>Draws</span>
            <span className={styles.value} style={{ color: '#8b5cf6' }}>
              {stats.draws}
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Sidebar
