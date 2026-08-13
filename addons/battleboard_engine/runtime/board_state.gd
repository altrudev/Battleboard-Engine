class_name BBBoardState
extends RefCounted

const SIZE := 8
var occupant_by_cell: Dictionary = {}
var cell_by_profile: Dictionary = {}
var role_by_profile: Dictionary = {}
var side_by_profile: Dictionary = {}

func register_profile(profile_id: String, cell: Vector2i, role: String, side: String) -> void:
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
	if not cell_by_profile.has(profile_id):
		return
	var origin: Vector2i = cell_by_profile[profile_id]
	occupant_by_cell.erase(origin)
	occupant_by_cell[destination] = profile_id
	cell_by_profile[profile_id] = destination

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
