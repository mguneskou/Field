class_name ObstacleDefinition
extends Resource
## A static circular obstacle. Particles that touch it fail the level
## (unless a future objective type says otherwise).

@export var position: Vector2 = Vector2.ZERO
@export var radius: float = 20.0
