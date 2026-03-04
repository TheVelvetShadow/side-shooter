extends CharacterBody2D
class_name Player

const MAX_SLOTS: int = 6

@export var max_hp: int = 100
@export var max_shield: int = 50
@export var attack_multiplier: float = 1.0
@export var move_speed: float = 462.0
@export var fire_rate_mult: float = 1.2
@onready var ship: PlayerShip = $Ship

var armour: int = 0          # flat damage reduction per hit (from ship stat)
var weapon_bonus: int = 0    # flat bonus added to all weapon damage before pilot chain

var current_hp: int
var current_shield: int

var unlocked_slots: int = 2
var weapon_slots: Array = []    # size MAX_SLOTS, each null or weapon Dictionary
var slot_timers: Array[float] = []  # seconds until next shot per slot
var weapon_xp: Array[int] = []      # accumulated XP per slot

@onready var bullet_spawn: Marker2D = $BulletSpawn
@export var bullet_scene: PackedScene

func _ready() -> void:
	current_hp = max_hp
	current_shield = max_shield
	for i in MAX_SLOTS:
		weapon_slots.append(null)
		slot_timers.append(0.0)
		weapon_xp.append(0)
	add_to_group("player")
	EventBus.energy_collected.connect(_on_energy_collected)
	# Start with a basic weapon in slot 0
	equip_weapon(WeaponDB.get_weapon("ballistic", 1))

func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_firing(delta)
	move_and_slide()
	clamp_to_screen()

func _handle_movement() -> void:
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	velocity = dir.normalized() * move_speed if dir != Vector2.ZERO else Vector2.ZERO
	ship.set_movement_state(dir.y)
	
func _handle_firing(delta: float) -> void:
	if not Input.is_action_pressed("fire"):
		return
	for i in unlocked_slots:
		if weapon_slots[i] == null:
			continue
		slot_timers[i] -= delta
		if slot_timers[i] <= 0.0:
			_fire_from_slot(i)
			slot_timers[i] = weapon_slots[i]["fire_rate"] / (PilotManager.get_fire_rate_mult() * fire_rate_mult)

func _fire_from_slot(slot: int) -> void:
	if not bullet_scene:
		return
	var weapon: Dictionary = weapon_slots[slot]
	var bullet = bullet_scene.instantiate()
	var base_damage := int(weapon["damage"] * attack_multiplier) + weapon_bonus
	var weapon_type: String = weapon.get("category", weapon.get("type", ""))
	var chain := PilotManager.get_damage_chain(base_damage, weapon_type)
	bullet.damage = chain["final"]
	bullet.damage_chain = chain["steps"]
	bullet.bounce_damage_multiplier = PilotManager.get_bounce_multiplier()
	bullet.burn_pct      = weapon.get("burn_pct", 0.0)
	bullet.burn_duration = weapon.get("burn_duration", 0.0)
	bullet.aoe_radius    = weapon.get("aoe_radius", 0.0)
	bullet.homing          = weapon.get("homing", false)
	bullet.homing_strength = weapon.get("homing_strength", 2.5)
	bullet.split_count     = weapon.get("split_count", 0)
	bullet.split_spread    = weapon.get("split_spread", 45.0)
	bullet.split_child_damage = weapon.get("split_child_damage", -1)
	bullet.speed = move_speed * 2.0
	bullet.bullet_color = weapon["color"]
	bullet.weapon_slot = slot
	bullet.global_position = bullet_spawn.global_position
	get_tree().root.add_child(bullet)
	if GameManager.aiming_enabled:
		var crosshairs := get_tree().get_nodes_in_group("crosshair")
		if crosshairs.size() > 0:
			var to_target: Vector2 = (crosshairs[0] as Node2D).global_position - bullet_spawn.global_position
			if to_target.length() > 1.0:
				bullet.velocity = to_target.normalized() * bullet.speed
	else:
		bullet.velocity = Vector2.RIGHT * bullet.speed
	EventBus.bullet_fired.emit({"position": bullet_spawn.global_position})

func equip_weapon(weapon_data: Dictionary) -> void:
	# Fill first empty unlocked slot
	for i in unlocked_slots:
		if weapon_slots[i] == null:
			weapon_slots[i] = weapon_data
			weapon_xp[i] = 0
			slot_timers[i] = 0.0
			EventBus.weapon_equipped.emit(i, weapon_data)
			return
	# All slots full — replace the lowest-tier weapon if new one is stronger
	var weakest_slot := 0
	var weakest_tier: int = weapon_slots[0]["tier"]
	for i in range(1, unlocked_slots):
		if weapon_slots[i]["tier"] < weakest_tier:
			weakest_tier = weapon_slots[i]["tier"]
			weakest_slot = i
	if weapon_data["tier"] > weakest_tier:
		weapon_slots[weakest_slot] = weapon_data
		weapon_xp[weakest_slot] = 0
		slot_timers[weakest_slot] = 0.0
		EventBus.weapon_equipped.emit(weakest_slot, weapon_data)

func _on_energy_collected(amount: int, slot: int) -> void:
	# Track per-slot XP for future weapon merging; upgrade trigger is handled by GameManager
	if slot < 0 or slot >= unlocked_slots or weapon_slots[slot] == null:
		return
	weapon_xp[slot] += amount

func upgrade_weapon_choice(slot: int) -> void:
	var weapon: Dictionary = weapon_slots[slot]
	var tier: int = weapon["tier"]
	if tier >= 5:
		return
	weapon_slots[slot] = WeaponDB.get_weapon(weapon["type"], tier + 1)
	weapon_xp[slot] = 0
	EventBus.weapon_equipped.emit(slot, weapon_slots[slot])
	EventBus.weapon_tiered_up.emit(slot, weapon_slots[slot])
	EventBus.weapon_upgrade_chosen.emit(slot)

func unlock_slot() -> void:
	if unlocked_slots < MAX_SLOTS:
		unlocked_slots += 1
		EventBus.weapon_equipped.emit(unlocked_slots - 1, null)

func apply_ship(ship_data: Dictionary) -> void:
	max_hp        = int(ship_data.get("hp",           max_hp))
	move_speed    = float(ship_data.get("speed",      move_speed))
	armour        = int(ship_data.get("armour",       armour))
	weapon_bonus  = int(ship_data.get("weapon_bonus", weapon_bonus))
	unlocked_slots = int(ship_data.get("weapon_slots", unlocked_slots))
	current_hp    = max_hp
	current_shield = max_shield
	EventBus.player_hp_changed.emit(current_hp, max_hp)
	EventBus.player_shield_changed.emit(current_shield, max_shield)

func take_damage(amount: int) -> void:
	amount = maxi(amount - armour, 1)  # armour reduces but never below 1
	if current_shield > 0:
		var shield_absorbed := mini(current_shield, amount)
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
