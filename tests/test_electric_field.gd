class_name TestElectricField
extends TestCase

func test_positive_charge_accelerates_with_field() -> void:
	var field := ElectricField.new()
	field.direction = Vector2.RIGHT
	field.strength = 10.0
	var p := Particle.new(ParticleTypes.positive())
	assert_vec_almost_eq(field.force_on(p), Vector2(10.0, 0.0), 0.001,
		"positive charge should feel force aligned with E")

func test_negative_charge_accelerates_against_field() -> void:
	var field := ElectricField.new()
	field.direction = Vector2.RIGHT
	field.strength = 10.0
	var p := Particle.new(ParticleTypes.negative())
	assert_vec_almost_eq(field.force_on(p), Vector2(-10.0, 0.0), 0.001,
		"negative charge should feel force opposing E")

func test_neutral_particle_unaffected() -> void:
	var field := ElectricField.new()
	field.direction = Vector2.RIGHT
	field.strength = 10.0
	var p := Particle.new(ParticleTypes.neutral())
	assert_vec_almost_eq(field.force_on(p), Vector2.ZERO, 0.001,
		"neutral particle should feel no electric force")

func test_field_strength_scales_force() -> void:
	var field := ElectricField.new()
	field.direction = Vector2.UP
	field.strength = 25.0
	var p := Particle.new(ParticleTypes.positive())
	assert_vec_almost_eq(field.force_on(p), Vector2.UP * 25.0, 0.001,
		"force magnitude should scale linearly with field strength")

func test_acceleration_equals_force_over_mass() -> void:
	var p := Particle.new(ParticleTypes.positive(), Vector2.ZERO, Vector2.ZERO)
	p.mass = 2.0
	PhysicsIntegrator.integrate(p, Vector2(10.0, 0.0), 1.0)
	assert_almost_eq(p.velocity.x, 5.0, 0.001, "a = F/m should determine velocity change")

func test_disabled_field_produces_no_force() -> void:
	var field := ElectricField.new()
	field.direction = Vector2.RIGHT
	field.strength = 999.0
	field.enabled = false
	var p := Particle.new(ParticleTypes.positive())
	assert_vec_almost_eq(field.force_on(p), Vector2.ZERO, 0.001,
		"disabled field should exert no force")
