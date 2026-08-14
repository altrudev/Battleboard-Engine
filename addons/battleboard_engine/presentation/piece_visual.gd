class_name BBPieceVisual
extends Node3D

## Replaceable presentation facade for a Battleboard participant.

var profile: BBProfile
var side := "player"
var role := "pawn"
var joints: Dictionary = {}
var current_state := "idle"
var state_time := 0.0
var state_duration := 0.0
var permanent_down := false
var equipment_socket: Node3D
var label_anchor: Node3D

func configure(new_profile: BBProfile, new_side: String, new_role: String) -> void:
	profile = new_profile
	side = new_side
	role = new_role.to_lower()
	var built := BBPieceRig.build(self, side, role)
	joints = built["joints"]
	equipment_socket = built["equipment_socket"]
	label_anchor = built["label_anchor"]

func play_state(state_name: String, duration := 0.5) -> void:
	if permanent_down: return
	current_state = state_name
	state_time = 0.0
	state_duration = maxf(0.05, duration)

func set_down() -> void:
	permanent_down = true
	current_state = "down"
	state_time = 0.0
	state_duration = 9999.0

func equipment_world_position() -> Vector3:
	if equipment_socket == null: return global_position + Vector3.UP
	return equipment_socket.global_position

func label_world_position() -> Vector3:
	if label_anchor == null: return global_position + Vector3.UP * 2.2
	return label_anchor.global_position

func _process(delta: float) -> void:
	if joints.is_empty(): return
	state_time += delta
	if not permanent_down and current_state not in ["idle", "run"] and state_time >= state_duration:
		current_state = "idle"
		state_time = 0.0
		state_duration = 0.0
	if not permanent_down and current_state == "idle":
		var body := get_parent() as CharacterBody3D
		if body != null and body.velocity.length() > 0.2:
			current_state = "run"
	elif not permanent_down and current_state == "run":
		var body := get_parent() as CharacterBody3D
		if body == null or body.velocity.length() <= 0.2:
			current_state = "idle"
	BBPiecePose.apply(joints, current_state, state_time, state_duration)
