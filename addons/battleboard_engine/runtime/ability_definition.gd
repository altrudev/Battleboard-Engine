class_name BBAbilityDefinition
extends Resource

var ability_id := ""
var display_name := ""
var category := "primary"
var power_multiplier := 1.0
var focus_cost := 0.0
var cooldown := 0.0
var status_effects: Array[Dictionary] = []

static func from_dictionary(data: Dictionary) -> BBAbilityDefinition:
	var ability := BBAbilityDefinition.new()
	ability.ability_id = str(data.get("id", ""))
	ability.display_name = str(data.get("name", ability.ability_id))
	ability.category = str(data.get("category", "primary"))
	ability.power_multiplier = float(data.get("power_multiplier", 1.0))
	ability.focus_cost = float(data.get("focus_cost", 0.0))
	ability.cooldown = float(data.get("cooldown", 0.0))
	for raw_effect in data.get("status_effects", []):
		if raw_effect is Dictionary:
			var effect: Dictionary = raw_effect
			ability.status_effects.append(effect.duplicate(true))
	return ability

func to_dictionary() -> Dictionary:
	return {
		"id": ability_id,
		"name": display_name,
		"category": category,
		"power_multiplier": power_multiplier,
		"focus_cost": focus_cost,
		"cooldown": cooldown,
		"status_effects": status_effects.duplicate(true),
	}

func validate() -> Dictionary:
	var errors: Array[String] = []
	if ability_id == "":
		errors.append("missing_ability_id")
	if power_multiplier < 0.0:
		errors.append("negative_power_multiplier")
	if focus_cost < 0.0:
		errors.append("negative_focus_cost")
	if cooldown < 0.0:
		errors.append("negative_cooldown")
	return {"ok": errors.is_empty(), "errors": errors}
