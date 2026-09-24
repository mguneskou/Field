class_name TestPairProduction
extends TestCase

func _make_photon(position: Vector2, direction: Vector2, momentum_magnitude: float, c: float) -> Particle:
	var photon := Particle.new(ParticleTypes.photon(), position, direction.normalized() * c)
	photon.momentum_magnitude = momentum_magnitude
	return photon

func test_photons_above_threshold_produce_electron_positron_pair() -> void:
	var c := 50.0
	var world := PhysicsWorld.new()
	world.speed_of_light = c
	# Each photon carries energy 60*50=3000; combined 6000 > 2*mc^2=5000.
	world.add_particle(_make_photon(Vector2(-1, 0), Vector2.RIGHT, 60.0, c))
	world.add_particle(_make_photon(Vector2(1, 0), Vector2.LEFT, 60.0, c))

	var result := world.pair_production_system.process(world.particles, c)
	assert_eq(result["created"].size(), 2, "photons above threshold should produce exactly two particles")
	var types: Array[String] = []
	for p in result["created"]:
		types.append(p.type_id)
	types.sort()
	assert_eq(types, ["electron", "positron"], "pair production should yield one electron and one positron")

func test_pair_production_conserves_momentum_and_energy() -> void:
	var c := 50.0
	var world := PhysicsWorld.new()
	world.speed_of_light = c
	world.relativistic = true # so ConservationTracker uses relativistic accounting to match
	# Nearly (not exactly) opposite directions: like a real pair-production
	# event, the reaction needs enough energy AFTER accounting for net
	# momentum too (E^2 - (Pc)^2 >= (2mc^2)^2), which fails if the photons'
	# net momentum is too large relative to their combined energy — as it
	# would be if they were moving more sideways-to-each-other than head-on.
	world.add_particle(_make_photon(Vector2(-1, 0), Vector2(1, 0.05), 70.0, c))
	world.add_particle(_make_photon(Vector2(1, 0), Vector2(-1, 0.05), 55.0, c))

	var momentum_before := ConservationTracker.total_momentum(world)
	var energy_before := ConservationTracker.total_energy(world)

	var result := world.pair_production_system.process(world.particles, c)
	world.particles = result["created"] # the two photons are fully consumed

	var momentum_after := ConservationTracker.total_momentum(world)
	var energy_after := ConservationTracker.total_energy(world)

	assert_vec_almost_eq(momentum_after, momentum_before, momentum_before.length() * 0.01 + 0.1,
		"total momentum should be conserved through pair production")
	assert_almost_eq(energy_after, energy_before, energy_before * 0.001,
		"total energy should be conserved through pair production")

func test_high_energy_but_excessive_net_momentum_is_correctly_rejected() -> void:
	# Regression test for a real bug caught during development: combined
	# energy alone isn't a sufficient threshold check. A pair with plenty
	# of raw energy but too much NET momentum (photons moving more
	# sideways-to-each-other than head-on) can still fail the true
	# invariant-mass condition E^2 - (Pc)^2 >= (2mc^2)^2. An earlier
	# version only checked energy, then silently clamped the resulting
	# (mathematically invalid) momentum split — producing a pair that
	# violated energy conservation instead of correctly not forming.
	var c := 50.0
	var world := PhysicsWorld.new()
	world.speed_of_light = c
	world.add_particle(_make_photon(Vector2(-1, 0), Vector2(1, 0.3), 70.0, c))
	world.add_particle(_make_photon(Vector2(1, 0), Vector2(1, -0.1), 55.0, c))
	# Combined energy (70+55)*50=6250 is well above the naive 2mc^2=5000
	# threshold, but these near-parallel (not opposing) directions give
	# too much net momentum for the reaction to actually be possible.
	var result := world.pair_production_system.process(world.particles, c)
	assert_eq(result["created"].size(), 0,
		"high energy with excessive net momentum should still correctly fail the full invariant-mass threshold")

func test_below_threshold_photons_pass_through_unchanged() -> void:
	var c := 50.0
	var world := PhysicsWorld.new()
	world.speed_of_light = c
	# Each photon carries energy 20*50=1000; combined 2000 < 2*mc^2=5000.
	world.add_particle(_make_photon(Vector2(-1, 0), Vector2.RIGHT, 20.0, c))
	world.add_particle(_make_photon(Vector2(1, 0), Vector2.LEFT, 20.0, c))

	var result := world.pair_production_system.process(world.particles, c)
	assert_eq(result["created"].size(), 0,
		"photons below the 2mc^2 threshold should not be able to pair-produce")

func test_disabled_system_does_nothing() -> void:
	var c := 50.0
	var world := PhysicsWorld.new()
	world.speed_of_light = c
	world.pair_production_system.enabled = false
	world.add_particle(_make_photon(Vector2(-1, 0), Vector2.RIGHT, 60.0, c))
	world.add_particle(_make_photon(Vector2(1, 0), Vector2.LEFT, 60.0, c))

	var result := world.pair_production_system.process(world.particles, c)
	assert_eq(result["created"].size(), 0, "a disabled PairProductionSystem should never produce a pair")

func test_non_photon_particles_are_ignored() -> void:
	var world := PhysicsWorld.new()
	world.add_particle(Particle.new(ParticleTypes.positive(), Vector2(0, 0)))
	world.add_particle(Particle.new(ParticleTypes.negative(), Vector2(0, 0)))

	var result := world.pair_production_system.process(world.particles, world.speed_of_light)
	assert_eq(result["created"].size(), 0, "only overlapping photon pairs should be considered for pair production")
