extends SceneTree
## Dev tool, not part of the shipped game: builds LevelDefinition
## resources in code and saves them as .tres files. Safer than hand-
## authoring the Godot text-resource format, and doubles as the pattern
## for adding more of the planned 20 levels later.
## Run with: godot --headless --path . --script res://scripts/tools/generate_levels.gd

func _init() -> void:
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("levels"):
		dir.make_dir("levels")

	_save(_level_01())
	_save(_level_02())
	_save(_level_03())
	_save(_level_04())
	_save(_level_05())
	_save(_level_06())
	_save(_level_07())
	_save(_level_08())
	_save(_level_09())
	_save(_level_10())
	_save(_level_11())
	_save(_level_12())
	_save(_level_13())
	_save(_level_14())
	_save(_level_15())
	_save(_level_16())
	_save(_level_17())
	_save(_level_18())
	_save(_level_19())
	_save(_level_20())

	print("Level generation complete.")
	quit(0)

func _save(level: LevelDefinition) -> void:
	var path := "res://levels/%s.tres" % level.id
	var err := ResourceSaver.save(level, path)
	if err != OK:
		printerr("Failed to save %s: error %d" % [path, err])
	else:
		print("Saved %s" % path)

func _particle(type_id: String, position: Vector2, velocity: Vector2 = Vector2.ZERO) -> ParticleSpawn:
	var s := ParticleSpawn.new()
	s.type_id = type_id
	s.position = position
	s.velocity = velocity
	return s

func _target(position: Vector2, radius: float, particle_index: int = 0) -> TargetDefinition:
	var t := TargetDefinition.new()
	t.position = position
	t.radius = radius
	t.particle_index = particle_index
	return t

func _obstacle(position: Vector2, radius: float) -> ObstacleDefinition:
	var o := ObstacleDefinition.new()
	o.position = position
	o.radius = radius
	return o

func _level_01() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_01"
	l.level_name = "Level 1 — Positive Charge"
	l.difficulty = 1
	l.tutorial_text = "Positive charges accelerate WITH the electric field (F = qE). Drag the dial to point a field at the target."
	l.world_size = Vector2(1280, 720)
	l.particles = [_particle("positive", Vector2(200, 360))]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 60.0
	l.targets = [_target(Vector2(1080, 360), 32.0)]
	return l

func _level_02() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_02"
	l.level_name = "Level 2 — Negative Charge"
	l.difficulty = 1
	l.tutorial_text = "Negative charges accelerate AGAINST the field direction. Point the field away from the target to push the charge toward it."
	l.world_size = Vector2(1280, 720)
	l.particles = [_particle("negative", Vector2(1080, 360))]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 60.0
	l.targets = [_target(Vector2(200, 360), 32.0)]
	return l

func _level_03() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_03"
	l.level_name = "Level 3 — Field Direction"
	l.difficulty = 2
	l.tutorial_text = "This field's strength is fixed — only its direction is yours to control. Aim carefully to reach the target."
	l.world_size = Vector2(1280, 720)
	l.particles = [_particle("positive", Vector2(640, 600))]
	l.initial_field_direction = Vector2.UP
	l.initial_field_strength = 40.0
	l.field_direction_editable = true
	l.field_strength_editable = false
	l.field_strength_min = 40.0
	l.field_strength_max = 40.0
	l.targets = [_target(Vector2(950, 200), 34.0)]
	return l

func _level_04() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_04"
	l.level_name = "Level 4 — Field Strength"
	l.difficulty = 2
	l.tutorial_text = "This time only field strength is yours to control — and the clock is ticking. Too weak, and you won't make it in time."
	l.world_size = Vector2(1280, 720)
	l.particles = [_particle("positive", Vector2(150, 360))]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = false
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 240.0
	l.targets = [_target(Vector2(950, 360), 32.0)]
	l.time_limit = 3.0
	return l

