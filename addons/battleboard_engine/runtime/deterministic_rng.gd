class_name BBDeterministicRNG
extends RefCounted

const MODULUS := 2147483647
const MULTIPLIER := 48271

var state := 1

func _init(seed := 1) -> void:
	set_seed(seed)

func set_seed(seed: int) -> void:
	state = abs(seed) % MODULUS
	if state == 0:
		state = 1

func next_int() -> int:
	state = int((state * MULTIPLIER) % MODULUS)
	return state

func randf() -> float:
	return float(next_int()) / float(MODULUS)

func randi_range(minimum: int, maximum: int) -> int:
	if maximum <= minimum:
		return minimum
	var span := maximum - minimum + 1
	return minimum + (next_int() % span)

func chance(probability: float) -> bool:
	return randf() < clampf(probability, 0.0, 1.0)

func clone() -> BBDeterministicRNG:
	var copy := BBDeterministicRNG.new(1)
	copy.state = state
	return copy

func snapshot() -> Dictionary:
	return {"state": state}

func restore_snapshot(data: Dictionary) -> void:
	set_seed(int(data.get("state", 1)))
