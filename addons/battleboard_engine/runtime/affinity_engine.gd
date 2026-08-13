class_name BBAffinityEngine
extends RefCounted

static func evaluate(a: BBProfile, b: BBProfile) -> Dictionary:
	var shared_predispositions := _intersection(a.predispositions, b.predispositions)
	var shared_experiences := _intersection(a.experiences, b.experiences)
	var relationship := (a.relationship_with(b.profile_id) + b.relationship_with(a.profile_id)) * 0.5
	var score := relationship * 0.35
	score += shared_predispositions.size() * 12.0
	score += shared_experiences.size() * 18.0
	if "loner" in a.predispositions or "loner" in b.predispositions:
		score -= 10.0
	return {
		"score": clampf(score, -100.0, 100.0),
		"shared_predispositions": shared_predispositions,
		"shared_experiences": shared_experiences,
		"resonance": _resonance_name(shared_predispositions, shared_experiences, score),
	}

static func _intersection(a: Array[String], b: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for item in a:
		if item in b and item not in result:
			result.append(item)
	return result

static func _resonance_name(pred: Array[String], exp: Array[String], score: float) -> String:
	if "street" in pred and "aggressive" in pred:
		return "Wolfpack"
	if "disciplined" in pred:
		return "Formation"
	if "rejected_qualifier" in exp:
		return "The Unchosen"
	if score >= 35.0:
		return "Strong Resonance"
	if score >= 15.0:
		return "Resonance"
	if score <= -20.0:
		return "Friction"
	return "Neutral"
