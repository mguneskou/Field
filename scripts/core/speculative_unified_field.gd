class_name SpeculativeUnifiedField
extends RefCounted
## SPECULATIVE GAME ABSTRACTION — NOT a real physical theory, and not an
## implementation of any experimentally confirmed unification. Read this
## docstring before touching this file or showing it to a player.
##
## Real unification: the electromagnetic and weak forces are
## experimentally confirmed to merge into one "electroweak" force at high
## enough energy. Grand Unified Theories PROPOSE (untested, unconfirmed)
## that the strong force joins them at even higher energy. A full "Theory
## of Everything" — unifying gravity too — has no confirmed formulation
## at all. This class implements none of that physics.
##
## What it actually is: a toy interpolation between two forces already in
## this engine —
##   - the familiar 1/r^2 Coulomb force (unification = 0)
##   - an invented "confinement" force whose magnitude GROWS with
##     distance instead of shrinking (unification = 1), echoing the real,
##     well-established qualitative behavior of quark confinement (the
##     strong force does get stronger with separation) — but the specific
##     blend formula here is not derived from QCD or anything else real.
## It exists to make the qualitative IDEA — "forces that look different
## can behave as one force as some parameter changes" — interactively
## explorable, not to model how real unification actually works.
## Off by default; enabling it does not change how any classical
## electromagnetism level behaves.

var unification: float = 0.0 # 0 = ordinary Coulomb, 1 = fully "confining"
var coulomb_constant: float = 250000.0
var confinement_strength: float = 5.0
var softening: float = 8.0
var enabled: bool = false

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

			var coulomb_mag: float = coulomb_constant * a.charge * b.charge / (eff_dist * eff_dist)
			var confinement_mag: float = confinement_strength * a.charge * b.charge * eff_dist
			var blended_mag: float = lerp(coulomb_mag, confinement_mag, clamp(unification, 0.0, 1.0))

			var force_on_b := dir * blended_mag
			forces[b] += force_on_b
			forces[a] -= force_on_b

	return forces
