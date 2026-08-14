# Battleboard Engine Architecture

Version 0.2 keeps the deterministic rules layer independent from scene rendering and adds a replaceable presentation contract for the first visual proof.

## Runtime boundaries

- `BBProfile`: persistent participant identity, stats, position aptitudes, predispositions, experiences and relationships.
- `BBAffinityEngine`: derives chemistry/resonance from two profiles without scene dependencies.
- `BBBoardState`: authoritative 8x8 occupancy, roles and sides.
- `BBBoardRules`: legal movement based on the currently assigned board position.
- `BBEncounterContext`: handoff information between tactical board mode and the direct 3D encounter layer.

## Presentation boundary

- `BBPieceVisual`: asset-independent articulated humanoid rig with named joints, role-specific weapon construction, a right-hand weapon socket, tactical silhouette palettes and procedural animation states (`idle`, `run`, `attack`, `technique`, `parry`, `dodge`, `hit`, `support`, `down`).

The primitive meshes are deliberately replaceable. A production glTF character can implement the same public presentation API without changing board, affinity, recruitment or encounter rules.

Rendering remains non-authoritative: board occupancy, roles, relationships, support and encounter results are still owned by deterministic state.

## Promotion path

The addon remains isolated so stable runtime and presentation interfaces can later be promoted into native Godot modules/GDExtension code without changing game-facing data contracts.
