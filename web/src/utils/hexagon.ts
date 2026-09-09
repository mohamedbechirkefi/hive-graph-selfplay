// Axial coordinate system for hexagonal grids
export interface HexCoord {
  q: number
  r: number
}

export interface CubeCoord {
  x: number
  y: number
  z: number
}

// Convert axial to cube coordinates
export function axialToCube(q: number, r: number): CubeCoord {
  const x = q
  const z = r
  const y = -x - z
  return { x, y, z }
}

// Convert cube to axial coordinates
export function cubeToAxial(x: number, y: number, z: number): HexCoord {
  return { q: x, r: z }
}

// Get neighboring hex in a direction (0-5)
export function getNeighbor(hex: HexCoord, direction: number): HexCoord {
  const directions = [
    { q: 1, r: 0 },   // East
    { q: 1, r: -1 },  // Northeast
    { q: 0, r: -1 },  // Northwest
    { q: -1, r: 0 },  // West
    { q: -1, r: 1 },  // Southwest
    { q: 0, r: 1 },   // Southeast
  ]
  const dir = directions[direction % 6]
  return { q: hex.q + dir.q, r: hex.r + dir.r }
}

// Get distance between two hexes
export function hexDistance(a: HexCoord, b: HexCoord): number {
  const ca = axialToCube(a.q, a.r)
  const cb = axialToCube(b.q, b.r)
  return (Math.abs(ca.x - cb.x) + Math.abs(ca.y - cb.y) + Math.abs(ca.z - cb.z)) / 2
}

// Get all hexes within radius
export function hexesInRadius(center: HexCoord, radius: number): HexCoord[] {
  const results: HexCoord[] = []
  for (let q = -radius; q <= radius; q++) {
    for (let r = Math.max(-radius, -q - radius); r <= Math.min(radius, -q + radius); r++) {
      results.push({ q: center.q + q, r: center.r + r })
    }
  }
  return results
}

// Convert hex coordinates to 3D position for rendering
const SQRT3 = Math.sqrt(3)

export function hexToWorldPos(
  hex: HexCoord,
  hexSize: number = 1.5
): { x: number; y: number } {
  const x = hexSize * (SQRT3 / 2 * hex.q + SQRT3 / 2 * hex.r)
  const y = hexSize * (3 / 2 * hex.r)
  return { x, y }
}

// Convert world position to hex coordinates
export function worldPosToHex(
  x: number,
  y: number,
  hexSize: number = 1.5
): HexCoord {
  const q = (SQRT3 / 3 * x - 1 / 3 * y) / hexSize
  const r = (2 / 3 * y) / hexSize
  return axialRound(q, r)
}

// Round axial coordinates to nearest hex
function axialRound(q: number, r: number): HexCoord {
  let rq = Math.round(q)
  let rr = Math.round(r)
  const rs = Math.round(-q - r)

  const qDiff = Math.abs(rq - q)
  const rDiff = Math.abs(rr - r)
  const sDiff = Math.abs(rs - (-q - r))

  if (qDiff > rDiff && qDiff > sDiff) {
    rq = -rr - rs
  } else if (rDiff > sDiff) {
    rr = -rq - rs
  }

  return { q: rq, r: rr }
}

// Get ring of hexes at distance from center
export function hexRing(center: HexCoord, radius: number): HexCoord[] {
  if (radius === 0) return [center]

  const results: HexCoord[] = []
  let cube = axialToCube(center.q, center.r)
  cube.x += radius
  cube.z -= radius

  const directions = [
    { x: -1, y: 1, z: 0 },
    { x: -1, y: 0, z: 1 },
    { x: 0, y: -1, z: 1 },
    { x: 1, y: -1, z: 0 },
    { x: 1, y: 0, z: -1 },
    { x: 0, y: 1, z: -1 },
  ]

  for (const dir of directions) {
    for (let i = 0; i < radius; i++) {
      results.push(cubeToAxial(cube.x, cube.y, cube.z))
      cube.x += dir.x
      cube.y += dir.y
      cube.z += dir.z
    }
  }

  return results
}
