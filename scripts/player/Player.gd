extends CharacterBody2D
class_name Player

@export var max_hp: int = 100
@export var max_shield: int = 50
@export var attack_multiplier: float = 1.0
@export var move_speed: float = 300.0
@export var fire_rate: float = 0.25

var current_hp: int
var current_shield: int
var can_fire: bool = true

var weapon_slots: Array = [null, null]
var active_slot: int = 0

@onready var fire_timer: Timer = $FireTimer
@onready var bullet_spawn: Marker2D = $BulletSpawn

@export var bullet_scene: PackedScene

func _ready() -> void:
	current_hp = max_hp
	current_shield = max_shield
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	_handle_movement()
	_handle_weapon_switch()
	_handle_firing()
	move_and_slide()
	clamp_to_screen()

func _handle_movement() -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	velocity = direction * move_speed

func _handle_weapon_switch() -> void:
	if Input.is_action_just_pressed("special"):
		active_slot = 1 - active_slot
		EventBus.weapon_slot_switched.emit(active_slot)

func _handle_firing() -> void:
	if Input.is_action_pressed("fire") and can_fire:
		fire()

func fire() -> void:
	if not bullet_scene:
		return
	can_fire = false
	var bullet = bullet_scene.instantiate()
	var weapon = weapon_slots[active_slot]
	if weapon:
		bullet.damage = int(weapon["damage"] * attack_multiplier)
		bullet.speed = weapon["bullet_speed"]
		bullet.bullet_color = weapon["color"]
		fire_timer.wait_time = weapon["fire_rate"]
	else:
		bullet.damage = int(10.0 * attack_multiplier)
		fire_timer.wait_time = fire_rate
	bullet.global_position = bullet_spawn.global_position
	get_tree().root.add_child(bullet)
	EventBus.bullet_fired.emit({"position": bullet_spawn.global_position})
	fire_timer.start()

func _on_fire_timer_timeout() -> void:
	can_fire = true

func equip_weapon(weapon_data: Dictionary) -> void:
	var type = weapon_data["type"]
	var tier = weapon_data["tier"]
	# Merge if same type + tier exists in a slot
	for i in 2:
		if weapon_slots[i] != null and weapon_slots[i]["type"] == type and weapon_slots[i]["tier"] == tier:
			if tier < 5:
				weapon_slots[i] = WeaponDB.get_weapon(type, tier + 1)
				EventBus.weapon_merged.emit(type, tier + 1)
				EventBus.weapon_equipped.emit(i, weapon_slots[i])
			return
	# Fill empty slot
	for i in 2:
		if weapon_slots[i] == null:
			weapon_slots[i] = weapon_data
			EventBus.weapon_equipped.emit(i, weapon_data)
			return
	# Both full — replace active slot
	weapon_slots[active_slot] = weapon_data
	EventBus.weapon_equipped.emit(active_slot, weapon_data)

func take_damage(amount: int) -> void:
	if current_shield > 0:
		var shield_absorbed: int = mini(current_shield, amount)
		current_shield -= shield_absorbed
		amount -= shield_absorbed
		EventBus.player_shield_changed.emit(current_shield, max_shield)
	if amount > 0:
		current_hp -= amount
		EventBus.player_hp_changed.emit(current_hp, max_hp)
		EventBus.player_damaged.emit(amount)
		if current_hp <= 0:
			die()

func heal(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)
	EventBus.player_hp_changed.emit(current_hp, max_hp)
	EventBus.player_healed.emit(amount)

func die() -> void:
	EventBus.player_died.emit()
	queue_free()

func apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"hp":
			max_hp += 20
			heal(20)
			EventBus.player_hp_changed.emit(current_hp, max_hp)
		"shield":
			max_shield += 15
			current_shield = max_shield
			EventBus.player_shield_changed.emit(current_shield, max_shield)
		"attack":
			attack_multiplier += 0.2
		"speed":
			move_speed += 30.0

func clamp_to_screen() -> void:
	var screen := get_viewport_rect().size
	global_position.x = clampf(global_position.x, 0, screen.x)
	global_position.y = clampf(global_position.y, 0, screen.y)
