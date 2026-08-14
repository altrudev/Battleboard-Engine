@tool
extends EditorPlugin

const ENGINE_VERSION := "0.4.0"

func _enter_tree() -> void:
	print("Battleboard Engine %s loaded" % ENGINE_VERSION)

func _exit_tree() -> void:
	pass
