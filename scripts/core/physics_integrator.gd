class_name PhysicsIntegrator
extends RefCounted
## Numerical integration, isolated from force calculation so the
## integration scheme can change without touching any field/law code.
##
## Two modes:
## - integrate(): classical semi-implicit (symplectic) Euler, F=ma. Used by
##   every existing electromagnetism level. Velocity is hard-clamped to
##   MAX_SPEED purely as a numerical safety net.
## - integrate_relativistic(): treats force as dp/dt on relativistic
##   momentum (see RelativisticKinematics) and derives velocity from
##   momentum afterward. This makes the speed-of-light cap emerge from the
##   physics itself — v asymptotically approaches c under sustained force
##   rather than needing an artificial clamp.
##
## Both share massless-particle handling: a particle with ~0 mass (a
## photon) is unaffected by any force and simply free-streams at whatever
## velocity it was created with.

const MAX_SPEED: float = 4000.0
const MAX_ACCELERATION: float = 200000.0
const MAX_MOMENTUM: float = 1.0e9 # defensive ceiling only; never reached in normal play

static func integrate(particle: Particle, force: Vector2, dt: float) -> void:
	if particle.mass <= 0.0001:
		_integrate_massless(particle, dt)
		return

	var accel := force / particle.mass
	if not _is_finite_vector(accel):
		accel = Vector2.ZERO
	accel = accel.limit_length(MAX_ACCELERATION)
	particle.acceleration = accel

	particle.velocity += accel * dt
	if not _is_finite_vector(particle.velocity):
		particle.velocity = Vector2.ZERO
	particle.velocity = particle.velocity.limit_length(MAX_SPEED)

	particle.position += particle.velocity * dt
	if not _is_finite_vector(particle.position):
		particle.position = Vector2.ZERO
		particle.velocity = Vector2.ZERO

static func integrate_relativistic(particle: Particle, force: Vector2, dt: float, c: float = RelativisticKinematics.DEFAULT_C) -> void:
	if particle.mass <= 0.0001:
		_integrate_massless(particle, dt)
		return

	var p := RelativisticKinematics.momentum(particle.mass, particle.velocity, c)
	p += force * dt
	if not _is_finite_vector(p):
		p = Vector2.ZERO
	p = p.limit_length(MAX_MOMENTUM)

	var new_velocity := RelativisticKinematics.velocity_from_momentum(particle.mass, p, c)
	if not _is_finite_vector(new_velocity):
		new_velocity = Vector2.ZERO

	particle.acceleration = (new_velocity - particle.velocity) / max(dt, 0.000001)
	particle.velocity = new_velocity

	particle.position += particle.velocity * dt
	if not _is_finite_vector(particle.position):
		particle.position = Vector2.ZERO
		particle.velocity = Vector2.ZERO

static func _integrate_massless(particle: Particle, dt: float) -> void:
	particle.position += particle.velocity * dt
	if not _is_finite_vector(particle.position):
		particle.position = Vector2.ZERO

static func _is_finite_vector(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)
