extends Node

enum State { IDLE, PLAYING, CLEARING, BOSS_FIGHT, COMPLETE }

const WAVES_PER_LEVEL: int = 20
const LEVELS_PER_ANTE: int = 3

const MINI_BOSS_SCENE = preload("res://scenes/enemies/MiniBoss.tscn")
const BIG_BOSS_SCENE  = preload("res://scenes/enemies/BigBoss.tscn")

# Difficulty multipliers indexed by ante (0 = ante 1)
const HP_MULT:    Array[float] = [1.0, 1.5, 2.5]
const SPEED_MULT: Array[float] = [1.0, 1.2, 1.4]

var ante: int = 1
var level_in_ante: int = 1
var waves_spawned: int = 0
var active_enemies: int = 0
var state: State = State.IDLE

## Global enemy strength multiplier — scales all enemy HP, speed, and contact damage.
## 1.0 = normal. Raise to make all enemies tougher; lower to nerf them globally.
var enemy_strength: float = 1.0

func _ready() -> void:
	EventBus.enemy_spawned.connect(func(_id): active_enemies += 1)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.wave_spawned.connect(_on_wave_spawned)
	EventBus.game_over.connect(func(): state = State.IDLE)

func start_run() -> void:
	ante = 1
	level_in_ante = 1
	waves_spawned = 0
	active_enemies = 0
	state = State.PLAYING
	EventBus.level_started.emit(ante, level_in_ante)

func get_difficulty() -> Dictionary:
	var idx := clampi(ante - 1, 0, HP_MULT.size() - 1)
	return {
		"hp_mult":    HP_MULT[idx]    * enemy_strength,
		"speed_mult": SPEED_MULT[idx] * enemy_strength,
	}

func _on_wave_spawned(wave_index: int) -> void:
	waves_spawned = wave_index + 1
	if waves_spawned >= WAVES_PER_LEVEL and state == State.PLAYING:
		state = State.CLEARING
		EventBus.waves_exhausted.emit()
		if active_enemies <= 0:
			_start_boss_fight()

func _on_enemy_died(_id: String, _xp: int) -> void:
	active_enemies = maxi(active_enemies - 1, 0)
	if state == State.CLEARING and active_enemies <= 0:
		_start_boss_fight()
	elif state == State.BOSS_FIGHT and active_enemies <= 0:
		_complete_level()

func _start_boss_fight() -> void:
	state = State.BOSS_FIGHT
	active_enemies = 0  # reset so boss death triggers _complete_level
	var boss_scene: PackedScene = MINI_BOSS_SCENE if level_in_ante < LEVELS_PER_ANTE else BIG_BOSS_SCENE
	var boss := boss_scene.instantiate()
	var vp := get_viewport().get_visible_rect()
	boss.global_position = Vector2(vp.size.x + 100.0, vp.size.y * 0.5)
	var diff := get_difficulty()
	if "max_hp" in boss:
		boss.max_hp = int(boss.max_hp * diff["hp_mult"])
	if "speed" in boss:
		boss.speed = boss.speed * diff["speed_mult"]
	get_tree().root.add_child(boss)

func _complete_level() -> void:
	if state == State.COMPLETE:
		return
	state = State.COMPLETE
	GameManager.award_level_wage(ante, level_in_ante)
	EventBus.level_completed.emit(ante, level_in_ante)
	await EventBus.pilot_academy_closed
	_advance()

func debug_skip_level() -> void:
	match state:
		State.PLAYING, State.CLEARING:
			active_enemies = 0
			state = State.CLEARING
			_start_boss_fight()
		State.BOSS_FIGHT:
			active_enemies = 0
			_complete_level()

func _advance() -> void:
	level_in_ante += 1
	if level_in_ante > LEVELS_PER_ANTE:
		level_in_ante = 1
		ante += 1
		EventBus.ante_completed.emit(ante - 1)
	waves_spawned = 0
	active_enemies = 0
	state = State.PLAYING
	EventBus.level_started.emit(ante, level_in_ante)
