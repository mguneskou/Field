class_name Objective
extends RefCounted
## Evaluates whether a level's win/fail conditions are currently met.
## Stateful (checkpoint progress, hold timers) so it's instantiated fresh
## per attempt by LevelManager, alongside the PhysicsWorld it judges.

enum Status { RUNNING, SUCCESS, FAILURE }

var next_checkpoint_index: int = 0
var hold_timer: float = 0.0

func evaluate(level: LevelDefinition, world: PhysicsWorld, dt: float) -> int:
	if level.time_limit > 0.0 and world.time >= level.time_limit:
		return Status.FAILURE

	for p in world.particles:
		for obstacle in level.obstacles:
			if CollisionSystem.circles_overlap(p.position, p.radius, obstacle.position, obstacle.radius):
				return Status.FAILURE

	if world.particles.is_empty() and not level.particles.is_empty():
		return Status.FAILURE

	match level.objective_kind:
		LevelDefinition.ObjectiveKind.CHECKPOINTS:
			return _evaluate_checkpoints(level, world)
		LevelDefinition.ObjectiveKind.HOLD_IN_REGION:
			return _evaluate_hold(level, world, dt)
		LevelDefinition.ObjectiveKind.CAPTURE:
			return _evaluate_capture(level, world)
		LevelDefinition.ObjectiveKind.SEPARATE:
			return _evaluate_separate(level, world)
		_:
			return _evaluate_reach_target(level, world)

func _find(world: PhysicsWorld, spawn_index: int) -> Particle:
	for p in world.particles:
		if p.spawn_index == spawn_index:
			return p
	return null

func _evaluate_reach_target(level: LevelDefinition, world: PhysicsWorld) -> int:
	if level.targets.is_empty():
		return Status.RUNNING
	for target in level.targets:
		if not _target_satisfied(target, world):
			return Status.RUNNING
	return Status.SUCCESS

func _target_satisfied(target: TargetDefinition, world: PhysicsWorld) -> bool:
	if target.particle_index >= 0:
		var p := _find(world, target.particle_index)
		return p != null and CollisionSystem.circles_overlap(p.position, p.radius, target.position, target.radius)
	for p in world.particles:
		if CollisionSystem.circles_overlap(p.position, p.radius, target.position, target.radius):
			return true
	return false

func _evaluate_checkpoints(level: LevelDefinition, world: PhysicsWorld) -> int:
	if level.targets.is_empty():
		return Status.RUNNING
	if next_checkpoint_index >= level.targets.size():
		return Status.SUCCESS
	var target := level.targets[next_checkpoint_index]
	if _target_satisfied(target, world):
		next_checkpoint_index += 1
		if next_checkpoint_index >= level.targets.size():
			return Status.SUCCESS
	return Status.RUNNING

func _evaluate_hold(level: LevelDefinition, world: PhysicsWorld, dt: float) -> int:
	if level.targets.is_empty():
		return Status.RUNNING
	if _target_satisfied(level.targets[0], world):
		hold_timer += dt
	else:
		hold_timer = 0.0
	return Status.SUCCESS if hold_timer >= level.hold_duration else Status.RUNNING

func _evaluate_capture(level: LevelDefinition, world: PhysicsWorld) -> int:
	var a := _find(world, level.capture_particle_a)
	var b := _find(world, level.capture_particle_b)
	if a == null or b == null:
		return Status.RUNNING
	if CollisionSystem.circles_overlap(a.position, a.radius, b.position, b.radius):
		return Status.SUCCESS
	return Status.RUNNING

func _evaluate_separate(level: LevelDefinition, world: PhysicsWorld) -> int:
	var a := _find(world, level.separate_particle_a)
	var b := _find(world, level.separate_particle_b)
	if a == null or b == null:
		return Status.RUNNING
	if a.position.distance_to(b.position) >= level.separate_distance:
		return Status.SUCCESS
	return Status.RUNNING
