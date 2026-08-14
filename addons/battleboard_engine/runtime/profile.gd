class_name BBProfile
extends Resource

var profile_id: String = ""
var display_name: String = ""
var background: String = ""
var level: int = 1
var stats: Dictionary = {}
var aptitudes: Dictionary = {}
var predispositions: Array[String] = []
var experiences: Array[String] = []
var traits: Array[String] = []
var relationships: Dictionary = {}

static func from_dictionary(data: Dictionary) -> BBProfile:
	var p := BBProfile.new()
	p.profile_id = str(data.get("id", ""))
	p.display_name = str(data.get("name", p.profile_id))
	p.background = str(data.get("background", ""))
	p.level = int(data.get("level", 1))
	p.stats = data.get("stats", {}).duplicate(true)
	p.aptitudes = data.get("aptitudes", {}).duplicate(true)
	p.predispositions.assign(data.get("predispositions", []))
	p.experiences.assign(data.get("experiences", []))
	p.traits.assign(data.get("traits", []))
	p.relationships = data.get("relationships", {}).duplicate(true)
	return p

func to_dictionary() -> Dictionary:
	return {
		"id": profile_id,
		"name": display_name,
		"background": background,
		"level": level,
		"stats": stats.duplicate(true),
		"aptitudes": aptitudes.duplicate(true),
		"predispositions": predispositions.duplicate(),
		"experiences": experiences.duplicate(),
		"traits": traits.duplicate(),
		"relationships": relationships.duplicate(true),
	}

func aptitude_for(position_name: String) -> float:
	return float(aptitudes.get(position_name.to_lower(), 0.0))

func relationship_with(other_id: String) -> float:
	return float(relationships.get(other_id, 0.0))

func stat(stat_name: String, fallback := 50.0) -> float:
	return float(stats.get(stat_name, fallback))

func set_relationship(other_id: String, value: float) -> void:
	relationships[other_id] = clampf(value, -100.0, 100.0)

func adjust_relationship(other_id: String, amount: float) -> void:
	set_relationship(other_id, relationship_with(other_id) + amount)
