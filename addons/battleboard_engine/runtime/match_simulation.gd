class_name BBMatchSimulation
extends RefCounted

var state := BBBoardState.new()
var profiles: Dictionary = {}
var rng := BBDeterministicRNG.new(1)
var statuses: Dictionary = {}
var event_log: Array[Dictionary] = []
var turn_index := 0

func setup(initial_state: BBBoardState, initial_profiles: Dictionary, seed := 1) -> void:
	state = initial_state.clone()
	profiles = initial_profiles.duplicate()
	rng = BBDeterministicRNG.new(seed)
	statuses.clear()
	event_log.clear()
	turn_index = 0

func apply_command(command: Dictionary) -> Dictionary:
	var shape := BBMatchCommand.validate(command)
	if not bool(shape["ok"]):
		return _failure("invalid_command:%s" % ",".join(PackedStringArray(shape["errors"])))
	var profile_id := str(command.get("profile_id", ""))
	if not state.cell_by_profile.has(profile_id):
		return _failure("profile_not_on_board")
	if not profiles.has(profile_id):
		return _failure("profile_data_missing")
	var before := snapshot()
	var start_event := event_log.size()
	var command_type := str(command["type"])
	match command_type:
		BBMatchCommand.MOVE:
			var move_result := _apply_move(profile_id, command["destination"])
			if not bool(move_result["ok"]):
				return _rollback_failure(before, str(move_result.get("error", "move_failed")))
		BBMatchCommand.ENGAGE:
			var engage_result := _apply_engagement(profile_id, command["destination"])
			if not bool(engage_result["ok"]):
				return _rollback_failure(before, str(engage_result.get("error", "engagement_failed")))
		BBMatchCommand.WAIT:
			_append_event("WAIT", {"profile_id": profile_id})
		_:
			return _rollback_failure(before, "unsupported_command")
	turn_index += 1
	for expired in BBStatusSystem.tick(statuses):
		_append_event("STATUS_EXPIRED", expired)
	var invariant := state.validate_invariants()
	if not bool(invariant["ok"]):
		return _rollback_failure(before, "post_command_invariant:%s" % ",".join(PackedStringArray(invariant["errors"])))
	return {
		"ok": true,
		"events": event_log.slice(start_event, event_log.size()),
		"state_hash": state.state_hash(),
		"simulation_hash": simulation_hash(),
	}

func preview_command(command: Dictionary) -> Dictionary:
	var copy := clone()
	var result := copy.apply_command(command)
	result["simulation"] = copy
	return result

func clone() -> BBMatchSimulation:
	var copy := BBMatchSimulation.new()
	copy.state = state.clone()
	copy.profiles = profiles.duplicate()
	copy.rng = rng.clone()
	copy.statuses = statuses.duplicate(true)
	copy.event_log = event_log.duplicate(true)
	copy.turn_index = turn_index
	return copy

func snapshot() -> Dictionary:
	return {
		"board": state.snapshot(),
		"rng": rng.snapshot(),
		"statuses": statuses.duplicate(true),
		"turn_index": turn_index,
		"events": event_log.duplicate(true),
	}

func restore_snapshot(data: Dictionary) -> void:
	state.restore_snapshot(data.get("board", {}))
	rng.restore_snapshot(data.get("rng", {}))
	statuses = data.get("statuses", {}).duplicate(true)
	turn_index = int(data.get("turn_index", 0))
	event_log.assign(data.get("events", []))

func simulation_hash() -> String:
	var rows: Array[String] = [state.canonical_string(), "turn:%d" % turn_index, "rng:%d" % rng.state]
	var profile_ids: Array[String] = []
	for raw_id in statuses.keys():
		profile_ids.append(str(raw_id))
	profile_ids.sort()
	for profile_id in profile_ids:
		var profile_statuses: Dictionary = statuses[profile_id]
		var status_ids: Array[String] = []
		for raw_status_id in profile_statuses.keys():
			status_ids.append(str(raw_status_id))
		status_ids.sort()
		for status_id in status_ids:
			var entry: Dictionary = profile_statuses[status_id]
			rows.append("status:%s:%s:%d:%.4f" % [profile_id, status_id, int(entry.get("duration", 0)), float(entry.get("potency", 0.0))])
	return "\n".join(PackedStringArray(rows)).sha256_text()

func _apply_move(profile_id: String, destination: Vector2i) -> Dictionary:
	if destination not in BBBoardRules.legal_moves(state, profile_id):
		return {"ok": false, "error": "illegal_move"}
	if state.occupant(destination) != "":
		return {"ok": false, "error": "engagement_required"}
	var origin := state.cell_of(profile_id)
	var move_result := state.apply_move(profile_id, destination)
	if not bool(move_result["ok"]):
		return {"ok": false, "error": str(move_result["error"])}
	_append_event("MOVE", {
		"profile_id": profile_id,
		"origin": [origin.x, origin.y],
		"destination": [destination.x, destination.y],
	})
	return {"ok": true}

func _apply_engagement(profile_id: String, destination: Vector2i) -> Dictionary:
	if destination not in BBBoardRules.legal_moves(state, profile_id):
		return {"ok": false, "error": "illegal_engagement"}
	var target_id := state.occupant(destination)
	if target_id == "":
		return {"ok": false, "error": "engagement_target_missing"}
	if state.side_of(target_id) == state.side_of(profile_id):
		return {"ok": false, "error": "engagement_target_friendly"}
	var attacker: BBProfile = profiles.get(profile_id)
	var defender: BBProfile = profiles.get(target_id)
	if attacker == null or defender == null:
		return {"ok": false, "error": "engagement_profile_missing"}
	var attacker_support := BBFormationGraph.support_bonus(state, profiles, profile_id, destination) * 0.04
	var defender_support := BBFormationGraph.support_bonus(state, profiles, target_id) * 0.04
	var combat := BBCombatResolver.resolve(attacker, defender, rng, attacker_support, defender_support)
	_append_event("ENGAGE", {
		"attacker_id": profile_id,
		"defender_id": target_id,
		"destination": [destination.x, destination.y],
		"attacker_win_probability": combat["attacker_win_probability"],
		"roll": combat["roll"],
		"winner_id": combat["winner_id"],
		"loser_id": combat["loser_id"],
	})
	if bool(combat["attacker_won"]):
		var origin := state.cell_of(profile_id)
		var move_result := state.apply_move(profile_id, destination)
		if not bool(move_result["ok"]):
			return {"ok": false, "error": str(move_result["error"])}
		_append_event("DOWNED", {"profile_id": target_id, "by": profile_id})
		_append_event("MOVE", {
			"profile_id": profile_id,
			"origin": [origin.x, origin.y],
			"destination": [destination.x, destination.y],
		})
	else:
		state.remove_profile(profile_id)
		_append_event("DOWNED", {"profile_id": profile_id, "by": target_id})
	return {"ok": true, "combat": combat}

func _append_event(event_type: String, payload: Dictionary = {}) -> void:
	event_log.append(BBMatchEvent.make(event_log.size(), event_type, payload))

func _rollback_failure(before: Dictionary, reason: String) -> Dictionary:
	restore_snapshot(before)
	return _failure(reason)

func _failure(reason: String) -> Dictionary:
	return {
		"ok": false,
		"error": reason,
		"state_hash": state.state_hash(),
		"simulation_hash": simulation_hash(),
	}
