class_name TestSymmetryBreaking
extends TestCase

func _make_potential() -> SymmetryBreakingPotential:
	var pot := SymmetryBreakingPotential.new()
	pot.enabled = true
	pot.center = Vector2.ZERO
	pot.a = 0.01
	pot.b = 100.0
	return pot

func test_force_is_zero_exactly_at_center() -> void:
	var pot := _make_potential()
	var p := Particle.new(ParticleTypes.neutral(), Vector2.ZERO)
	assert_vec_almost_eq(pot.force_on(p), Vector2.ZERO, 0.0001,
		"the center is an equilibrium point (unstable, but force should still be exactly zero there)")

func test_force_is_zero_exactly_on_the_ring() -> void:
	var pot := _make_potential()
	var p := Particle.new(ParticleTypes.neutral(), Vector2(100.0, 0.0)) # r == b
	assert_vec_almost_eq(pot.force_on(p), Vector2.ZERO, 0.001,
		"the ring r=b is the potential's stable equilibrium, so force should be ~zero there")

func test_force_pushes_outward_from_near_center() -> void:
	var pot := _make_potential()
	var p := Particle.new(ParticleTypes.neutral(), Vector2(5.0, 0.0)) # small r, inside the ring
	var force := pot.force_on(p)
	assert_true(force.x > 0.0, "near the unstable center, force should push AWAY from center")

func test_force_pulls_inward_from_outside_the_ring() -> void:
	var pot := _make_potential()
	var p := Particle.new(ParticleTypes.neutral(), Vector2(180.0, 0.0)) # r > b
	var force := pot.force_on(p)
	assert_true(force.x < 0.0, "outside the ring, force should pull back TOWARD the ring")

func test_potential_is_rotationally_symmetric() -> void:
	var pot := _make_potential()
	var v1 := pot.potential_at(Vector2(70.0, 0.0))
	var v2 := pot.potential_at(Vector2(0.0, 70.0))
	var v3 := pot.potential_at(Vector2(49.497, 49.497)) # same radius, 45 degrees
	assert_almost_eq(v1, v2, 0.001, "the potential should not favor any particular direction")
	assert_almost_eq(v1, v3, max(abs(v1), 1.0) * 0.001,
		"the potential should depend only on distance from center, not angle")

func test_particle_starting_at_exact_center_stays_put() -> void:
	# With NO perturbation, the (unstable) equilibrium is exact: nothing
	# pushes it anywhere, since the force is exactly zero there.
	var world := PhysicsWorld.new()
	world.symmetry_breaking = _make_potential()
	var p := Particle.new(ParticleTypes.neutral(), Vector2.ZERO, Vector2.ZERO)
	world.add_particle(p)
	for i in range(120):
		world.step(1.0 / 60.0)
	assert_vec_almost_eq(p.position, Vector2.ZERO, 0.01,
		"an unperturbed particle at the exact unstable equilibrium should not spontaneously move")

func test_particle_settles_near_the_ring_after_perturbation() -> void:
	var world := PhysicsWorld.new()
	world.symmetry_breaking = _make_potential()
	var p := Particle.new(ParticleTypes.neutral(), Vector2(1.0, 0.0), Vector2.ZERO) # tiny nudge off-center
	world.add_particle(p)
	for i in range(600): # 10s to let it roll out and settle
		world.step(1.0 / 60.0)
	var r := p.position.length()
	assert_almost_eq(r, world.symmetry_breaking.b, world.symmetry_breaking.b * 0.25,
		"a perturbed particle should roll out and end up orbiting near the ring of minima")

func test_different_perturbation_directions_break_symmetry_differently() -> void:
	# The potential itself has no preferred direction, but WHICH point on
	# the ring a particle ends up near depends entirely on which way it
	# was nudged — that's the "spontaneous" part of symmetry breaking.
	var world_a := PhysicsWorld.new()
	world_a.symmetry_breaking = _make_potential()
	var p_a := Particle.new(ParticleTypes.neutral(), Vector2(1.0, 0.0), Vector2.ZERO)
	world_a.add_particle(p_a)

	var world_b := PhysicsWorld.new()
	world_b.symmetry_breaking = _make_potential()
	var p_b := Particle.new(ParticleTypes.neutral(), Vector2(0.0, 1.0), Vector2.ZERO)
	world_b.add_particle(p_b)

	for i in range(600):
		world_a.step(1.0 / 60.0)
		world_b.step(1.0 / 60.0)

	var angle_a := p_a.position.angle()
	var angle_b := p_b.position.angle()
	assert_true(abs(angle_a - angle_b) > 0.5,
		"different initial nudges should break the symmetry toward different points on the ring")
