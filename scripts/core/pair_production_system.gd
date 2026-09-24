class_name PairProductionSystem
extends RefCounted
## gamma + gamma -> e- + e+. The time-reverse of AnnihilationSystem,
## completing the spec's "creation and annihilation" pairing. Two
## overlapping photons whose combined energy meets or exceeds the
## threshold 2*mass*c^2 (the rest-mass energy of the pair being created)
## convert into an electron and a positron, conserving momentum and
## energy exactly — below threshold, real photon-photon collisions can't
## produce a massive pair either, so nothing happens and the photons
## pass through each other undisturbed.
##
## Same simplification as AnnihilationSystem, and for the same reason:
## real pair production's angular distribution depends on the specific
## interaction, not on conservation laws alone. This picks the equal-
## energy-split solution, the cleanest fully-conserving choice.

var enabled: bool = true
var product_mass: float = 1.0 # mass of each created particle (electron/positron share one)

## Scans a snapshot of particles (see AnnihilationSystem.process for why
## a snapshot, not a live/mutated list, matters). Returns
## {"created": Array[Particle], "consumed": Array[Particle]}.
func process(particles: Array[Particle], speed_of_light: float) -> Dictionary:
	var created: Array[Particle] = []
	var to_remove: Array[Particle] = []
	if not enabled:
		return {"created": created, "consumed": to_remove}

	for i in range(particles.size()):
		var a: Particle = particles[i]
		if a.type_id != "photon" or a in to_remove:
			continue
		for j in range(i + 1, particles.size()):
			var b: Particle = particles[j]
			if b.type_id != "photon" or b in to_remove:
				continue
			if not CollisionSystem.circles_overlap(a.position, a.radius, b.position, b.radius):
				continue
			var pair := _produce(a, b, speed_of_light)
			if pair.is_empty():
				continue # below threshold: photons pass through, untouched
			created.append_array(pair)
			to_remove.append(a)
			to_remove.append(b)
			break

	return {"created": created, "consumed": to_remove}

## Returns [] if the pair's combined energy is below the 2*mc^2 threshold.
func _produce(a: Particle, b: Particle, c: float) -> Array[Particle]:
	var total_momentum: Vector2 = _photon_momentum(a) + _photon_momentum(b)
	var total_energy: float = RelativisticKinematics.massless_energy(a.momentum_magnitude, c) \
		+ RelativisticKinematics.massless_energy(b.momentum_magnitude, c)

	var rest_energy: float = product_mass * c * c
	var half_energy: float = total_energy / 2.0
	if half_energy < rest_energy:
		return [] # not even enough energy for an equal split to reach rest mass;
		# sqrt() below would otherwise be given a negative number and return
		# NaN, and "NaN < 0.0" is false in IEEE754 — silently NOT caught by
		# the h_squared check further down. Caught this exact failure mode
		# via a test with two exactly-opposing low-energy photons: total
		# energy was below 2mc^2, but the resulting "particles" were built
		# from NaN momentum instead of being correctly rejected.

	# Equal-energy split: each new particle gets E_total/2, so by
	# E^2 = (pc)^2 + (mc^2)^2, each has momentum magnitude
	# sqrt((E/2)^2 - (mc^2)^2) / c. Solve for the perpendicular offset
	# from P/2 that gives both momenta this magnitude, same construction
	# as AnnihilationSystem — EXCEPT here it's not guaranteed real, unlike
	# annihilation's photon products. A massless photon pair's momentum
	# can be split into two equal-energy massive particles only if the
	# pair's full invariant mass clears the threshold: E^2 - (Pc)^2 >=
	# (2mc^2)^2 (not just E >= 2mc^2 — a naive energy-only check, checking
	# "target_mag^2 > 0", misses that a large net momentum P can still
	# make the reaction impossible even with enough raw energy). That
	# full condition is exactly "h_squared computed below is positive" —
	# a first version of this code clamped a negative h_squared to 0
	# instead of checking it, which silently violated energy conservation
	# for exactly this case instead of correctly rejecting the reaction.
	var target_mag: float = sqrt(half_energy * half_energy - rest_energy * rest_energy) / c
	var half_p := total_momentum / 2.0
	var h_squared: float = target_mag * target_mag - half_p.length_squared()
	if h_squared < 0.0:
		return [] # below the true (momentum-aware) threshold: not possible
	var h: float = sqrt(h_squared)

	var perp := total_momentum.orthogonal().normalized() if total_momentum.length() > 0.0001 else Vector2.UP
	var p1 := half_p + perp * h
	var p2 := half_p - perp * h

	var midpoint := (a.position + b.position) / 2.0
	var electron := _make_massive(midpoint, p1, ParticleTypes.electron(), c)
	var positron := _make_massive(midpoint, p2, ParticleTypes.positron(), c)
	var pair: Array[Particle] = [electron, positron]
	return pair

func _photon_momentum(photon: Particle) -> Vector2:
	if photon.velocity.length() < 0.0001:
		return Vector2.ZERO
	return photon.velocity.normalized() * photon.momentum_magnitude

func _make_massive(position: Vector2, p: Vector2, type: ParticleType, c: float) -> Particle:
	var particle := Particle.new(type, position, Vector2.ZERO)
	particle.velocity = RelativisticKinematics.velocity_from_momentum(particle.mass, p, c)
	return particle
