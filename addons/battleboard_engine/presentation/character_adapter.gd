class_name BBCharacterAdapter
extends Node3D

var model_root: Node3D
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var skeleton: Skeleton3D
var equipment_socket: Node3D
var label_anchor: Node3D

func attach(scene: PackedScene) -> bool:
	for child in get_children():
		child.queue_free()
	model_root = null
	animation_player = null
	animation_tree = null
	skeleton = null
	equipment_socket = null
	label_anchor = null
	if scene == null:
		return false
	var instance := scene.instantiate()
	if not instance is Node3D:
		instance.queue_free()
		return false
	model_root = instance as Node3D
	add_child(model_root)
	_scan(model_root)
	if equipment_socket == null:
		equipment_socket = model_root
	if label_anchor == null:
		label_anchor = model_root
	return true

func play_state(state_name: String) -> bool:
	var animation_name := _animation_name(state_name)
	if animation_tree != null:
		var playback = animation_tree.get("parameters/playback")
		if playback is AnimationNodeStateMachinePlayback:
			(playback as AnimationNodeStateMachinePlayback).travel(animation_name)
			return true
	if animation_player != null:
		for candidate in [animation_name, state_name, state_name.capitalize()]:
			if animation_player.has_animation(candidate):
				animation_player.play(candidate)
				return true
	return false

func is_production_rig() -> bool:
	return skeleton != null

func _scan(node: Node) -> void:
	if animation_player == null and node is AnimationPlayer:
		animation_player = node as AnimationPlayer
	if animation_tree == null and node is AnimationTree:
		animation_tree = node as AnimationTree
	if skeleton == null and node is Skeleton3D:
		skeleton = node as Skeleton3D
	var lowered := node.name.to_lower()
	if equipment_socket == null and lowered in ["equipment_socket", "weapon_socket", "hand_r_socket"] and node is Node3D:
		equipment_socket = node as Node3D
	if label_anchor == null and lowered in ["label_anchor", "head_anchor", "ui_anchor"] and node is Node3D:
		label_anchor = node as Node3D
	for child in node.get_children():
		_scan(child)

func _animation_name(state_name: String) -> String:
	match state_name:
		"primary": return "attack"
		"technique": return "technique"
		"parry": return "parry"
		"dodge": return "dodge"
		"impact": return "hit"
		"support": return "support"
		"down": return "downed"
		_: return state_name
