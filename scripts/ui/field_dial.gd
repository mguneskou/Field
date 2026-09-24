class_name FieldDial
extends Control
## A single circular control for the electric field: drag angle sets
## direction, drag distance from center sets strength (0..max_strength).
## When direction/strength editing is individually disabled by the level,
## dragging is constrained to the axis that's still allowed.

signal field_changed(direction: Vector2, strength: float)

@export var dial_radius: float = 64.0
@export var direction: Vector2 = Vector2.RIGHT
@export var strength: float = 0.0
@export var max_strength: float = 100.0
@export var direction_editable: bool = true
@export var strength_editable: bool = true

var _dragging: bool = false

func configure(dir: Vector2, str_value: float, max_str: float, dir_editable: bool, str_editable: bool) -> void:
	direction = dir.normalized() if dir.length() > 0.0001 else Vector2.RIGHT
	strength = str_value
	max_strength = max(max_str, 0.001)
	direction_editable = dir_editable
	strength_editable = str_editable
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not (direction_editable or strength_editable):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			_apply_drag(event.position)
	elif event is InputEventMouseMotion and _dragging:
		_apply_drag(event.position)

func _apply_drag(local_pos: Vector2) -> void:
	var center := size / 2.0
	var offset := local_pos - center
	if offset.length() < 0.001:
		return

	if direction_editable:
		direction = offset.normalized()

	if strength_editable:
		var ratio: float = clamp(offset.length() / dial_radius, 0.0, 1.0)
		strength = ratio * max_strength
	elif direction_editable:
		pass # strength stays fixed by the level

	field_changed.emit(direction, strength)
	queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	var track_color := Color(1, 1, 1, 0.12)
	var active_color := Color(0.35, 0.78, 1.0, 0.9)
	if not (direction_editable or strength_editable):
		active_color = Color(0.6, 0.6, 0.65, 0.6)

	draw_circle(center, dial_radius, track_color)
	draw_arc(center, dial_radius, 0, TAU, 48, Color(1, 1, 1, 0.25), 1.5)

	var ratio: float = clamp(strength / max_strength, 0.0, 1.0)
	var handle_pos := center + direction * dial_radius * ratio
	draw_line(center, handle_pos, active_color, 3.0)
	draw_circle(handle_pos, 8.0, active_color)
	draw_circle(center, 3.0, Color(1, 1, 1, 0.4))

	# Arrowhead pointing outward along the field direction.
	if ratio > 0.05:
		var perp := direction.orthogonal()
		var tip := handle_pos + direction * 10.0
		var a := handle_pos + perp * 5.0
		var b := handle_pos - perp * 5.0
		draw_colored_polygon(PackedVector2Array([tip, a, b]), active_color)
