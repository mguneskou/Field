class_name RelativisticKinematics
extends RefCounted
## Special-relativistic kinematics as pure functions of (mass, velocity, c).
## Kept separate from PhysicsIntegrator (which decides WHEN to use these
## vs. classical Newtonian mechanics) and from PhysicsWorld (which just
## flips a mode flag) — see the "clearly separate equations from
## integration from game constraints" rule this project follows.
##
## `c` is a GAME-SCALE speed of light, not 299,792,458 m/s — chosen so
## relativistic effects (time dilation, velocity capping, mass-energy)
## become visible within the velocities this game's fields can produce,
## the same compromise already made for the Coulomb constant.

const DEFAULT_C: float = 2000.0

## Lorentz factor gamma = 1 / sqrt(1 - (v/c)^2). Clamps v just under c so
## a numerically-overshot speed never produces NaN/Inf.
static func gamma(speed: float, c: float = DEFAULT_C) -> float:
	var ratio: float = clamp(speed / c, 0.0, 0.999999)
	return 1.0 / sqrt(1.0 - ratio * ratio)

## Relativistic momentum p = gamma * m * v (vector form).
static func momentum(mass: float, velocity: Vector2, c: float = DEFAULT_C) -> Vector2:
	return velocity * gamma(velocity.length(), c) * mass

## Recovers velocity from relativistic momentum: v = p / sqrt(m^2 + |p|^2/c^2).
## This is the inverse of momentum() and is what makes force-on-momentum
## integration naturally asymptote toward c instead of needing a hard clamp.
static func velocity_from_momentum(mass: float, p: Vector2, c: float = DEFAULT_C) -> Vector2:
	if mass <= 0.0001:
		return Vector2.ZERO # massless particles don't carry rest-mass momentum this way
	var denom: float = sqrt(mass * mass + p.length_squared() / (c * c))
	var v: Vector2 = p / denom
	# At extreme momentum magnitudes, 32-bit float precision can lose the
	# mass term entirely and round v up to exactly c (or fractionally over).
	# Clamp defensively so "always strictly below c" holds numerically too.
	return v.limit_length(c * 0.999999)

## Total relativistic energy E = gamma * m * c^2.
static func total_energy(mass: float, speed: float, c: float = DEFAULT_C) -> float:
	return gamma(speed, c) * mass * c * c

## Kinetic energy only: E_total - rest energy.
static func kinetic_energy(mass: float, speed: float, c: float = DEFAULT_C) -> float:
	return (gamma(speed, c) - 1.0) * mass * c * c

## Photon/massless-particle energy from momentum magnitude: E = |p| * c.
static func massless_energy(momentum_magnitude: float, c: float = DEFAULT_C) -> float:
	return momentum_magnitude * c
