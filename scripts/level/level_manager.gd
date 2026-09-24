class_name LevelManager
extends Node
## Builds a PhysicsWorld from a LevelDefinition, drives it forward with a
## fixed timestep (sub-stepped for sim-speed control), and evaluates the
## objective each step. The only bridge between "level data" and "physics".

signal level_loaded(level: LevelDefinition)
signal level_completed
signal level_failed
signal status_changed(status: int)

const FIXED_DT := 1.0 / 60.0

var current_level: LevelDefinition
var world: PhysicsWorld
var is_running: bool = false
var sim_speed: float = 1.0
var status: int = Objective.Status.RUNNING
var replay_recorder: ReplayRecorder = ReplayRecorder.new()
var objective: Objective = Objective.new()

var _speed_accumulator: float = 0.0

func load_level(level: LevelDefinition) -> void:
	current_level = level
	_rebuild_world()

func reset() -> void:
	if current_level == null:
		return
	_rebuild_world()

func play() -> void:
	is_running = true

func pause() -> void:
	is_running = false

func toggle_play_pause() -> void:
	is_running = not is_running

func set_sim_speed(speed: float) -> void:
	sim_speed = speed

func set_field_direction(dir: Vector2) -> void:
	if current_level == null or not current_level.field_direction_editable:
		return
	world.electric_field.set_direction(dir)

func set_field_strength(value: float) -> void:
	if current_level == null or not current_level.field_strength_editable:
		return
	world.electric_field.strength = clamp(value, current_level.field_strength_min, current_level.field_strength_max)

func set_magnetic_strength(value: float) -> void:
	if current_level == null or not current_level.magnetic_editable:
		return
	world.magnetic_field.strength = clamp(value, current_level.magnetic_strength_min, current_level.magnetic_strength_max)

func _rebuild_world() -> void:
	world = PhysicsWorld.new()
	world.electric_field.direction = current_level.initial_field_direction
	world.electric_field.strength = current_level.initial_field_strength
	world.magnetic_field.strength = current_level.initial_magnetic_strength
	world.interaction_system.enabled = current_level.coulomb_enabled
	world.bounds = Rect2(Vector2.ZERO, current_level.world_size)

	world.relativistic = current_level.relativistic
	world.speed_of_light = current_level.speed_of_light

	world.symmetry_breaking.enabled = current_level.symmetry_breaking_enabled
	world.symmetry_breaking.center = current_level.symmetry_breaking_center
	world.symmetry_breaking.a = current_level.symmetry_breaking_a
	world.symmetry_breaking.b = current_level.symmetry_breaking_b
	world.symmetry_breaking.damping = current_level.symmetry_breaking_damping

	for i in range(current_level.particles.size()):
		var spawn: ParticleSpawn = current_level.particles[i]
		var p := Particle.new(ParticleTypes.by_id(spawn.type_id), spawn.position, spawn.velocity)
		if spawn.mass_override > 0.0:
			p.mass = spawn.mass_override
		p.momentum_magnitude = spawn.momentum_magnitude
		p.spawn_index = i
		world.add_particle(p)

	is_running = false
	_speed_accumulator = 0.0
	status = Objective.Status.RUNNING
	objective = Objective.new()
	replay_recorder.start()
	status_changed.emit(status)
	level_loaded.emit(current_level)

func _physics_process(_delta: float) -> void:
	if not is_running or current_level == null or status != Objective.Status.RUNNING:
		return

	_speed_accumulator += sim_speed
	while _speed_accumulator >= 1.0:
		# Motion first, then the objective check, then reactions — so a
		# CAPTURE objective on two colliding particles sees them actually
		# touching before annihilation/pair production could consume them
		# first. See PhysicsWorld.step_reactions()'s docstring.
		world.step_motion(FIXED_DT)
		replay_recorder.capture(world)
		_speed_accumulator -= 1.0

		var new_status := objective.evaluate(current_level, world, FIXED_DT)
		if new_status != status:
			status = new_status
			status_changed.emit(status)

		# Run reactions every tick regardless of what the objective just
		# found — even on the tick where CAPTURE just succeeded, so the
		# player still sees the annihilation flash into photons rather
		# than the sim freezing one frame early on "still touching."
		# Success/failure was already correctly decided from the
		# pre-reaction state above.
		world.step_reactions()

		if status != Objective.Status.RUNNING:
			is_running = false
			if status == Objective.Status.SUCCESS:
				level_completed.emit()
			else:
				level_failed.emit()
			break
