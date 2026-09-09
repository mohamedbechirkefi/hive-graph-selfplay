import React, { useEffect, useRef } from 'react'
import * as THREE from 'three'
import gsap from 'gsap'
import { useGameStore } from '../store/gameStore'
import { hexToWorldPos, HexCoord } from '../utils/hexagon'
import { api } from '../utils/api'

interface PieceData {
  id: string
  bug_type: string
  player: string
  q: number
  r: number
}

export const Board3D: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const sceneRef = useRef<THREE.Scene | null>(null)
  const rendererRef = useRef<THREE.WebGLRenderer | null>(null)
  const boardGroupRef = useRef<THREE.Group | null>(null)
  const piecesGroupRef = useRef<THREE.Group | null>(null)
  const hexTilesRef = useRef<Map<string, THREE.Mesh>>(new Map())
  const selectedPieceRef = useRef<string | null>(null)

  const gameId = useGameStore((state) => state.gameId)
  const gameState = useGameStore((state) => state.gameState)
  const setGameState = useGameStore((state) => state.setGameState)
  const addMove = useGameStore((state) => state.addMove)
  const setPredictions = useGameStore((state) => state.setPredictions)

  useEffect(() => {
    if (!canvasRef.current || !gameState) return

    // Scene setup
    const scene = new THREE.Scene()
    scene.background = new THREE.Color(0x0a0e27)
    scene.fog = new THREE.Fog(0x0a0e27, 60, 120)
    sceneRef.current = scene

    const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 1000)
    camera.position.set(0, 14, 14)
    camera.lookAt(0, 0, 0)

    const renderer = new THREE.WebGLRenderer({ canvas: canvasRef.current, antialias: true })
    renderer.setSize(window.innerWidth, window.innerHeight)
    renderer.setPixelRatio(window.devicePixelRatio)
    renderer.shadowMap.enabled = true
    rendererRef.current = renderer

    // Lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6)
    scene.add(ambientLight)

    const directionalLight = new THREE.DirectionalLight(0xffffff, 1)
    directionalLight.position.set(20, 30, 20)
    directionalLight.castShadow = true
    directionalLight.shadow.mapSize.width = 2048
    directionalLight.shadow.mapSize.height = 2048
    scene.add(directionalLight)

    const pointLight = new THREE.PointLight(0x6366f1, 0.7, 60)
    pointLight.position.set(0, 20, 0)
    scene.add(pointLight)

    // Board and pieces groups
    const boardGroup = new THREE.Group()
    boardGroupRef.current = boardGroup
    scene.add(boardGroup)

    const piecesGroup = new THREE.Group()
    piecesGroupRef.current = piecesGroup
    scene.add(piecesGroup)

    // Create board
    const hexSize = 1.5
    const boardRadius = 5

    const createHexTile = (hex: HexCoord, size: number) => {
      const pos = hexToWorldPos(hex, size)
      const key = `${hex.q},${hex.r}`

      const geometry = new THREE.CylinderGeometry(size, size, 0.12, 6)
      const material = new THREE.MeshStandardMaterial({
        color: 0x1f2937,
        metalness: 0.5,
        roughness: 0.5,
        emissive: 0x4f46e5,
        emissiveIntensity: 0.15,
      })

      const hexMesh = new THREE.Mesh(geometry, material)
      hexMesh.position.set(pos.x, 0, pos.y)
      hexMesh.rotation.x = Math.PI / 2
      hexMesh.castShadow = true
      hexMesh.receiveShadow = true
      hexMesh.userData = { hex: key }

      boardGroup.add(hexMesh)
      hexTilesRef.current.set(key, hexMesh)

      // Border
      const borderGeometry = new THREE.CylinderGeometry(size * 1.05, size * 1.05, 0.18, 6)
      const borderMaterial = new THREE.MeshStandardMaterial({
        color: 0x4f46e5,
        metalness: 0.6,
        roughness: 0.3,
        emissive: 0x818cf8,
        emissiveIntensity: 0.2,
      })

      const border = new THREE.Mesh(borderGeometry, borderMaterial)
      border.position.set(pos.x, -0.08, pos.y)
      border.rotation.x = Math.PI / 2
      boardGroup.add(border)
    }

    for (let q = -boardRadius; q <= boardRadius; q++) {
      for (let r = Math.max(-boardRadius, -q - boardRadius); r <= Math.min(boardRadius, -q + boardRadius); r++) {
        createHexTile({ q, r }, hexSize)
      }
    }

    // Add pieces from game state
    if (gameState.pieces && gameState.pieces.length > 0) {
      gameState.pieces.forEach((piece: PieceData) => {
        const mesh = createInsectPiece(piece.bug_type, piece.player)
        const pos = hexToWorldPos({ q: piece.q, r: piece.r }, hexSize)
        mesh.position.set(pos.x, 0.4, pos.y)
        mesh.userData = { piece_id: piece.id, ...piece }
        piecesGroup.add(mesh)

        // Hover bob animation
        gsap.to(mesh.position, { y: 0.7, duration: 2, yoyo: true, repeat: -1, ease: 'sine.inOut' })
      })
    } else {
      // Game just started - show demo pieces on board for testing
      const demoPieces = [
        { type: 'queen', player: 'white', q: 0, r: 0 },
        { type: 'ant', player: 'black', q: 1, r: 0 },
        { type: 'spider', player: 'white', q: -1, r: 1 },
        { type: 'beetle', player: 'black', q: 0, r: 1 },
      ]

      demoPieces.forEach((p) => {
        const mesh = createInsectPiece(p.type, p.player)
        const pos = hexToWorldPos({ q: p.q, r: p.r }, hexSize)
        mesh.position.set(pos.x, 0.4, pos.y)
        piecesGroup.add(mesh)
        gsap.to(mesh.position, { y: 0.7, duration: 2, yoyo: true, repeat: -1, ease: 'sine.inOut' })
      })
    }

    // Handle clicks
    const raycaster = new THREE.Raycaster()
    const mouse = new THREE.Vector2()

    const onMouseClick = async (event: MouseEvent) => {
      mouse.x = (event.clientX / window.innerWidth) * 2 - 1
      mouse.y = -(event.clientY / window.innerHeight) * 2 + 1

      raycaster.setFromCamera(mouse, camera)

      const hexes = Array.from(hexTilesRef.current.values())
      const intersects = raycaster.intersectObjects(hexes)

      if (intersects.length > 0) {
        const hex = intersects[0].object.userData.hex
        if (gameState?.valid_moves && gameState.valid_moves.length > 0) {
          const moveNotation = gameState.valid_moves[0]
          try {
            const response = await api.makeMove(gameId!, moveNotation)
            setGameState(response)
            addMove(moveNotation)
            const predictions = await api.predictMove(gameId!)
            setPredictions(predictions.top_moves.map(([move, prob]) => ({ move, probability: prob })))
          } catch (error) {
            console.error('Move failed:', error)
          }
        }
      }
    }

    window.addEventListener('click', onMouseClick)

    // Handle resize
    const handleResize = () => {
      camera.aspect = window.innerWidth / window.innerHeight
      camera.updateProjectionMatrix()
      renderer.setSize(window.innerWidth, window.innerHeight)
    }
    window.addEventListener('resize', handleResize)

    // Animation loop
    let frameId: number
    const animate = () => {
      frameId = requestAnimationFrame(animate)
      renderer.render(scene, camera)
    }
    animate()

    return () => {
      window.removeEventListener('click', onMouseClick)
      window.removeEventListener('resize', handleResize)
      cancelAnimationFrame(frameId)
      renderer.dispose()
    }
  }, [gameState, gameId, setGameState, addMove, setPredictions])

  return (
    <canvas
      ref={canvasRef}
      style={{
        display: 'block',
        width: '100%',
        height: '100%',
        position: 'absolute',
        top: 0,
        left: 0,
      }}
    />
  )
}

