# Battleboard Engine

Battleboard Engine is the reusable runtime and presentation layer behind Battleboard.

## v0.2 visual-proof scope

The engine remains grounded in a deterministic board/participant model while adding the first replaceable 3D fighter presentation contract.

- pinned upstream: Godot `4.7.1-stable`
- deterministic 8x8 board state and movement rules
- fighter profiles with stats, position aptitudes, predispositions, experiences and relationships
- affinity/resonance evaluation
- tactical-to-direct encounter context
- `BBPieceVisual`: articulated procedural humanoid, named joints, weapon socket, role weapon silhouettes and procedural animation states

The primitive fighter meshes are not final art. Production glTF rigs can replace them without changing the board, recruitment or affinity systems.

No GitHub Actions are required for build or release.
