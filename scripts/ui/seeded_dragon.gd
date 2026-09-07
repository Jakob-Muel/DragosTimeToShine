class_name SeededDragon
extends Control

## Deterministic dragon portraits drawn from curved, interchangeable anatomy.
## Traits remain independent of rendering so saved seeds retain their identity.

const ART_SIZE := Vector2(320.0, 360.0)
const INK := Color("#382b3d")
const CREAM := Color("#fff1d2")
const CREAM_SHADE := Color("#d9b98a")

const BODY_NAMES := ["ROUND", "TALL", "STURDY"]
const WING_NAMES := ["BROAD", "MOON", "LEAF", "SPLIT"]
const HORN_NAMES := ["SWEPT", "CRYSTAL", "CROWN", "BRANCHED", "CURL"]
const PATTERN_NAMES := ["SPOTS", "STRIPES", "MOONS", "BLAZE", "STARS"]
const TAIL_NAMES := ["SPADE", "FLAME", "LEAF", "CRYSTAL"]
const EYE_NAMES := ["GOLD", "SKY", "MINT", "LILAC"]
const NAME_STARTS := ["Ari", "Bram", "Cinder", "Dra", "Ember", "Fae", "Lumi", "Mira", "Nori", "Pip"]
const NAME_ENDS := ["bloom", "flare", "gleam", "leaf", "mist", "spark", "wing", "whisk", "shine", "song"]
const EYE_COLORS := [
	Color("#e9aa46"),
	Color("#78d6ed"),
	Color("#4f956c"),
	Color("#9a78b3"),
]
const PALETTES := [
	{
		"name": "EMBER",
		"primary": Color("#e6644f"),
		"light": Color("#f49a62"),
		"shade": Color("#9e3f42"),
		"accent": Color("#f5c877"),
	},
	{
		"name": "TIDAL",
		"primary": Color("#58b9dc"),
		"light": Color("#a8e6f5"),
		"shade": Color("#347ca5"),
		"accent": Color("#dff3ef"),
	},
	{
		"name": "MOSS",
		"primary": Color("#69a978"),
		"light": Color("#a9d69a"),
		"shade": Color("#35684d"),
		"accent": Color("#f5c877"),
	},
	{
		"name": "AMETHYST",
		"primary": Color("#9a78b3"),
		"light": Color("#c5a7d6"),
		"shade": Color("#6d5085"),
		"accent": Color("#f08bb0"),
	},
	{
		"name": "ROSE",
		"primary": Color("#e75d91"),
		"light": Color("#f08bb0"),
		"shade": Color("#9e3f68"),
		"accent": Color("#fff1d2"),
	},
	{
		"name": "SUN",
		"primary": Color("#e9aa46"),
		"light": Color("#f5c877"),
		"shade": Color("#ad6f31"),
		"accent": Color("#fff1d2"),
	},
	{
		"name": "FROST",
		"primary": Color("#a8d8e8"),
		"light": Color("#dff3ef"),
		"shade": Color("#6a9fb3"),
		"accent": Color("#fffaf0"),
	},
	{
		"name": "STORM",
		"primary": Color("#65758f"),
		"light": Color("#9aa9bd"),
		"shade": Color("#3f465d"),
		"accent": Color("#78d6ed"),
	},
]

var dragon_seed := 1
var appearance: Dictionary = {}
var animate := true
var _elapsed := 0.0
var _surface_cache: Dictionary = {}
# Small shared light maps are generated once per material, not per dragon/frame.
static var _light_maps: Dictionary = {}
static var _shadow_map: ImageTexture
const LIGHT_MAP_SIZE := 128


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)
	set_process(animate)
	set_seed(dragon_seed)


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func set_seed(value: int) -> void:
	dragon_seed = maxi(1, value)
	appearance = traits_for_seed(dragon_seed)
	_surface_cache.clear()
	queue_redraw()


func trait_summary() -> Dictionary:
	return appearance.duplicate(true)


static func traits_for_seed(value: int) -> Dictionary:
	var stable_seed := maxi(1, value)
	var rng := RandomNumberGenerator.new()
	rng.seed = stable_seed
	var palette_index := rng.randi_range(0, PALETTES.size() - 1)
	var body_index := rng.randi_range(0, BODY_NAMES.size() - 1)
	var wing_index := rng.randi_range(0, WING_NAMES.size() - 1)
	var horn_index := rng.randi_range(0, HORN_NAMES.size() - 1)
	var pattern_index := rng.randi_range(0, PATTERN_NAMES.size() - 1)
	var tail_index := rng.randi_range(0, TAIL_NAMES.size() - 1)
	var eye_index := rng.randi_range(0, EYE_NAMES.size() - 1)
	var name_start: String = NAME_STARTS[rng.randi_range(0, NAME_STARTS.size() - 1)]
	var name_end: String = NAME_ENDS[rng.randi_range(0, NAME_ENDS.size() - 1)]
	return {
		"seed": stable_seed,
		"name": name_start + name_end,
		"palette": palette_index,
		"palette_name": PALETTES[palette_index]["name"],
		"body": body_index,
		"body_name": BODY_NAMES[body_index],
		"wings": wing_index,
		"wing_name": WING_NAMES[wing_index],
		"horns": horn_index,
		"horn_name": HORN_NAMES[horn_index],
		"pattern": pattern_index,
		"pattern_name": PATTERN_NAMES[pattern_index],
		"tail": tail_index,
		"tail_name": TAIL_NAMES[tail_index],
		"eyes": eye_index,
		"eye_name": EYE_NAMES[eye_index],
		"rare": rng.randf() < 0.08,
	}


