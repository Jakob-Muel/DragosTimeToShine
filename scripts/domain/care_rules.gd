class_name CareRules
extends RefCounted

const HAPPY_THRESHOLD := 70
const GROOMED_CLEANLINESS := 100.0


static func happiness(dragon: Dictionary) -> int:
	var hunger := clampi(int(dragon.get("hunger", 0)), 0, 100)
	var cleanliness := clampf(float(dragon.get("cleanliness", 0.0)), 0.0, 100.0)
	return clampi(roundi((hunger + cleanliness) * 0.5), 0, 100)


static func is_happy(dragon: Dictionary) -> bool:
	return happiness(dragon) >= HAPPY_THRESHOLD


static func is_groomed(dragon: Dictionary) -> bool:
	return float(dragon.get("cleanliness", 0.0)) >= GROOMED_CLEANLINESS


static func training_xp_multiplier(dragon: Dictionary, maximum_bonus := 0.25) -> float:
	return 1.0 + clampf(maximum_bonus, 0.0, 1.0) * happiness(dragon) / 100.0
