class_name BBAbilitySystem
extends RefCounted

static func resolve(
	attacker: BBProfile,
	defender: BBProfile,
	ability: BBAbilityDefinition,
	rng: BBDeterministicRNG,
	statuses: Dictionary,
	attacker_support := 0.0,
	defender_support := 0.0
) -> Dictionary:
	if attacker == null or defender == null or ability == null:
		return {"ok": false, "error": "missing_ability_participant"}
	var validation := ability.validate()
	if not bool(validation["ok"]):
		return {"ok": false, "error": "invalid_ability"}
	var adjusted_attacker := _ability_profile(attacker, ability.power_multiplier)
	var combat := BBCombatResolver.resolve(adjusted_attacker, defender, rng, attacker_support, defender_support)
	var applied: Array[Dictionary] = []
	if bool(combat["attacker_won"]):
		for raw_effect in ability.status_effects:
			var effect: Dictionary = raw_effect
			var status_id := str(effect.get("id", ""))
			if status_id == "":
				continue
			var target := str(effect.get("target", "defender"))
			var target_id := attacker.profile_id if target == "attacker" else defender.profile_id
			var entry := BBStatusSystem.apply(
				statuses,
				target_id,
				status_id,
				int(effect.get("duration", 1)),
				float(effect.get("potency", 1.0)),
				str(effect.get("modifier", ""))
			)
			applied.append({"profile_id": target_id, "status_id": status_id, "entry": entry.duplicate(true)})
	return {
		"ok": true,
		"ability_id": ability.ability_id,
		"combat": combat,
		"statuses_applied": applied,
	}

static func _ability_profile(source: BBProfile, power_multiplier: float) -> BBProfile:
	var copy := BBProfile.from_dictionary(source.to_dictionary())
	copy.stats["power"] = source.stat("power") * maxf(0.0, power_multiplier)
	return copy
