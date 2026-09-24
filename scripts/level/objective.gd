class_name Objective
extends RefCounted
## Evaluates whether a level's win/fail conditions are currently met.
## Pure function of (LevelDefinition, PhysicsWorld) — no side effects,
## no UI, no knowledge of how the state got there.

enum Status { RUNNING, SUCCESS, FAILURE }

static func evaluate(level: LevelDefinition, world: PhysicsWorld) -> int:
	if level.time_limit > 0.0 and world.time >= level.time_limit:
		return Status.FAILURE

	for p in world.particles:
		for obstacle in level.obstacles:
			if CollisionSystem.circles_overlap(p.position, p.radius, obstacle.position, obstacle.radius):
				return Status.FAILURE

	if world.particles.is_empty() and not level.particles.is_empty():
		return Status.FAILURE # every particle left the play area

	if level.targets.is_empty():
		return Status.RUNNING

	for target in level.targets:
		if not _target_satisfied(target, world):
			return Status.RUNNING

	return Status.SUCCESS

static func _target_satisfied(target: TargetDefinition, world: PhysicsWorld) -> bool:
	if target.particle_index >= 0:
		for p in world.particles:
			if p.spawn_index == target.particle_index:
				return CollisionSystem.circles_overlap(p.position, p.radius, target.position, target.radius)
		return false
	for p in world.particles:
		if CollisionSystem.circles_overlap(p.position, p.radius, target.position, target.radius):
			return true
	return false
