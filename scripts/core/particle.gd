class_name Particle
extends RefCounted
## A single simulated particle. Pure state + small helpers — no physics laws
## live here (those belong to the field/integrator/interaction systems) and
## no rendering lives here (that belongs to the view layer).

var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO
var mass: float = 1.0
var charge: float = 0.0
var radius: float = 6.0
var type_id: String = "neutral"
var color: Color = Color.WHITE
var spawn_index: int = -1 # stable identity from the level's particle list, survives array filtering

var lifetime: float = -1.0 # -1 = infinite
var age: float = 0.0
var alive: bool = true

var trail: Array[Vector2] = []
var max_trail_length: int = 90
var trail_enabled: bool = true

func _init(p_type: ParticleType = null, p_position: Vector2 = Vector2.ZERO, p_velocity: Vector2 = Vector2.ZERO) -> void:
	if p_type != null:
		apply_type(p_type)
	position = p_position
	velocity = p_velocity

func apply_type(p_type: ParticleType) -> void:
	type_id = p_type.id
	charge = p_type.charge
	mass = p_type.mass
	radius = p_type.radius
	color = p_type.color

func record_trail() -> void:
	if not trail_enabled:
		return
	trail.append(position)
	if trail.size() > max_trail_length:
		trail.pop_front()

func clear_trail() -> void:
	trail.clear()

func update_lifetime(dt: float) -> void:
	if lifetime < 0.0:
		return
	age += dt
	if age >= lifetime:
		alive = false

func clone_state() -> Dictionary:
	return {
		"position": position,
		"velocity": velocity,
		"charge": charge,
		"mass": mass,
		"radius": radius,
		"type_id": type_id,
	}
