class_name TestSpeculativeUnifiedField
extends TestCase
## Tests the toy blend behaves as designed. This is explicitly a game
## abstraction (see SpeculativeUnifiedField's docstring) — these tests
## check internal consistency, not agreement with any real theory.

func test_disabled_by_default() -> void:
	var field := SpeculativeUnifiedField.new()
	assert_eq(field.enabled, false, "the unified field should be off by default so no existing level is affected")

func test_zero_unification_matches_pure_coulomb() -> void:
	var field := SpeculativeUnifiedField.new()
	field.enabled = true
	field.unification = 0.0
	var a := Particle.new(ParticleTypes.positive(), Vector2(-30, 0))
	var b := Particle.new(ParticleTypes.negative(), Vector2(30, 0))
	var forces := field.compute_forces([a, b])

	var reference := InteractionSystem.new()
	reference.coulomb_constant = field.coulomb_constant
	reference.softening = field.softening
	var expected := reference.compute_forces([a, b])

	assert_vec_almost_eq(forces[a], expected[a], 0.01,
		"at unification=0 the toy field should exactly match ordinary Coulomb attraction")

func test_full_unification_force_grows_with_distance() -> void:
	var field := SpeculativeUnifiedField.new()
	field.enabled = true
	field.unification = 1.0
	var near_a := Particle.new(ParticleTypes.positive(), Vector2(-20, 0))
	var near_b := Particle.new(ParticleTypes.negative(), Vector2(20, 0))
	var near_forces := field.compute_forces([near_a, near_b])

	var far_a := Particle.new(ParticleTypes.positive(), Vector2(-80, 0))
	var far_b := Particle.new(ParticleTypes.negative(), Vector2(80, 0))
	var far_forces := field.compute_forces([far_a, far_b])

	assert_true(far_forces[far_a].length() > near_forces[near_a].length(),
		"at full unification (confinement-like), force should grow with separation instead of shrinking")

func test_intermediate_unification_is_a_blend() -> void:
	var field := SpeculativeUnifiedField.new()
	field.enabled = true
	var a := Particle.new(ParticleTypes.positive(), Vector2(-40, 0))
	var b := Particle.new(ParticleTypes.negative(), Vector2(40, 0))

	field.unification = 0.0
	var force0: Vector2 = field.compute_forces([a, b])[a]
	var f0: float = force0.length()
	field.unification = 0.5
	var force_half: Vector2 = field.compute_forces([a, b])[a]
	var f_half: float = force_half.length()
	field.unification = 1.0
	var force1: Vector2 = field.compute_forces([a, b])[a]
	var f1: float = force1.length()

	assert_true((f_half > f0) == (f1 > f0) or is_equal_approx(f_half, f0) or is_equal_approx(f_half, f1),
		"the halfway blend should sit between (or at) the two endpoint force magnitudes, not overshoot both")

func test_charge_sign_still_determines_attraction_vs_repulsion() -> void:
	var field := SpeculativeUnifiedField.new()
	field.enabled = true
	field.unification = 1.0
	var a := Particle.new(ParticleTypes.positive(), Vector2(-40, 0))
	var b := Particle.new(ParticleTypes.positive(), Vector2(40, 0))
	var forces := field.compute_forces([a, b])
	assert_true(forces[a].x < 0.0, "like charges should still repel under the unified toy force")

func test_uncharged_particles_feel_nothing() -> void:
	var field := SpeculativeUnifiedField.new()
	field.enabled = true
	field.unification = 1.0
	var a := Particle.new(ParticleTypes.neutral(), Vector2(-40, 0))
	var b := Particle.new(ParticleTypes.positive(), Vector2(40, 0))
	var forces := field.compute_forces([a, b])
	assert_vec_almost_eq(forces[a], Vector2.ZERO, 0.0001, "a neutral particle should feel no force from any charge-based law")

func test_disabled_field_produces_no_forces() -> void:
	var field := SpeculativeUnifiedField.new()
	field.enabled = false
	var a := Particle.new(ParticleTypes.positive(), Vector2(-40, 0))
	var b := Particle.new(ParticleTypes.negative(), Vector2(40, 0))
	var forces := field.compute_forces([a, b])
	assert_vec_almost_eq(forces[a], Vector2.ZERO, 0.0001, "a disabled unified field should never exert a force")

func test_world_unified_field_is_off_by_default() -> void:
	var world := PhysicsWorld.new()
	assert_eq(world.unified_field.enabled, false,
		"PhysicsWorld's unified_field should default to off, leaving every existing level unaffected")
