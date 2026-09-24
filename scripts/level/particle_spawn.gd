class_name ParticleSpawn
extends Resource
## One particle's initial configuration inside a LevelDefinition.

@export var type_id: String = "positive" # "positive" | "negative" | "neutral"
@export var position: Vector2 = Vector2.ZERO
@export var velocity: Vector2 = Vector2.ZERO
@export var mass_override: float = -1.0 # -1 = use ParticleType default
