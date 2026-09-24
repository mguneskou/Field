class_name ParticleTypes
extends RefCounted
## Presets for the initial particle roster. Adding "electron", "proton",
## etc. later is just adding another factory function here.

static func positive() -> ParticleType:
	var t := ParticleType.new()
	t.id = "positive"
	t.display_name = "Positive Particle"
	t.charge = 1.0
	t.mass = 1.0
	t.radius = 7.0
	t.color = Color(1.0, 0.38, 0.38)
	return t

static func negative() -> ParticleType:
	var t := ParticleType.new()
	t.id = "negative"
	t.display_name = "Negative Particle"
	t.charge = -1.0
	t.mass = 1.0
	t.radius = 7.0
	t.color = Color(0.35, 0.62, 1.0)
	return t

static func neutral() -> ParticleType:
	var t := ParticleType.new()
	t.id = "neutral"
	t.display_name = "Neutral Particle"
	t.charge = 0.0
	t.mass = 1.0
	t.radius = 6.0
	t.color = Color(0.82, 0.84, 0.88)
	return t

## Massless, chargeless — always free-streams at whatever speed it's given
## (see PhysicsIntegrator's massless handling) and is untouched by any
## field or Coulomb force. Used by AnnihilationSystem's gamma-ray products.
static func photon() -> ParticleType:
	var t := ParticleType.new()
	t.id = "photon"
	t.display_name = "Photon"
	t.charge = 0.0
	t.mass = 0.0
	t.radius = 4.0
	t.color = Color(1.0, 0.95, 0.6)
	return t

static func by_id(id: String) -> ParticleType:
	match id:
		"positive":
			return positive()
		"negative":
			return negative()
		"photon":
			return photon()
		_:
			return neutral()
