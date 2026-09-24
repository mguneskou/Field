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
## REACH_TARGET: every entry in `targets` must be simultaneously occupied.
## CHECKPOINTS: `targets` must be visited in array order.
## HOLD_IN_REGION: the particle at targets[0].particle_index must stay
##   inside targets[0] for `hold_duration` seconds (need not be contiguous
##   across pauses, but resets on reset()).
## CAPTURE: particles `capture_particle_a`/`b` must touch each other.
## SEPARATE: particles `separate_particle_a`/`b` must reach `separate_distance` apart.
enum ObjectiveKind { REACH_TARGET, CHECKPOINTS, HOLD_IN_REGION, CAPTURE, SEPARATE }

@export var objective_kind: ObjectiveKind = ObjectiveKind.REACH_TARGET
@export var targets: Array[TargetDefinition] = []
@export var obstacles: Array[ObstacleDefinition] = []
@export var time_limit: float = -1.0 # -1 = no limit

@export_group("Objective Parameters")
@export var hold_duration: float = 2.0
@export var capture_particle_a: int = 0
@export var capture_particle_b: int = 1
@export var separate_particle_a: int = 0
@export var separate_particle_b: int = 1
@export var separate_distance: float = 300.0
