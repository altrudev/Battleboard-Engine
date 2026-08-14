class_name BBCombatResolver
extends RefCounted

static func estimate(attacker: BBProfile, defender: BBProfile, attacker_support := 0.0, defender_support := 0.0) -> Dictionary:
	var attack_score := _offense(attacker) + attacker_support
	var defense_score := _defense(defender) + defender_support
	var delta := attack_score - defense_score
	var probability := clampf(0.5 + delta / 220.0, 0.08, 0.92)
	return {
		"attacker_score": attack_score,
		"defender_score": defense_score,
		"delta": delta,
		"attacker_win_probability": probability,
	}

static func resolve(attacker: BBProfile, defender: BBProfile, rng: BBDeterministicRNG, attacker_support := 0.0, defender_support := 0.0) -> Dictionary:
	var estimate_result := estimate(attacker, defender, attacker_support, defender_support)
	var probability := float(estimate_result["attacker_win_probability"])
	var roll := rng.randf()
	var attacker_won := roll < probability
	return {
		"winner_id": attacker.profile_id if attacker_won else defender.profile_id,
		"loser_id": defender.profile_id if attacker_won else attacker.profile_id,
		"attacker_won": attacker_won,
		"roll": roll,
		"attacker_win_probability": probability,
		"attacker_score": estimate_result["attacker_score"],
		"defender_score": estimate_result["defender_score"],
	}

static func _offense(profile: BBProfile) -> float:
	return (
		profile.stat("power") * 0.38
		+ profile.stat("technique") * 0.32
		+ profile.stat("speed") * 0.20
		+ profile.stat("guard") * 0.10
		+ float(profile.level) * 1.5
	)

static func _defense(profile: BBProfile) -> float:
	return (
		profile.stat("guard") * 0.40
		+ profile.stat("technique") * 0.28
		+ profile.stat("speed") * 0.20
		+ profile.stat("power") * 0.12
		+ float(profile.level) * 1.5
	)
