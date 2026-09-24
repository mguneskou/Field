class_name HUD
extends CanvasLayer
## All on-screen UI: field controls, simulation transport, tutorial text,
## the optional Science panel, and the level-result overlay. Built in code
## rather than a hand-authored .tscn so the layout stays easy to review as
## a diff. Observes LevelManager via signals; never touches PhysicsWorld
## directly except to read values for display.

signal reset_pressed
signal play_pause_pressed
signal continue_requested
signal retry_requested

var level_manager: LevelManager

var _field_dial: FieldDial
var _magnetic_slider: MagneticSlider
var _magnetic_box: VBoxContainer
var _play_pause_button: Button
var _speed_buttons: Dictionary = {}
var _science_button: Button
var _science_panel: PanelContainer
var _science_label: RichTextLabel
var _tutorial_panel: PanelContainer
var _tutorial_label: RichTextLabel
var _result_panel: PanelContainer
var _result_title: Label
var _result_body: Label
var _result_button: Button
var _level_title: Label
var _last_result_was_success: bool = false

const SPEED_OPTIONS := [0.25, 0.5, 1.0, 2.0, 4.0]

func setup(manager: LevelManager) -> void:
	level_manager = manager
	level_manager.level_loaded.connect(_on_level_loaded)
	level_manager.level_completed.connect(_on_level_completed)
	level_manager.level_failed.connect(_on_level_failed)
	GameState.science_mode_changed.connect(_on_science_mode_changed)
	_build_ui()
	set_process(true)

func _process(_delta: float) -> void:
	if _science_panel.visible:
		_update_science_panel()

# ---------------------------------------------------------------- building

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_top_bar(root)
	_build_field_controls(root)
	_build_transport(root)
	_build_science_panel(root)
	_build_tutorial_panel(root)
	_build_result_panel(root)

func _panel(parent: Control) -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.09, 0.85)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	style.border_color = Color(1, 1, 1, 0.08)
	style.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", style)
	parent.add_child(p)
	return p

func _build_top_bar(root: Control) -> void:
	_level_title = Label.new()
	_level_title.add_theme_font_size_override("font_size", 20)
	_level_title.add_theme_color_override("font_color", Color(0.9, 0.92, 0.96))
	_level_title.position = Vector2(24, 20)
	root.add_child(_level_title)

	_science_button = Button.new()
	_science_button.text = "Science: Off"
	_science_button.toggle_mode = true
	_science_button.position = Vector2(1280 - 160, 20)
	_science_button.custom_minimum_size = Vector2(136, 32)
	_science_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_science_button.toggled.connect(func(on): GameState.set_science_mode(on))
	root.add_child(_science_button)

func _build_field_controls(root: Control) -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(24, 720 - 240)
	box.custom_minimum_size = Vector2(160, 0)
	root.add_child(box)

	var dial_label := Label.new()
	dial_label.text = "ELECTRIC FIELD"
	dial_label.add_theme_font_size_override("font_size", 12)
	dial_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9))
	box.add_child(dial_label)

	_field_dial = FieldDial.new()
	_field_dial.custom_minimum_size = Vector2(144, 144)
	_field_dial.mouse_filter = Control.MOUSE_FILTER_STOP
	_field_dial.field_changed.connect(_on_field_dial_changed)
	box.add_child(_field_dial)

	_magnetic_box = VBoxContainer.new()
	root.add_child(_magnetic_box)
	_magnetic_box.position = Vector2(24, 720 - 70)
	_magnetic_box.custom_minimum_size = Vector2(220, 0)

	var mag_label := Label.new()
	mag_label.text = "MAGNETIC FIELD (out ⊙  /  in ⊗)"
	mag_label.add_theme_font_size_override("font_size", 12)
	mag_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.45))
	_magnetic_box.add_child(mag_label)

	_magnetic_slider = MagneticSlider.new()
	_magnetic_slider.custom_minimum_size = Vector2(220, 28)
	_magnetic_slider.mouse_filter = Control.MOUSE_FILTER_STOP
	_magnetic_slider.strength_changed.connect(_on_magnetic_changed)
	_magnetic_box.add_child(_magnetic_slider)

func _build_transport(root: Control) -> void:
	var box := HBoxContainer.new()
	box.position = Vector2(1280 - 468, 720 - 60)
	box.add_theme_constant_override("separation", 8)
	root.add_child(box)

	_play_pause_button = Button.new()
	_play_pause_button.text = "Play"
	_play_pause_button.custom_minimum_size = Vector2(72, 36)
	_play_pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_play_pause_button.pressed.connect(func(): play_pause_pressed.emit())
	box.add_child(_play_pause_button)

	var reset_button := Button.new()
	reset_button.text = "Reset (R)"
	reset_button.custom_minimum_size = Vector2(88, 36)
	reset_button.mouse_filter = Control.MOUSE_FILTER_STOP
	reset_button.pressed.connect(func(): reset_pressed.emit())
	box.add_child(reset_button)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(12, 0)
	box.add_child(sep)

	for speed in SPEED_OPTIONS:
		var b := Button.new()
		b.text = "%sx" % _format_speed(speed)
		b.toggle_mode = true
		b.button_pressed = (speed == 1.0)
		b.custom_minimum_size = Vector2(44, 36)
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		b.pressed.connect(func(): _select_speed(speed))
		box.add_child(b)
		_speed_buttons[speed] = b

