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