func _level_05() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_05"
	l.level_name = "Level 5 — Electric + Magnetic"
	l.difficulty = 3
	l.tutorial_text = "Combine both fields: push the charge forward with E, then bend its path with B to curve around the obstacle and into the target."
	l.world_size = Vector2(1280, 720)
	l.particles = [_particle("positive", Vector2(200, 400))]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 120.0
	l.initial_magnetic_strength = 0.0
	l.magnetic_editable = true
	l.magnetic_strength_min = -40.0
	l.magnetic_strength_max = 40.0
	l.obstacles = [_obstacle(Vector2(640, 400), 50.0)]
	l.targets = [_target(Vector2(1000, 200), 40.0)]
	return l

func _level_06() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_06"
	l.level_name = "Level 6 — Neutral Particle"
	l.difficulty = 1
	l.tutorial_text = "Neutral particles ignore electric and magnetic fields entirely. Only the charged particle below will respond — watch the difference."
	l.world_size = Vector2(1280, 720)
	l.particles = [
		_particle("neutral", Vector2(300, 200)),
		_particle("positive", Vector2(300, 520)),
	]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 60.0
	l.targets = [_target(Vector2(980, 520), 32.0, 1)]
	return l

func _level_07() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_07"
	l.level_name = "Level 7 — Stationary vs Moving"
	l.difficulty = 2
	l.tutorial_text = "A stationary charge feels no magnetic force. This field has a fixed magnetic component — but nothing happens until you give the particle some velocity with the electric field."
	l.world_size = Vector2(1280, 720)
	l.particles = [_particle("positive", Vector2(300, 500))]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 80.0
	l.initial_magnetic_strength = 22.0
	l.magnetic_editable = false
	l.targets = [_target(Vector2(950, 180), 36.0)]
	return l

func _level_08() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_08"
	l.level_name = "Level 8 — Magnetic Strength"
	l.difficulty = 2
	l.tutorial_text = "Only the magnetic field is yours to control now. Its strength sets how tightly the path curves — and its sign decides which way."
	l.world_size = Vector2(1280, 720)
	l.particles = [_particle("positive", Vector2(250, 400), Vector2.ZERO)]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 40.0
	l.field_direction_editable = false
	l.field_strength_editable = false
	l.field_strength_min = 40.0
	l.field_strength_max = 40.0
	l.initial_magnetic_strength = 0.0
	l.magnetic_editable = true
	l.magnetic_strength_min = -60.0
	l.magnetic_strength_max = 60.0
	l.targets = [_target(Vector2(880, 150), 40.0)]
	return l

func _level_09() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_09"
	l.level_name = "Level 9 — Two Particles, One Field"
	l.difficulty = 2
	l.tutorial_text = "One field, two charges, two different responses. Point the field so the positive charge rides with it and the negative charge rides against it — into their own targets at the same time."
	l.world_size = Vector2(1280, 720)
	l.particles = [
		_particle("positive", Vector2(640, 200)),
		_particle("negative", Vector2(640, 520)),
	]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 70.0
	l.targets = [
		_target(Vector2(1080, 200), 32.0, 0),
		_target(Vector2(200, 520), 32.0, 1),
	]
	return l

func _level_10() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_10"
	l.level_name = "Level 10 — Coulomb Attraction"
	l.difficulty = 1
	l.tutorial_text = "Opposite charges attract through the Coulomb force (F = kq1q2/r²) — no field needed. Press Play and watch them come together."
	l.world_size = Vector2(1280, 720)
	l.particles = [
		_particle("positive", Vector2(560, 360)),
		_particle("negative", Vector2(720, 360)),
	]
	l.coulomb_enabled = true
	l.initial_field_strength = 0.0
	l.field_direction_editable = false
	l.field_strength_editable = false
	l.objective_kind = LevelDefinition.ObjectiveKind.CAPTURE
	l.capture_particle_a = 0
	l.capture_particle_b = 1
	return l

