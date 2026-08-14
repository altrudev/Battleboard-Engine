class_name BBReplay
extends Resource

const SCHEMA_VERSION := 1

var engine_version := "0.4.0"
var seed := 1
var initial_board: Dictionary = {}
var commands: Array[Dictionary] = []
var expected_hashes: Array[String] = []

func begin(state: BBBoardState, replay_seed: int) -> void:
	seed = replay_seed
	initial_board = state.snapshot()
	commands.clear()
	expected_hashes.clear()

func record(command: Dictionary, simulation_hash: String) -> void:
	commands.append(command.duplicate(true))
	expected_hashes.append(simulation_hash)

func play(profiles: Dictionary) -> Dictionary:
	var initial_state := BBBoardState.new()
	initial_state.restore_snapshot(initial_board)
	var simulation := BBMatchSimulation.new()
	simulation.setup(initial_state, profiles, seed)
	var results: Array[Dictionary] = []
	for i in range(commands.size()):
		var result := simulation.apply_command(commands[i])
		results.append(result.duplicate(true))
		if not bool(result.get("ok", false)):
			return {"ok": false, "error": "command_failed:%d" % i, "results": results}
		if i < expected_hashes.size() and expected_hashes[i] != "" and str(result["simulation_hash"]) != expected_hashes[i]:
			return {
				"ok": false,
				"error": "hash_mismatch:%d" % i,
				"expected": expected_hashes[i],
				"actual": result["simulation_hash"],
				"results": results,
			}
	return {"ok": true, "results": results, "simulation": simulation}

func to_dictionary() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"engine_version": engine_version,
		"seed": seed,
		"initial_board": initial_board.duplicate(true),
		"commands": commands.duplicate(true),
		"expected_hashes": expected_hashes.duplicate(),
	}

static func from_dictionary(data: Dictionary) -> BBReplay:
	var replay := BBReplay.new()
	replay.engine_version = str(data.get("engine_version", ""))
	replay.seed = int(data.get("seed", 1))
	replay.initial_board = data.get("initial_board", {}).duplicate(true)
	replay.commands.assign(data.get("commands", []))
	replay.expected_hashes.assign(data.get("expected_hashes", []))
	return replay
