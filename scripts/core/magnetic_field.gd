class_name MagneticField
extends RefCounted
## Uniform magnetic field, 2D simplification: since the simulation plane is
## the xy-plane, only the field's out-of-plane (z) component can do
## anything to in-plane motion, so B collapses to a single scalar.
## Positive strength = out of the screen, negative = into the screen.
##
## Full Lorentz term: F = q(v x B), with B = (0, 0, Bz):
##   v x B = (vy*Bz, -vx*Bz, 0)

var strength: float = 0.0
var enabled: bool = true

func get_field_at(_position: Vector2) -> float:
	if not enabled:
		return 0.0
	return strength

func force_on(particle: Particle) -> Vector2:
	var b := get_field_at(particle.position)
	if b == 0.0 or particle.charge == 0.0:
		return Vector2.ZERO
	var v := particle.velocity
	return particle.charge * Vector2(v.y * b, -v.x * b)
