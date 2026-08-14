class_name BBThreatMap
extends RefCounted

static func build(state: BBBoardState, side: String) -> Dictionary:
	var result: Dictionary = {}
	var ids: Array[String] = []
	for raw_id in state.cell_by_profile.keys():
		var profile_id := str(raw_id)
		if state.side_of(profile_id) == side:
			ids.append(profile_id)
	ids.sort()
	for profile_id in ids:
		for cell in BBBoardRules.attack_cells(state, profile_id):
			var attackers: Array = result.get(cell, [])
			attackers.append(profile_id)
			result[cell] = attackers
	return result

static func pressure_at(state: BBBoardState, side: String, cell: Vector2i) -> int:
	var attackers: Array = build(state, side).get(cell, [])
	return attackers.size()

static func attackers_at(state: BBBoardState, side: String, cell: Vector2i) -> Array[String]:
	var result: Array[String] = []
	for raw_id in build(state, side).get(cell, []):
		result.append(str(raw_id))
	return result

static func total_pressure(state: BBBoardState, side: String) -> int:
	var total := 0
	for raw_attackers in build(state, side).values():
		var attackers: Array = raw_attackers
		total += attackers.size()
	return total
