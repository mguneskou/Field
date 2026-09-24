extends Node2D
## Wires the five independent systems together: LevelManager (physics +
## level data), SimulationView (rendering), HUD (in-level UI),
## InputController (raw input -> actions), LevelSelectMenu (level
## navigation). None of them know about each other directly.

@onready var simulation_view: SimulationView = $SimulationView
@onready var hud: HUD = $HUD
@onready var level_manager: LevelManager = $LevelManager
@onready var input_controller: InputController = $InputController
@onready var level_select_menu: LevelSelectMenu = $LevelSelectMenu

func _ready() -> void:
	simulation_view.setup(level_manager)
	hud.setup(level_manager)
	level_select_menu.setup()

	hud.play_pause_pressed.connect(_on_play_pause)
	hud.reset_pressed.connect(_on_reset)
	hud.continue_requested.connect(_on_continue)
	hud.retry_requested.connect(_on_reset)
	hud.menu_requested.connect(_show_menu)

	input_controller.pause_toggled.connect(_on_play_pause)
	input_controller.reset_requested.connect(_on_reset)
	input_controller.menu_requested.connect(_show_menu)

	level_select_menu.level_selected.connect(_on_level_selected)

	_show_menu()

func _show_menu() -> void:
	level_manager.pause()
	hud.set_play_pause_label(false)
	hud.hide()
	simulation_view.hide()
	level_select_menu.refresh()
	level_select_menu.show()

func _on_level_selected(index: int) -> void:
	GameState.current_level_index = index
	level_select_menu.hide()
	hud.show()
	simulation_view.show()
	_load_current_level()

func _load_current_level() -> void:
	var path := GameState.get_current_level_path()
	if path.is_empty():
		push_warning("No levels found in res://levels/")
		return
	var level: LevelDefinition = load(path)
	level_manager.load_level(level)

func _on_play_pause() -> void:
	if level_select_menu.visible:
		return
	level_manager.toggle_play_pause()
	hud.set_play_pause_label(level_manager.is_running)

func _on_reset() -> void:
	if level_select_menu.visible:
		return
	level_manager.reset()
	hud.set_play_pause_label(false)

func _on_continue() -> void:
	if GameState.has_next_level():
		GameState.advance_to_next_level()
		_load_current_level()
	else:
		_show_menu()
