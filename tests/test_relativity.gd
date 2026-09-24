class_name TestRelativity
extends TestCase

func test_gamma_is_one_at_rest() -> void:
	assert_almost_eq(RelativisticKinematics.gamma(0.0, 1000.0), 1.0, 0.0001,
		"gamma should be exactly 1 for a stationary particle")

func test_gamma_increases_with_speed() -> void:
	var g_slow := RelativisticKinematics.gamma(100.0, 1000.0)
	var g_fast := RelativisticKinematics.gamma(900.0, 1000.0)
	assert_true(g_fast > g_slow, "gamma should grow as speed approaches c")
	assert_true(g_slow > 1.0, "gamma should exceed 1 for any nonzero speed")

func test_gamma_never_exceeds_finite_bound_near_c() -> void:
	var g := RelativisticKinematics.gamma(999999.0, 1000.0) # absurdly overshot v > c
	assert_true(is_finite(g), "gamma should stay finite even if speed is fed as >= c")

func test_low_speed_momentum_matches_classical_approximation() -> void:
	# At v << c, relativistic momentum should reduce to p ~= m*v.
	var c := 2000.0
	var v := Vector2(5.0, 0.0) # 0.25% of c
	var p := RelativisticKinematics.momentum(3.0, v, c)
	assert_vec_almost_eq(p, v * 3.0, 0.01, "low-speed momentum should match classical m*v")

func test_velocity_from_momentum_is_inverse_of_momentum() -> void:
	var c := 2000.0
	var mass := 2.0
	var v := Vector2(400.0, -250.0)
	var p := RelativisticKinematics.momentum(mass, v, c)
	var recovered := RelativisticKinematics.velocity_from_momentum(mass, p, c)
	assert_vec_almost_eq(recovered, v, 0.01, "velocity_from_momentum should invert momentum()")

func test_velocity_from_momentum_never_reaches_c() -> void:
	var c := 2000.0
	var huge_momentum := Vector2(1.0e8, 0.0)
	var v := RelativisticKinematics.velocity_from_momentum(1.0, huge_momentum, c)
	assert_true(v.length() < c, "no finite momentum should produce a velocity >= c")
	assert_true(v.length() > c * 0.99, "very large momentum should approach c closely")

func test_energy_momentum_relation() -> void:
	# E^2 = (pc)^2 + (mc^2)^2
	var c := 2000.0
	var mass := 1.5
	var speed := 800.0
	var e := RelativisticKinematics.total_energy(mass, speed, c)
	var p := mass * RelativisticKinematics.gamma(speed, c) * speed
	var lhs := e * e
	var rhs := (p * c) * (p * c) + (mass * c * c) * (mass * c * c)
	assert_almost_eq(lhs, rhs, rhs * 0.001, "E^2 should equal (pc)^2 + (mc^2)^2")

func test_relativistic_integration_never_exceeds_speed_of_light() -> void:
	var c := 500.0
	var p := Particle.new(ParticleTypes.positive(), Vector2.ZERO, Vector2.ZERO)
	# Apply a huge, sustained force for a long time — classical integration
	# would blow straight past c.
	for i in range(5000):
		PhysicsIntegrator.integrate_relativistic(p, Vector2(50000.0, 0.0), 1.0 / 60.0, c)
	assert_true(p.velocity.length() < c, "relativistic integration must never reach c")
	assert_true(p.velocity.length() > c * 0.9, "sustained force should push speed close to c")

func test_relativistic_integration_matches_classical_at_low_speed() -> void:
	# At speeds far below c, relativistic and classical integration should
	# agree closely — relativity should not visibly perturb ordinary levels.
	var c := 2000.0
	var p_classical := Particle.new(ParticleTypes.positive(), Vector2.ZERO, Vector2.ZERO)
	var p_relativistic := Particle.new(ParticleTypes.positive(), Vector2.ZERO, Vector2.ZERO)
	for i in range(60): # 1 second of a modest force
		PhysicsIntegrator.integrate(p_classical, Vector2(40.0, 0.0), 1.0 / 60.0)
		PhysicsIntegrator.integrate_relativistic(p_relativistic, Vector2(40.0, 0.0), 1.0 / 60.0, c)
	assert_vec_almost_eq(p_classical.velocity, p_relativistic.velocity, 0.5,
		"at low speed, relativistic and classical integration should nearly agree")

func test_massless_particle_free_streams_ignoring_force() -> void:
	var photon := Particle.new(ParticleTypes.photon(), Vector2.ZERO, Vector2(300.0, 0.0))
	PhysicsIntegrator.integrate_relativistic(photon, Vector2(999999.0, 0.0), 1.0 / 60.0)
	assert_vec_almost_eq(photon.velocity, Vector2(300.0, 0.0), 0.001,
		"a massless particle's velocity should be unaffected by any force")
	assert_vec_almost_eq(photon.position, Vector2(5.0, 0.0), 0.01,
		"a massless particle should still translate at its own velocity")

func test_world_relativistic_flag_gates_integration_mode() -> void:
	var world := PhysicsWorld.new()
	world.relativistic = true
	world.speed_of_light = 300.0
	world.electric_field.direction = Vector2.RIGHT
	world.electric_field.strength = 100000.0 # deliberately extreme
	var p := Particle.new(ParticleTypes.positive(), Vector2.ZERO, Vector2.ZERO)
	world.add_particle(p)
	for i in range(600):
		world.step(1.0 / 60.0)
	assert_true(p.velocity.length() < world.speed_of_light,
		"PhysicsWorld in relativistic mode should never let a particle reach c")
