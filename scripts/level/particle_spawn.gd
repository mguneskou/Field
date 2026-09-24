class_name ParticleSpawn
extends Resource
## One particle's initial configuration inside a LevelDefinition.

@export var type_id: String = "positive" # "positive" | "negative" | "neutral" | "photon" | "electron" | "positron"
@export var position: Vector2 = Vector2.ZERO
@export var velocity: Vector2 = Vector2.ZERO
@export var mass_override: float = -1.0 # -1 = use ParticleType default

## Only meaningful for "photon" spawns: a photon's velocity always has
## magnitude c and by itself carries no energy information (see
## Particle.momentum_magnitude). Set this to give a level-authored photon
## a specific energy, e.g. for a pair-production level.
@export var momentum_magnitude: float = 0.0
