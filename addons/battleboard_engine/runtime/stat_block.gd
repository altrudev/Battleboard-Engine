class_name BBStatBlock
extends Resource

var power := 50.0
var technique := 50.0
var speed := 50.0
var guard := 50.0

static func from_dictionary(data: Dictionary) -> BBStatBlock:
	var block := BBStatBlock.new()
	block.power = float(data.get("power", 50.0))
	block.technique = float(data.get("technique", 50.0))
	block.speed = float(data.get("speed", 50.0))
	block.guard = float(data.get("guard", 50.0))
	return block

func to_dictionary() -> Dictionary:
	return {
		"power": power,
		"technique": technique,
		"speed": speed,
		"guard": guard,
	}

func get_stat(stat_name: String, fallback := 50.0) -> float:
	match stat_name.to_lower():
		"power": return power
		"technique": return technique
		"speed": return speed
		"guard": return guard
		_: return fallback

func validate() -> Dictionary:
	var errors: Array[String] = []
	for entry in {"power": power, "technique": technique, "speed": speed, "guard": guard}.keys():
		var value := get_stat(str(entry))
		if value < 0.0 or value > 200.0:
			errors.append("stat_out_of_range:%s" % entry)
	return {"ok": errors.is_empty(), "errors": errors}
