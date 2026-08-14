class_name BBPieceRig
extends RefCounted

static func build(owner: Node3D, side: String, role: String) -> Dictionary:
	for child in owner.get_children(): child.queue_free()
	var mats := _materials(side, role)
	var joints: Dictionary = {}
	var rig_root := _joint(owner, joints, "rig_root", Vector3.ZERO)
	var hips := _joint(rig_root, joints, "hips", Vector3(0, 0.92, 0))
	var spine := _joint(hips, joints, "spine", Vector3(0, 0.38, 0))
	var chest := _joint(spine, joints, "chest", Vector3(0, 0.42, 0))
	var neck := _joint(chest, joints, "neck", Vector3(0, 0.42, 0))
	var head := _joint(neck, joints, "head", Vector3(0, 0.28, 0))
	_part(hips, BoxMesh.new(), Vector3(0, 0.08, 0), Vector3(0.62, 0.28, 0.38), mats["body"])
	_part(spine, BoxMesh.new(), Vector3(0, 0.18, 0), Vector3(0.64, 0.46, 0.34), mats["body"])
	_part(chest, BoxMesh.new(), Vector3(0, 0.10, 0), Vector3(0.82, 0.38, 0.42), mats["accent"])
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.23
	head_mesh.height = 0.46
	_part(head, head_mesh, Vector3.ZERO, Vector3.ONE, mats["skin"])
	var arm_l := _joint(chest, joints, "upper_arm_l", Vector3(-0.52, 0.18, 0))
	var fore_l := _joint(arm_l, joints, "forearm_l", Vector3(0, -0.48, 0))
	var hand_l := _joint(fore_l, joints, "hand_l", Vector3(0, -0.43, 0))
	var arm_r := _joint(chest, joints, "upper_arm_r", Vector3(0.52, 0.18, 0))
	var fore_r := _joint(arm_r, joints, "forearm_r", Vector3(0, -0.48, 0))
	var hand_r := _joint(fore_r, joints, "hand_r", Vector3(0, -0.43, 0))
	_limb(arm_l, 0.48, 0.12, mats["body"])
	_limb(fore_l, 0.43, 0.10, mats["skin"])
	_limb(arm_r, 0.48, 0.12, mats["body"])
	_limb(fore_r, 0.43, 0.10, mats["skin"])
	_hand(hand_l, mats["skin"])
	_hand(hand_r, mats["skin"])
	var thigh_l := _joint(hips, joints, "thigh_l", Vector3(-0.22, -0.08, 0))
	var shin_l := _joint(thigh_l, joints, "shin_l", Vector3(0, -0.62, 0))
	var foot_l := _joint(shin_l, joints, "foot_l", Vector3(0, -0.56, -0.05))
	var thigh_r := _joint(hips, joints, "thigh_r", Vector3(0.22, -0.08, 0))
	var shin_r := _joint(thigh_r, joints, "shin_r", Vector3(0, -0.62, 0))
	var foot_r := _joint(shin_r, joints, "foot_r", Vector3(0, -0.56, -0.05))
	_limb(thigh_l, 0.62, 0.14, mats["body"])
	_limb(shin_l, 0.56, 0.12, mats["accent"])
	_limb(thigh_r, 0.62, 0.14, mats["body"])
	_limb(shin_r, 0.56, 0.12, mats["accent"])
	_foot(foot_l, mats["body"])
	_foot(foot_r, mats["body"])
	var equipment_socket := _joint(hand_r, joints, "equipment_socket", Vector3(0, -0.08, -0.02))
	var label_anchor := _joint(head, joints, "label_anchor", Vector3(0, 0.42, 0))
	_part(chest, BoxMesh.new(), Vector3(-0.46, 0.18, 0), Vector3(0.28, 0.16, 0.50), mats["accent"])
	_part(chest, BoxMesh.new(), Vector3(0.46, 0.18, 0), Vector3(0.28, 0.16, 0.50), mats["accent"])
	_build_equipment(equipment_socket, role, mats)
	return {"joints": joints, "equipment_socket": equipment_socket, "label_anchor": label_anchor}

