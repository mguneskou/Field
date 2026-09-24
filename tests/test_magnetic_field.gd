class_name TestMagneticField
extends TestCase

func test_stationary_charge_feels_no_magnetic_force() -> void:
	var field := MagneticField.new()
	field.strength = 5.0
	var p := Particle.new(ParticleTypes.positive(), Vector2.ZERO, Vector2.ZERO)
	assert_vec_almost_eq(field.force_on(p), Vector2.ZERO, 0.001,
		"a stationary charge should feel no magnetic force")

func test_moving_positive_charge_feels_perpendicular_force() -> void:
	var field := MagneticField.new()
	field.strength = 1.0
	var p := Particle.new(ParticleTypes.positive(), Vector2.ZERO, Vector2(1.0, 0.0))
	# F = q(v x B), B=(0,0,Bz) -> (vy*Bz, -vx*Bz) = (0, -1)
	assert_vec_almost_eq(field.force_on(p), Vector2(0.0, -1.0), 0.001,
		"moving positive charge should feel force perpendicular to velocity")

func test_moving_negative_charge_curves_opposite_direction() -> void:
	var field := MagneticField.new()
	field.strength = 1.0
	var p := Particle.new(ParticleTypes.negative(), Vector2.ZERO, Vector2(1.0, 0.0))
	assert_vec_almost_eq(field.force_on(p), Vector2(0.0, 1.0), 0.001,
		"negative charge should curve opposite to a positive charge")

func test_reversing_field_reverses_curvature() -> void:
	var field := MagneticField.new()
	var p := Particle.new(ParticleTypes.positive(), Vector2.ZERO, Vector2(1.0, 0.0))
	field.strength = 1.0
	var force_pos := field.force_on(p)
	field.strength = -1.0
	var force_neg := field.force_on(p)
	assert_vec_almost_eq(force_neg, -force_pos, 0.001,
		"reversing B direction should reverse the resulting force")

func test_neutral_particle_unaffected_by_magnetic_field() -> void:
	var field := MagneticField.new()
	field.strength = 5.0
	var p := Particle.new(ParticleTypes.neutral(), Vector2.ZERO, Vector2(3.0, 4.0))
	assert_vec_almost_eq(field.force_on(p), Vector2.ZERO, 0.001,
		"neutral particle should feel no magnetic force regardless of velocity")

func test_moving_charge_produces_circular_motion() -> void:
	# A charge moving perpendicular to a uniform B with no other forces
	# should trace an (approximately) circular path: speed stays constant.
	var world := PhysicsWorld.new()
	world.magnetic_field.strength = 2.0
	var p := Particle.new(ParticleTypes.positive(), Vector2.ZERO, Vector2(50.0, 0.0))
	p.mass = 1.0
	world.add_particle(p)
	var initial_speed := p.velocity.length()
	for i in range(120):
		world.step(1.0 / 60.0)
	# Semi-implicit Euler has a small, well-known energy drift on curved
	# paths; a tight tolerance here would test the integrator, not the
	# physics law, so we allow a modest margin.
	assert_almost_eq(p.velocity.length(), initial_speed, initial_speed * 0.1,
		"magnetic force should not change speed much, only direction")
