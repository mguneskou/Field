class_name ElectricField
extends RefCounted
## Uniform electric field: E is constant everywhere in the level.
## F = qE. Extending to non-uniform fields later means adding a
## get_field_at() that actually varies with position; callers already
## go through that method.

var direction: Vector2 = Vector2.RIGHT # kept normalized
var strength: float = 0.0 # game units, not SI volts/meter
var enabled: bool = true

func set_direction(d: Vector2) -> void:
	if d.length() > 0.0001:
		direction = d.normalized()

func get_field_at(_position: Vector2) -> Vector2:
	if not enabled:
		return Vector2.ZERO
	return direction * strength

## F = qE
func force_on(particle: Particle) -> Vector2:
	return get_field_at(particle.position) * particle.charge
