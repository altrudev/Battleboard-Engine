class_name BBStatusSystem
extends RefCounted

static func apply(statuses: Dictionary, profile_id: String, status_id: String, duration: int, potency := 1.0) -> Dictionary:
	var profile_statuses: Dictionary = statuses.get(profile_id, {}).duplicate(true)
	profile_statuses[status_id] = {
		"duration": maxi(1, duration),
		"potency": potency,
	}
	statuses[profile_id] = profile_statuses
	return profile_statuses[status_id]

static func remove(statuses: Dictionary, profile_id: String, status_id: String) -> void:
	if not statuses.has(profile_id):
		return
	var profile_statuses: Dictionary = statuses[profile_id]
	profile_statuses.erase(status_id)
	if profile_statuses.is_empty():
		statuses.erase(profile_id)

static func tick(statuses: Dictionary) -> Array[Dictionary]:
	var expired: Array[Dictionary] = []
	var profile_ids: Array = statuses.keys()
	for raw_id in profile_ids:
		var profile_id := str(raw_id)
		var profile_statuses: Dictionary = statuses.get(profile_id, {})
		var status_ids: Array = profile_statuses.keys()
		for raw_status_id in status_ids:
			var status_id := str(raw_status_id)
			var entry: Dictionary = profile_statuses[status_id]
			entry["duration"] = int(entry.get("duration", 1)) - 1
			if int(entry["duration"]) <= 0:
				profile_statuses.erase(status_id)
				expired.append({"profile_id": profile_id, "status_id": status_id})
			else:
				profile_statuses[status_id] = entry
		if profile_statuses.is_empty():
			statuses.erase(profile_id)
		else:
			statuses[profile_id] = profile_statuses
	return expired

static func modifier(statuses: Dictionary, profile_id: String, key: String) -> float:
	var total := 0.0
	for raw_entry in (statuses.get(profile_id, {}) as Dictionary).values():
		var entry: Dictionary = raw_entry
		if str(entry.get("modifier", "")) == key:
			total += float(entry.get("potency", 0.0))
	return total