func _draw() -> void:
	if appearance.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return
	var scale_factor := minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	var origin := (size - ART_SIZE * scale_factor) * 0.5
	var bounce := sin(_elapsed * 2.1) * 1.4 if animate else 0.0
	draw_set_transform(origin, 0.0, Vector2.ONE * scale_factor)
	_soft_shadow(Vector2(168, 333), Vector2(96, 13), Color(INK, 0.23))
	_soft_shadow(Vector2(156, 332), Vector2(57, 5), Color(INK, 0.20))
	draw_set_transform(origin + Vector2(0, bounce * scale_factor), 0.0, Vector2.ONE * scale_factor)
	var palette: Dictionary = PALETTES[int(appearance["palette"])]
	_draw_wings(palette)
	_draw_tail(palette)
	_draw_legs(palette)
	_draw_body(palette)
	_draw_belly(palette)
	_draw_body_pattern(palette)
	var head: Vector2 = _body_geometry()["head"]
	_soft_shadow(head + Vector2(5, 63), Vector2(43, 14), Color(palette["shade"].darkened(0.15), 0.28), _body_points())
	_draw_arms(palette)
	_draw_cheek_frills(palette)
	_draw_horns(palette)
	_draw_head(palette)
	_draw_crest(palette)
	_draw_head_pattern(palette)
	_draw_face(palette)
	if bool(appearance["rare"]):
		_draw_sparkles(palette)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _body_geometry() -> Dictionary:
	match int(appearance["body"]):
		1:
			return {"center": Vector2(159, 245), "radius": Vector2(49, 78), "head": Vector2(143, 124), "head_radius": Vector2(63, 59)}
		2:
			return {"center": Vector2(159, 257), "radius": Vector2(66, 64), "head": Vector2(143, 134), "head_radius": Vector2(72, 61)}
		_:
			return {"center": Vector2(159, 252), "radius": Vector2(60, 70), "head": Vector2(143, 130), "head_radius": Vector2(69, 64)}


func _draw_wings(palette: Dictionary) -> void:
	# Each membrane follows the same curved finger endpoints as its ribs.
	# Concave scallops supply the bat-wing silhouette without floating panels.
	var design := int(appearance["wings"])
	var tip := Vector2(22, 112)
	var middle := Vector2(20, 204)
	var bottom := Vector2(58, 259)
	match design:
		1:
			tip = Vector2(46, 91)
			middle = Vector2(17, 184)
			bottom = Vector2(53, 248)
		2:
			tip = Vector2(20, 137)
			middle = Vector2(18, 215)
			bottom = Vector2(58, 250)
		3:
			tip = Vector2(36, 103)
			middle = Vector2(12, 202)
			bottom = Vector2(52, 265)
	var body: Dictionary = _body_geometry()
	var root_point: Vector2 = body["center"] + body["radius"] * Vector2(-0.48, -0.12)
	var knuckle := tip + Vector2(28, 39)
	var points := _path(root_point, [
		[Vector2(84, 215), knuckle + Vector2(12, 17), knuckle],
		[knuckle + Vector2(-9, -17), tip + Vector2(8, 3), tip],
		[tip + Vector2(22, 39), middle + Vector2(28, -24), middle],
		[middle + Vector2(28, -12), bottom + Vector2(2, -39), bottom],
		[bottom + Vector2(23, -26), Vector2(89, 229), root_point],
	])
	for far in [true, false]:
		var surface := _wing_points(points, far)
		var membrane: Color = palette["primary"].lerp(palette["shade"], 0.38).lerp(palette["accent"], 0.12)
		if far:
			membrane = membrane.darkened(0.20)
		_shaded_shape(surface, membrane, palette["shade"].darkened(0.18), palette["accent"], 1.8, 0.45)
		var elbow := _wing_point(knuckle, far)
		var bone := _path(_wing_point(root_point, far), [[
			_wing_point(Vector2(83, 214), far), _wing_point(knuckle + Vector2(12, 17), far), elbow,
		], [elbow + Vector2(-3, -12), _wing_point(tip + Vector2(10, 5), far), _wing_point(tip, far)]])
		_draw_polyline(bone, palette["shade"], 7.0)
		_draw_polyline(bone, palette["primary"], 4.8)
		_draw_polyline(bone, Color(palette["light"], 0.36), 1.3)
		for endpoint in [middle, bottom]:
			var rib := _quadratic_curve_points(elbow, _wing_point(knuckle.lerp(endpoint, 0.5) + Vector2(12, 0), far), _wing_point(endpoint, far), 20)
			_draw_polyline(rib, Color(palette["shade"], 0.8), 3.7)
			_draw_polyline(rib, palette["primary"].lerp(palette["light"], 0.35), 1.7)
		var claw := _path(knuckle + Vector2(-3, 2), [[knuckle + Vector2(-13, -1), knuckle + Vector2(-10, -13), knuckle + Vector2(-5, -17)], [knuckle + Vector2(-6, -7), knuckle + Vector2(4, -5), knuckle + Vector2(3, 1)]])
		_shaded_shape(_wing_points(claw, far), CREAM, CREAM_SHADE, Color.WHITE, 1.2)
		# Quiet inlaid markings stay inside the upper membrane.
		var marking := _wing_point(knuckle.lerp(middle, 0.52) + Vector2(5, -1), far)
		_draw_star(marking, 5.5, Color(palette["accent"], 0.65))


func _wing_point(point: Vector2, far: bool) -> Vector2:
	if not far:
		return point
	return Vector2(207 + (308 - point.x - 207) * 0.93, 214 + (point.y - 214) * 0.94 - 9)


func _wing_points(points: PackedVector2Array, far: bool) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(_wing_point(point, far))
	return result


