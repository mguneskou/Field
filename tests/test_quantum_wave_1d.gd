class_name TestQuantumWave1D
extends TestCase

func test_normalization_is_conserved_over_time() -> void:
	var wave := QuantumWave1D.new(400, 1.0, 1.0)
	wave.set_free_space()
	wave.set_gaussian_wavepacket(100.0, 10.0, 1.0)
	var before := wave.total_probability()
	for i in range(400):
		wave.step(0.02)
	var after := wave.total_probability()
	assert_almost_eq(before, 1.0, 0.01, "a freshly normalized wavepacket should start with total probability 1")
	assert_almost_eq(after, before, 0.02, "total probability (norm) should stay ~conserved under unitary evolution")

func test_free_particle_group_velocity_matches_hbar_k_over_m() -> void:
	# k0*dx must be small for the grid's dispersion relation to match the
	# continuum formula hbar*k/m closely (a discretized Hamiltonian's true
	# dispersion is v_g = (hbar/m/dx)*sin(k*dx); it only reduces to hbar*k/m
	# in the small-k*dx limit, same as any lattice model). k0=0.3 with
	# dx=1 keeps that discretization error under ~1.5%.
	var mass := 1.0
	var k0 := 0.3
	var wave := QuantumWave1D.new(600, 1.0, mass)
	wave.set_free_space()
	wave.set_gaussian_wavepacket(150.0, 12.0, k0)
	var x_start := wave.expectation_position()
	var steps := 400
	var dt := 0.02
	for i in range(steps):
		wave.step(dt)
	var x_end := wave.expectation_position()
	var measured_velocity: float = (x_end - x_start) / (steps * dt)
	var expected_velocity: float = (QuantumWave1D.HBAR * k0) / mass
	assert_almost_eq(measured_velocity, expected_velocity, expected_velocity * 0.1,
		"a free wavepacket's <x> should advance at the de Broglie group velocity hbar*k/m")

func test_wavepacket_disperses_over_time() -> void:
	# Quantum dispersion: a localized packet's spatial spread grows over
	# time even with zero potential, because it's a superposition of
	# different momenta each moving at their own velocity. A classical
	# free particle under no force has no analogous spreading.
	var wave := QuantumWave1D.new(500, 1.0, 1.0)
	wave.set_free_space()
	wave.set_gaussian_wavepacket(150.0, 5.0, 0.0)
	var variance_before := wave.position_variance()
	for i in range(800):
		wave.step(0.05)
	var variance_after := wave.position_variance()
	assert_true(variance_after > variance_before * 1.3,
		"a free wavepacket's position variance should grow noticeably over time (dispersion)")

func test_tunneling_through_classically_forbidden_barrier() -> void:
	# Give the packet an average kinetic energy well below the barrier
	# height. Classically, transmission would be exactly zero. Quantum
	# mechanically, some probability leaks through anyway.
	var mass := 1.0
	var k0 := 0.5
	var kinetic_energy: float = (QuantumWave1D.HBAR * QuantumWave1D.HBAR * k0 * k0) / (2.0 * mass)
	var barrier_height: float = kinetic_energy * 3.0 # comfortably classically forbidden, but thin enough to measure

	var wave := QuantumWave1D.new(300, 1.0, mass)
	wave.set_free_space()
	var barrier_start := 150
	var barrier_end := 153
	wave.set_barrier(barrier_start, barrier_end, barrier_height)
	wave.set_gaussian_wavepacket(80.0, 10.0, k0)

	for i in range(3000):
		wave.step(0.05)

	var transmitted := wave.probability_beyond(barrier_end)
	assert_true(transmitted > 0.001,
		"some probability should tunnel through a classically forbidden barrier")
	assert_true(transmitted < 0.5,
		"a tall barrier should still block most of the packet — this checks tunneling, not a barrier that's basically absent")

func test_measurement_collapses_wavefunction_near_sampled_position() -> void:
	var wave := QuantumWave1D.new(400, 1.0, 1.0)
	wave.set_free_space()
	wave.set_gaussian_wavepacket(200.0, 5.0, 0.0)

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var measured := wave.measure_position(rng)

	assert_true(measured > 150.0 and measured < 250.0,
		"the measured position should fall within the original wavepacket's support")
	assert_almost_eq(wave.total_probability(), 1.0, 0.01,
		"the collapsed wavefunction should still be normalized")

	# After collapse, probability should be concentrated near the measured point.
	var near_probability := 0.0
	var lo: int = max(int(measured) - 15, 0)
	var hi: int = min(int(measured) + 15, wave.grid_size)
	for i in range(lo, hi):
		near_probability += wave.probability_density(i) * wave.dx
	assert_true(near_probability > 0.9,
		"after collapse, almost all probability should be concentrated near the measured position")

func test_measurement_outcomes_follow_probability_density_statistically() -> void:
	# Repeat measurement on an identically-prepared, strongly asymmetric
	# distribution many times and confirm the outcomes actually track
	# |psi|^2 rather than, say, always returning the same point or being
	# uniformly random across the grid.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var count_left := 0
	var count_right := 0
	var trials := 200
	for t in range(trials):
		var wave := QuantumWave1D.new(200, 1.0, 1.0)
		wave.set_free_space()
		# Two separated bumps with directly-specified relative probability
		# density (u = sqrt(density), v = 0), roughly an 80/20 split.
		for i in range(wave.grid_size):
			var x: float = i * wave.dx
			var left_density: float = 0.8 * exp(-pow(x - 50.0, 2.0) / (2.0 * 36.0))
			var right_density: float = 0.2 * exp(-pow(x - 150.0, 2.0) / (2.0 * 36.0))
			wave.u[i] = sqrt(left_density + right_density)
			wave.v[i] = 0.0
		wave.normalize()
		var measured := wave.measure_position(rng)
		if measured < 100.0:
			count_left += 1
		else:
			count_right += 1
	var left_fraction: float = float(count_left) / float(trials)
	assert_true(left_fraction > 0.6 and left_fraction < 0.95,
		"measurement outcomes should statistically favor the higher-probability region without being deterministic")
