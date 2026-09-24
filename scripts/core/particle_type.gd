class_name ParticleType
extends Resource
## Data describing a category of particle (charge, mass, radius, look).
## Kept generic on purpose: "positive"/"negative"/"neutral" today,
## "electron"/"proton"/"photon" later, without changing any physics code.

@export var id: String = "neutral"
@export var display_name: String = "Neutral Particle"
@export var charge: float = 0.0
@export var mass: float = 1.0
@export var radius: float = 6.0
@export var color: Color = Color(0.82, 0.84, 0.88)
