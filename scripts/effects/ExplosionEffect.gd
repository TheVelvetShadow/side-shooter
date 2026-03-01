extends Node2D
class_name ExplosionEffect

# Spawned by Bullet._aoe_explode(). Expanding ring + inner glow, then frees itself.

var radius: float = 100.0
var explosion_color: Color = Color(1.0, 0.55, 0.1, 1.0)

var _t: float = 0.0
const DURATION := 0.35

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= DURATION:
		queue_free()

func _draw() -> void:
	var p := minf(_t / DURATION, 1.0)
	var r := radius * p
	var a := 1.0 - p
	var c := explosion_color
	# Inner fill glow
	draw_circle(Vector2.ZERO, r, Color(c.r, c.g, c.b, a * 0.20))
	# Bright ring
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(c.r, c.g, c.b, a), 4.0)
	# Outer soft ring
	draw_arc(Vector2.ZERO, r * 1.15, 0.0, TAU, 48, Color(c.r, c.g, c.b, a * 0.4), 2.0)