func _draw_legs(palette: Dictionary) -> void:
	var geometry := _body_geometry()
	var center: Vector2 = geometry["center"]
	var radius: Vector2 = geometry["radius"]
	for direction in [-1.0, 1.0]:
		var hip := Vector2(center.x + radius.x * 0.62 * direction, 293)
		var foot := hip + Vector2(-5, 28)
		var paw := _path(foot + Vector2(-27, 3), [
			[foot + Vector2(-28, -12), foot + Vector2(-5, -20), foot + Vector2(13, -12)],
			[foot + Vector2(24, -9), foot + Vector2(29, 1), foot + Vector2(23, 9)],
			[foot + Vector2(7, 14), foot + Vector2(-18, 13), foot + Vector2(-27, 3)],
		])
		# A single leg-to-paw surface removes the old ankle seam.
		var leg_key := hash([hip, paw, "leg"])
		if not _surface_cache.has(leg_key):
			_surface_cache[leg_key] = Geometry2D.merge_polygons(_ellipse_points(hip, Vector2(27, 33)), paw)
		for leg in _surface_cache[leg_key]:
			_shaded_shape(leg, palette["primary"], palette["shade"], palette["light"], 1.8)
		for x in [-15.0, -3.0, 9.0]:
			_draw_claw(foot + Vector2(x, 8), 4.3)


func _draw_claw(center: Vector2, width: float) -> void:
	var claw := _path(center + Vector2(-width, 0), [[center + Vector2(-width, -7), center + Vector2(width, -7), center + Vector2(width, 0)], [center + Vector2(width, 4), center + Vector2(0, 5), center + Vector2(-width, 0)]])
	_shaded_shape(claw, CREAM, CREAM_SHADE, Color.WHITE, 0.8)


func _body_points() -> PackedVector2Array:
	var geometry := _body_geometry()
	var c: Vector2 = geometry["center"]
	var r: Vector2 = geometry["radius"]
	return _path(c + Vector2(-r.x * 0.52, -r.y), [
		[c + Vector2(-r.x * 1.0, -r.y * 0.46), c + Vector2(-r.x * 1.25, r.y * 0.65), c + Vector2(-r.x * 0.45, r.y * 0.92)],
		[c + Vector2(0, r.y * 1.13), c + Vector2(r.x * 0.92, r.y * 0.99), c + Vector2(r.x, r.y * 0.40)],
		[c + Vector2(r.x * 1.04, -r.y * 0.13), c + Vector2(r.x * 0.61, -r.y * 0.74), c + Vector2(r.x * 0.38, -r.y * 1.12)],
		[c + Vector2(r.x * 0.1, -r.y * 1.28), c + Vector2(-r.x * 0.32, -r.y * 1.23), c + Vector2(-r.x * 0.52, -r.y)],
	])


func _draw_body(palette: Dictionary) -> void:
	_shaded_shape(_torso_points(), palette["primary"], palette["shade"], palette["light"], 1.8, 1.0, Vector3.ZERO, _bounds(_body_points()))


func _draw_belly(palette: Dictionary) -> void:
	var geometry := _body_geometry()
	var c: Vector2 = geometry["center"] + Vector2(-10, 2)
	var r: Vector2 = geometry["radius"] * Vector2(0.62, 0.93)
	var belly := _path(c + Vector2(-r.x * 0.48, -r.y), [
		[c + Vector2(-r.x * 0.63, -r.y * 0.4), c + Vector2(-r.x * 1.14, r.y * 0.49), c + Vector2(-r.x * 0.45, r.y * 0.83)],
		[c + Vector2(0, r.y * 1.12), c + Vector2(r.x * 0.81, r.y * 0.86), c + Vector2(r.x * 0.88, r.y * 0.39)],
		[c + Vector2(r.x, -r.y * 0.12), c + Vector2(r.x * 0.46, -r.y * 0.79), c + Vector2(r.x * 0.30, -r.y * 1.05)],
		[c + Vector2(0, -r.y * 1.1), c + Vector2(-r.x * 0.24, -r.y * 1.09), c + Vector2(-r.x * 0.48, -r.y)],
	])
	var cream := CREAM.lerp(palette["accent"], 0.13)
	_shaded_shape(belly, cream, CREAM_SHADE, Color("#fffcef"), 0.0, 1.0, Vector3.ZERO, _bounds(_body_points()))
	for ratio in [-0.54, -0.17, 0.22, 0.58]:
		var y: float = c.y + r.y * ratio
		var width := r.x * (0.66 if ratio < -0.3 else 0.79)
		var line := _quadratic_curve_points(Vector2(c.x - width * 0.83, y), Vector2(c.x, y + 10), Vector2(c.x + width, y + 1), 24)
		var inset_line := PackedVector2Array()
		for point in line:
			if Geometry2D.is_point_in_polygon(point + Vector2(-1, 0), belly) and Geometry2D.is_point_in_polygon(point + Vector2(1, 0), belly):
				inset_line.append(point)
		_draw_polyline(inset_line, Color(CREAM_SHADE, 0.54), 1.1)
		var bevel := PackedVector2Array()
		for point in inset_line:
			bevel.append(point + Vector2(0, -1.0))
		_draw_polyline(bevel, Color(CREAM, 0.27), 0.8)


func _draw_body_pattern(palette: Dictionary) -> void:
	var geometry := _body_geometry()
	var c: Vector2 = geometry["center"]
	var r: Vector2 = geometry["radius"]
	for index in 3:
		var point := c + Vector2(r.x * (0.74 - float(index) * 0.015), -12 + index * 17)
		match int(appearance["pattern"]):
			0:
				_ellipse(point, Vector2(4, 3), Color(palette["accent"], 0.75), 24, 0)
			1, 3:
				_draw_polyline(_quadratic_curve_points(point + Vector2(0, -5), point + Vector2(-8, -2), point + Vector2(-10, 3), 12), Color(palette["shade"], 0.6), 3.0)
			2:
				_draw_polyline(_quadratic_curve_points(point + Vector2(0, -4), point + Vector2(-6, 0), point + Vector2(1, 4), 12), Color(palette["accent"], 0.75), 2.0)
			4:
				_draw_star(point, 4.0, Color(palette["accent"], 0.8))


