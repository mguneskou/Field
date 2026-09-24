extends SceneTree
## Dev tool: loads every level resource and runs it headless through
## LevelManager for a few seconds with reasonable input, checking for
## load errors and NaN/instability. Not part of the shipped game.

func _init() -> void:
	var manager := LevelManager.new()
	root.add_child(manager)

	var ids: Array[String] = []
	var dir := DirAccess.open("res://levels")
	if dir != null:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				ids.append(file_name.trim_suffix(".tres"))
			file_name = dir.get_next()
		dir.list_dir_end()
	ids.sort()

	for id in ids:
		var path := "res://levels/%s.tres" % id
		var level: LevelDefinition = load(path)
		if level == null:
			printerr("FAILED TO LOAD %s" % path)
			continue
		manager.load_level(level)
		manager.set_field_direction(Vector2(1, -0.3))
		manager.set_field_strength(level.field_strength_max * 0.8)
		manager.set_magnetic_strength(level.magnetic_strength_max * 0.5)
		manager.play()

		for i in range(300): # 5 seconds at 60hz
			manager._physics_process(1.0 / 60.0)
			for p in manager.world.particles:
				if not (is_finite(p.position.x) and is_finite(p.position.y)):
					printerr("NaN position in %s at step %d" % [id, i])
					break

		print("%s: OK, particles=%d, status=%d, time=%.2f" % [
			id, manager.world.particles.size(), manager.status, manager.world.time
		])

	print("Smoke test complete.")
	quit(0)
