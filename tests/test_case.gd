class_name TestCase
extends RefCounted
## Minimal assertion helpers shared by every physics test. Deliberately
## tiny/dependency-free rather than pulling in an addon, per the project's
## "avoid unnecessary external dependencies" rule.

var failures: Array[String] = []
var passed_count: int = 0

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed_count += 1
	else:
		failures.append(msg)

func assert_eq(a, b, msg: String) -> void:
	assert_true(a == b, "%s (expected %s, got %s)" % [msg, str(b), str(a)])

func assert_almost_eq(a: float, b: float, eps: float, msg: String) -> void:
	assert_true(abs(a - b) <= eps, "%s (expected ~%s, got %s)" % [msg, str(b), str(a)])

func assert_vec_almost_eq(a: Vector2, b: Vector2, eps: float, msg: String) -> void:
	assert_true(a.distance_to(b) <= eps, "%s (expected ~%s, got %s)" % [msg, str(b), str(a)])
