class_name TestConservation
extends TestCase

func test_charge_is_conserved_over_time() -> void:
	var world := PhysicsWorld.new()
	world.interaction_system.enabled = true
	world.add_particle(Particle.new(ParticleTypes.positive(), Vector2(-40, 0)))
	world.add_particle(Particle.new(ParticleTypes.negative(), Vector2(40, 0)))
	var before := ConservationTracker.total_charge(world)
	for i in range(120):
		world.step(1.0 / 60.0)
	var after := ConservationTracker.total_charge(world)
	assert_almost_eq(after, before, 0.0001, "total charge should never change")
	assert_almost_eq(after, 0.0, 0.0001, "a +1/-1 pair should sum to zero charge")

func test_momentum_conserved_in_isolated_coulomb_pair() -> void:
	# No external field, no obstacles: Newton's third law means the pair's
	# internal forces cancel at every step, so total momentum should stay
	# constant (starting at zero, since both particles start at rest).
	var world := PhysicsWorld.new()
	world.interaction_system.enabled = true
	world.add_particle(Particle.new(ParticleTypes.positive(), Vector2(-60, 0)))
	world.add_particle(Particle.new(ParticleTypes.negative(), Vector2(60, 0)))
	var before := ConservationTracker.total_momentum(world)
	for i in range(180):
		world.step(1.0 / 60.0)
	var after := ConservationTracker.total_momentum(world)
	assert_vec_almost_eq(after, before, 0.5,
		"an isolated pair's total momentum should stay ~constant (Newton's third law)")

func test_speed_and_energy_conserved_under_pure_magnetic_field() -> void:
	# The magnetic force is always perpendicular to velocity, so it does no
	# work: kinetic energy (and therefore speed) should stay constant. The
	# Boris integrator preserves this almost exactly, so use a tight bound.
	var world := PhysicsWorld.new()
	world.magnetic_field.strength = 3.0
	var p := Particle.new(ParticleTypes.positive(), Vector2.ZERO, Vector2(120.0, 0.0))
	world.add_particle(p)
	var before := ConservationTracker.total_energy(world)
	for i in range(300):
		world.step(1.0 / 60.0)
	var after := ConservationTracker.total_energy(world)
	assert_almost_eq(after, before, before * 0.005,
		"kinetic energy should be conserved under a pure magnetic field (it does no work)")

func test_relativistic_energy_and_momentum_conserved_without_external_force() -> void:
	var world := PhysicsWorld.new()
	world.relativistic = true
	world.speed_of_light = 1000.0
	var p := Particle.new(ParticleTypes.neutral(), Vector2.ZERO, Vector2(600.0, 200.0))
	world.add_particle(p)
	var e_before := ConservationTracker.total_energy(world)
	var p_before := ConservationTracker.total_momentum(world)
	for i in range(120):
		world.step(1.0 / 60.0)
	assert_almost_eq(ConservationTracker.total_energy(world), e_before, e_before * 0.001,
		"a free relativistic particle's energy should not change with no force acting")
	assert_vec_almost_eq(ConservationTracker.total_momentum(world), p_before, 0.01,
		"a free relativistic particle's momentum should not change with no force acting")

func test_photon_energy_comes_from_momentum_magnitude_not_velocity() -> void:
	var world := PhysicsWorld.new()
	world.speed_of_light = 500.0
	var photon := Particle.new(ParticleTypes.photon(), Vector2.ZERO, Vector2(500.0, 0.0))
	photon.momentum_magnitude = 12.0
	world.add_particle(photon)
	assert_almost_eq(ConservationTracker.total_energy(world), 12.0 * 500.0, 0.001,
		"photon energy should be momentum_magnitude * c, independent of its (always-c) velocity")
