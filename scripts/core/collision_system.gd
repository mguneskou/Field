class_name CollisionSystem
extends RefCounted
## Simple circle-based overlap tests shared by targets, checkpoints,
## obstacles and particle-particle collisions. No physics response here —
## callers (Objective, LevelManager) decide what an overlap means.

static func circles_overlap(pos_a: Vector2, radius_a: float, pos_b: Vector2, radius_b: float) -> bool:
	return pos_a.distance_squared_to(pos_b) <= pow(radius_a + radius_b, 2)

static func point_in_circle(point: Vector2, center: Vector2, radius: float) -> bool:
	return point.distance_squared_to(center) <= radius * radius

static func point_in_rect(point: Vector2, rect: Rect2) -> bool:
	return rect.has_point(point)
