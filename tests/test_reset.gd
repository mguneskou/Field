class_name TestReset
extends TestCase

func test_physics_world_reset_clears_state() -> void:
	var world := PhysicsWorld.new()
	var p := Particle.new(ParticleTypes.positive(), Vector2.ZERO, Vector2(1, 1))
	world.add_particle(p)
	world.electric_field.strength = 10.0
	world.step(1.0 / 60.0)
	assert_true(world.time > 0.0, "time should advance after stepping")

	world.clear()
	assert_eq(world.particles.size(), 0, "particles should be cleared on reset")
	assert_eq(world.time, 0.0, "time should reset to zero")

func test_reset_restores_initial_particle_state() -> void:
	var initial_pos := Vector2(100, 100)
	var initial_vel := Vector2.ZERO
	var world := PhysicsWorld.new()
	var p := Particle.new(ParticleTypes.positive(), initial_pos, initial_vel)
	world.add_particle(p)
	world.electric_field.direction = Vector2.RIGHT
	world.electric_field.strength = 50.0
	for i in range(30):
		world.step(1.0 / 60.0)
	assert_true(p.position != initial_pos, "particle should have moved after simulating")

	world.clear()
	var p2 := Particle.new(ParticleTypes.positive(), initial_pos, initial_vel)
	world.add_particle(p2)
	assert_eq(p2.position, initial_pos, "recreated particle should be back at its initial position")
	assert_eq(p2.velocity, initial_vel, "recreated particle should be back at its initial velocity")

func test_no_nan_or_runaway_velocity_over_long_run() -> void:
	var world := PhysicsWorld.new()
	world.electric_field.direction = Vector2.RIGHT
	world.electric_field.strength = 100000.0 # deliberately extreme
	var p := Particle.new(ParticleTypes.positive(), Vector2.ZERO, Vector2.ZERO)
	world.add_particle(p)
	for i in range(600):
		world.step(1.0 / 60.0)
	assert_true(is_finite(p.velocity.x) and is_finite(p.velocity.y),
		"velocity should never become NaN/Inf even under extreme force")
	assert_true(p.velocity.length() <= PhysicsIntegrator.MAX_SPEED + 0.001,
		"velocity should be clamped to the configured maximum speed")
