class_name DragonViews
extends "res://scripts/ui/seeded_dragon.gd"

## Every view consumes the same seed, palette, horns, markings and body traits.
## Portrait anatomy stays unchanged; flight views reuse its actual head renderer.
var view_pose := "portrait"

func _draw() -> void:
	if view_pose == "portrait":
		super._draw()
		return
	if appearance.is_empty() or size.x <= 0 or size.y <= 0:
		return
	var art := Vector2(320, 220) if view_pose == "flight" else Vector2(320, 360)
	var factor := minf(size.x / art.x, size.y / art.y)
	var origin := (size - art * factor) * 0.5
	var palette: Dictionary = PALETTES[int(appearance["palette"])]
	draw_set_transform(origin, 0, Vector2.ONE * factor)
	if view_pose == "flight":
		_flight(palette, origin, factor)
	else:
		_overhead(palette, origin, factor)
	draw_set_transform(Vector2.ZERO)

func _skin(points: PackedVector2Array, p: Dictionary, dark := false) -> void:
	_shaded_shape(points, p["primary"].darkened(0.15) if dark else p["primary"], p["shade"], p["light"], 2.0)

func _flight(p: Dictionary, origin: Vector2, factor: float) -> void:
	var sturdy := float(appearance["body"]) * 3.0
	var sweep := float(appearance["wings"]) * 5.0
	# Far wing, tail and tucked hind legs sit behind one continuous torso.
	var far_wing := _path(Vector2(189, 131), [[Vector2(154, 109), Vector2(171, 39), Vector2(119+sweep, 22)], [Vector2(133, 61), Vector2(105, 90), Vector2(106, 120)], [Vector2(147, 106), Vector2(154, 144), Vector2(189, 131)]])
	_skin(far_wing, p, true)
	var tail := _path(Vector2(127, 134), [[Vector2(90, 151), Vector2(46, 185), Vector2(21, 155)], [Vector2(7, 143), Vector2(11, 131), Vector2(9, 125)], [Vector2(31, 158), Vector2(58, 146), Vector2(75, 132)], [Vector2(92, 117), Vector2(117, 112), Vector2(127, 134)]])
	_skin(tail, p)
	var tail_tip := int(appearance["tail"])
	if tail_tip == 3:
		_shaded_shape(PackedVector2Array([Vector2(8,143), Vector2(1,121), Vector2(10,110), Vector2(24,127)]), p["accent"], p["shade"], p["light"], 1.5)
	else:
		_skin(_path(Vector2(13,146), [[Vector2(-3,136), Vector2(7,116-tail_tip*3), Vector2(7,112)], [Vector2(17,123), Vector2(31,128), Vector2(13,146)]]), p)
	for x in [124.0, 169.0]:
		_skin(_path(Vector2(x,154), [[Vector2(x-7,166), Vector2(x-4,185), Vector2(x+20,182)], [Vector2(x+30,173), Vector2(x+5,175), Vector2(x+10,150)]]), p, true)
		_draw_claw(Vector2(x+21,178), 3)
	var torso := _path(Vector2(93,139), [[Vector2(99,111-sturdy), Vector2(163,96-sturdy), Vector2(193,108)], [Vector2(222,114), Vector2(247,135), Vector2(227,157)], [Vector2(200,189+sturdy), Vector2(106,181+sturdy), Vector2(93,139)]])
	_skin(torso, p)
	_shaded_shape(_path(Vector2(142,156), [[Vector2(168,146), Vector2(207,140), Vector2(223,144)], [Vector2(220,173), Vector2(169,181), Vector2(142,156)]]), CREAM, CREAM_SHADE, Color.WHITE, 0)
	# One swept membrane with a shared shoulder, rather than overlapping triangles.
	var root_point := Vector2(185,132)
	var elbow := Vector2(115,69)
	var tip := Vector2(66+sweep,23)
	var wing := _path(root_point, [[Vector2(160,117), Vector2(140,62), elbow], [Vector2(104,49), Vector2(80,28), tip], [Vector2(83,62), Vector2(71,85), Vector2(39,104)], [Vector2(76,98), Vector2(94,111), Vector2(93,142)], [Vector2(124,123), Vector2(157,130), root_point]])
	_shaded_shape(wing, p["primary"].lerp(p["accent"], 0.33), p["shade"], p["light"], 2.2, 0.75)
	for end in [Vector2(39,104), Vector2(93,142), root_point]:
		var rib := _quadratic_curve_points(elbow, elbow.lerp(end,0.5)+Vector2(8,4),end,24)
		_draw_polyline(rib,p["shade"],3.2)
		_draw_polyline(rib,p["light"],1.1)
	_draw_polyline(_quadratic_curve_points(root_point,Vector2(141,91),tip,32),p["primary"],5)
	# The portrait's head is mirrored into a right-facing three-quarter view.
	var head: Vector2 = _body_geometry()["head"]
	var head_scale := Vector2(-0.70, 0.70)
	draw_set_transform(origin + (Vector2(246,105)-head*head_scale)*factor,0,head_scale*factor)
	_draw_cheek_frills(p)
	_draw_horns(p)
	_draw_head(p)
	_draw_crest(p)
	_draw_head_pattern(p)
	_draw_face(p)

