class_name QuantumWave2D
extends RefCounted
## The 2D generalization of QuantumWave1D — same real Schrödinger
## equation, same leapfrog (Visscher) integration scheme, same hard-wall
## boundaries, just a 2D grid with a 5-point-stencil Laplacian. Exists
## specifically because double-slit interference is fundamentally a 2D
## (or 3D) phenomenon: it's about the path-length difference between two
## slits reaching a point off-axis, which a 1D grid has no room to
## represent.

const HBAR: float = 1.0

var width: int
var height: int
var dx: float
var mass: float
var potential: PackedFloat32Array # flattened, index = y*width + x
var u: PackedFloat32Array # Re(psi)
var v: PackedFloat32Array # Im(psi)
var time: float = 0.0

func _init(p_width: int = 160, p_height: int = 100, p_dx: float = 1.0, p_mass: float = 1.0) -> void:
	width = p_width
	height = p_height
	dx = p_dx
	mass = p_mass
	var n := width * height
	potential = PackedFloat32Array()
	potential.resize(n)
	u = PackedFloat32Array()
	u.resize(n)
	v = PackedFloat32Array()
	v.resize(n)

func _idx(x: int, y: int) -> int:
	return y * width + x

func set_gaussian_wavepacket(x0: float, y0: float, sigma_x: float, sigma_y: float, kx0: float, ky0: float) -> void:
	for y in range(height):
		for x in range(width):
			var envelope: float = exp(-pow(x - x0, 2.0) / (4.0 * sigma_x * sigma_x) - pow(y - y0, 2.0) / (4.0 * sigma_y * sigma_y))
			var phase: float = kx0 * x + ky0 * y
			var i := _idx(x, y)
			u[i] = envelope * cos(phase)
			v[i] = envelope * sin(phase)
	time = 0.0
	normalize()

func set_free_space() -> void:
	potential.fill(0.0)

## A vertical wall at x in [wall_x, wall_x+thickness), opaque (height
## `wall_height`) everywhere except within each (center_y, slit_width)
## opening in `slits`, where the potential is left at 0.
func set_double_slit(wall_x: int, thickness: int, slits: Array, slit_width: float, wall_height: float) -> void:
	for x in range(wall_x, min(wall_x + thickness, width)):
		for y in range(height):
			var blocked := true
			for center_y in slits:
				if abs(y - center_y) <= slit_width / 2.0:
					blocked = false
					break
			if blocked:
				potential[_idx(x, y)] = wall_height

func probability_density(x: int, y: int) -> float:
	var i := _idx(x, y)
	return u[i] * u[i] + v[i] * v[i]

func total_probability() -> float:
	var total := 0.0
	var cell_area: float = dx * dx
	for i in range(u.size()):
		total += (u[i] * u[i] + v[i] * v[i]) * cell_area
	return total

func normalize() -> void:
	var total := total_probability()
	if total <= 0.0000001:
		return
	var scale: float = 1.0 / sqrt(total)
	for i in range(u.size()):
		u[i] *= scale
		v[i] *= scale

## Probability density profile along a vertical line at column x —
## exactly "what would light up on a screen placed there," which is what
## you compare against a photographic double-slit interference pattern.
func probability_profile_at_column(x: int) -> PackedFloat32Array:
	var profile := PackedFloat32Array()
	profile.resize(height)
	for y in range(height):
		profile[y] = probability_density(x, y)
	return profile

func _apply_hamiltonian(f: PackedFloat32Array, out: PackedFloat32Array) -> void:
	var coeff: float = -(HBAR * HBAR) / (2.0 * mass * dx * dx)
	for y in range(height):
		for x in range(width):
			var i := _idx(x, y)
			var left: float = f[_idx(x - 1, y)] if x > 0 else 0.0
			var right: float = f[_idx(x + 1, y)] if x < width - 1 else 0.0
			var down: float = f[_idx(x, y - 1)] if y > 0 else 0.0
			var up: float = f[_idx(x, y + 1)] if y < height - 1 else 0.0
			var laplacian: float = left + right + up + down - 4.0 * f[i]
			out[i] = coeff * laplacian + potential[i] * f[i]

func step(dt: float) -> void:
	var h_u := PackedFloat32Array()
	h_u.resize(u.size())
	_apply_hamiltonian(u, h_u)
	for i in range(v.size()):
		v[i] -= (dt / HBAR) * h_u[i]

	var h_v := PackedFloat32Array()
	h_v.resize(v.size())
	_apply_hamiltonian(v, h_v)
	for i in range(u.size()):
		u[i] += (dt / HBAR) * h_v[i]

	time += dt
