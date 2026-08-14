# Battleboard Engine architecture

## Authority boundary

Battleboard's logical state is authoritative. Presentation consumes state and never owns it.

## Runtime modules

- `BBProfile`: persistent fighter identity, statistics, aptitude, predisposition, experience, traits and relationships.
- `BBBoardState`: deterministic occupancy, side and board-role state.
- `BBBoardRules`: legal movement for the six board roles.
- `BBAffinityEngine`: pairwise chemistry and resonance classification.
- `BBEncounterContext`: board-to-direct-control handoff data.
- `BBTacticalPlanner`: deterministic candidate-move evaluation for automated boards.
- `BBPieceVisual`, `BBPieceRig`, `BBPiecePose`: replaceable procedural presentation layer.

The game repository may replace procedural presentation with imported glTF characters without changing authoritative tactical state.
