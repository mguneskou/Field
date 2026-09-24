class_name MagneticSlider
extends Control
## Horizontal slider for the (scalar, 2D-simplified) magnetic field
## strength. Center = zero field; left = into the screen, right = out of
## the screen.

signal strength_changed(value: float)

@export var value: float = 0.0
@export var min_value: float = -50.0
@export var max_value: float = 50.0
@export var editable: bool = true

var _dragging: bool = false

func configure(v: float, v_min: float, v_max: float, is_editable: bool) -> void:
	value = v
	min_value = v_min
	max_value = v_max
	editable = is_editable
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not editable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			_apply_drag(event.position.x)
	elif event is InputEventMouseMotion and _dragging:
		_apply_drag(event.position.x)

func _apply_drag(local_x: float) -> void:
	var ratio: float = clamp(local_x / size.x, 0.0, 1.0)
	value = lerp(min_value, max_value, ratio)
	strength_changed.emit(value)
	queue_redraw()

func _draw() -> void:
	var track_y := size.y / 2.0
	draw_line(Vector2(0, track_y), Vector2(size.x, track_y), Color(1, 1, 1, 0.15), 3.0)

	var zero_ratio: float = inverse_lerp(min_value, max_value, 0.0)
	draw_line(Vector2(size.x * zero_ratio, track_y - 8), Vector2(size.x * zero_ratio, track_y + 8), Color(1, 1, 1, 0.3), 1.5)

	var ratio: float = inverse_lerp(min_value, max_value, value)
	var handle_x: float = clamp(ratio, 0.0, 1.0) * size.x
	var color := Color(0.65, 0.4, 1.0, 0.9) if editable else Color(0.6, 0.6, 0.65, 0.6)
	draw_circle(Vector2(handle_x, track_y), 9.0, color)
