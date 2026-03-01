extends Node

enum State { IDLE, PLAYING, CLEARING, COMPLETE }

const WAVES_PER_LEVEL: int = 4
const LEVELS_PER_ANTE: int = 3

# Difficulty multipliers indexed by ante (0 = ante 1)
const HP_MULT:    Array[float] = [1.0, 1.5, 2.5]
const SPEED_MULT: Array[float] = [1.0, 1.2, 1.4]

var ante: int = 1
var level_in_ante: int = 1
var waves_spawned: int = 0
var active_enemies: int = 0
var state: State = State.IDLE

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
	return {"hp_mult": HP_MULT[idx], "speed_mult": SPEED_MULT[idx]}

func _on_wave_spawned(wave_index: int) -> void:
	waves_spawned = wave_index + 1
	if waves_spawned >= WAVES_PER_LEVEL and state == State.PLAYING:
		state = State.CLEARING
		EventBus.waves_exhausted.emit()
		if active_enemies <= 0:
			_complete_level()

func _on_enemy_died(_id: String, _xp: int) -> void:
	active_enemies = maxi(active_enemies - 1, 0)
	if state == State.CLEARING and active_enemies <= 0:
		_complete_level()

func _complete_level() -> void:
	if state == State.COMPLETE:
		return
	state = State.COMPLETE
	EventBus.level_completed.emit(ante, level_in_ante)
	# Phase C will replace this delay with the Shop scene
	await get_tree().create_timer(3.0).timeout
	_advance()

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