function createInsectPiece(type: string, player: string): THREE.Mesh {
  const isWhite = player === 'white'
  const baseColor = isWhite ? 0xe0e7ff : 0x1e293b
  const glowColor = isWhite ? 0xa5b4fc : 0x475569

  const group = new THREE.Group() as any
  const material = new THREE.MeshStandardMaterial({
    color: baseColor,
    metalness: 0.8,
    roughness: 0.2,
    emissive: glowColor,
    emissiveIntensity: 0.5,
  })

  let mesh: THREE.Mesh

  switch (type) {
    case 'queen': {
      const geometry = new THREE.OctahedronGeometry(0.4, 2)
      mesh = new THREE.Mesh(geometry, material)
      break
    }
    case 'ant': {
      const geometry = new THREE.ConeGeometry(0.25, 0.6, 8)
      mesh = new THREE.Mesh(geometry, material)
      mesh.scale.set(1, 0.8, 1)
      break
    }
    case 'beetle': {
      const geometry = new THREE.BoxGeometry(0.35, 0.25, 0.35)
      mesh = new THREE.Mesh(geometry, material)
      break
    }
    case 'grasshopper': {
      const geometry = new THREE.TetrahedronGeometry(0.35, 1)
      mesh = new THREE.Mesh(geometry, material)
      break
    }
    case 'spider': {
      const geometry = new THREE.IcosahedronGeometry(0.3, 3)
      mesh = new THREE.Mesh(geometry, material)
      // Add leg spikes
      for (let i = 0; i < 4; i++) {
        const legGeometry = new THREE.CylinderGeometry(0.05, 0.03, 0.4)
        const legMesh = new THREE.Mesh(legGeometry, material)
        legMesh.position.set(Math.cos(i * Math.PI / 2) * 0.3, -0.2, Math.sin(i * Math.PI / 2) * 0.3)
        legMesh.rotation.z = Math.PI / 4
        mesh.add(legMesh)
      }
      break
    }
    case 'mosquito': {
      const geometry = new THREE.ConeGeometry(0.15, 0.7, 6)
      mesh = new THREE.Mesh(geometry, material)
      mesh.scale.set(0.6, 1, 0.6)
      break
    }
    case 'ladybug': {
      const geometry = new THREE.IcosahedronGeometry(0.35, 2)
      mesh = new THREE.Mesh(geometry, material)
      // Add spots
      const spotGeometry = new THREE.SphereGeometry(0.08, 4, 4)
      const spotMaterial = new THREE.MeshStandardMaterial({
        color: 0xff0000,
        emissive: 0xff0000,
        emissiveIntensity: 0.3,
      })
      for (let i = 0; i < 3; i++) {
        const spot = new THREE.Mesh(spotGeometry, spotMaterial)
        spot.position.set((i - 1) * 0.15, 0.25, 0)
        mesh.add(spot)
      }
      break
    }
    case 'pillbug':
    default: {
      const geometry = new THREE.SphereGeometry(0.35, 8, 8)
      mesh = new THREE.Mesh(geometry, material)
      break
    }
  }

  mesh.castShadow = true
  mesh.receiveShadow = true
  mesh.userData = { type, player }

  return mesh
}

export default Board3D
