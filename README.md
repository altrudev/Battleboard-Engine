# Battleboard Engine

Battleboard Engine is the reusable tactical runtime foundation for Battleboard, based on an exact pinned Godot 4.7.1-stable foundation.

## v0.4 deterministic runtime

v0.4 introduces a production-oriented simulation authority while preserving the v0.3 game-facing APIs:

- transactional board movement/capture with invariant validation;
- canonical snapshots and deterministic state/simulation hashes;
- explicit command and event contracts for replay and evidence;
- seeded deterministic RNG and headless combat resolution;
- timed status-effect lifecycle;
- formation-wide affinity/resonance graphs and tactical threat maps;
- deterministic multi-ply opponent planning;
- typed stat and ability resources with legacy profile compatibility;
- production `Skeleton3D` / `AnimationTree` character support with procedural fallback.

The campaign, recruitment, training, tournament progression and game content remain in `Battleboard-Game`.

## Headless smoke test

With Godot 4.7.1 available on PATH:

```bash
godot --headless --path . --script tests/runtime_smoke.gd
```

The runtime does not require GitHub Actions. Deterministic verification is intended to run locally, in DDC/Calibration workers, or in another explicitly controlled runner.
