extends SceneTree

var failures := 0

func _init() -> void:
	_test_transactional_capture()
	_test_deterministic_simulation()
	_test_replay_roundtrip()
	_test_ability_status_resolution()
	_test_planner_repeatability()
	_test_profile_schema()
	if failures > 0:
		push_error("Battleboard Engine smoke tests failed: %d" % failures)
		quit(1)
		return
	print("Battleboard Engine smoke tests passed")
	quit(0)

func _test_transactional_capture() -> void:
	var state := BBBoardState.new()
	state.register_profile("alpha", Vector2i(0, 0), "rook", "player")
	state.register_profile("beta", Vector2i(0, 2), "pawn", "rival")
	var result := state.apply_move("alpha", Vector2i(0, 2))
	_check(bool(result["ok"]), "capture move succeeds")
	_check(str(result["captured_id"]) == "beta", "capture reports defeated profile")
	_check(not state.cell_by_profile.has("beta"), "captured profile removed from reverse lookup")
	_check(state.occupant(Vector2i(0, 2)) == "alpha", "destination owned by attacker")
	_check(bool(state.validate_invariants()["ok"]), "board invariants survive capture")

func _test_deterministic_simulation() -> void:
	var state := BBBoardState.new()
	state.register_profile("alpha", Vector2i(0, 0), "rook", "player")
	state.register_profile("beta", Vector2i(0, 1), "rook", "rival")
	var profiles := {
		"alpha": _profile("alpha", [72, 68, 61, 64]),
		"beta": _profile("beta", [65, 70, 58, 69]),
	}
	var command := BBMatchCommand.engage("alpha", Vector2i(0, 1))
	var first := BBMatchSimulation.new()
	first.setup(state, profiles, 314159)
	var first_result := first.apply_command(command)
	var second := BBMatchSimulation.new()
	second.setup(state, profiles, 314159)
	var second_result := second.apply_command(command)
	_check(bool(first_result["ok"]) and bool(second_result["ok"]), "deterministic engagement executes")
	_check(first_result["simulation_hash"] == second_result["simulation_hash"], "same seed produces same simulation hash")
	_check(first.event_log == second.event_log, "same seed produces same event log")

func _test_replay_roundtrip() -> void:
	var state := BBBoardState.new()
	state.register_profile("alpha", Vector2i(0, 0), "rook", "player")
	state.register_profile("beta", Vector2i(7, 7), "rook", "rival")
	var profiles := {
		"alpha": _profile("alpha", [60, 60, 60, 60]),
		"beta": _profile("beta", [60, 60, 60, 60]),
	}
	var command := BBMatchCommand.move("alpha", Vector2i(0, 1))
	var simulation := BBMatchSimulation.new()
	simulation.setup(state, profiles, 4242)
	var replay := BBReplay.new()
	replay.begin(state, 4242)
	var result := simulation.apply_command(command)
	_check(bool(result["ok"]), "replay source command executes")
	if bool(result["ok"]):
		replay.record(command, str(result["simulation_hash"]))
		var replay_result := replay.play(profiles)
		_check(bool(replay_result["ok"]), "recorded command replays with matching hash")

func _test_ability_status_resolution() -> void:
	var attacker := _profile("caster", [180, 120, 100, 80])
	var defender := _profile("target", [20, 20, 20, 20])
	var ability := BBAbilityDefinition.from_dictionary({
		"id": "break_guard",
		"name": "Break Guard",
		"power_multiplier": 1.25,
		"status_effects": [{
			"id": "guard_broken",
			"target": "defender",
			"duration": 2,
			"potency": -15.0,
			"modifier": "guard",
		}],
	})
	var statuses: Dictionary = {}
	var result := BBAbilitySystem.resolve(attacker, defender, ability, BBDeterministicRNG.new(1), statuses)
	_check(bool(result["ok"]), "ability resolver executes")
	_check(statuses.has("target"), "winning deterministic ability applies target status")
	_check(BBStatusSystem.modifier(statuses, "target", "guard") == -15.0, "status modifier is queryable")

func _test_planner_repeatability() -> void:
	var state := BBBoardState.new()
	state.register_profile("p_rook", Vector2i(0, 0), "rook", "player")
	state.register_profile("p_king", Vector2i(4, 0), "king", "player")
	state.register_profile("r_rook", Vector2i(7, 7), "rook", "rival")
	state.register_profile("r_king", Vector2i(4, 7), "king", "rival")
	var profiles := {
		"p_rook": _profile("p_rook", [60, 60, 60, 60]),
		"p_king": _profile("p_king", [70, 65, 50, 75]),
		"r_rook": _profile("r_rook", [62, 61, 60, 63]),
		"r_king": _profile("r_king", [68, 66, 52, 74]),
	}
	var first := BBTacticalPlanner.choose_move(state, profiles, "rival")
	var second := BBTacticalPlanner.choose_move(state, profiles, "rival")
	_check(not first.is_empty(), "planner finds a rival move")
	_check(first == second, "planner returns identical decision for identical state")

func _test_profile_schema() -> void:
	var profile := _profile("schema", [55, 60, 65, 70])
	var validation := profile.validate_schema()
	_check(bool(validation["ok"]), "profile schema accepts valid legacy-compatible profile")
	_check(int(profile.to_dictionary()["schema_version"]) == BBProfile.SCHEMA_VERSION, "profile serialization emits current schema")

func _profile(profile_id: String, values: Array) -> BBProfile:
	return BBProfile.from_dictionary({
		"id": profile_id,
		"name": profile_id,
		"level": 2,
		"stats": {
			"power": values[0],
			"technique": values[1],
			"speed": values[2],
			"guard": values[3],
		},
		"aptitudes": {"rook": 65.0, "king": 62.0},
		"predispositions": ["disciplined"],
		"experiences": ["qualifier"],
	})

func _check(condition: bool, label: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % label)
