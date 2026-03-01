extends Node
class_name BurnComponent

# Attached dynamically to any enemy hit by a burning weapon.
# Ticks damage every TICK_INTERVAL seconds for the burn duration.
# Re-applying burn refreshes the timer rather than stacking.

const TICK_INTERVAL := 0.5

var _damage_per_tick: int = 0
var _ticks_remaining:  int = 0
var _timer:            float = 0.0

# ── Static helper — call from Bullet or any other source ─────────────────
static func apply_to(target: Node, hit_damage: int, burn_pct: float, duration: float) -> void:
	var total_burn := maxi(1, int(hit_damage * burn_pct))
	var burn := target.get_node_or_null("BurnComponent") as BurnComponent
	if burn == null:
		burn = BurnComponent.new()
		burn.name = "BurnComponent"
		target.add_child(burn)
	burn.start(total_burn, duration)

# ── Instance methods ──────────────────────────────────────────────────────
func start(total_damage: int, duration: float) -> void:
	var ticks := maxi(1, int(duration / TICK_INTERVAL))
	_damage_per_tick  = maxi(1, total_damage / ticks)
	_ticks_remaining  = ticks
	_timer            = 0.0
	_set_burning_tint(true)

func _process(delta: float) -> void:
	if _ticks_remaining <= 0:
		return
	_timer += delta
	if _timer >= TICK_INTERVAL:
		_timer -= TICK_INTERVAL
		_ticks_remaining -= 1
		var parent := get_parent()
		if is_instance_valid(parent) and parent.has_method("take_damage"):
			parent.take_damage(_damage_per_tick)
		if _ticks_remaining <= 0:
			_set_burning_tint(false)

func _set_burning_tint(burning: bool) -> void:
	var parent := get_parent()
	if is_instance_valid(parent) and parent is Node2D:
		(parent as Node2D).modulate = Color(1.0, 0.45, 0.1, 1.0) if burning else Color.WHITE
