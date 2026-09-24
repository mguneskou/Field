extends SceneTree
## Headless physics test runner.
## Run with: godot --headless --script res://tests/run_tests.gd
## Exits with code 0 if all tests pass, 1 otherwise (CI-friendly).

func _init() -> void:
	var test_scripts := [
		"res://tests/test_electric_field.gd",
		"res://tests/test_magnetic_field.gd",
		"res://tests/test_coulomb.gd",
		"res://tests/test_reset.gd",
		"res://tests/test_objective.gd",
	]

	var total_pass := 0
	var total_fail := 0
	var fail_messages: Array[String] = []

	for path in test_scripts:
		var script: GDScript = load(path)
		var instance: TestCase = script.new()
		for m in instance.get_method_list():
			var mname: String = m["name"]
			if mname.begins_with("test_"):
				instance.callv(mname, [])
		total_pass += instance.passed_count
		for f in instance.failures:
			total_fail += 1
			fail_messages.append("[%s] %s" % [path.get_file(), f])

	print("---- FIELD physics test results ----")
	print("Passed: %d" % total_pass)
	print("Failed: %d" % total_fail)
	if fail_messages.size() > 0:
		print("Failures:")
		for f in fail_messages:
			print("  - " + f)
	print("-------------------------------------")

	quit(1 if total_fail > 0 else 0)
