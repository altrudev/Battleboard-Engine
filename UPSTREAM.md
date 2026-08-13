# Upstream Engine Policy

Battleboard Engine is based on a pinned Godot upstream rather than a floating dependency.

## Current baseline

- Upstream project: Godot Engine
- Release: 4.7.1-stable
- Commit: a13da4feb8d8aefc283c3763d33a2f170a18d541

## Policy

1. Production builds must resolve to an exact upstream commit.
2. Battleboard-owned engine changes should remain isolated from upstream code wherever practical.
3. Upstream upgrades are explicit engineering changes, not automatic background updates.
4. Each proposed upgrade must be tested against deterministic board simulation, fighter data compatibility, affinity/resonance behavior, camera transitions, 3D runtime behavior, saves/replays, and export targets.
5. DDC/Calibration evidence should record the impact and verification of an upstream upgrade before it becomes the production baseline.
6. GitHub Actions are not required for the build or release path.

The project may initially consume upstream source plus an overlay/module layer. Deeper modifications to Godot internals should be introduced only where Battleboard requires engine-level behavior that cannot be cleanly implemented as modules, extensions, or editor tooling.
