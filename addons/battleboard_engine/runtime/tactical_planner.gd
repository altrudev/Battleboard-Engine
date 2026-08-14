class_name BBTacticalPlanner
extends RefCounted

const ROLE_VALUE := {"king": 1000.0, "queen": 90.0, "rook": 62.0, "bishop": 48.0, "knight": 48.0, "pawn": 22.0}

static func choose_move(state: BBBoardState, profiles: Dictionary, side := "rival", depth := 2, beam_width := 12) -> Dictionary:
	var candidates := _ranked_candidates(state, profiles, side)
	if candidates.is_empty():
		return {}
	var best: Dictionary = {}
	var best_score := -1.0e20
	var limit := mini(beam_width, candidates.size())
	for i in range(limit):
		var candidate: Dictionary = candidates[i].duplicate(true)
		var projected := state.clone()
		_project_action(projected, profiles, candidate)
		var future := _search(projected, profiles, side, _opponent(side), maxi(0, depth - 1), beam_width)
		var score := future + float(candidate["immediate_score"]) * 0.22
		candidate["score"] = score
		if best.is_empty() or score > best_score + 0.001 or (absf(score - best_score) <= 0.001 and _candidate_key(candidate) < _candidate_key(best)):
			best = candidate
			best_score = score
	return best

static func _search(state: BBBoardState, profiles: Dictionary, root_side: String, current_side: String, depth: int, beam_width: int) -> float:
	if depth <= 0 or _side_count(state, root_side) == 0 or _side_count(state, _opponent(root_side)) == 0:
		return _evaluate_position(state, profiles, root_side)
	var candidates := _ranked_candidates(state, profiles, current_side)
	if candidates.is_empty():
		return _evaluate_position(state, profiles, root_side)
	var maximizing := current_side == root_side
	var best := -1.0e20 if maximizing else 1.0e20
	var limit := mini(beam_width, candidates.size())
	for i in range(limit):
		var projected := state.clone()
		_project_action(projected, profiles, candidates[i])
		var value := _search(projected, profiles, root_side, _opponent(current_side), depth - 1, beam_width)
		if maximizing:
			best = maxf(best, value)
		else:
			best = minf(best, value)
	return best

static func _ranked_candidates(state: BBBoardState, profiles: Dictionary, side: String) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var ids: Array[String] = []
	for raw_id in state.cell_by_profile.keys():
		var profile_id := str(raw_id)
		if state.side_of(profile_id) == side:
			ids.append(profile_id)
	ids.sort()
	for profile_id in ids:
		var profile: BBProfile = profiles.get(profile_id)
		if profile == null:
			continue
		var origin := state.cell_of(profile_id)
		var moves := BBBoardRules.legal_moves(state, profile_id)
		moves.sort_custom(func(a: Vector2i, b: Vector2i): return a.y * BBBoardState.SIZE + a.x < b.y * BBBoardState.SIZE + b.x)
		for destination in moves:
			var target_id := state.occupant(destination)
			candidates.append({
				"profile_id": profile_id,
				"origin": origin,
				"destination": destination,
				"target_id": target_id,
				"immediate_score": _action_score(state, profiles, profile_id, destination, target_id),
			})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary):
		if absf(float(a["immediate_score"]) - float(b["immediate_score"])) > 0.001:
			return float(a["immediate_score"]) > float(b["immediate_score"])
		return _candidate_key(a) < _candidate_key(b)
	)
	return candidates

static func _action_score(state: BBBoardState, profiles: Dictionary, profile_id: String, destination: Vector2i, target_id: String) -> float:
	var profile: BBProfile = profiles.get(profile_id)
	if profile == null:
		return -10000.0
	var score := _position_score(destination)
	score += profile.aptitude_for(state.role_of(profile_id)) * 0.08
	score += BBFormationGraph.support_bonus(state, profiles, profile_id, destination) * 0.10
	var enemy_side := _opponent(state.side_of(profile_id))
	score -= float(BBThreatMap.pressure_at(state, enemy_side, destination)) * 7.5
	if target_id != "":
		var target: BBProfile = profiles.get(target_id)
		if target != null:
			var attacker_support := BBFormationGraph.support_bonus(state, profiles, profile_id, destination) * 0.04
			var defender_support := BBFormationGraph.support_bonus(state, profiles, target_id) * 0.04
			var estimate := BBCombatResolver.estimate(profile, target, attacker_support, defender_support)
			var win_probability := float(estimate["attacker_win_probability"])
			var target_value := float(ROLE_VALUE.get(state.role_of(target_id), 20.0))
			var own_value := float(ROLE_VALUE.get(state.role_of(profile_id), 20.0))
			score += target_value * win_probability
			score -= own_value * (1.0 - win_probability) * 0.72
			score += _matchup(profile, target) * 0.10
	return score

