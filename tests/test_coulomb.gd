class_name TestCoulomb
extends TestCase

func test_like_charges_repel() -> void:
	var sys := InteractionSystem.new()
	var a := Particle.new(ParticleTypes.positive(), Vector2(-5, 0))
	var b := Particle.new(ParticleTypes.positive(), Vector2(5, 0))
	var forces := sys.compute_forces([a, b])
	assert_true(forces[a].x < 0.0, "like charges: force on a should push it away from b")
	assert_true(forces[b].x > 0.0, "like charges: force on b should push it away from a")

func test_opposite_charges_attract() -> void:
	var sys := InteractionSystem.new()
	var a := Particle.new(ParticleTypes.positive(), Vector2(-5, 0))
	var b := Particle.new(ParticleTypes.negative(), Vector2(5, 0))
	var forces := sys.compute_forces([a, b])
	assert_true(forces[a].x > 0.0, "opposite charges: force on a should pull it toward b")
	assert_true(forces[b].x < 0.0, "opposite charges: force on b should pull it toward a")

func test_softening_prevents_singularity() -> void:
	var sys := InteractionSystem.new()
	var a := Particle.new(ParticleTypes.positive(), Vector2.ZERO)
	var b := Particle.new(ParticleTypes.positive(), Vector2(0.0001, 0.0))
	var forces := sys.compute_forces([a, b])
	assert_true(is_finite(forces[a].x) and is_finite(forces[a].y),
		"force should stay finite even at near-zero separation")

func test_newtons_third_law() -> void:
	var sys := InteractionSystem.new()
	var a := Particle.new(ParticleTypes.positive(), Vector2(-3, 1))
	var b := Particle.new(ParticleTypes.negative(), Vector2(4, -2))
	var forces := sys.compute_forces([a, b])
	assert_vec_almost_eq(forces[a], -forces[b], 0.001,
		"force on a should be equal and opposite to force on b")

func test_neutral_particle_ignored() -> void:
	var sys := InteractionSystem.new()
	var a := Particle.new(ParticleTypes.neutral(), Vector2(-5, 0))
	var b := Particle.new(ParticleTypes.positive(), Vector2(5, 0))
	var forces := sys.compute_forces([a, b])
	assert_vec_almost_eq(forces[a], Vector2.ZERO, 0.001, "neutral particle should feel no Coulomb force")
	assert_vec_almost_eq(forces[b], Vector2.ZERO, 0.001, "neutral particle should exert no Coulomb force")

func test_force_falls_off_with_square_of_distance() -> void:
	var sys := InteractionSystem.new()
	var near_a := Particle.new(ParticleTypes.positive(), Vector2(-10, 0))
	var near_b := Particle.new(ParticleTypes.positive(), Vector2(10, 0))
	var near_forces := sys.compute_forces([near_a, near_b])

	var far_a := Particle.new(ParticleTypes.positive(), Vector2(-20, 0))
	var far_b := Particle.new(ParticleTypes.positive(), Vector2(20, 0))
	var far_forces := sys.compute_forces([far_a, far_b])

	# Doubling distance should quarter the force magnitude.
	assert_almost_eq(far_forces[far_a].length(), near_forces[near_a].length() / 4.0,
		near_forces[near_a].length() * 0.05, "Coulomb force should fall off with 1/r^2")
