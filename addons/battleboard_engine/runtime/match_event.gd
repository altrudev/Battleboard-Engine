class_name BBMatchEvent
extends RefCounted

static func make(index: int, event_type: String, payload: Dictionary = {}) -> Dictionary:
	return {
		"index": index,
		"type": event_type,
		"payload": payload.duplicate(true),
	}
