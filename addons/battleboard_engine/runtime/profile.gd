class_name BBProfile
extends Resource

const SCHEMA_VERSION := 3

var schema_version := SCHEMA_VERSION
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
var abilities: Array[BBAbilityDefinition] = []
var equipment: Dictionary = {}
var metadata: Dictionary = {}

static func from_dictionary(data: Dictionary) -> BBProfile:
	var p := BBProfile.new()
	p.schema_version = SCHEMA_VERSION
	p.profile_id = str(data.get("id", ""))
	p.display_name = str(data.get("name", p.profile_id))
	p.background = str(data.get("background", ""))
	p.level = maxi(1, int(data.get("level", 1)))
	p.stats = data.get("stats", {}).duplicate(true)
	p.aptitudes = data.get("aptitudes", {}).duplicate(true)
	p.predispositions.assign(data.get("predispositions", []))
	p.experiences.assign(data.get("experiences", []))
	p.traits.assign(data.get("traits", []))
	p.relationships = data.get("relationships", {}).duplicate(true)
	for raw_ability in data.get("abilities", []):
		if raw_ability is Dictionary:
			var ability_data: Dictionary = raw_ability
			p.abilities.append(BBAbilityDefinition.from_dictionary(ability_data))
	p.equipment = data.get("equipment", {}).duplicate(true)
	p.metadata = data.get("metadata", {}).duplicate(true)
	return p

func to_dictionary() -> Dictionary:
	var ability_rows: Array[Dictionary] = []
	for ability in abilities:
		ability_rows.append(ability.to_dictionary())
	return {
		"schema_version": SCHEMA_VERSION,
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
		"abilities": ability_rows,
		"equipment": equipment.duplicate(true),
		"metadata": metadata.duplicate(true),
	}

func typed_stats() -> BBStatBlock:
	return BBStatBlock.from_dictionary(stats)

func ability(ability_id: String) -> BBAbilityDefinition:
	for entry in abilities:
		if entry.ability_id == ability_id:
			return entry
	return null

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

func validate_schema() -> Dictionary:
	var errors: Array[String] = []
	if profile_id == "":
		errors.append("missing_profile_id")
	if level < 1:
		errors.append("invalid_level")
	var stat_validation := typed_stats().validate()
	for error in stat_validation["errors"]:
		errors.append(str(error))
	for raw_role in aptitudes.keys():
		var value := float(aptitudes[raw_role])
		if value < -100.0 or value > 200.0:
			errors.append("aptitude_out_of_range:%s" % str(raw_role))
	var ability_ids: Dictionary = {}
	for entry in abilities:
		var validation := entry.validate()
		for error in validation["errors"]:
			errors.append("ability:%s:%s" % [entry.ability_id, str(error)])
		if ability_ids.has(entry.ability_id):
			errors.append("duplicate_ability:%s" % entry.ability_id)
		ability_ids[entry.ability_id] = true
	return {"ok": errors.is_empty(), "errors": errors, "schema_version": SCHEMA_VERSION}
