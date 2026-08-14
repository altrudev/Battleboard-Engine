class_name BBFormationGraph
extends RefCounted

const ADJACENT_WEIGHT := 1.0
const NEAR_WEIGHT := 0.35

static func evaluate_side(state: BBBoardState, profiles: Dictionary, side: String) -> Dictionary:
	var ids: Array[String] = []
	for raw_id in state.cell_by_profile.keys():
		var profile_id := str(raw_id)
		if state.side_of(profile_id) == side and profiles.get(profile_id) is BBProfile:
			ids.append(profile_id)
	ids.sort()
	var edges: Array[Dictionary] = []
	var total := 0.0
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			var a_id := ids[i]
			var b_id := ids[j]
			var a_cell := state.cell_of(a_id)
			var b_cell := state.cell_of(b_id)
			var distance := maxi(abs(a_cell.x - b_cell.x), abs(a_cell.y - b_cell.y))
			if distance > 2:
				continue
			var affinity := BBAffinityEngine.evaluate(profiles[a_id], profiles[b_id])
			var weight := ADJACENT_WEIGHT if distance <= 1 else NEAR_WEIGHT
			var edge_score := float(affinity["score"]) * weight
			total += edge_score
			edges.append({
				"a": a_id,
				"b": b_id,
				"distance": distance,
				"score": edge_score,
				"raw_score": float(affinity["score"]),
				"resonance": str(affinity["resonance"]),
			})
	return {"side": side, "total": total, "edges": edges, "nodes": ids}

static func support_for(state: BBBoardState, profiles: Dictionary, profile_id: String, at_cell := Vector2i(-1, -1)) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var profile: BBProfile = profiles.get(profile_id)
	if profile == null:
		return result
	var origin := at_cell if state.inside(at_cell) else state.cell_of(profile_id)
	for raw_other in state.cell_by_profile.keys():
		var other_id := str(raw_other)
		if other_id == profile_id or state.side_of(other_id) != state.side_of(profile_id):
			continue
		var other_profile: BBProfile = profiles.get(other_id)
		if other_profile == null:
			continue
		var other_cell := state.cell_of(other_id)
		var distance := maxi(abs(other_cell.x - origin.x), abs(other_cell.y - origin.y))
		if distance > 2:
			continue
		var affinity := BBAffinityEngine.evaluate(profile, other_profile)
		var weight := ADJACENT_WEIGHT if distance <= 1 else NEAR_WEIGHT
		var score := float(affinity["score"]) * weight
		result.append({
			"profile_id": other_id,
			"distance": distance,
			"score": score,
			"affinity": affinity,
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary):
		if absf(float(a["score"]) - float(b["score"])) > 0.001:
			return float(a["score"]) > float(b["score"])
		return str(a["profile_id"]) < str(b["profile_id"])
	)
	return result

static func support_bonus(state: BBBoardState, profiles: Dictionary, profile_id: String, at_cell := Vector2i(-1, -1)) -> float:
	var total := 0.0
	for edge in support_for(state, profiles, profile_id, at_cell):
		total += maxf(0.0, float(edge["score"]))
	return total