func _arm_geometry(far: bool) -> Dictionary:
	var geometry := _body_geometry()
	var c: Vector2 = geometry["center"]
	var r: Vector2 = geometry["radius"]
	var shoulder := c + Vector2(-r.x * 0.86, -r.y * 0.47) if far else c + Vector2(r.x * 0.86, -r.y * 0.47)
	var hand := shoulder + Vector2(-4, 47) if far else shoulder + Vector2(3, 48)
	# Anchor at the sides of the ribcage, with hands resting outside the belly.
	# A cap above the shoulder would create a step in the merged silhouette.
	var root_point := c + r * Vector2(-0.54 if far else 0.50, -0.65)
	var arm := _path(root_point + Vector2(-8, 0), [
		[shoulder + Vector2(-15, -3), hand + Vector2(-17, -10), hand + Vector2(-12, 3)],
		[hand + Vector2(-7, 14), hand + Vector2(14, 11), hand + Vector2(15, -2)],
		[hand + Vector2(20, -19), shoulder + Vector2(19, -2), root_point + Vector2(8, 0)],
		[root_point + Vector2(5, -6), root_point + Vector2(-5, -6), root_point + Vector2(-8, 0)],
	])
	return {"points": arm, "hand": hand}


func _torso_points() -> PackedVector2Array:
	if not _surface_cache.has("torso"):
		var joined := _body_points()
		for far in [true, false]:
			var merged := Geometry2D.merge_polygons(joined, _arm_geometry(far)["points"])
			assert(merged.size() == 1, "Shoulders must connect to the torso.")
			joined = merged[0]
		_surface_cache["torso"] = joined
	return _surface_cache["torso"]


func _draw_arms(palette: Dictionary) -> void:
	for far in [true, false]:
		var geometry := _arm_geometry(far)
		var arm: PackedVector2Array = geometry["points"]
		var hand: Vector2 = geometry["hand"]
		# Only the hand/elbow lifts away from the body; the shoulder has no cast seam.
		_soft_shadow(hand + Vector2(6, -7), Vector2(19, 29), Color(palette["shade"].darkened(0.15), 0.27), _body_points())
		# The opaque root uses the torso's exact light field, so the cream belly
		# cannot show through the feathered skin at the shoulder.
		_shaded_shape(arm, palette["primary"], palette["shade"], palette["light"], 0.0, 1.0, Vector3.ZERO, _bounds(_body_points()))
		_shaded_shape(arm, palette["primary"], palette["shade"], palette["light"], 1.3, 1.0, Vector3(0.48, 0, 0))
		for offset in [-6.0, 4.0]:
			_draw_claw(hand + Vector2(offset, 6), 3.5)


func _draw_cheek_frills(palette: Dictionary) -> void:
	var c: Vector2 = _body_geometry()["head"]
	var r: Vector2 = _body_geometry()["head_radius"]
	for direction in [-1.0, 1.0]:
		var attach := c + Vector2(r.x * 0.78 * direction, 9)
		for index in 3:
			var root_point := attach + Vector2(-3 * direction, index * 13 - 16)
			var tip := root_point + Vector2((25 - index * 3) * direction, -14 + index * 9)
			var frill := _path(root_point + Vector2(0, -9), [[root_point + Vector2(12 * direction, -6), tip + Vector2(-3 * direction, 0), tip], [tip + Vector2(-3 * direction, 11), root_point + Vector2(6 * direction, 15), root_point + Vector2(-3 * direction, 8)]])
			_shaded_shape(frill, palette["primary"], palette["shade"], palette["light"], 1.3)


func _draw_horns(palette: Dictionary) -> void:
	var c: Vector2 = _body_geometry()["head"]
	var r: Vector2 = _body_geometry()["head_radius"]
	for far in [true, false]:
		var base := c + Vector2(-r.x * 0.60, -r.y * 0.46) if far else c + Vector2(r.x * 0.55, -r.y * 0.45)
		var points := PackedVector2Array()
		var color := CREAM.lerp(palette["accent"], 0.22)
		match int(appearance["horns"]):
			0, 2:
				points = _path(Vector2(-13, 9), [[Vector2(-21, -10), Vector2(13, -33), Vector2(14, -62)], [Vector2(32, -35), Vector2(22, -1), Vector2(10, 9)], [Vector2(4, 13), Vector2(-7, 13), Vector2(-13, 9)]])
			1:
				points = PackedVector2Array([Vector2(-13, 9), Vector2(-17, -17), Vector2(10, -58), Vector2(18, -18), Vector2(12, 10)])
				color = palette["accent"].lerp(palette["light"], 0.45)
			3:
				# A continuous antler silhouette keeps the branch join seamless.
				points = _path(Vector2(-9, 10), [[Vector2(-16, -7), Vector2(5, -36), Vector2(7, -60)], [Vector2(16, -43), Vector2(12, -28), Vector2(10, -23)], [Vector2(20, -26), Vector2(26, -33), Vector2(30, -43)], [Vector2(33, -24), Vector2(18, -12), Vector2(11, -10)], [Vector2(9, -3), Vector2(12, 7), Vector2(7, 10)]])
			4:
				points = _path(Vector2(-10, 10), [[Vector2(-30, -7), Vector2(-24, -45), Vector2(0, -49)], [Vector2(25, -54), Vector2(36, -24), Vector2(17, -17)], [Vector2(27, -36), Vector2(-7, -43), Vector2(-8, -24)], [Vector2(-11, -11), Vector2(9, -4), Vector2(12, 8)], [Vector2(5, 13), Vector2(-4, 13), Vector2(-10, 10)]])
		var transformed := PackedVector2Array()
		for point in points:
			transformed.append(base + Vector2(point.x * (-0.83 if far else 1.0), point.y * (0.84 if far else 1.0)))
		_shaded_shape(transformed, color, CREAM_SHADE, Color("#fffdf3"), 1.8)