static func _project_action(state: BBBoardState, profiles: Dictionary, candidate: Dictionary) -> void:
	var profile_id := str(candidate["profile_id"])
	var destination: Vector2i = candidate["destination"]
	var target_id := state.occupant(destination)
	if target_id == "":
		state.apply_move(profile_id, destination)
		return
	var attacker: BBProfile = profiles.get(profile_id)
	var defender: BBProfile = profiles.get(target_id)
	if attacker == null or defender == null:
		state.apply_move(profile_id, destination)
		return
	var attacker_support := BBFormationGraph.support_bonus(state, profiles, profile_id, destination) * 0.04
	var defender_support := BBFormationGraph.support_bonus(state, profiles, target_id) * 0.04
	var estimate := BBCombatResolver.estimate(attacker, defender, attacker_support, defender_support)
	if float(estimate["attacker_win_probability"]) >= 0.5:
		state.apply_move(profile_id, destination)
	else:
		state.remove_profile(profile_id)

static func _evaluate_position(state: BBBoardState, profiles: Dictionary, root_side: String) -> float:
	var enemy_side := _opponent(root_side)
	var score := 0.0
	for raw_id in state.cell_by_profile.keys():
		var profile_id := str(raw_id)
		var profile: BBProfile = profiles.get(profile_id)
		if profile == null:
			continue
		var sign := 1.0 if state.side_of(profile_id) == root_side else -1.0
		var role := state.role_of(profile_id)
		score += sign * float(ROLE_VALUE.get(role, 20.0))
		score += sign * profile.aptitude_for(role) * 0.06
		score += sign * _position_score(state.cell_of(profile_id)) * 0.55
	var root_formation := BBFormationGraph.evaluate_side(state, profiles, root_side)
	var enemy_formation := BBFormationGraph.evaluate_side(state, profiles, enemy_side)
	score += (float(root_formation["total"]) - float(enemy_formation["total"])) * 0.08
	score += float(BBThreatMap.total_pressure(state, root_side) - BBThreatMap.total_pressure(state, enemy_side)) * 0.35
	var root_king := _king_cell(state, root_side)
	var enemy_king := _king_cell(state, enemy_side)
	if state.inside(root_king) and BBBoardRules.is_square_attacked(state, root_king, enemy_side):
		score -= 75.0
	if state.inside(enemy_king) and BBBoardRules.is_square_attacked(state, enemy_king, root_side):
		score += 75.0
	return score

static func _position_score(cell: Vector2i) -> float:
	var center := (float(BBBoardState.SIZE) - 1.0) * 0.5
	var dx := absf(float(cell.x) - center)
	var dy := absf(float(cell.y) - center)
	return 12.0 - (dx + dy) * 1.4

static func _matchup(a: BBProfile, b: BBProfile) -> float:
	var a_total := a.stat("power") + a.stat("technique") + a.stat("speed") + a.stat("guard")
	var b_total := b.stat("power") + b.stat("technique") + b.stat("speed") + b.stat("guard")
	return (a_total - b_total) / 4.0

static func _candidate_key(candidate: Dictionary) -> String:
	var destination: Vector2i = candidate.get("destination", Vector2i(-1, -1))
	return "%s:%03d" % [str(candidate.get("profile_id", "")), destination.y * BBBoardState.SIZE + destination.x]

static func _side_count(state: BBBoardState, side: String) -> int:
	var count := 0
	for raw_id in state.cell_by_profile.keys():
		if state.side_of(str(raw_id)) == side:
			count += 1
	return count

static func _king_cell(state: BBBoardState, side: String) -> Vector2i:
	for raw_id in state.cell_by_profile.keys():
		var profile_id := str(raw_id)
		if state.side_of(profile_id) == side and state.role_of(profile_id) == "king":
			return state.cell_of(profile_id)
	return Vector2i(-1, -1)

static func _opponent(side: String) -> String:
	return "player" if side == "rival" else "rival"
