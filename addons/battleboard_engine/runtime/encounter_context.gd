class_name BBEncounterContext
extends RefCounted

var initiator_id: String
var counterpart_id: String
var destination: Vector2i
var initiator_support: Array[String] = []
var counterpart_support: Array[String] = []
var affinity_snapshot: Dictionary = {}

func _init(a := "", b := "", cell := Vector2i.ZERO) -> void:
	initiator_id = a
	counterpart_id = b
	destination = cell
