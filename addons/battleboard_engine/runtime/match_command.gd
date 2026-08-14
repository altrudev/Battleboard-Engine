class_name BBMatchCommand
extends RefCounted

const MOVE := "move"
const ENGAGE := "engage"
const WAIT := "wait"

static func move(profile_id: String, destination: Vector2i) -> Dictionary:
	return {
		"type": MOVE,
		"profile_id": profile_id,
		"destination": destination,
	}

static func engage(profile_id: String, destination: Vector2i) -> Dictionary:
	return {
		"type": ENGAGE,
		"profile_id": profile_id,
		"destination": destination,
	}

static func wait(profile_id: String) -> Dictionary:
	return {"type": WAIT, "profile_id": profile_id}

static func validate(command: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var command_type := str(command.get("type", ""))
	if command_type not in [MOVE, ENGAGE, WAIT]:
		errors.append("unknown_type")
	if str(command.get("profile_id", "")) == "":
		errors.append("missing_profile_id")
	if command_type in [MOVE, ENGAGE] and not command.has("destination"):
		errors.append("missing_destination")
	return {"ok": errors.is_empty(), "errors": errors}
