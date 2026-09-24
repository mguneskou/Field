extends Node2D
## Wires the four independent systems together: LevelManager (physics +
## level data), SimulationView (rendering), HUD (UI), InputController
## (raw input -> actions). None of those four know about each other.

@onready var simulation_view: SimulationView = $SimulationView
@onready var hud: HUD = $HUD
@onready var level_manager: LevelManager = $LevelManager
@onready var input_controller: InputController = $InputController

func _ready() -> void:
	simulation_view.setup(level_manager)
	hud.setup(level_manager)

	hud.play_pause_pressed.connect(_on_play_pause)
	hud.reset_pressed.connect(_on_reset)
	hud.continue_requested.connect(_on_continue)
	hud.retry_requested.connect(_on_reset)

	input_controller.pause_toggled.connect(_on_play_pause)
	input_controller.reset_requested.connect(_on_reset)

	_load_current_level()

func _load_current_level() -> void:
	var path := GameState.get_current_level_path()
	if path.is_empty():
		push_warning("No levels found in res://levels/")
		return
	var level: LevelDefinition = load(path)
	level_manager.load_level(level)

func _on_play_pause() -> void:
	level_manager.toggle_play_pause()
	hud.set_play_pause_label(level_manager.is_running)

func _on_reset() -> void:
	level_manager.reset()
	hud.set_play_pause_label(false)

func _on_continue() -> void:
	if GameState.has_next_level():
		GameState.advance_to_next_level()
		_load_current_level()
