# Battleboard Engine

Battleboard Engine is the production runtime foundation for the Battleboard tactical action RPG.

It is designed around a pinned Godot upstream plus Battleboard-owned deterministic systems for board simulation, fighters, affinity/resonance, third-person combat, board-to-duel transitions, AI, and production validation.

## Architecture

```text
Godot 4.7.1-stable (pinned upstream)
        |
        v
Battleboard Engine overlay
        |
        +-- deterministic BattleCore
        +-- fighter runtime
        +-- affinity / predisposition / resonance graph
        +-- combat runtime
        +-- board <-> duel transition system
        +-- camera runtime
        +-- AI interfaces
        +-- editor tooling
        +-- DDC / Calibration evidence hooks
        |
        v
Battleboard Game
```

## Upstream pin

- Project: Godot Engine
- Release: `4.7.1-stable`
- Commit: `a13da4feb8d8aefc283c3763d33a2f170a18d541`
- Upstream repository: `godotengine/godot`

The upstream source is not treated as a floating dependency. See `UPSTREAM.md`.

## Repository policy

- No GitHub Actions are required for build or release.
- Engine changes must remain separable from upstream Godot changes.
- BattleCore rules should remain deterministic and testable without rendering.
- Visual systems consume simulation results; they do not become the source of truth for game state.
- Save/replay schema changes must be versioned.
- Third-party code and assets must retain their applicable notices and licences.

## Initial milestone

The first vertical slice is intentionally narrow:

1. 8x8 3D board.
2. Four controllable fighters.
3. Legal board movement.
4. Position support and affinity evaluation.
5. Attack creates a `CombatContext`.
6. Seamless tactical-camera to third-person-duel transition.
7. Playable 1v1 combat.
8. One visible affinity/support intervention.
9. Combat result resolves board occupancy.
10. Camera returns to tactical view.

The first proof is successful when moving a fighter on the board and becoming that fighter in combat feels like one continuous game, not two disconnected modes.
