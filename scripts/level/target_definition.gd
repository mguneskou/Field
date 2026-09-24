class_name TargetDefinition
extends Resource
## A circular target zone a particle must reach (or stay inside, for
## "maintain in region" objectives).

@export var position: Vector2 = Vector2.ZERO
@export var radius: float = 20.0
@export var particle_index: int = 0 # which spawned particle must reach it, -1 = any