func _level_11() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_11"
	l.level_name = "Level 11 — Coulomb Repulsion"
	l.difficulty = 1
	l.tutorial_text = "Like charges repel through the same Coulomb force. No field needed — just watch them push apart."
	l.world_size = Vector2(1280, 720)
	l.particles = [
		_particle("positive", Vector2(600, 360)),
		_particle("positive", Vector2(680, 360)),
	]
	l.coulomb_enabled = true
	l.initial_field_strength = 0.0
	l.field_direction_editable = false
	l.field_strength_editable = false
	l.targets = [
		_target(Vector2(350, 360), 32.0, 0),
		_target(Vector2(930, 360), 32.0, 1),
	]
	return l

func _level_12() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_12"
	l.level_name = "Level 12 — Obstacles"
	l.difficulty = 2
	l.tutorial_text = "An obstacle blocks the straight path. Curve around it using both fields together."
	l.world_size = Vector2(1280, 720)
	l.particles = [_particle("positive", Vector2(200, 400))]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 90.0
	l.initial_magnetic_strength = 0.0
	l.magnetic_editable = true
	l.magnetic_strength_min = -40.0
	l.magnetic_strength_max = 40.0
	l.obstacles = [_obstacle(Vector2(640, 400), 70.0)]
	l.targets = [_target(Vector2(1050, 280), 38.0)]
	return l

func _level_13() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_13"
	l.level_name = "Level 13 — Multiple Particles"
	l.difficulty = 3
	l.tutorial_text = "Three particles, one shared field. Positive and negative charges answer it differently — find a direction that gets all three home at once."
	l.world_size = Vector2(1280, 720)
	l.particles = [
		_particle("positive", Vector2(250, 130)),
		_particle("negative", Vector2(1030, 400)),
		_particle("positive", Vector2(250, 670)),
	]
	l.coulomb_enabled = false
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 70.0
	l.targets = [
		_target(Vector2(1030, 130), 46.0, 0),
		_target(Vector2(250, 400), 46.0, 1),
		_target(Vector2(1030, 670), 46.0, 2),
	]
	return l

func _level_14() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_14"
	l.level_name = "Level 14 — Checkpoints"
	l.difficulty = 3
	l.tutorial_text = "Fly through the checkpoints in order. You'll likely need to pause, change the field, and resume mid-flight."
	l.world_size = Vector2(1280, 720)
	l.particles = [_particle("positive", Vector2(150, 360))]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 90.0
	l.initial_magnetic_strength = 0.0
	l.magnetic_editable = true
	l.magnetic_strength_min = -40.0
	l.magnetic_strength_max = 40.0
	l.objective_kind = LevelDefinition.ObjectiveKind.CHECKPOINTS
	l.targets = [
		_target(Vector2(450, 200), 30.0),
		_target(Vector2(750, 520), 30.0),
		_target(Vector2(1080, 300), 30.0),
	]
	return l

func _level_15() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_15"
	l.level_name = "Level 15 — Time Constraint"
	l.difficulty = 3
	l.tutorial_text = "Same idea, new pressure: curve around the obstacle and reach the target before time runs out."
	l.world_size = Vector2(1280, 720)
	l.particles = [_particle("positive", Vector2(150, 360))]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 150.0
	l.initial_magnetic_strength = 0.0
	l.magnetic_editable = true
	l.magnetic_strength_min = -50.0
	l.magnetic_strength_max = 50.0
	l.obstacles = [_obstacle(Vector2(640, 360), 55.0)]
	l.targets = [_target(Vector2(1080, 250), 34.0)]
	l.time_limit = 4.0
	return l

func _level_16() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_16"
	l.level_name = "Level 16 — Particle Separation"
	l.difficulty = 3
	l.tutorial_text = "These opposite charges want to attract. Point a field strong enough, in the right direction, to force them apart to a safe distance."
	l.world_size = Vector2(1280, 720)
	l.particles = [
		_particle("positive", Vector2(600, 360)),
		_particle("negative", Vector2(680, 360)),
	]
	l.coulomb_enabled = true
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 120.0
	l.objective_kind = LevelDefinition.ObjectiveKind.SEPARATE
	l.separate_particle_a = 0
	l.separate_particle_b = 1
	l.separate_distance = 350.0
	return l

