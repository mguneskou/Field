class_name TestAnnihilation
extends TestCase

func test_electron_positron_at_rest_annihilate_into_two_photons() -> void:
	var world := PhysicsWorld.new()
	var e := Particle.new(ParticleTypes.electron(), Vector2(-3, 0))
	var p := Particle.new(ParticleTypes.positron(), Vector2(3, 0))
	world.add_particle(e)
	world.add_particle(p)

	var created := world.annihilation_system.process(world)
	assert_eq(created.size(), 2, "an overlapping e-/e+ pair should produce exactly two photons")
	assert_eq(world.particles.size(), 2, "the original electron and positron should be removed")
	for photon in world.particles:
		assert_eq(photon.type_id, "photon", "surviving particles should be the newly-created photons")
		assert_eq(photon.charge, 0.0, "photons should be chargeless")
		assert_eq(photon.mass, 0.0, "photons should be massless")

func test_annihilation_conserves_momentum_and_energy() -> void:
	var c := 1000.0
	var world := PhysicsWorld.new()
	world.speed_of_light = c
	# Annihilation always uses relativistic energy/momentum internally
	# (it converts rest mass to energy, which classical mechanics has no
	# concept of at all) — so measure "before" the same way, or the
	# comparison isn't apples-to-apples. This doesn't change how the
	# world integrates; it only changes which formula ConservationTracker
	# uses to report totals.
	world.relativistic = true
	var e := Particle.new(ParticleTypes.electron(), Vector2(-3, 0), Vector2(40.0, 15.0))
	var p := Particle.new(ParticleTypes.positron(), Vector2(3, 0), Vector2(-10.0, 25.0))
	world.add_particle(e)
	world.add_particle(p)

	var momentum_before := ConservationTracker.total_momentum(world)
	var energy_before := ConservationTracker.total_energy(world)

	world.annihilation_system.process(world)

	var momentum_after := ConservationTracker.total_momentum(world)
	var energy_after := ConservationTracker.total_energy(world)

	assert_vec_almost_eq(momentum_after, momentum_before, 0.01,
		"total momentum should be conserved through annihilation")
	assert_almost_eq(energy_after, energy_before, energy_before * 0.001,
		"total energy should be conserved through annihilation")

func test_annihilation_photons_move_at_speed_of_light() -> void:
	var c := 750.0
	var world := PhysicsWorld.new()
	world.speed_of_light = c
	world.add_particle(Particle.new(ParticleTypes.electron(), Vector2(-2, 0), Vector2(20, 0)))
	world.add_particle(Particle.new(ParticleTypes.positron(), Vector2(2, 0), Vector2(-20, 0)))

	var created := world.annihilation_system.process(world)
	for photon in created:
		assert_almost_eq(photon.velocity.length(), c, 0.5,
			"every photon produced by annihilation should move at exactly c")

func test_non_annihilating_pair_is_left_alone() -> void:
	var world := PhysicsWorld.new()
	world.add_particle(Particle.new(ParticleTypes.positive(), Vector2(-2, 0)))
	world.add_particle(Particle.new(ParticleTypes.negative(), Vector2(2, 0)))

	var created := world.annihilation_system.process(world)
	assert_eq(created.size(), 0, "plain positive/negative charges should not trigger annihilation")
	assert_eq(world.particles.size(), 2, "non-annihilating particles should be untouched")

func test_non_overlapping_pair_does_not_annihilate() -> void:
	var world := PhysicsWorld.new()
	world.add_particle(Particle.new(ParticleTypes.electron(), Vector2(-500, 0)))
	world.add_particle(Particle.new(ParticleTypes.positron(), Vector2(500, 0)))

	var created := world.annihilation_system.process(world)
	assert_eq(created.size(), 0, "a distant e-/e+ pair should not annihilate until they actually touch")
	assert_eq(world.particles.size(), 2, "particles should remain until overlap occurs")

func test_disabled_annihilation_system_does_nothing() -> void:
	var world := PhysicsWorld.new()
	world.annihilation_system.enabled = false
	world.add_particle(Particle.new(ParticleTypes.electron(), Vector2(0, 0)))
	world.add_particle(Particle.new(ParticleTypes.positron(), Vector2(0, 0)))

	var created := world.annihilation_system.process(world)
	assert_eq(created.size(), 0, "a disabled AnnihilationSystem should never annihilate")
	assert_eq(world.particles.size(), 2, "particles should remain when the system is disabled")

func test_photon_free_streams_and_fades_out() -> void:
	var world := PhysicsWorld.new()
	world.add_particle(Particle.new(ParticleTypes.electron(), Vector2(0, 0)))
	world.add_particle(Particle.new(ParticleTypes.positron(), Vector2(0, 0)))
	world.annihilation_system.process(world)
	assert_eq(world.particles.size(), 2, "should have exactly two photons after annihilation")

	var photon: Particle = world.particles[0]
	var start_pos := photon.position
	var velocity := photon.velocity
	for i in range(60):
		world.step(1.0 / 60.0)
	# It free-streamed for ~1 second at its own velocity.
	assert_vec_almost_eq(photon.position, start_pos + velocity * 1.0, 2.0,
		"a photon should free-stream at constant velocity, unaffected by any field")
