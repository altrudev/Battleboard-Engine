class_name BBBoardRules
extends RefCounted

static func legal_moves(state: BBBoardState, profile_id: String) -> Array[Vector2i]:
	var origin := state.cell_of(profile_id)
	var role := state.role_of(profile_id)
	var side := state.side_of(profile_id)
	match role:
		"knight": return _jump_moves(state, profile_id, origin)
		"rook": return _ray_moves(state, profile_id, origin, [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)])
		"bishop": return _ray_moves(state, profile_id, origin, [Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)])
		"queen": return _ray_moves(state, profile_id, origin, [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1), Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)])
		"king": return _step_moves(state, profile_id, origin)
		_: return _pawn_moves(state, profile_id, origin, side)

static func _can_enter(state: BBBoardState, profile_id: String, cell: Vector2i) -> bool:
	if not state.inside(cell): return false
	var other := state.occupant(cell)
	return other == "" or state.side_of(other) != state.side_of(profile_id)

static func _jump_moves(state: BBBoardState, profile_id: String, origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for d in [Vector2i(1,2),Vector2i(2,1),Vector2i(-1,2),Vector2i(-2,1),Vector2i(1,-2),Vector2i(2,-1),Vector2i(-1,-2),Vector2i(-2,-1)]:
		var c := origin + d
		if _can_enter(state, profile_id, c): result.append(c)
	return result

static func _step_moves(state: BBBoardState, profile_id: String, origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(-1,2):
		for y in range(-1,2):
			if x == 0 and y == 0: continue
			var c := origin + Vector2i(x,y)
			if _can_enter(state, profile_id, c): result.append(c)
	return result

static func _pawn_moves(state: BBBoardState, profile_id: String, origin: Vector2i, side: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var dy := 1 if side == "player" else -1
	var forward := origin + Vector2i(0,dy)
	if state.inside(forward) and state.occupant(forward) == "": result.append(forward)
	for dx in [-1,1]:
		var c := origin + Vector2i(dx,dy)
		var other := state.occupant(c)
		if state.inside(c) and other != "" and state.side_of(other) != side: result.append(c)
	return result

static func _ray_moves(state: BBBoardState, profile_id: String, origin: Vector2i, directions: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction in directions:
		var c: Vector2i = origin + direction
		while state.inside(c):
			var other := state.occupant(c)
			if other == "":
				result.append(c)
			else:
				if state.side_of(other) != state.side_of(profile_id): result.append(c)
				break
			c += direction
	return result
