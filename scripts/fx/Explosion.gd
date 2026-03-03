extends Node2D

## Self-contained explosion effect. Set max_radius before add_child().
## Spawns particle sparks and draws an expanding ring, then frees itself.

var max_radius: float = 50.0

const _DURATION := 0.45

var _time:   float = 0.0
var _radius: float = 0.0
var _alpha:  float = 1.0


func _ready() -> void:
	z_index = 10
	_spawn_particles()


func _process(delta: float) -> void:
	_time += delta
	var t := minf(_time / _DURATION, 1.0)
	_radius = max_radius * t
	_alpha  = 1.0 - t
	queue_redraw()
	if _time >= _DURATION:
		queue_free()


func _draw() -> void:
	if _alpha <= 0.01:
		return
	# Outer expanding ring
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 32,
			Color(1.0, 0.55, 0.1, _alpha), 3.0)
	# Inner ring
	draw_arc(Vector2.ZERO, _radius * 0.45, 0.0, TAU, 24,
			Color(1.0, 0.85, 0.4, _alpha * 0.6), 2.0)
	# Centre flash — only in the first third of the animation
	if _time < _DURATION * 0.33:
		var flash_r := maxf(_radius * 0.18, 5.0)
		draw_circle(Vector2.ZERO, flash_r,
				Color(1.0, 1.0, 0.85, _alpha * 0.85))


func _spawn_particles() -> void:
	var p := CPUParticles2D.new()
	p.emitting              = true
	p.one_shot              = true
	p.explosiveness         = 0.95
	p.amount                = 18
	p.lifetime              = 0.6
	p.direction             = Vector2.UP
	p.spread                = 180.0
	p.gravity               = Vector2(0.0, 60.0)
	p.initial_velocity_min  = 30.0
	p.initial_velocity_max  = max_radius * 2.8
	p.color                 = Color(1.0, 0.6, 0.15)
	p.scale_amount_min      = 2.0
	p.scale_amount_max      = 5.0
	add_child(p)
