class_name ConservationTracker
extends RefCounted
## Reports aggregate conserved quantities for a PhysicsWorld snapshot:
## total charge, momentum, and energy. Purely a measurement tool — it
## never mutates state. Exists so conservation can be verified by tests
## (and later, optionally surfaced in the Science panel) instead of just
## asserted in a comment.

static func total_charge(world: PhysicsWorld) -> float:
	var total := 0.0
	for p in world.particles:
		total += p.charge
	return total

static func total_momentum(world: PhysicsWorld) -> Vector2:
	var total := Vector2.ZERO
	for p in world.particles:
		total += particle_momentum(p, world)
	return total

static func total_energy(world: PhysicsWorld) -> float:
	var total := 0.0
	for p in world.particles:
		total += particle_energy(p, world)
	return total

## A single particle's momentum vector, massless-aware.
static func particle_momentum(p: Particle, world: PhysicsWorld) -> Vector2:
	if p.mass <= 0.0001:
		if p.velocity.length() < 0.0001:
			return Vector2.ZERO
		return p.velocity.normalized() * p.momentum_magnitude
	if world.relativistic:
		return RelativisticKinematics.momentum(p.mass, p.velocity, world.speed_of_light)
	return p.velocity * p.mass

## A single particle's total energy (kinetic + rest mass, when relativistic;
## classical kinetic energy only otherwise — Newtonian mechanics has no
## rest-mass-energy term, so "total energy" there just means 1/2 m v^2).
static func particle_energy(p: Particle, world: PhysicsWorld) -> float:
	if p.mass <= 0.0001:
		return RelativisticKinematics.massless_energy(p.momentum_magnitude, world.speed_of_light)
	if world.relativistic:
		return RelativisticKinematics.total_energy(p.mass, p.velocity.length(), world.speed_of_light)
	return 0.5 * p.mass * p.velocity.length_squared()
