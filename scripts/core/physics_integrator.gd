class_name PhysicsIntegrator
extends RefCounted
## Numerical integration, isolated from force calculation so the
## integration scheme can change without touching any field/law code.
## Semi-implicit (symplectic) Euler: update velocity first, then use the
## new velocity to update position. More energy-stable than explicit Euler
## for oscillatory/orbital motion, which this game leans on heavily.

const MAX_SPEED: float = 4000.0
const MAX_ACCELERATION: float = 200000.0

static func integrate(particle: Particle, force: Vector2, dt: float) -> void:
	if particle.mass <= 0.0001:
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

static func _is_finite_vector(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)