func _head_points() -> PackedVector2Array:
	var c: Vector2 = _body_geometry()["head"]
	var r: Vector2 = _body_geometry()["head_radius"]
	return _path(c + Vector2(-r.x * 0.9, 6), [
		[c + Vector2(-r.x, -r.y * 0.50), c + Vector2(-r.x * 0.58, -r.y), c + Vector2(-r.x * 0.08, -r.y)],
		[c + Vector2(r.x * 0.62, -r.y * 1.09), c + Vector2(r.x * 1.02, -r.y * 0.49), c + Vector2(r.x * 0.97, 5)],
		[c + Vector2(r.x * 1.08, r.y * 0.61), c + Vector2(r.x * 0.52, r.y * 0.98), c + Vector2(-r.x * 0.1, r.y * 0.94)],
		[c + Vector2(-r.x * 0.84, r.y * 0.95), c + Vector2(-r.x * 1.05, r.y * 0.44), c + Vector2(-r.x * 0.9, 6)],
	])


func _draw_head(palette: Dictionary) -> void:
	_shaded_shape(_head_points(), palette["primary"], palette["shade"], palette["light"], 1.8)


func _draw_crest(palette: Dictionary) -> void:
	var c: Vector2 = _body_geometry()["head"]
	var r: Vector2 = _body_geometry()["head_radius"]
	for index in range(2, -1, -1):
		var base := c + Vector2(-8 + index * 15, -r.y + 8 + index * 2)
		var crown := int(appearance["horns"]) == 2
		var tip := base + Vector2(6, (-40 if index == 0 else -25) if crown else -24 + index * 4)
		var crest := _path(base + Vector2(-8, 3), [[base + Vector2(-8, -8), tip + Vector2(-4, 5), tip], [tip + Vector2(3, 7), base + Vector2(13, -1), base + Vector2(8, 6)]])
		_cast_shadow(crest, _head_points(), Vector2(2, 3), Color(palette["shade"], 0.12))
		_shaded_shape(crest, CREAM.lerp(palette["accent"], 0.4) if crown else palette["accent"].lerp(palette["primary"], 0.6), palette["shade"], palette["light"], 1.0, 1.0, Vector3(0, 0.30, 0))


func _draw_head_pattern(palette: Dictionary) -> void:
	var c: Vector2 = _body_geometry()["head"] + Vector2(-5, -35)
	var accent: Color = palette["accent"]
	match int(appearance["pattern"]):
		0:
			for offset in [Vector2(-8, 3), Vector2(0, -1), Vector2(8, 3)]:
				_ellipse(c + offset, Vector2(2.6, 2), Color(accent, 0.8), 24, 0)
		1:
			for offset in [-7.0, 1.0, 9.0]:
				_draw_polyline(_quadratic_curve_points(c + Vector2(offset, -6), c + Vector2(offset - 3, 0), c + Vector2(offset - 1, 5), 12), Color(palette["shade"], 0.5), 2.2)
		2:
			_draw_polyline(_quadratic_curve_points(c + Vector2(3, -5), c + Vector2(-9, 0), c + Vector2(3, 6), 20), accent, 2.8)
		3:
			_filled_polygon(PackedVector2Array([c + Vector2(1, -8), c + Vector2(5, -1), c + Vector2(-1, 7), c + Vector2(-5, 0)]), accent, 0)
		4:
			_draw_star(c, 6, accent)


func _draw_face(palette: Dictionary) -> void:
	var c: Vector2 = _body_geometry()["head"]
	var eye_color: Color = EYE_COLORS[int(appearance["eyes"])]
	for far in [true, false]:
		var eye := c + Vector2(-35, -4) if far else c + Vector2(24, -2)
		var radius := Vector2(12, 18) if far else Vector2(16, 22)
		_volume(eye + Vector2(0, -1), radius + Vector2(2.0, 2.0), palette["shade"], palette["shade"], palette["primary"], 0)
		_volume(eye, radius, Color("#202639"), Color("#141827"), eye_color.darkened(0.5), 1.0)
		# A low iris crescent keeps the large glossy pupils from reading as rings.
		_ellipse(eye + Vector2(1, 6), radius * Vector2(0.68, 0.65), eye_color, 48, 0)
		_ellipse(eye + Vector2(0, 1), radius * Vector2(0.66, 0.75), Color("#172133"), 48, 0)
		_ellipse(eye + Vector2(-4, -8), Vector2(4.5, 6.5) if far else Vector2(6, 8), Color("#fffef7"), 40, 0)
		_ellipse(eye + Vector2(5, 8), Vector2(2.2, 2.6), Color("#fffef7"), 24, 0)
		var brow := _quadratic_curve_points(eye + Vector2(-radius.x + 1, -radius.y - 5), eye + Vector2(0, -radius.y - 10), eye + Vector2(radius.x - 1, -radius.y - 4), 20)
		_draw_polyline(brow, Color(palette["light"], 0.35), 1.5)
	# The muzzle projects left of the cheek and overlaps the lower face.
	var muzzle := _path(c + Vector2(-65, 19), [
		[c + Vector2(-59, 8), c + Vector2(-40, 9), c + Vector2(-22, 13)],
		[c + Vector2(-5, 18), c + Vector2(7, 21), c + Vector2(20, 23)],
		[c + Vector2(34, 24), c + Vector2(34, 41), c + Vector2(22, 49)],
		[c + Vector2(7, 60), c + Vector2(-28, 61), c + Vector2(-52, 50)],
		[c + Vector2(-69, 43), c + Vector2(-74, 29), c + Vector2(-65, 19)],
	])
	_soft_shadow(c + Vector2(0, 47), Vector2(40, 12), Color(palette["shade"], 0.18), _head_points())
	_shaded_shape(muzzle, palette["primary"].lerp(palette["light"], 0.10), palette["shade"], palette["light"], 0.85, 1.0, Vector3(0.32, 0, 0.22))
	for nostril in [Vector2(-53, 28), Vector2(-16, 31)]:
		_ellipse(c + nostril, Vector2(2.3, 3.2), palette["shade"].darkened(0.25), 24, 0)
		_ellipse(c + nostril + Vector2(-1, -2.8), Vector2(2.6, 1), Color(palette["light"], 0.8), 24, 0)
	var smile := _path(c + Vector2(-43, 49), [[c + Vector2(-20, 58), c + Vector2(13, 54), c + Vector2(23, 40)]])
	_draw_polyline(smile, palette["shade"].darkened(0.35), 1.8)
	_draw_polyline(_quadratic_curve_points(c + Vector2(20, 39), c + Vector2(24, 40), c + Vector2(26, 42), 12), palette["shade"].darkened(0.35), 1.5)
	_ellipse(c + Vector2(40, 26), Vector2(8, 4), Color(palette["accent"], 0.25), 40, 0)
	for offset in [Vector2(36, 21), Vector2(43, 18), Vector2(48, 24)]:
		_ellipse(c + offset, Vector2(1.5, 1.2), Color(palette["light"], 0.8), 20, 0)


