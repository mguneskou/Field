class_name TestQuantumWave2D
extends TestCase
## Note: test_double_slit_produces_interference_fringes runs ~2200 steps
## of a 100x60 2D grid, which takes on the order of a minute headless —
## by far the slowest test in the suite. That cost buys something no
## faster test could: actual proof that path-difference interference
## emerges from the real wave equation, not an assumption baked into the
## test setup.

func test_double_slit_produces_interference_fringes() -> void:
	var wave := QuantumWave2D.new(100, 60, 1.0, 1.0)
	wave.set_free_space()
	wave.set_double_slit(45, 4, [21, 39], 5.0, 8.0)
	wave.set_gaussian_wavepacket(15.0, 30.0, 6.0, 16.0, 0.5, 0.0)

	var dt := 0.05
	for i in range(2200):
		wave.step(dt)

	assert_almost_eq(wave.total_probability(), 1.0, 0.05,
		"probability should stay ~conserved through diffraction and interference")

	var profile := wave.probability_profile_at_column(55)
	var peak_count := _count_significant_local_maxima(profile)
	assert_true(peak_count >= 3,
		"a genuine two-slit interference pattern should show multiple fringes (found %d), not just the two slits' geometric shadows" % peak_count)

func test_single_slit_does_not_produce_multiple_fringes() -> void:
	# Control case: block one of the two slits. A single opening produces
	# a diffraction envelope (one central lobe, maybe faint side lobes)
	# but not the same multi-fringe oscillation two coherent slits give —
	# confirms the double-slit result above is really about having TWO
	# slits, not an artifact of the barrier/geometry in general.
	var wave := QuantumWave2D.new(100, 60, 1.0, 1.0)
	wave.set_free_space()
	wave.set_double_slit(45, 4, [30], 5.0, 8.0) # one slit, centered
	wave.set_gaussian_wavepacket(15.0, 30.0, 6.0, 16.0, 0.5, 0.0)

	var dt := 0.05
	for i in range(2200):
		wave.step(dt)

	var profile := wave.probability_profile_at_column(55)
	var peak_count := _count_significant_local_maxima(profile)
	assert_true(peak_count <= 2,
		"a single slit should not produce the multi-fringe pattern two coherent slits do (found %d peaks)" % peak_count)

## Counts local maxima that dip to less than 70% of the smaller
## neighboring peak before rising again — filters out numerical-noise
## wiggles so this measures real fringes, not grid jitter.
func _count_significant_local_maxima(profile: PackedFloat32Array) -> int:
	var maxima: Array[int] = []
	for i in range(1, profile.size() - 1):
		if profile[i] > profile[i - 1] and profile[i] >= profile[i + 1] and profile[i] > 0.00002:
			maxima.append(i)

	var significant := 0
	var last_accepted_value := -1.0
	for i in range(maxima.size()):
		var value: float = profile[maxima[i]]
		if last_accepted_value < 0.0:
			significant += 1
			last_accepted_value = value
			continue
		# Find the minimum between this peak and the last accepted one.
		var lo: int = maxima[i - 1] if i > 0 else 0
		var hi: int = maxima[i]
		var dip := value
		for j in range(lo, hi + 1):
			dip = min(dip, profile[j])
		if dip < min(value, last_accepted_value) * 0.7:
			significant += 1
			last_accepted_value = value
	return significant