func _level_17() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_17"
	l.level_name = "Level 17 — Particle Capture"
	l.difficulty = 3
	l.tutorial_text = "This neutral particle won't come to you — it ignores every field. Navigate the charged particle around the obstacle to make contact."
	l.world_size = Vector2(1280, 720)
	l.particles = [
		_particle("positive", Vector2(200, 420)),
		_particle("neutral", Vector2(950, 260)),
	]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 100.0
	l.initial_magnetic_strength = 0.0
	l.magnetic_editable = true
	l.magnetic_strength_min = -40.0
	l.magnetic_strength_max = 40.0
	l.obstacles = [_obstacle(Vector2(600, 380), 55.0)]
	l.objective_kind = LevelDefinition.ObjectiveKind.CAPTURE
	l.capture_particle_a = 0
	l.capture_particle_b = 1
	return l

func _level_18() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_18"
	l.level_name = "Level 18 — Complex Field"
	l.difficulty = 4
	l.tutorial_text = "Two obstacles this time, in opposite corners of the path. A single field curves one way — you'll likely need to pause partway and change it to weave through both."
	l.world_size = Vector2(1280, 720)
	l.particles = [_particle("positive", Vector2(150, 360))]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 140.0
	l.initial_magnetic_strength = 0.0
	l.magnetic_editable = true
	l.magnetic_strength_min = -45.0
	l.magnetic_strength_max = 45.0
	l.obstacles = [
		_obstacle(Vector2(500, 250), 45.0),
		_obstacle(Vector2(780, 480), 45.0),
	]
	l.targets = [_target(Vector2(1100, 360), 36.0)]
	return l

func _level_19() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_19"
	l.level_name = "Level 19 — Open Challenge: Gauntlet"
	l.difficulty = 4
	l.tutorial_text = "Four checkpoints, two obstacles, your choice of path. Take your time — pause, adjust, and plan each leg."
	l.world_size = Vector2(1280, 720)
	l.particles = [_particle("positive", Vector2(120, 360))]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 150.0
	l.initial_magnetic_strength = 0.0
	l.magnetic_editable = true
	l.magnetic_strength_min = -50.0
	l.magnetic_strength_max = 50.0
	l.obstacles = [
		_obstacle(Vector2(450, 360), 50.0),
		_obstacle(Vector2(830, 200), 45.0),
	]
	l.objective_kind = LevelDefinition.ObjectiveKind.CHECKPOINTS
	l.targets = [
		_target(Vector2(300, 150), 28.0),
		_target(Vector2(620, 550), 28.0),
		_target(Vector2(950, 400), 28.0),
		_target(Vector2(1150, 150), 32.0),
	]
	return l

func _level_20() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_20"
	l.level_name = "Level 20 — Open Challenge: Against the Clock"
	l.difficulty = 5
	l.tutorial_text = "Everything you've learned, against the clock. Good luck."
	l.world_size = Vector2(1280, 720)
	l.particles = [_particle("positive", Vector2(120, 360))]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 180.0
	l.initial_magnetic_strength = 0.0
	l.magnetic_editable = true
	l.magnetic_strength_min = -60.0
	l.magnetic_strength_max = 60.0
	l.obstacles = [
		_obstacle(Vector2(400, 300), 48.0),
		_obstacle(Vector2(750, 500), 48.0),
		_obstacle(Vector2(980, 250), 40.0),
	]
	l.objective_kind = LevelDefinition.ObjectiveKind.CHECKPOINTS
	l.targets = [
		_target(Vector2(280, 550), 26.0),
		_target(Vector2(600, 180), 26.0),
		_target(Vector2(880, 550), 26.0),
		_target(Vector2(1150, 300), 30.0),
	]
	l.time_limit = 10.0
	return l
