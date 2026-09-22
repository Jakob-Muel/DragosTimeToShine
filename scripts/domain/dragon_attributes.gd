extends RefCounted

const IDS := ["attack_power", "attack_speed", "movement_speed"]
const BASE_VALUE := 10
const VERSION := 1

static func potentials(seed_value: int) -> Dictionary:
	var result := {}
	var value := maxi(1, seed_value % 2147483647)
	for id: String in IDS:
		value = (value * 48271) % 2147483647
		result[id] = 30 + value % 71
	return result

static func normalize(source: Dictionary, seed_value: int, fresh := false) -> Dictionary:
	var defaults := potentials(seed_value)
	var result := {}
	for id: String in IDS:
		var saved: Variant = source.get(id, {})
		if not saved is Dictionary:
			saved = {}
		var potential := maxi(BASE_VALUE, int(saved.get("potential", defaults[id])))
		result[id] = {
			"potential": potential,
			"value": BASE_VALUE if fresh else clampi(int(saved.get("value", BASE_VALUE)), BASE_VALUE, potential),
		}
	return result

static func training_attribute(category: StringName) -> String:
	return "movement_speed" if category == &"flight" else "attack_power"

static func train(dragon: Dictionary, attribute: String, points: int) -> int:
	if not IDS.has(attribute) or points <= 0:
		return 0
	var attributes: Dictionary = dragon.get("attributes", {})
	if not attributes.has(attribute):
		return 0
	var stat: Dictionary = attributes[attribute]
	var before := int(stat["value"])
	stat["value"] = mini(int(stat["potential"]), before + points)
	return int(stat["value"]) - before
