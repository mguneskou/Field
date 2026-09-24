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

	for i in range(current_level.particles.size()):
		var spawn: ParticleSpawn = current_level.particles[i]
		var p := Particle.new(ParticleTypes.by_id(spawn.type_id), spawn.position, spawn.velocity)
		if spawn.mass_override > 0.0:
			p.mass = spawn.mass_override
		p.spawn_index = i
		world.add_particle(p)

	is_running = false
	_speed_accumulator = 0.0
	status = Objective.Status.RUNNING
	replay_recorder.start()
	status_changed.emit(status)
	level_loaded.emit(current_level)

func _physics_process(_delta: float) -> void:
	if not is_running or current_level == null or status != Objective.Status.RUNNING:
		return

	_speed_accumulator += sim_speed
	while _speed_accumulator >= 1.0:
		world.step(FIXED_DT)
		replay_recorder.capture(world)
		_speed_accumulator -= 1.0

		var new_status := Objective.evaluate(current_level, world)
		if new_status != status:
			status = new_status
			status_changed.emit(status)

		if status != Objective.Status.RUNNING:
			is_running = false
			if status == Objective.Status.SUCCESS:
				level_completed.emit()
			else:
				level_failed.emit()
			break
