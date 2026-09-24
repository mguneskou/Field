class_name LevelSelectMenu
extends CanvasLayer
## The level-select screen: a scrollable grid of every level in
## res://levels/, showing completion state, that lets the player jump
## directly to any level instead of only stepping through "Next Level."
## Pure UI — reads GameState for the level list/results, never touches
## PhysicsWorld or LevelManager.

signal level_selected(index: int)

var _grid: GridContainer
var _buttons: Array[Button] = []

const COLUMNS := 5
const CARD_SIZE := Vector2(220, 112)

func setup() -> void:
	_build_ui()
	refresh()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var title := Label.new()
	title.text = "FIELD"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.92, 0.96))
	title.position = Vector2(40, 32)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Select a level"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.55, 0.6, 0.68))
	subtitle.position = Vector2(42, 78)
	root.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 120)
	scroll.custom_minimum_size = Vector2(1280 - 80, 720 - 160)
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(_grid)

## Rebuilds the level cards from GameState's current level list/results.
## Call again whenever completion state may have changed (e.g. on
## returning to the menu after finishing a level).
func refresh() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_buttons.clear()

	for i in range(GameState.level_paths.size()):
		var path: String = GameState.level_paths[i]
		var level: LevelDefinition = load(path)
		if level == null:
			continue
		_grid.add_child(_build_card(i, level))

func _build_card(index: int, level: LevelDefinition) -> Control:
	var result: Dictionary = GameState.results.get(level.id, {})
	var completed: bool = result.get("completed", false)

	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.clip_text = false
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = "%s%s\n\n%s" % [
		"✓  " if completed else "",
		_wrap_text(level.level_name, 22),
		_difficulty_stars(level.difficulty),
	]

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.32, 0.18, 0.9) if completed else Color(0.09, 0.10, 0.13, 0.9)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	style.border_color = Color(0.4, 0.85, 0.5, 0.5) if completed else Color(1, 1, 1, 0.08)
	style.set_border_width_all(1)
	button.add_theme_stylebox_override("normal", style)

	var hover_style: StyleBoxFlat = style.duplicate()
	hover_style.bg_color = style.bg_color.lightened(0.12)
	button.add_theme_stylebox_override("hover", hover_style)

	button.pressed.connect(func(): level_selected.emit(index))
	_buttons.append(button)
	return button

func _difficulty_stars(difficulty: int) -> String:
	return "★".repeat(clamp(difficulty, 0, 5)) + "☆".repeat(5 - clamp(difficulty, 0, 5))

## Simple greedy word-wrap — Button's built-in text has no autowrap
## option, so long level names are wrapped manually before assignment.
func _wrap_text(text: String, max_chars: int) -> String:
	var words := text.split(" ")
	var lines: Array[String] = []
	var current := ""
	for word in words:
		var candidate: String = word if current.is_empty() else current + " " + word
		if candidate.length() > max_chars and not current.is_empty():
			lines.append(current)
			current = word
		else:
			current = candidate
	if not current.is_empty():
		lines.append(current)
	return "\n".join(lines)
