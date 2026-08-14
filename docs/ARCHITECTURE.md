# Battleboard Engine architecture

## Authority boundary

Battleboard's logical state is authoritative. Presentation consumes state and never owns it. In v0.4, state transitions intended for deterministic/headless play flow through `BBMatchSimulation`; the existing game-facing board APIs remain compatible while the demo migrates to the simulation authority.

## Runtime modules

### Fighter data

- `BBProfile`: persistent fighter identity, statistics, aptitude, predisposition, experience, traits, relationships, equipment and abilities. Legacy dictionary access is retained for compatibility.
- `BBStatBlock`: typed core combat statistics.
- `BBAbilityDefinition`: typed ability contract.

### Board and tactical state

- `BBBoardState`: deterministic occupancy, side and board-role state, transactional capture/movement, snapshots, invariant validation and state hashes.
- `BBBoardRules`: legal movement plus attacked-square calculation for the six board roles.
- `BBThreatMap`: deterministic attack pressure and attacker lookup.
- `BBAffinityEngine`: pairwise chemistry and resonance classification.
- `BBFormationGraph`: board-position-aware resonance network and support projection.

### Deterministic simulation

- `BBMatchCommand`: canonical move/engage/wait commands.
- `BBMatchEvent`: ordered event records for replay and evidence.
- `BBDeterministicRNG`: seeded reproducible random stream.
- `BBCombatResolver`: headless engagement estimate and resolution.
- `BBStatusSystem`: deterministic timed status lifecycle.
- `BBMatchSimulation`: command validation, authoritative state transitions, event logging, snapshots and simulation hashes.
- `BBTacticalPlanner`: deterministic multi-ply beam search over projected board states.
- `BBEncounterContext`: tactical-board to direct-control handoff data used by the game layer.

## Presentation boundary

- `BBPieceVisual`: stable presentation facade consumed by the game.
- `BBCharacterAdapter`: production `Skeleton3D` / `AnimationTree` / `AnimationPlayer` adapter with conventional equipment and UI sockets.
- `BBPieceRig` and `BBPiecePose`: deterministic procedural fallback for prototypes, missing assets, tests and diagnostics.

A profile may select a production character with `metadata.visual_scene`. If the scene is unavailable or incompatible, Battleboard falls back to the procedural rig without changing tactical state.

## Determinism contract

Given the same board snapshot, profile data, command sequence and RNG seed, the deterministic runtime must produce the same ordered event log and simulation hash. Any upstream Godot upgrade or Battleboard Engine change that violates this contract is a regression until explicitly versioned and migrated.

## Godot boundary

Battleboard Engine remains an addon/runtime layer on an exact pinned Godot release. Godot source changes should only be introduced when a required behavior cannot be implemented cleanly through GDScript, GDExtension, modules or editor tooling.
