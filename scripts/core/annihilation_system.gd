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

## Scans world.particles for overlapping annihilating pairs, replaces each
## with two photons, and returns the photons created (empty if none).
func process(world: PhysicsWorld) -> Array[Particle]:
	var created: Array[Particle] = []
	if not enabled:
		return created

	var to_remove: Array[Particle] = []
	var particles := world.particles
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
			var photons := _annihilate(a, b, world.speed_of_light)
			created.append_array(photons)
			to_remove.append(a)
			to_remove.append(b)
			break # a is consumed; move on to the next i

	if not to_remove.is_empty():
		var survivors: Array[Particle] = particles.filter(func(p): return not (p in to_remove))
		world.particles = survivors
		for photon in created:
			world.particles.append(photon)
	return created

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
