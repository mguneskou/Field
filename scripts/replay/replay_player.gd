class_name ReplayPlayer
extends RefCounted
## Steps through frames recorded by ReplayRecorder, one fixed-step at a
## time, independent of the live physics simulation.

var frames: Array[Dictionary] = []
var playing: bool = false
var _index: int = 0

func load_frames(f: Array[Dictionary]) -> void:
	frames = f
	_index = 0

func play() -> void:
	if frames.is_empty():
		return
	playing = true
	_index = 0

func stop() -> void:
	playing = false

## Returns { spawn_index: Vector2 } for the current frame and advances.
func advance() -> Dictionary:
	if not playing or frames.is_empty():
		return {}
	var frame: Dictionary = frames[_index]
	_index += 1
	if _index >= frames.size():
		playing = false
	return frame.get("positions", {})
