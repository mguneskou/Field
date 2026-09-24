class_name LevelDefinition
extends Resource
## A complete, data-driven level. No level should ever require custom
## code — everything a level needs is a value on this resource.

@export_group("Identity")
@export var id: String = "level_00"
@export var level_name: String = "Untitled Level"
@export var tutorial_text: String = ""
@export var difficulty: int = 1

@export_group("World")
@export var world_size: Vector2 = Vector2(1280, 720)

@export_group("Particles")
@export var particles: Array[ParticleSpawn] = []

@export_group("Fields")
@export var initial_field_direction: Vector2 = Vector2.RIGHT
@export var initial_field_strength: float = 0.0
@export var field_direction_editable: bool = true
@export var field_strength_editable: bool = true
@export var field_strength_min: float = -100.0
@export var field_strength_max: float = 100.0

@export var initial_magnetic_strength: float = 0.0
@export var magnetic_editable: bool = false
@export var magnetic_strength_min: float = -50.0
@export var magnetic_strength_max: float = 50.0

@export var coulomb_enabled: bool = false

@export_group("Objectives")
@export var targets: Array[TargetDefinition] = []
@export var obstacles: Array[ObstacleDefinition] = []
@export var time_limit: float = -1.0 # -1 = no limit
