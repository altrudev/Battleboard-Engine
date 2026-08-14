class_name BBBoardState
extends RefCounted

const SIZE := 8
const SNAPSHOT_SCHEMA := 1

var occupant_by_cell: Dictionary = {}
var cell_by_profile: Dictionary = {}
var role_by_profile: Dictionary = {}
var side_by_profile: Dictionary = {}

func register_profile(profile_id: String, cell: Vector2i, role: String, side: String) -> void:
	if profile_id == "" or not inside(cell):
		return
	remove_profile(profile_id)
	if occupant_by_cell.has(cell):
		remove_profile(str(occupant_by_cell[cell]))
	occupant_by_cell[cell] = profile_id
	cell_by_profile[profile_id] = cell
	role_by_profile[profile_id] = role.to_lower()
	side_by_profile[profile_id] = side

func remove_profile(profile_id: String) -> void:
	if cell_by_profile.has(profile_id):
		occupant_by_cell.erase(cell_by_profile[profile_id])
	cell_by_profile.erase(profile_id)
	role_by_profile.erase(profile_id)
	side_by_profile.erase(profile_id)

func move_profile(profile_id: String, destination: Vector2i) -> void:
	apply_move(profile_id, destination)

func apply_move(profile_id: String, destination: Vector2i) -> Dictionary:
	var result := {
		"ok": false,
		"profile_id": profile_id,
		"origin": cell_of(profile_id),
		"destination": destination,
		"captured_id": "",
		"error": "",
	}
	if not cell_by_profile.has(profile_id):
		result["error"] = "profile_not_registered"
		return result
	if not inside(destination):
		result["error"] = "destination_outside_board"
		return result
	var origin: Vector2i = cell_by_profile[profile_id]
	if origin == destination:
		result["ok"] = true
		return result
	var target_id := occupant(destination)
	if target_id != "" and side_of(target_id) == side_of(profile_id):
		result["error"] = "destination_occupied_by_friendly"
		return result
	var before := snapshot()
	if target_id != "":
		result["captured_id"] = target_id
		remove_profile(target_id)
	occupant_by_cell.erase(origin)
	occupant_by_cell[destination] = profile_id
	cell_by_profile[profile_id] = destination
	var invariant := validate_invariants()
	if not bool(invariant["ok"]):
		restore_snapshot(before)
		result["captured_id"] = ""
		result["error"] = "invariant_failure:%s" % ",".join(PackedStringArray(invariant["errors"]))
		return result
	result["ok"] = true
	return result

func occupant(cell: Vector2i) -> String:
	return str(occupant_by_cell.get(cell, ""))

func cell_of(profile_id: String) -> Vector2i:
	return cell_by_profile.get(profile_id, Vector2i(-1, -1))

func side_of(profile_id: String) -> String:
	return str(side_by_profile.get(profile_id, ""))

func role_of(profile_id: String) -> String:
	return str(role_by_profile.get(profile_id, "pawn"))

func inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < SIZE and cell.y >= 0 and cell.y < SIZE

func clone() -> BBBoardState:
	var copy := BBBoardState.new()
	copy.restore_snapshot(snapshot())
	return copy

func snapshot() -> Dictionary:
	var ids: Array[String] = []
	for raw_id in cell_by_profile.keys():
		ids.append(str(raw_id))
	ids.sort()
	var pieces: Array[Dictionary] = []
	for profile_id in ids:
		var cell := cell_of(profile_id)
		pieces.append({
			"id": profile_id,
			"cell": [cell.x, cell.y],
			"role": role_of(profile_id),
			"side": side_of(profile_id),
		})
	return {"schema": SNAPSHOT_SCHEMA, "size": SIZE, "pieces": pieces}

func restore_snapshot(data: Dictionary) -> void:
	occupant_by_cell.clear()
	cell_by_profile.clear()
	role_by_profile.clear()
	side_by_profile.clear()
	for raw_piece in data.get("pieces", []):
		var piece: Dictionary = raw_piece
		var raw_cell: Array = piece.get("cell", [-1, -1])
		if raw_cell.size() < 2:
			continue
		register_profile(
			str(piece.get("id", "")),
			Vector2i(int(raw_cell[0]), int(raw_cell[1])),
			str(piece.get("role", "pawn")),
			str(piece.get("side", ""))
		)

func validate_invariants() -> Dictionary:
	var errors: Array[String] = []
	for raw_id in cell_by_profile.keys():
		var profile_id := str(raw_id)
		var cell: Vector2i = cell_by_profile[raw_id]
		if not inside(cell):
			errors.append("outside:%s" % profile_id)
		elif occupant(cell) != profile_id:
			errors.append("reverse_lookup:%s" % profile_id)
		if not role_by_profile.has(profile_id):
			errors.append("missing_role:%s" % profile_id)
		if not side_by_profile.has(profile_id):
			errors.append("missing_side:%s" % profile_id)
	for raw_cell in occupant_by_cell.keys():
		var cell: Vector2i = raw_cell
		var profile_id := str(occupant_by_cell[raw_cell])
		if not cell_by_profile.has(profile_id):
			errors.append("ghost_occupant:%s" % profile_id)
		elif cell_by_profile[profile_id] != cell:
			errors.append("cell_mismatch:%s" % profile_id)
	return {"ok": errors.is_empty(), "errors": errors}

func canonical_string() -> String:
	var rows: Array[String] = []
	for piece in snapshot()["pieces"]:
		var cell: Array = piece["cell"]
		rows.append("%s|%d|%d|%s|%s" % [piece["id"], cell[0], cell[1], piece["role"], piece["side"]])
	return ";".join(PackedStringArray(rows))

func state_hash() -> String:
	return canonical_string().sha256_text()