func _overhead(p: Dictionary, origin: Vector2, factor: float) -> void:
	var width := 34.0 + int(appearance["body"])*4.0
	var sweep := float(appearance["wings"])*6.0
	# The body narrows into the tail without a stack of detached ellipses.
	var body := _path(Vector2(160-width,140), [[Vector2(103,193),Vector2(144,256),Vector2(159,276)], [Vector2(177,304),Vector2(149,321),Vector2(129,335)], [Vector2(185,330),Vector2(194,288),Vector2(179,260)], [Vector2(213,208),Vector2(206,170),Vector2(160+width,140)], [Vector2(185,117),Vector2(131,118),Vector2(160-width,140)]])
	for direction in [-1.0,1.0]:
		var root_point := Vector2(160+direction*26,167)
		var tip := Vector2(160+direction*137,112-sweep)
		var elbow := Vector2(160+direction*85,127)
		var middle := Vector2(160+direction*128,211)
		var end := Vector2(160+direction*62,240)
		var wing := _path(root_point,[[Vector2(160+direction*56,125),elbow,tip],[Vector2(160+direction*119,153),Vector2(160+direction*109,177),middle],[Vector2(160+direction*88,186),Vector2(160+direction*79,208),end],[Vector2(160+direction*53,219),Vector2(160+direction*30,215),root_point]])
		_shaded_shape(wing,p["primary"].lerp(p["accent"],0.40),p["shade"],p["light"],2,0.7)
		for edge in [middle,end]:
			_draw_polyline(_quadratic_curve_points(elbow,elbow.lerp(edge,.5)+Vector2(-direction*8,-3),edge,24),p["shade"],2.5)
		_skin(_path(Vector2(160+direction*29,232),[[Vector2(160+direction*62,233),Vector2(160+direction*63,258),Vector2(160+direction*48,263)],[Vector2(160+direction*30,264),Vector2(160+direction*30,241),Vector2(160+direction*29,232)]]),p,true)
	_skin(body,p)
	# Paired swept horns and cheek fins read from above, with a foreshortened snout.
	var head: Vector2 = _body_geometry()["head"]
	var horn_scale := Vector2(0.73, -0.62)
	draw_set_transform(origin + (Vector2(160,108)-head*horn_scale)*factor,0,horn_scale*factor)
	_draw_horns(p)
	draw_set_transform(origin,0,Vector2.ONE*factor)
	_skin(_path(Vector2(112,103),[[Vector2(109,82),Vector2(123,61),Vector2(143,60)],[Vector2(177,50),Vector2(203,77),Vector2(209,100)],[Vector2(213,131),Vector2(186,153),Vector2(159,150)],[Vector2(131,152),Vector2(107,130),Vector2(112,103)]]),p)
	_volume(Vector2(159,73),Vector2(32,24),p["primary"],p["shade"],p["light"],1.5)
	for direction in [-1.0,1.0]:
		var eye := Vector2(160+direction*38,88)
		_volume(eye,Vector2(7,13),Color("#172133"),Color("#172133"),EYE_COLORS[int(appearance["eyes"])],1)
		_ellipse(eye+Vector2(-2,-5),Vector2(2.5,4),Color.WHITE,24,0)
		_ellipse(Vector2(160+direction*12,57),Vector2(2,3),p["shade"],24,0)
	for index in 5:
		var y := 137.0+index*23
		var radius := 8.0-index*.7
		_shaded_shape(_path(Vector2(160-radius,y+5),[[Vector2(160-radius,y-3),Vector2(160,y-13),Vector2(160,y-13)],[Vector2(160+radius,y-3),Vector2(160+radius,y+5),Vector2(160-radius,y+5)]]),p["accent"],p["shade"],p["light"],1)
	# Seed-specific forehead marks remain visible in the small view.
	var mark_origin := head + Vector2(-5,-35)
	draw_set_transform(origin + (Vector2(159,113)-mark_origin)*factor,0,Vector2.ONE*factor)
	_draw_head_pattern(p)
	draw_set_transform(origin,0,Vector2.ONE*factor)
