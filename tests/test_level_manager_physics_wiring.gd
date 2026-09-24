class_name TestLevelManagerPhysicsWiring
extends TestCase
## The underlying physics (relativistic integration, symmetry breaking)
## is already thoroughly tested at the PhysicsWorld/PhysicsIntegrator
## level. This just checks LevelManager correctly copies LevelDefinition
## fields onto the PhysicsWorld it builds — a thin mapping, but a typo
## here would silently make a level's relativity/symmetry-breaking
## settings do nothing.

func test_relativistic_settings_propagate_to_world() -> void:
	var level := LevelDefinition.new()
	level.relativistic = true
	level.speed_of_light = 777.0

	var manager := LevelManager.new()
	manager.load_level(level)

	assert_eq(manager.world.relativistic, true, "world.relativistic should match the level's setting")
	assert_almost_eq(manager.world.speed_of_light, 777.0, 0.001, "world.speed_of_light should match the level's setting")

func test_symmetry_breaking_settings_propagate_to_world() -> void:
	var level := LevelDefinition.new()
	level.symmetry_breaking_enabled = true
	level.symmetry_breaking_center = Vector2(100, 200)
	level.symmetry_breaking_a = 0.02
	level.symmetry_breaking_b = 88.0
	level.symmetry_breaking_damping = 0.3

	var manager := LevelManager.new()
	manager.load_level(level)

	var pot := manager.world.symmetry_breaking
	assert_eq(pot.enabled, true, "symmetry_breaking.enabled should match the level's setting")
	assert_vec_almost_eq(pot.center, Vector2(100, 200), 0.001, "symmetry_breaking.center should match the level's setting")
	assert_almost_eq(pot.a, 0.02, 0.0001, "symmetry_breaking.a should match the level's setting")
	assert_almost_eq(pot.b, 88.0, 0.001, "symmetry_breaking.b should match the level's setting")
	assert_almost_eq(pot.damping, 0.3, 0.001, "symmetry_breaking.damping should match the level's setting")

func test_capture_objective_fires_before_annihilation_consumes_the_pair() -> void:
	# Regression test for a real bug: AnnihilationSystem ran inside
	# PhysicsWorld.step() unconditionally, so an electron/positron pair
	# that touched would be consumed into photons in the SAME tick before
	# LevelManager ever got to check a CAPTURE objective on them — the
	# named particles were already gone by the time evaluate() ran, so
	# CAPTURE could never fire, and the fast photon products then quickly
	# left the level's normal-sized bounds and triggered "all particles
	# lost" FAILURE instead of the intended SUCCESS. Fixed by splitting
	# PhysicsWorld.step() into step_motion()/step_reactions() and having
	# LevelManager evaluate the objective in between.
	var level := LevelDefinition.new()
	level.world_size = Vector2(1280, 720)
	level.particles = [
		_spawn("electron", Vector2(636, 360)),
		_spawn("positron", Vector2(644, 360)), # already overlapping (radius 7 each)
	]
	level.objective_kind = LevelDefinition.ObjectiveKind.CAPTURE
	level.capture_particle_a = 0
	level.capture_particle_b = 1

	var manager := LevelManager.new()
	manager.load_level(level)
	manager.play()
	manager._physics_process(1.0 / 60.0)

	assert_eq(manager.status, Objective.Status.SUCCESS,
		"CAPTURE should succeed the moment the pair touches, not be preempted by annihilation")
	var found_photon := false
	for p in manager.world.particles:
		if p.type_id == "photon":
			found_photon = true
	assert_true(found_photon, "the annihilation should still visibly happen (reactions run every tick, not just non-success ticks)")

func _spawn(type_id: String, position: Vector2) -> ParticleSpawn:
	var s := ParticleSpawn.new()
	s.type_id = type_id
	s.position = position
	return s

func test_defaults_leave_new_physics_off() -> void:
	# A level that doesn't opt into any of this should behave exactly
	# like the original 20-level roster always did.
	var level := LevelDefinition.new()
	var manager := LevelManager.new()
	manager.load_level(level)

	assert_eq(manager.world.relativistic, false, "relativistic should default to off")
	assert_eq(manager.world.symmetry_breaking.enabled, false, "symmetry breaking should default to off")
