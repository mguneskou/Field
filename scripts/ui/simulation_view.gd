class_name SimulationView
extends Node2D
## Pure renderer: reads LevelManager/PhysicsWorld state and draws it.
## Never mutates simulation state. Redraws every frame — particle counts
## in this game stay small, so this is cheap and keeps the code simple.

var level_manager: LevelManager
var current_level: LevelDefinition

func setup(manager: LevelManager) -> void:
	level_manager = manager
	level_manager.level_loaded.connect(_on_level_loaded)
	set_process(true)

func _on_level_loaded(level: LevelDefinition) -> void:
	current_level = level
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if current_level == null or level_manager == null or level_manager.world == null:
		return
	_draw_electric_field()
	_draw_magnetic_field()
	_draw_obstacles()
	_draw_targets()
	_draw_particles()

func _draw_electric_field() -> void:
	var e := level_manager.world.electric_field
	if e.strength <= 0.01:
		return
	var spacing := 110.0
	var ratio: float = clamp(e.strength / max(current_level.field_strength_max, 1.0), 0.0, 1.0)
	var arrow_len: float = lerp(10.0, 26.0, ratio)
	var color := Color(0.35, 0.78, 1.0, 0.35)

	var x := spacing / 2.0
	while x < current_level.world_size.x:
		var y := spacing / 2.0
		while y < current_level.world_size.y:
			_draw_arrow(Vector2(x, y), e.direction, arrow_len, color)
			y += spacing
		x += spacing

func _draw_arrow(origin: Vector2, dir: Vector2, length: float, color: Color) -> void:
	var tip := origin + dir * length
	draw_line(origin, tip, color, 1.5)
	var perp := dir.orthogonal()
	var a := tip - dir * 5.0 + perp * 3.0
	var b := tip - dir * 5.0 - perp * 3.0
	draw_colored_polygon(PackedVector2Array([tip, a, b]), color)

func _draw_magnetic_field() -> void:
	var b := level_manager.world.magnetic_field.strength
	if abs(b) < 0.01:
		return
	var spacing := 160.0
	var color := Color(1.0, 0.7, 0.3, 0.35)

	var x := spacing
	while x < current_level.world_size.x:
		var y := spacing
		while y < current_level.world_size.y:
			if b > 0.0:
				draw_arc(Vector2(x, y), 6.0, 0, TAU, 14, color, 1.0)
				draw_circle(Vector2(x, y), 1.6, color)
			else:
				draw_line(Vector2(x - 5, y - 5), Vector2(x + 5, y + 5), color, 1.0)
				draw_line(Vector2(x - 5, y + 5), Vector2(x + 5, y - 5), color, 1.0)
			y += spacing
		x += spacing

func _draw_obstacles() -> void:
	for o in current_level.obstacles:
		draw_circle(o.position, o.radius, Color(0.9, 0.25, 0.25, 0.22))
		draw_arc(o.position, o.radius, 0, TAU, 32, Color(0.95, 0.35, 0.35, 0.6), 2.0)

func _draw_targets() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var pulse: float = 0.5 + 0.5 * sin(t * 2.0)
	for target in current_level.targets:
		draw_arc(target.position, target.radius, 0, TAU, 40, Color(0.35, 1.0, 0.55, 0.4 + 0.3 * pulse), 2.0)
		draw_circle(target.position, max(target.radius * 0.12, 2.0), Color(0.35, 1.0, 0.55, 0.85))

func _draw_particles() -> void:
	for p in level_manager.world.particles:
		_draw_trail(p)
		_draw_particle_body(p)

func _draw_trail(p: Particle) -> void:
	if p.trail.size() < 2:
		return
	for i in range(1, p.trail.size()):
		var a: float = float(i) / float(p.trail.size())
		var col := p.color
		col.a = a * 0.35
		draw_line(p.trail[i - 1], p.trail[i], col, 2.0)

func _draw_particle_body(p: Particle) -> void:
	for i in range(3, 0, -1):
		var glow_r: float = p.radius * (1.0 + float(i) * 0.9)
		var a: float = 0.05 * float(4 - i)
		draw_circle(p.position, glow_r, Color(p.color.r, p.color.g, p.color.b, a))

	if p.charge > 0.0:
		draw_circle(p.position, p.radius, p.color)
	elif p.charge < 0.0:
		draw_arc(p.position, p.radius, 0, TAU, 24, p.color, 2.5)
		draw_circle(p.position, p.radius * 0.25, p.color)
	else:
		draw_circle(p.position, p.radius * 0.7, p.color)
