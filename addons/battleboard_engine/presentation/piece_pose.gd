class_name BBPiecePose
extends RefCounted

static func apply(joints: Dictionary, state: String, time: float, duration: float) -> void:
	_reset(joints)
	var root: Node3D = joints["rig_root"]
	var chest: Node3D = joints["chest"]
	var arm_l: Node3D = joints["upper_arm_l"]
	var arm_r: Node3D = joints["upper_arm_r"]
	var fore_r: Node3D = joints["forearm_r"]
	var thigh_l: Node3D = joints["thigh_l"]
	var thigh_r: Node3D = joints["thigh_r"]
	var shin_l: Node3D = joints["shin_l"]
	var shin_r: Node3D = joints["shin_r"]
	match state:
		"idle":
			root.position.y = sin(time * 2.2) * 0.018
			chest.rotation.z = sin(time * 1.5) * 0.025
			arm_l.rotation.x = -0.12 + sin(time * 1.7) * 0.035
			arm_r.rotation.x = 0.12 - sin(time * 1.7) * 0.035
		"run":
			var swing := sin(time * 9.5) * 0.68
			root.position.y = abs(sin(time * 9.5)) * 0.055
			thigh_l.rotation.x = swing
			thigh_r.rotation.x = -swing
			shin_l.rotation.x = maxf(0.0, -swing) * 0.55
			shin_r.rotation.x = maxf(0.0, swing) * 0.55
			arm_l.rotation.x = -swing * 0.55
			arm_r.rotation.x = swing * 0.55
		"primary":
			var p := _progress(time, duration)
			var arc := sin(p * PI)
			chest.rotation.y = -0.48 * arc
			arm_r.rotation.x = -1.55 + 1.15 * p
			arm_r.rotation.z = -0.72 * arc
			fore_r.rotation.x = -0.55 * arc
		"technique":
			var p := _progress(time, duration)
			var arc := sin(p * PI)
			chest.rotation.y = -0.75 * arc
			arm_r.rotation.x = -2.05 + 1.65 * p
			arm_r.rotation.z = -1.05 * arc
			root.position.z = -0.12 * arc
		"parry":
			arm_l.rotation.x = -1.05
			arm_l.rotation.z = -0.62
			arm_r.rotation.x = -1.28
			arm_r.rotation.z = 0.54
			fore_r.rotation.x = -0.42
		"dodge":
			var p := _progress(time, duration)
			root.rotation.z = sin(p * PI) * 0.48
			chest.rotation.y = sin(p * PI) * 0.42
			thigh_l.rotation.x = 0.42
			thigh_r.rotation.x = -0.32
		"impact":
			var p := _progress(time, duration)
			root.rotation.x = -sin(p * PI) * 0.26
			chest.rotation.z = sin(p * PI) * 0.32
		"support":
			var p := _progress(time, duration)
			var arc := sin(p * PI)
			arm_r.rotation.x = -1.62 * arc
			arm_r.rotation.z = -0.45 * arc
			chest.rotation.y = -0.38 * arc
		"down":
			root.rotation.z = -1.47
			root.position.y = -0.48

static func _progress(time: float, duration: float) -> float:
	return clampf(time / maxf(duration, 0.01), 0.0, 1.0)

static func _reset(joints: Dictionary) -> void:
	for key in joints.keys():
		var joint := joints[key] as Node3D
		joint.rotation = Vector3.ZERO
	(joints["rig_root"] as Node3D).position = Vector3.ZERO
