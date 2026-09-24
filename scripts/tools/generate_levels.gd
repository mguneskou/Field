extends SceneTree
## Dev tool, not part of the shipped game: builds LevelDefinition
## resources in code and saves them as .tres files. Safer than hand-
## authoring the Godot text-resource format.
## Run with: godot --headless --path . --script res://scripts/tools/generate_levels.gd
##
## Level roster redesigned 2026-09 after playtesting feedback: the
## original 20-level roster was almost entirely electric/magnetic-field
## drills and felt repetitive. Trimmed to 4 EM levels that each teach a
## genuinely distinct idea (single force, charge sign, combined field +
## obstacle, multi-particle attraction), then the roster moves on to
## other physics systems (relativity, annihilation, pair production,
## symmetry breaking) rather than continuing to drill electromagnetism.

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

func _photon(position: Vector2, velocity: Vector2, momentum_magnitude: float) -> ParticleSpawn:
	var s := _particle("photon", position, velocity)
	s.momentum_magnitude = momentum_magnitude
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
	l.level_name = "Level 3 — Electric + Magnetic"
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

func _level_04() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_04"
	l.level_name = "Level 4 — Coulomb Attraction"
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

func _level_05() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_05"
	l.level_name = "Level 5 — Nothing Outruns Light"
	l.difficulty = 2
	l.tutorial_text = "This universe has a speed limit, c. Push as hard as you like — watch the trail: instead of spreading further and further apart, the dots settle into a steady rhythm as your speed approaches (but never reaches) the limit."
	l.world_size = Vector2(1280, 720)
	l.relativistic = true
	l.speed_of_light = 400.0
	l.particles = [_particle("positive", Vector2(150, 360))]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = false
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 300.0
	l.targets = [_target(Vector2(1130, 360), 34.0)]
	return l

func _level_06() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_06"
	l.level_name = "Level 6 — Annihilation"
	l.difficulty = 2
	l.tutorial_text = "An electron and a positron are opposite charges — point the field so they're both pulled toward each other. When they touch: e⁻ + e⁺ → γ + γ. Matter into pure energy."
	l.world_size = Vector2(1280, 720)
	l.particles = [
		_particle("electron", Vector2(450, 360)),
		_particle("positron", Vector2(830, 360)),
	]
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 80.0
	l.objective_kind = LevelDefinition.ObjectiveKind.CAPTURE
	l.capture_particle_a = 0
	l.capture_particle_b = 1
	return l

func _level_07() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_07"
	l.level_name = "Level 7 — Pair Production"
	l.difficulty = 2
	l.tutorial_text = "The reverse is also true: enough energy in one place can create matter out of pure light. γ + γ → e⁻ + e⁺. Press Play and watch the flash."
	l.world_size = Vector2(1280, 720)
	l.speed_of_light = 300.0
	l.particles = [
		_photon(Vector2(300, 360), Vector2(300, 0), 700.0),
		_photon(Vector2(980, 360), Vector2(-300, 0), 700.0),
	]
	l.field_direction_editable = false
	l.field_strength_editable = false
	l.targets = [
		_target(Vector2(640, 180), 44.0, -1),
		_target(Vector2(640, 540), 44.0, -1),
	]
	return l

func _level_08() -> LevelDefinition:
	var l := LevelDefinition.new()
	l.id = "level_08"
	l.level_name = "Level 8 — Symmetry Breaking"
	l.difficulty = 3
	l.tutorial_text = "This field has an unstable peak at the center and a stable ring around it. Give the particle a brief nudge in one direction, then dial the field back to zero and watch where it settles."
	l.world_size = Vector2(1280, 720)
	l.particles = [_particle("positive", Vector2(640, 360))]
	l.symmetry_breaking_enabled = true
	l.symmetry_breaking_center = Vector2(640, 360)
	l.symmetry_breaking_a = 0.01
	l.symmetry_breaking_b = 150.0
	l.symmetry_breaking_damping = 0.5
	l.initial_field_direction = Vector2.RIGHT
	l.initial_field_strength = 0.0
	l.field_direction_editable = true
	l.field_strength_editable = true
	l.field_strength_min = 0.0
	l.field_strength_max = 20.0
	l.targets = [_target(Vector2(790, 360), 55.0)]
	return l
