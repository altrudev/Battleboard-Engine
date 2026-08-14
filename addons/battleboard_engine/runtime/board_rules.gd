class_name BBBoardRules
extends RefCounted

static func legal_moves(state: BBBoardState, profile_id: String) -> Array[Vector2i]:
	var origin: Vector2i = state.cell_of(profile_id)
	var role: String = state.role_of(profile_id)
	var side: String = state.side_of(profile_id)
	match role:
		"knight":
			return _jump_moves(state, profile_id, origin)
		"rook":
			var directions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			return _ray_moves(state, profile_id, origin, directions)
		"bishop":
			var directions: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
			return _ray_moves(state, profile_id, origin, directions)
		"queen":
			var directions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
			return _ray_moves(state, profile_id, origin, directions)
		"king":
			return _step_moves(state, profile_id, origin)
		_:
			return _pawn_moves(state, profile_id, origin, side)

static func _can_enter(state: BBBoardState, profile_id: String, cell: Vector2i) -> bool:
	if not state.inside(cell):
		return false
	var other: String = state.occupant(cell)
	return other == "" or state.side_of(other) != state.side_of(profile_id)

static func _jump_moves(state: BBBoardState, profile_id: String, origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [Vector2i(1, 2), Vector2i(2, 1), Vector2i(-1, 2), Vector2i(-2, 1), Vector2i(1, -2), Vector2i(2, -1), Vector2i(-1, -2), Vector2i(-2, -1)]
	for offset in offsets:
		var cell: Vector2i = origin + offset
		if _can_enter(state, profile_id, cell):
			result.append(cell)
	return result

static func _step_moves(state: BBBoardState, profile_id: String, origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(-1, 2):
		for y in range(-1, 2):
			if x == 0 and y == 0:
				continue
			var cell: Vector2i = origin + Vector2i(x, y)
			if _can_enter(state, profile_id, cell):
				result.append(cell)
	return result

static func _pawn_moves(state: BBBoardState, profile_id: String, origin: Vector2i, side: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var dy: int = 1 if side == "player" else -1
	var forward: Vector2i = origin + Vector2i(0, dy)
	if state.inside(forward) and state.occupant(forward) == "":
		result.append(forward)
	var capture_offsets: Array[int] = [-1, 1]
	for dx in capture_offsets:
		var cell: Vector2i = origin + Vector2i(dx, dy)
		if not state.inside(cell):
			continue
		var other: String = state.occupant(cell)
		if other != "" and state.side_of(other) != side:
			result.append(cell)
	return result

static func _ray_moves(state: BBBoardState, profile_id: String, origin: Vector2i, directions: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction in directions:
		var cell: Vector2i = origin + direction
		while state.inside(cell):
			var other: String = state.occupant(cell)
			if other == "":
				result.append(cell)
			else:
				if state.side_of(other) != state.side_of(profile_id):
					result.append(cell)
				break
			cell += direction
	return result
