class_name QuantumWave1D
extends RefCounted
## A real, numerically-integrated 1D time-dependent Schrödinger equation:
##   i*hbar * dpsi/dt = -hbar^2/(2m) * d^2psi/dx^2 + V(x)*psi
##
## This is not a fake — psi(x,t) is genuinely evolved on a grid via finite
## differences, not approximated by jittering a classical particle. Splits
## psi = u + i*v into real/imaginary grids and uses the standard
## real-imaginary leapfrog (Visscher) scheme: v is advanced using the
## current u, then u is advanced using the JUST-UPDATED v. This keeps the
## scheme well-behaved (bounded probability drift) the same way our
## particle integrator's semi-implicit Euler is better-behaved than plain
## explicit Euler.
##
## hbar and mass are game-scale units (hbar=1), chosen so wavepacket
## dynamics are visible on a few-hundred-point grid over a few seconds —
## not a claim about real quantum-mechanical magnitudes.
##
## Boundaries are hard walls (psi forced to 0 outside the grid), i.e. an
## infinite square well containing the whole simulated region.

const HBAR: float = 1.0

var grid_size: int
var dx: float
var mass: float
var potential: PackedFloat32Array
var u: PackedFloat32Array # Re(psi)
var v: PackedFloat32Array # Im(psi)
var time: float = 0.0

func _init(p_grid_size: int = 256, p_dx: float = 1.0, p_mass: float = 1.0) -> void:
	grid_size = p_grid_size
	dx = p_dx
	mass = p_mass
	potential = PackedFloat32Array()
	potential.resize(grid_size)
	u = PackedFloat32Array()
	u.resize(grid_size)
	v = PackedFloat32Array()
	v.resize(grid_size)

## Prepares psi as a normalized Gaussian wavepacket centered at x0, with
## spatial spread sigma and central momentum hbar*k0 (a superposition of
## momentum eigenstates, per the uncertainty principle: a spatially
## localized packet is necessarily a spread of momenta).
func set_gaussian_wavepacket(x0: float, sigma: float, k0: float) -> void:
	for i in range(grid_size):
		var x: float = i * dx
		var envelope: float = exp(-pow(x - x0, 2.0) / (4.0 * sigma * sigma))
		u[i] = envelope * cos(k0 * x)
		v[i] = envelope * sin(k0 * x)
	time = 0.0
	normalize()

func set_free_space() -> void:
	for i in range(grid_size):
		potential[i] = 0.0

## A rectangular potential barrier/well between grid indices [start, end).
func set_barrier(start_index: int, end_index: int, height: float) -> void:
	for i in range(max(start_index, 0), min(end_index, grid_size)):
		potential[i] = height

func probability_density(i: int) -> float:
	return u[i] * u[i] + v[i] * v[i]

func total_probability() -> float:
	var total := 0.0
	for i in range(grid_size):
		total += probability_density(i) * dx
	return total

func normalize() -> void:
	var total := total_probability()
	if total <= 0.0000001:
		return
	var scale: float = 1.0 / sqrt(total)
	for i in range(grid_size):
		u[i] *= scale
		v[i] *= scale

## <x> = integral of x * |psi(x)|^2 dx
func expectation_position() -> float:
	var total := 0.0
	for i in range(grid_size):
		total += (i * dx) * probability_density(i) * dx
	return total

## Variance of position: <x^2> - <x>^2. Its growth over time for a free
## wavepacket IS quantum dispersion — a real, distinctly quantum effect
## (a classical point particle's position variance under no force doesn't
## grow this way; a spread of momenta each moving at their own group
## velocity does).
func position_variance() -> float:
	var mean := expectation_position()
	var total := 0.0
	for i in range(grid_size):
		var x: float = i * dx
		total += (x - mean) * (x - mean) * probability_density(i) * dx
	return total

## Total probability found at or beyond a given grid index — e.g. the
## far side of a barrier, for measuring tunneling transmission.
func probability_beyond(index: int) -> float:
	var total := 0.0
	for i in range(max(index, 0), grid_size):
		total += probability_density(i) * dx
	return total

## Simulates a position measurement: samples a grid index from the
## |psi|^2 distribution (inverse-CDF sampling), then collapses psi to a
## narrow Gaussian at that location — the standard simplified textbook
## model of wavefunction collapse. Returns the measured position.
func measure_position(rng: RandomNumberGenerator, collapse_sigma: float = -1.0) -> float:
	var target: float = rng.randf() * total_probability()
	var accum := 0.0
	var measured_index := grid_size - 1
	for i in range(grid_size):
		accum += probability_density(i) * dx
		if accum >= target:
			measured_index = i
			break
	var measured_x: float = measured_index * dx
	var sigma: float = collapse_sigma if collapse_sigma > 0.0 else dx * 2.0
	set_gaussian_wavepacket(measured_x, sigma, 0.0)
	return measured_x

func _apply_hamiltonian(f: PackedFloat32Array, out: PackedFloat32Array) -> void:
	var coeff: float = -(HBAR * HBAR) / (2.0 * mass * dx * dx)
	for i in range(grid_size):
		var left: float = f[i - 1] if i > 0 else 0.0
		var right: float = f[i + 1] if i < grid_size - 1 else 0.0
		var laplacian: float = left - 2.0 * f[i] + right
		out[i] = coeff * laplacian + potential[i] * f[i]

func step(dt: float) -> void:
	var h_u := PackedFloat32Array()
	h_u.resize(grid_size)
	_apply_hamiltonian(u, h_u)
	for i in range(grid_size):
		v[i] -= (dt / HBAR) * h_u[i]

	var h_v := PackedFloat32Array()
	h_v.resize(grid_size)
	_apply_hamiltonian(v, h_v)
	for i in range(grid_size):
		u[i] += (dt / HBAR) * h_v[i]

	time += dt