func _format_speed(speed: float) -> String:
	if speed == floor(speed):
		return str(int(speed))
	return str(speed)

func _build_science_panel(root: Control) -> void:
	_science_panel = _panel(root)
	_science_panel.position = Vector2(1280 - 300, 64)
	_science_panel.custom_minimum_size = Vector2(280, 220)
	_science_panel.visible = false

	_science_label = RichTextLabel.new()
	_science_label.bbcode_enabled = true
	_science_label.fit_content = true
	_science_label.custom_minimum_size = Vector2(252, 190)
	_science_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_science_panel.add_child(_science_label)

func _build_tutorial_panel(root: Control) -> void:
	_tutorial_panel = _panel(root)
	_tutorial_panel.position = Vector2(1280 / 2.0 - 260, 20)
	_tutorial_panel.custom_minimum_size = Vector2(520, 0)
	_tutorial_panel.visible = false

	_tutorial_label = RichTextLabel.new()
	_tutorial_label.bbcode_enabled = true
	_tutorial_label.fit_content = true
	_tutorial_label.custom_minimum_size = Vector2(492, 0)
	_tutorial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_panel.add_child(_tutorial_label)

func _build_result_panel(root: Control) -> void:
	_result_panel = _panel(root)
	_result_panel.position = Vector2(1280 / 2.0 - 160, 720 / 2.0 - 90)
	_result_panel.custom_minimum_size = Vector2(320, 180)
	_result_panel.visible = false

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_result_panel.add_child(vbox)

	_result_title = Label.new()
	_result_title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_result_title)

	_result_body = Label.new()
	_result_body.add_theme_font_size_override("font_size", 14)
	_result_body.add_theme_color_override("font_color", Color(0.8, 0.82, 0.86))
	vbox.add_child(_result_body)

	_result_button = Button.new()
	_result_button.custom_minimum_size = Vector2(140, 36)
	_result_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_result_button.pressed.connect(_on_result_button_pressed)
	vbox.add_child(_result_button)

# ---------------------------------------------------------------- events

func _on_level_loaded(level: LevelDefinition) -> void:
	_level_title.text = level.level_name
	_field_dial.configure(level.initial_field_direction, level.initial_field_strength,
		level.field_strength_max, level.field_direction_editable, level.field_strength_editable)
	_magnetic_slider.configure(level.initial_magnetic_strength, level.magnetic_strength_min,
		level.magnetic_strength_max, level.magnetic_editable)
	_magnetic_box.visible = level.magnetic_editable
	_play_pause_button.text = "Play"
	_result_panel.visible = false
	_tutorial_panel.visible = not level.tutorial_text.is_empty()
	_tutorial_label.text = level.tutorial_text
	GameState.record_attempt(level.id)

func _on_field_dial_changed(direction: Vector2, strength: float) -> void:
	level_manager.set_field_direction(direction)
	level_manager.set_field_strength(strength)

func _on_magnetic_changed(value: float) -> void:
	level_manager.set_magnetic_strength(value)

func _select_speed(speed: float) -> void:
	level_manager.set_sim_speed(speed)
	for s in _speed_buttons.keys():
		_speed_buttons[s].button_pressed = (s == speed)

func set_play_pause_label(is_running: bool) -> void:
	_play_pause_button.text = "Pause" if is_running else "Play"

func _on_level_completed() -> void:
	_last_result_was_success = true
	_result_title.text = "Target reached"
	_result_title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	_result_body.text = "Solved in %.1fs" % level_manager.world.time
	_result_button.text = "Next Level" if GameState.has_next_level() else "Well done"
	if level_manager.current_level:
		GameState.record_completion(level_manager.current_level.id, level_manager.world.time)
	_result_panel.visible = true

func _on_level_failed() -> void:
	_last_result_was_success = false
	_result_title.text = "Try again"
	_result_title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	_result_body.text = "The objective wasn't met. Reset and adjust the field."
	_result_button.text = "Reset (R)"
	_result_panel.visible = true

func _on_result_button_pressed() -> void:
	if _last_result_was_success:
		continue_requested.emit()
	else:
		retry_requested.emit()

func _on_science_mode_changed(enabled: bool) -> void:
	_science_button.text = "Science: On" if enabled else "Science: Off"
	_science_panel.visible = enabled

func _update_science_panel() -> void:
	if level_manager.world == null or level_manager.world.particles.is_empty():
		_science_label.text = "[i]No particle to inspect.[/i]"
		return
	var p: Particle = level_manager.world.particles[0]
	var e := level_manager.world.electric_field
	var b := level_manager.world.magnetic_field
	_science_label.text = "\n".join([
		"[b]F = qE + q(v × B)[/b]",
		"a = F / m",
		"",
		"q = %.1f   m = %.1f" % [p.charge, p.mass],
		"E = %.1f  dir (%.2f, %.2f)" % [e.strength, e.direction.x, e.direction.y],
		"B = %.1f" % b.strength,
		"v = (%.0f, %.0f)  |v| = %.0f" % [p.velocity.x, p.velocity.y, p.velocity.length()],
		"a = (%.0f, %.0f)" % [p.acceleration.x, p.acceleration.y],
	])
