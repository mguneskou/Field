extends Node
## Autoload singleton. Holds cross-scene state that isn't physics and isn't
## per-frame: level progression, per-level results, and UI-wide preferences
## like Science Mode. Does not touch PhysicsWorld/LevelManager directly —
## Main wires those together and reports outcomes back here.

signal science_mode_changed(enabled: bool)

const LEVEL_DIR := "res://levels/"

var level_paths: Array[String] = []
var current_level_index: int = 0
var science_mode: bool = false

## level_id -> { "completed": bool, "best_time": float, "attempts": int }
var results: Dictionary = {}

func _ready() -> void:
	_discover_levels()

func _discover_levels() -> void:
	level_paths.clear()
	var dir := DirAccess.open(LEVEL_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			level_paths.append(LEVEL_DIR + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	level_paths.sort()

func get_current_level_path() -> String:
	if current_level_index < 0 or current_level_index >= level_paths.size():
		return ""
	return level_paths[current_level_index]

func has_next_level() -> bool:
	return current_level_index + 1 < level_paths.size()

func advance_to_next_level() -> void:
	if has_next_level():
		current_level_index += 1

func set_science_mode(enabled: bool) -> void:
	science_mode = enabled
	science_mode_changed.emit(enabled)

func record_attempt(level_id: String) -> void:
	var r: Dictionary = results.get(level_id, {"completed": false, "best_time": -1.0, "attempts": 0})
	r["attempts"] = int(r["attempts"]) + 1
	results[level_id] = r

func record_completion(level_id: String, time_taken: float) -> void:
	var r: Dictionary = results.get(level_id, {"completed": false, "best_time": -1.0, "attempts": 0})
	r["completed"] = true
	if r["best_time"] < 0.0 or time_taken < r["best_time"]:
		r["best_time"] = time_taken
	results[level_id] = r
