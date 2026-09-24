class_name TestObjective
extends TestCase

func _make_world(spawns: Array) -> PhysicsWorld:
	var world := PhysicsWorld.new()
	for i in range(spawns.size()):
		var p: Particle = spawns[i]
		p.spawn_index = i
		world.add_particle(p)
	return world

func test_reach_target_requires_all_targets() -> void:
	var level := LevelDefinition.new()
	level.objective_kind = LevelDefinition.ObjectiveKind.REACH_TARGET
	var t1 := TargetDefinition.new()
	t1.position = Vector2(0, 0)
	t1.radius = 10.0
	t1.particle_index = 0
	level.targets = [t1]

	var world := _make_world([Particle.new(ParticleTypes.positive(), Vector2(100, 100))])
	var obj := Objective.new()
	assert_eq(obj.evaluate(level, world, 1.0 / 60.0), Objective.Status.RUNNING,
		"should not succeed while particle is far from target")

	world.particles[0].position = Vector2(0, 0)
	assert_eq(obj.evaluate(level, world, 1.0 / 60.0), Objective.Status.SUCCESS,
		"should succeed once particle overlaps target")

func test_checkpoints_must_be_visited_in_order() -> void:
	var level := LevelDefinition.new()
	level.objective_kind = LevelDefinition.ObjectiveKind.CHECKPOINTS
	var t1 := TargetDefinition.new()
	t1.position = Vector2(0, 0)
	t1.radius = 10.0
	t1.particle_index = 0
	var t2 := TargetDefinition.new()
	t2.position = Vector2(100, 0)
	t2.radius = 10.0
	t2.particle_index = 0
	level.targets = [t1, t2]

	var world := _make_world([Particle.new(ParticleTypes.positive(), Vector2(100, 0))])
	var obj := Objective.new()
	# Touching the second checkpoint first should NOT count while first is unvisited.
	assert_eq(obj.evaluate(level, world, 1.0 / 60.0), Objective.Status.RUNNING,
		"visiting checkpoint 2 before checkpoint 1 should not advance")
	assert_eq(obj.next_checkpoint_index, 0, "checkpoint index should not advance out of order")

	world.particles[0].position = Vector2(0, 0)
	obj.evaluate(level, world, 1.0 / 60.0)
	assert_eq(obj.next_checkpoint_index, 1, "visiting checkpoint 1 should advance the index")

	world.particles[0].position = Vector2(100, 0)
	assert_eq(obj.evaluate(level, world, 1.0 / 60.0), Objective.Status.SUCCESS,
		"visiting both checkpoints in order should succeed")

func test_hold_in_region_requires_sustained_duration() -> void:
	var level := LevelDefinition.new()
	level.objective_kind = LevelDefinition.ObjectiveKind.HOLD_IN_REGION
	level.hold_duration = 1.0
	var t := TargetDefinition.new()
	t.position = Vector2(0, 0)
	t.radius = 10.0
	t.particle_index = 0
	level.targets = [t]

	var world := _make_world([Particle.new(ParticleTypes.positive(), Vector2(0, 0))])
	var obj := Objective.new()
	var dt := 1.0 / 60.0
	for i in range(30): # 0.5s, half the required duration
		assert_eq(obj.evaluate(level, world, dt), Objective.Status.RUNNING,
			"should not succeed before hold_duration elapses")

	world.particles[0].position = Vector2(500, 500) # leaves the region
	obj.evaluate(level, world, dt)
	assert_almost_eq(obj.hold_timer, 0.0, 0.001, "leaving the region should reset the hold timer")

func test_capture_succeeds_when_particles_touch() -> void:
	var level := LevelDefinition.new()
	level.objective_kind = LevelDefinition.ObjectiveKind.CAPTURE
	level.capture_particle_a = 0
	level.capture_particle_b = 1

	var a := Particle.new(ParticleTypes.positive(), Vector2(-50, 0))
	var b := Particle.new(ParticleTypes.negative(), Vector2(50, 0))
	var world := _make_world([a, b])
	var obj := Objective.new()
	assert_eq(obj.evaluate(level, world, 1.0 / 60.0), Objective.Status.RUNNING,
		"should not succeed while particles are apart")

	b.position = a.position
	assert_eq(obj.evaluate(level, world, 1.0 / 60.0), Objective.Status.SUCCESS,
		"should succeed once particles overlap")

func test_separate_succeeds_past_distance_threshold() -> void:
	var level := LevelDefinition.new()
	level.objective_kind = LevelDefinition.ObjectiveKind.SEPARATE
	level.separate_particle_a = 0
	level.separate_particle_b = 1
	level.separate_distance = 200.0

	var a := Particle.new(ParticleTypes.positive(), Vector2(0, 0))
	var b := Particle.new(ParticleTypes.positive(), Vector2(50, 0))
	var world := _make_world([a, b])
	var obj := Objective.new()
	assert_eq(obj.evaluate(level, world, 1.0 / 60.0), Objective.Status.RUNNING,
		"should not succeed while particles are close")

	b.position = Vector2(250, 0)
	assert_eq(obj.evaluate(level, world, 1.0 / 60.0), Objective.Status.SUCCESS,
		"should succeed once particles are far enough apart")

func test_obstacle_collision_fails_regardless_of_objective_kind() -> void:
	var level := LevelDefinition.new()
	var o := ObstacleDefinition.new()
	o.position = Vector2(0, 0)
	o.radius = 20.0
	level.obstacles = [o]

	var world := _make_world([Particle.new(ParticleTypes.positive(), Vector2(0, 0))])
	var obj := Objective.new()
	assert_eq(obj.evaluate(level, world, 1.0 / 60.0), Objective.Status.FAILURE,
		"touching an obstacle should always fail the level")

func test_all_particles_lost_fails() -> void:
	var level := LevelDefinition.new()
	var spawn := ParticleSpawn.new()
	level.particles = [spawn]

	var world := PhysicsWorld.new() # no live particles
	var obj := Objective.new()
	assert_eq(obj.evaluate(level, world, 1.0 / 60.0), Objective.Status.FAILURE,
		"losing every particle should fail rather than hang forever")