# Cubic contours are sampled densely, with antialiased, rounded strokes.
func _path(start: Vector2, segments: Array) -> PackedVector2Array:
	var points := PackedVector2Array([start])
	var from := start
	for segment in segments:
		var a: Vector2 = segment[0]
		var b: Vector2 = segment[1]
		var end: Vector2 = segment[2]
		for index in range(1, 17):
			var t := float(index) / 16.0
			var u := 1.0 - t
			points.append(from * u * u * u + a * 3 * u * u * t + b * 3 * u * t * t + end * t * t * t)
		from = end
	return points


func _quadratic_curve_points(start: Vector2, control: Vector2, end: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in segments + 1:
		var t := float(index) / float(segments)
		points.append(start * (1 - t) * (1 - t) + control * 2 * (1 - t) * t + end * t * t)
	return points


func _ellipse_points(center: Vector2, radius: Vector2, steps := 64) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in steps:
		var angle := TAU * float(index) / float(steps)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _ellipse(center: Vector2, radius: Vector2, color: Color, steps := 64, outline_width := 0.0) -> void:
	_filled_polygon(_ellipse_points(center, radius, maxi(32, steps)), color, outline_width)


func _volume(center: Vector2, radius: Vector2, primary: Color, shade: Color, light: Color, outline := 2.0) -> void:
	_shaded_shape(_ellipse_points(center, radius), primary, shade, light, outline)


func _shaded_shape(points: PackedVector2Array, primary: Color, shade: Color, light: Color, outline := 2.0, curvature := 1.0, attachment := Vector3.ZERO, light_bounds := Rect2()) -> void:
	# Continuous normal-based lighting replaces the old stacked highlight polygons.
	# UVs and textures are cached; the silhouette stays procedural and scalable.
	var key := hash([points, light_bounds])
	if not _surface_cache.has(key):
		var bounds := _bounds(points) if light_bounds.size == Vector2.ZERO else light_bounds
		var uv := PackedVector2Array()
		for point in points:
			uv.append((point - bounds.position) / bounds.size.max(Vector2.ONE))
		_surface_cache[key] = uv
	draw_polygon(points, PackedColorArray([Color.WHITE]), _surface_cache[key], _light_texture(primary, shade, light, curvature, attachment))
	if outline > 0.0:
		var border := _closed(points)
		var bounds := _bounds(points)
		var colors := PackedColorArray()
		for point in border:
			var uv := (point - bounds.position) / bounds.size.max(Vector2.ONE)
			var facing_light := clampf(1.0 - uv.x * 0.65 - uv.y * 0.6, 0, 1)
			var color := INK.lerp(shade, 0.65).lerp(primary, facing_light * 0.48)
			colors.append(Color(color, _attachment_alpha(uv, attachment)))
		draw_polyline_colors(border, colors, outline * 0.85, true)


static func _light_texture(primary: Color, shade: Color, light: Color, curvature: float, attachment := Vector3.ZERO) -> ImageTexture:
	var key := hash([primary, shade, light, curvature, attachment])
	if _light_maps.has(key):
		return _light_maps[key]
	var pixels := PackedByteArray()
	pixels.resize(LIGHT_MAP_SIZE * LIGHT_MAP_SIZE * 4)
	var lamp := Vector3(-0.48, -0.58, 0.76).normalized()
	for y in LIGHT_MAP_SIZE:
		for x in LIGHT_MAP_SIZE:
			var uv := Vector2(float(x), float(y)) / float(LIGHT_MAP_SIZE - 1)
			var xy := (uv - Vector2(0.5, 0.5)) * 1.9
			var normal := Vector3(xy.x, xy.y, sqrt(maxf(0.035, 1.0 - xy.length_squared()))).normalized()
			var diffuse := maxf(0.0, normal.dot(lamp))
			var color := shade.darkened(0.12).lerp(primary, smoothstep(0.05, 0.72, diffuse))
			color = color.lerp(light, smoothstep(0.55, 1.0, diffuse) * 0.64)
			# A broad satin reflection and cool bounce light describe a rounded surface.
			var specular := exp(-pow((uv.x - 0.33) / 0.21, 2) - pow((uv.y - 0.25) / 0.18, 2))
			color = color.lerp(light.lerp(Color.WHITE, 0.32), specular * 0.19)
			var rim := exp(-pow((uv.x - 0.91) / 0.07, 2)) * exp(-pow((uv.y - 0.60) / 0.38, 2))
			color = color.lerp(light, rim * 0.23)
			color = primary.lerp(color, curvature)
			var index := (y * LIGHT_MAP_SIZE + x) * 4
			pixels[index] = int(clampf(color.r, 0, 1) * 255)
			pixels[index + 1] = int(clampf(color.g, 0, 1) * 255)
			pixels[index + 2] = int(clampf(color.b, 0, 1) * 255)
			pixels[index + 3] = int(_attachment_alpha(uv, attachment) * 255)
	var image := Image.create_from_data(LIGHT_MAP_SIZE, LIGHT_MAP_SIZE, false, Image.FORMAT_RGBA8, pixels)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_light_maps[key] = texture
	return texture


static func _attachment_alpha(uv: Vector2, attachment: Vector3) -> float:
	# Feather only the anatomical root; the free silhouette remains crisp.
	var alpha := 1.0
	if attachment.x > 0:
		alpha *= smoothstep(0.0, attachment.x, uv.y)
	if attachment.y > 0:
		alpha *= 1.0 - smoothstep(1.0 - attachment.y, 1.0, uv.y)
	if attachment.z > 0:
		alpha *= 1.0 - smoothstep(1.0 - attachment.z, 1.0, uv.x)
	return alpha


func _bounds(points: PackedVector2Array) -> Rect2:
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return bounds


func _soft_shadow(center: Vector2, radius: Vector2, color: Color, receiver := PackedVector2Array()) -> void:
	if _shadow_map == null:
		var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		for y in 64:
			for x in 64:
				var distance := ((Vector2(x, y) / 63.0 - Vector2(0.5, 0.5)) * 2.0).length()
				image.set_pixel(x, y, Color(1, 1, 1, pow(maxf(0.0, 1.0 - distance * distance), 2)))
		image.generate_mipmaps()
		_shadow_map = ImageTexture.create_from_image(image)
	var quad := PackedVector2Array([center - radius, center + Vector2(radius.x, -radius.y), center + radius, center + Vector2(-radius.x, radius.y)])
	var key := hash([quad, receiver, "shadow"])
	if not _surface_cache.has(key):
		var polygons: Array = [quad] if receiver.is_empty() else Geometry2D.intersect_polygons(quad, receiver)
		var surfaces: Array = []
		for polygon in polygons:
			var uv := PackedVector2Array()
			for point in polygon:
				uv.append((point - center + radius) / (radius * 2.0))
			surfaces.append([polygon, uv])
		_surface_cache[key] = surfaces
	for surface in _surface_cache[key]:
		draw_polygon(surface[0], PackedColorArray([color]), surface[1], _shadow_map)


func _cast_shadow(occluder: PackedVector2Array, receiver: PackedVector2Array, offset: Vector2, color: Color) -> void:
	var key := hash([occluder, receiver, offset, "contact"])
	if not _surface_cache.has(key):
		var center := _bounds(occluder).get_center()
		var layers: Array[PackedVector2Array] = []
		for layer in 6:
			var expanded := PackedVector2Array()
			for point in occluder:
				expanded.append(center + (point - center) * (1.0 + layer * 0.018) + offset)
			layers.append_array(Geometry2D.intersect_polygons(expanded, receiver))
		_surface_cache[key] = layers
	for layer in _surface_cache[key]:
		draw_colored_polygon(layer, Color(color, color.a / 6.0))


func _filled_polygon(points: PackedVector2Array, color: Color, outline_width := 2.0) -> void:
	draw_colored_polygon(points, color)
	if outline_width > 0.0:
		_draw_polyline(_closed(points), INK, outline_width)


func _draw_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	_draw_polyline(PackedVector2Array([from, to]), color, width)


func _draw_polyline(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2:
		return
	draw_polyline(points, color, width, true)
	if not points[0].is_equal_approx(points[points.size() - 1]):
		draw_circle(points[0], width * 0.5, color, true, -1.0, true)
		draw_circle(points[points.size() - 1], width * 0.5, color, true, -1.0, true)


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty() and not result[0].is_equal_approx(result[result.size() - 1]):
		result.append(result[0])
	return result


func _draw_tail(palette: Dictionary) -> void:
	var primary: Color = palette["primary"]
	var light: Color = palette["light"]
	var shade: Color = palette["shade"]
	# The curve begins deep behind the hip, so the body naturally masks a broad
	# attachment. It then narrows continuously instead of behaving like a tube.
	var tail_lift := float((dragon_seed % 5) - 2) * 3.0
	var curve := _build_tapered_curve(
		Vector2(174, 264), Vector2(224, 294), Vector2(273, 286 + tail_lift * 0.35), Vector2(296, 242 + tail_lift),
		22.0, 6.5, 20
	)
	var centers: PackedVector2Array = curve["centers"]
	var upper: PackedVector2Array = curve["upper"]
	var lower: PackedVector2Array = curve["lower"]
	var normals: PackedVector2Array = curve["normals"]
	for fin_index in [9, 12, 15]:
		var fin := PackedVector2Array([
			upper[fin_index - 1],
			upper[fin_index] + normals[fin_index] * (11.0 - float(fin_index - 9) * 1.2),
			upper[fin_index + 1],
		])
		_filled_polygon(fin, shade, 1.5)
	var tail_texture := _light_texture(primary, shade, light, 1.0)
	for index in range(centers.size() - 1):
		# One textured quad per bend: the texture interpolates the full cross-section.
		var points := PackedVector2Array([upper[index], upper[index + 1], lower[index + 1], lower[index]])
		var u := 0.36 + float(index) / float(centers.size()) * 0.15
		var next_u := 0.36 + float(index + 1) / float(centers.size()) * 0.15
		var uv := PackedVector2Array([Vector2(u, 0), Vector2(next_u, 0), Vector2(next_u, 1), Vector2(u, 1)])
		draw_polygon(points, PackedColorArray([Color.WHITE]), uv, tail_texture)
	_draw_polyline(upper, shade.lerp(primary, 0.25), 1.4)
	_draw_polyline(lower, INK.lerp(shade, 0.6), 1.6)
	var end: Vector2 = centers[centers.size() - 1]
	var forward := (end - centers[centers.size() - 2]).normalized()
	var side := Vector2(-forward.y, forward.x)
	_draw_tail_tip(end, forward, side, palette)


func _build_tapered_curve(
	start: Vector2,
	control_a: Vector2,
	control_b: Vector2,
	end: Vector2,
	start_half_width: float,
	end_half_width: float,
	segments: int
) -> Dictionary:
	var centers := PackedVector2Array()
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	var normals := PackedVector2Array()
	for index in segments + 1:
		var t := float(index) / float(segments)
		var inverse := 1.0 - t
		var point := (
			start * inverse * inverse * inverse
			+ control_a * 3.0 * inverse * inverse * t
			+ control_b * 3.0 * inverse * t * t
			+ end * t * t * t
		)
		var tangent := (
			(control_a - start) * 3.0 * inverse * inverse
			+ (control_b - control_a) * 6.0 * inverse * t
			+ (end - control_b) * 3.0 * t * t
		).normalized()
		var normal := Vector2(tangent.y, -tangent.x)
		var width := lerpf(start_half_width, end_half_width, smoothstep(0.0, 1.0, t))
		centers.append(point)
		normals.append(normal)
		upper.append(point + normal * width)
		lower.append(point - normal * width)
	var polygon := upper.duplicate()
	for index in range(lower.size() - 1, -1, -1):
		polygon.append(lower[index])
	return {"centers": centers, "upper": upper, "lower": lower, "normals": normals, "polygon": polygon}


func _tail_local(origin: Vector2, forward: Vector2, side: Vector2, along: float, lateral: float) -> Vector2:
	return origin + forward * along + side * lateral


func _draw_tail_tip(origin: Vector2, forward: Vector2, side: Vector2, palette: Dictionary) -> void:
	var points := PackedVector2Array()
	var tip_color: Color = palette["accent"]
	match int(appearance["tail"]):
		0: # Spade
			points = PackedVector2Array([
				_tail_local(origin, forward, side, 0, 5), _tail_local(origin, forward, side, 10, 7),
				_tail_local(origin, forward, side, 17, 14), _tail_local(origin, forward, side, 24, 6),
				_tail_local(origin, forward, side, 32, 0), _tail_local(origin, forward, side, 24, -6),
				_tail_local(origin, forward, side, 17, -14), _tail_local(origin, forward, side, 10, -7),
				_tail_local(origin, forward, side, 0, -5),
			])
		1: # Flame
			points = PackedVector2Array([
				_tail_local(origin, forward, side, 0, 5), _tail_local(origin, forward, side, 10, 7),
				_tail_local(origin, forward, side, 18, 14), _tail_local(origin, forward, side, 20, 4),
				_tail_local(origin, forward, side, 33, 0), _tail_local(origin, forward, side, 22, -4),
				_tail_local(origin, forward, side, 25, -13), _tail_local(origin, forward, side, 13, -7),
				_tail_local(origin, forward, side, 0, -5),
			])
		2: # Leaf
			tip_color = palette["light"]
			points = PackedVector2Array([
				_tail_local(origin, forward, side, 0, 5), _tail_local(origin, forward, side, 12, 10),
				_tail_local(origin, forward, side, 24, 13), _tail_local(origin, forward, side, 34, 0),
				_tail_local(origin, forward, side, 24, -13), _tail_local(origin, forward, side, 12, -10),
				_tail_local(origin, forward, side, 0, -5),
			])
		3: # Crystal
			tip_color = palette["light"]
			points = PackedVector2Array([
				_tail_local(origin, forward, side, 0, 5), _tail_local(origin, forward, side, 14, 11),
				_tail_local(origin, forward, side, 32, 0), _tail_local(origin, forward, side, 14, -11),
				_tail_local(origin, forward, side, 0, -5),
			])
	if int(appearance["tail"]) != 3:
		points = _rounded_contour(points)
	_shaded_shape(points, tip_color, palette["shade"], palette["light"], 1.8)
	var facet := PackedVector2Array([
		_tail_local(origin, forward, side, 2, 0),
		_tail_local(origin, forward, side, 14, 0),
		_tail_local(origin, forward, side, 27, 0),
		_tail_local(origin, forward, side, 14, -6),
	])
	_filled_polygon(facet, Color(palette["shade"], 0.52), 0.0)
	_draw_line(_tail_local(origin, forward, side, 4, 0), _tail_local(origin, forward, side, 27, 0), Color(palette["light"], 0.74), 1.8)




func _draw_sparkles(palette: Dictionary) -> void:
	_draw_star(Vector2(48, 75), 12.0, palette["accent"])
	_draw_star(Vector2(274, 95), 9.0, palette["light"])
	_draw_star(Vector2(286, 176), 6.0, palette["accent"])


func _draw_crescent(center: Vector2, radius: float, color: Color, cutout: Color) -> void:
	_ellipse(center, Vector2(radius, radius), color, 14, 0.0)
	_ellipse(center + Vector2(5, -3), Vector2(radius * 0.78, radius * 0.78), cutout, 14, 0.0)


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -radius), center + Vector2(radius * 0.28, -radius * 0.28),
		center + Vector2(radius, 0), center + Vector2(radius * 0.28, radius * 0.28),
		center + Vector2(0, radius), center + Vector2(-radius * 0.28, radius * 0.28),
		center + Vector2(-radius, 0), center + Vector2(-radius * 0.28, -radius * 0.28),
	])
	_filled_polygon(points, color, 0.0)




func _rounded_contour(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in points.size():
		var point := points[index]
		var previous := points[(index - 1 + points.size()) % points.size()]
		var next := points[(index + 1) % points.size()]
		result.append_array(_quadratic_curve_points(point.lerp(previous, 0.18), point, point.lerp(next, 0.18), 6))
	return result
