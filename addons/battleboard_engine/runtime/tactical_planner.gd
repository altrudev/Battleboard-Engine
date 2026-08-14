class_name BBTacticalPlanner
extends RefCounted

const ROLE_VALUE := {"king": 1000.0, "queen": 90.0, "rook": 62.0, "bishop": 48.0, "knight": 48.0, "pawn": 22.0}

static func choose_move(state: BBBoardState, profiles: Dictionary, side := "rival") -> Dictionary:
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
		moves.sort_custom(func(a: Vector2i, b: Vector2i): return a.y * 8 + a.x < b.y * 8 + b.x)
		for destination in moves:
			var target_id := state.occupant(destination)
			var score := _position_score(destination)
			score += profile.aptitude_for(state.role_of(profile_id)) * 0.08
			if target_id != "":
				score += ROLE_VALUE.get(state.role_of(target_id), 20.0)
				var target: BBProfile = profiles.get(target_id)
				if target != null:
					score += _matchup(profile, target) * 0.18
			score += _support_projection(state, profiles, profile_id, destination) * 0.10
			candidates.append({
				"profile_id": profile_id,
				"origin": origin,
				"destination": destination,
				"target_id": target_id,
				"score": score,
			})
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary):
		if absf(float(a["score"]) - float(b["score"])) > 0.001:
			return float(a["score"]) > float(b["score"])
		var ad: Vector2i = a["destination"]
		var bd: Vector2i = b["destination"]
		var ak := "%s:%02d" % [str(a["profile_id"]), ad.y * 8 + ad.x]
		var bk := "%s:%02d" % [str(b["profile_id"]), bd.y * 8 + bd.x]
		return ak < bk
	)
	return candidates[0]

static func _position_score(cell: Vector2i) -> float:
	var dx := absf(float(cell.x) - 3.5)
	var dy := absf(float(cell.y) - 3.5)
	return 12.0 - (dx + dy) * 1.4

static func _matchup(a: BBProfile, b: BBProfile) -> float:
	var a_total := a.stat("power") + a.stat("technique") + a.stat("speed") + a.stat("guard")
	var b_total := b.stat("power") + b.stat("technique") + b.stat("speed") + b.stat("guard")
	return (a_total - b_total) / 4.0

static func _support_projection(state: BBBoardState, profiles: Dictionary, profile_id: String, destination: Vector2i) -> float:
	var a: BBProfile = profiles.get(profile_id)
	if a == null:
		return 0.0
	var score := 0.0
	for raw_other in state.cell_by_profile.keys():
		var other_id := str(raw_other)
		if other_id == profile_id or state.side_of(other_id) != state.side_of(profile_id):
			continue
		var other_cell := state.cell_of(other_id)
		if maxi(abs(other_cell.x - destination.x), abs(other_cell.y - destination.y)) <= 1:
			var b: BBProfile = profiles.get(other_id)
			if b != null:
				score += maxf(0.0, float(BBAffinityEngine.evaluate(a, b)["score"]))
	return score
