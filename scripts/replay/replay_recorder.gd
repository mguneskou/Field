class_name ReplayRecorder
extends RefCounted
## Records enough state to play back a completed run: per fixed-step
## particle positions, keyed by each particle's stable spawn_index.

var frames: Array[Dictionary] = []
var recording: bool = false

func start() -> void:
	frames.clear()
	recording = true

func stop() -> void:
	recording = false

func capture(world: PhysicsWorld) -> void:
	if not recording:
		return
	var positions: Dictionary = {}
	for p in world.particles:
		positions[p.spawn_index] = p.position
	frames.append({"t": world.time, "positions": positions})

func is_empty() -> bool:
	return frames.is_empty()
