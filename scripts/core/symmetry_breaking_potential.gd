class_name SymmetryBreakingPotential
extends RefCounted
## A rotationally-symmetric "Mexican hat" / "wine bottle" potential:
##   V(r) = a * (r^2 - b^2)^2,  r = distance from `center`
## This is the same potential shape used in real physics (Landau theory
## of phase transitions, the Higgs mechanism, ferromagnetism below the
## Curie point) to illustrate spontaneous symmetry breaking — not a
## speculative or made-up game mechanic. What IS a simplification: this
## is a single classical particle rolling in a fixed external potential,
## not an actual quantum field with its own vacuum expectation value.
##
## The potential itself is perfectly rotationally symmetric — there is no
## preferred direction anywhere in its definition. Its shape has an
## UNSTABLE equilibrium at the center (r=0) and a STABLE ring of minima
## at r=b (the "vacuum"). A particle placed exactly at center stays there
## forever in a frictionless simulation, in principle — but any
## infinitesimal perturbation (which is unavoidable in practice — here,
## from float rounding if nothing else, or a deliberate nudge) breaks the
## symmetry and sends it rolling out to some arbitrary point on the ring.
## Which point is determined entirely by which way it happened to be
## nudged, not by the (symmetric) potential — that's the "spontaneous"
## in spontaneous symmetry breaking.

var center: Vector2 = Vector2.ZERO
var a: float = 0.002 # steepness
var b: float = 150.0 # vacuum radius (ring of minima)
var enabled: bool = false

## Without any dissipation, a particle released near the unstable center
## conserves energy and oscillates forever between r=0 and r=b*sqrt(2) —
## it passes through the ring but never comes to rest there, the same way
## a frictionless ball never stops rolling in a real bowl. Some form of
## dissipation is physically necessary for a system to actually settle
## into a broken-symmetry ground state; `damping` is a simple velocity-
## proportional drag standing in for that (friction, radiation, thermal
## relaxation — whatever the real mechanism would be), not a separate
## physical law of its own.
var damping: float = 0.5

func potential_at(position: Vector2) -> float:
	var r2 := position.distance_squared_to(center)
	var x := r2 - b * b
	return a * x * x

## F = -grad(V) - damping*v. The conservative term is worked out in closed
## form: -grad(V) = -4a(r^2 - b^2) * offset, where offset = position -
## center (so |offset| = r).
func force_on(particle: Particle) -> Vector2:
	if not enabled:
		return Vector2.ZERO
	var offset := particle.position - center
	var r2 := offset.length_squared()
	var coeff: float = -4.0 * a * (r2 - b * b)
	return offset * coeff - particle.velocity * damping
