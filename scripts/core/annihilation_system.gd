class_name AnnihilationSystem
extends RefCounted
## e- + e+ -> gamma + gamma. When an electron and positron overlap, both
## are removed and replaced with two photons that exactly conserve total
## momentum and energy, via RelativisticKinematics — annihilation converts
## rest mass to energy, so this calculation is inherently relativistic
## regardless of whether the world's own integrator is currently running
## in relativistic mode.
##
## Simplification, clearly labeled: real annihilation's two photons can
## emerge along any axis consistent with conservation — the exact angle
## is set by QED matrix elements, not by conservation laws alone. This
## picks the specific solution where both photons carry equal energy: a
## clean, deterministic, fully-conserving choice, not a claim about real
## photon angular distributions.

var enabled: bool = true
var pairs: Array[Array] = [["electron", "positron"]] # extend here for future annihilating pairs

## Scans a snapshot of particles for overlapping annihilating pairs.
## Returns {"created": Array[Particle], "consumed": Array[Particle]} —
## does NOT mutate the list itself. This matters: if this ran against a
## live, already-mutated particle list that PairProductionSystem had
## just added to in the same step, a freshly-created electron/positron
## pair (still exactly co-located with its photon parents' collision
## point) would immediately re-match and annihilate right back — an
## invisible same-step ping-pong. PhysicsWorld takes a snapshot before
## running either reaction system and applies both results together
## afterward, so neither system ever sees the other's same-step output.
func process(particles: Array[Particle], speed_of_light: float) -> Dictionary:
	var created: Array[Particle] = []
	var to_remove: Array[Particle] = []
	if not enabled:
		return {"created": created, "consumed": to_remove}

	for i in range(particles.size()):
		var a: Particle = particles[i]
		if a in to_remove:
			continue
		for j in range(i + 1, particles.size()):
			var b: Particle = particles[j]
			if b in to_remove:
				continue
			if not _is_annihilating_pair(a.type_id, b.type_id):
				continue
			if not CollisionSystem.circles_overlap(a.position, a.radius, b.position, b.radius):
				continue
			var photons := _annihilate(a, b, speed_of_light)
			created.append_array(photons)
			to_remove.append(a)
			to_remove.append(b)
			break # a is consumed; move on to the next i

	return {"created": created, "consumed": to_remove}

func _is_annihilating_pair(type_a: String, type_b: String) -> bool:
	for pair in pairs:
		if (type_a == pair[0] and type_b == pair[1]) or (type_a == pair[1] and type_b == pair[0]):
			return true
	return false

func _annihilate(a: Particle, b: Particle, c: float) -> Array[Particle]:
	var total_momentum: Vector2 = RelativisticKinematics.momentum(a.mass, a.velocity, c) \
		+ RelativisticKinematics.momentum(b.mass, b.velocity, c)
	var total_energy: float = RelativisticKinematics.total_energy(a.mass, a.velocity.length(), c) \
		+ RelativisticKinematics.total_energy(b.mass, b.velocity.length(), c)

	# Equal-energy split: |p1| = |p2| = E/(2c). p1 = P/2 + perp*h and
	# p2 = P/2 - perp*h, solved so both have that magnitude. h is always
	# real for a physical pair, since (E/c)^2 >= |P|^2 always holds
	# (that's exactly the statement that the pair's invariant mass is
	# non-negative).
	var half_p := total_momentum / 2.0
	var target_mag: float = total_energy / (2.0 * c)
	var h_squared: float = max(target_mag * target_mag - half_p.length_squared(), 0.0)
	var h: float = sqrt(h_squared)

	var perp := total_momentum.orthogonal().normalized() if total_momentum.length() > 0.0001 else Vector2.UP
	var p1 := half_p + perp * h
	var p2 := half_p - perp * h

	var midpoint := (a.position + b.position) / 2.0
	var photons: Array[Particle] = [_make_photon(midpoint, p1, c), _make_photon(midpoint, p2, c)]
	return photons

func _make_photon(position: Vector2, p: Vector2, c: float) -> Particle:
	var photon := Particle.new(ParticleTypes.photon(), position, Vector2.ZERO)
	var magnitude := p.length()
	photon.momentum_magnitude = magnitude
	if magnitude > 0.0001:
		photon.velocity = p.normalized() * c
	photon.lifetime = 3.0 # fade out rather than linger forever
	return photon
