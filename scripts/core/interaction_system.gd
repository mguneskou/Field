class_name InteractionSystem
extends RefCounted
## Pairwise electrostatic (Coulomb) interaction between charged particles.
## F = k * q1 * q2 / r^2, directed along the separation vector.
## Like charges repel, opposite charges attract.
##
## `softening` is a minimum effective distance used only to keep the force
## finite as particles get very close (a common, clearly-documented game-
## physics compromise — real Coulomb's law has no such floor). The constant
## itself is tuned for readable on-screen gameplay, not SI units.

var coulomb_constant: float = 800.0
var softening: float = 4.0
var enabled: bool = true

## Returns a Dictionary mapping each input Particle to the net Coulomb
## force acting on it from every other particle in the list.
func compute_forces(particles: Array) -> Dictionary:
	var forces: Dictionary = {}
	for p in particles:
		forces[p] = Vector2.ZERO

	if not enabled:
		return forces

	for i in range(particles.size()):
		var a: Particle = particles[i]
		if a.charge == 0.0:
			continue
		for j in range(i + 1, particles.size()):
			var b: Particle = particles[j]
			if b.charge == 0.0:
				continue

			var delta := b.position - a.position
			var dist := delta.length()
			var dir: Vector2 = delta / dist if dist > 0.0001 else Vector2.RIGHT
			var eff_dist: float = max(dist, softening)
			var magnitude: float = coulomb_constant * a.charge * b.charge / (eff_dist * eff_dist)

			var force_on_b: Vector2 = dir * magnitude
			forces[b] += force_on_b
			forces[a] -= force_on_b

	return forces
