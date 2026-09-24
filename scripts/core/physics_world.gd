class_name PhysicsWorld
extends RefCounted
## Owns the particles and field state for one simulation and advances them
## by a fixed timestep. Has no knowledge of levels, objectives, input or
## rendering — it only knows forces and motion.

var particles: Array[Particle] = []
var electric_field: ElectricField = ElectricField.new()
var magnetic_field: MagneticField = MagneticField.new()
var interaction_system: InteractionSystem = InteractionSystem.new()
var bounds: Rect2 = Rect2(-100000, -100000, 200000, 200000)

var time: float = 0.0
var trails_enabled: bool = true

## When true, particles are integrated with relativistic momentum dynamics
## (velocity asymptotically bounded by speed_of_light) instead of classical
## F=ma. Off by default so every existing electromagnetism level keeps its
## original, already-tuned behavior.
var relativistic: bool = false
var speed_of_light: float = RelativisticKinematics.DEFAULT_C

func add_particle(p: Particle) -> void:
	p.trail_enabled = trails_enabled
	particles.append(p)

func clear() -> void:
	particles.clear()
	time = 0.0

## Advances the whole world by one fixed timestep.
func step(dt: float) -> void:
	var interaction_forces := interaction_system.compute_forces(particles)

	for p in particles:
		if not p.alive:
			continue
		var interaction_force: Vector2 = interaction_forces.get(p, Vector2.ZERO)
		var e_like_force: Vector2 = electric_field.force_on(p) + interaction_force

		if relativistic:
			# Relativistic + magnetic is a rarer combination not yet exercised
			# by any level; combine forces simply rather than extend Boris to
			# the relativistic case.
			PhysicsIntegrator.integrate_relativistic(p, e_like_force + magnetic_field.force_on(p), dt, speed_of_light)
		else:
			PhysicsIntegrator.integrate_boris(p, e_like_force, magnetic_field.get_field_at(p.position), dt)
		p.update_lifetime(dt)
		if not bounds.has_point(p.position):
			p.alive = false
		if trails_enabled:
			p.record_trail()

	time += dt
	if particles.any(func(p): return not p.alive):
		particles = particles.filter(func(p): return p.alive)
