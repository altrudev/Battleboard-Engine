class_name BBMatchEvent
extends RefCounted

static func make(index: int, event_type: String, payload := {}) -> Dictionary:
	return {
		"index": index,
		"type": event_type,
		"payload": (payload as Dictionary).duplicate(true),
	}