static func _materials(side: String, role: String) -> Dictionary:
	var body := StandardMaterial3D.new()
	var accent := StandardMaterial3D.new()
	var skin := StandardMaterial3D.new()
	var equipment := StandardMaterial3D.new()
	if side == "player":
		body.albedo_color = Color("#b9c8df")
		accent.albedo_color = _role_color(role)
		equipment.albedo_color = Color("#dce8f7")
	else:
		body.albedo_color = Color("#3a3136")
		accent.albedo_color = Color("#a94f4f")
		equipment.albedo_color = Color("#9aa0aa")
	skin.albedo_color = Color("#d7aa86")
	body.roughness = 0.72
	accent.roughness = 0.55
	equipment.metallic = 0.72
	equipment.roughness = 0.28
	return {"body": body, "accent": accent, "skin": skin, "equipment": equipment}

static func _role_color(role: String) -> Color:
	match role:
		"king": return Color("#d0ab52")
		"queen": return Color("#9277c4")
		"rook": return Color("#5b748e")
		"bishop": return Color("#62867a")
		"knight": return Color("#536f9b")
		_: return Color("#6f7d8c")

static func _joint(parent: Node, joints: Dictionary, name: String, at: Vector3) -> Node3D:
	var joint := Node3D.new()
	joint.name = name
	joint.position = at
	parent.add_child(joint)
	joints[name] = joint
	return joint

static func _part(parent: Node3D, resource: Mesh, at: Vector3, scale_value: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = resource
	mesh.position = at
	mesh.scale = scale_value
	mesh.material_override = material
	parent.add_child(mesh)

static func _limb(parent: Node3D, length: float, radius: float, material: Material) -> void:
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = maxf(length, radius * 2.1)
	_part(parent, capsule, Vector3(0, -length * 0.5, 0), Vector3.ONE, material)

static func _hand(parent: Node3D, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.11
	mesh.height = 0.22
	_part(parent, mesh, Vector3.ZERO, Vector3.ONE, material)

static func _foot(parent: Node3D, material: Material) -> void:
	_part(parent, BoxMesh.new(), Vector3(0, -0.05, -0.10), Vector3(0.24, 0.16, 0.42), material)

static func _build_equipment(socket: Node3D, role: String, mats: Dictionary) -> void:
	if role == "bishop":
		_long_staff(socket, mats)
	elif role == "rook":
		_heavy_prop(socket, mats)
	elif role == "king":
		_long_prop(socket, 1.25, 0.09, mats)
	elif role == "queen":
		_long_prop(socket, 1.10, 0.07, mats)
	elif role == "knight":
		_long_prop(socket, 1.18, 0.08, mats)
	else:
		_long_prop(socket, 0.92, 0.065, mats)

static func _long_prop(socket: Node3D, length: float, width: float, mats: Dictionary) -> void:
	_part(socket, BoxMesh.new(), Vector3(0, -length * 0.46, 0), Vector3(width, length, 0.045), mats["equipment"])
	_part(socket, BoxMesh.new(), Vector3(0, -0.02, 0), Vector3(0.34, 0.07, 0.08), mats["accent"])
	var grip := CylinderMesh.new()
	grip.top_radius = 0.045
	grip.bottom_radius = 0.045
	grip.height = 0.30
	_part(socket, grip, Vector3(0, 0.15, 0), Vector3.ONE, mats["body"])

static func _long_staff(socket: Node3D, mats: Dictionary) -> void:
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.035
	shaft.bottom_radius = 0.035
	shaft.height = 1.75
	_part(socket, shaft, Vector3(0, -0.58, 0), Vector3.ONE, mats["body"])
	var focus := SphereMesh.new()
	focus.radius = 0.13
	focus.height = 0.26
	_part(socket, focus, Vector3(0, -1.46, 0), Vector3.ONE, mats["accent"])

static func _heavy_prop(socket: Node3D, mats: Dictionary) -> void:
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.045
	shaft.bottom_radius = 0.045
	shaft.height = 1.0
	_part(socket, shaft, Vector3(0, -0.35, 0), Vector3.ONE, mats["body"])
	_part(socket, BoxMesh.new(), Vector3(0, -0.90, 0), Vector3(0.58, 0.22, 0.26), mats["equipment"])
