extends GutTest

var Player = load("res://scripts/player/Player.gd")
var player: Player

func before_each() -> void:
	player = Player.new()
	player.max_hp = 100
	player.max_shield = 50
	player.current_hp = 100
	player.current_shield = 50
	add_child_autofree(player)

# --- HP tests ---
func test_player_starts_with_full_hp() -> void:
	assert_eq(player.current_hp, 100, "Player should start with full HP")

func test_player_starts_with_full_shield() -> void:
	assert_eq(player.current_shield, 50, "Player should start with full shield")

# --- Damage tests ---
func test_shield_absorbs_damage_first() -> void:
	player.take_damage(30)
	assert_eq(player.current_shield, 20, "Shield should absorb damage first")
	assert_eq(player.current_hp, 100, "HP should be untouched while shield active")

func test_damage_overflows_from_shield_to_hp() -> void:
	player.take_damage(80)
	assert_eq(player.current_shield, 0, "Shield should be depleted")
	assert_eq(player.current_hp, 70, "Remaining 30 damage should hit HP")

func test_full_damage_to_hp_when_no_shield() -> void:
	player.current_shield = 0
	player.take_damage(25)
	assert_eq(player.current_hp, 75, "All damage should go to HP when no shield")

# --- Healing tests ---
func test_heal_increases_hp() -> void:
	player.current_hp = 50
	player.heal(30)
	assert_eq(player.current_hp, 80, "HP should increase by heal amount")

func test_heal_cannot_exceed_max_hp() -> void:
	player.current_hp = 90
	player.heal(50)
	assert_eq(player.current_hp, 100, "HP cannot exceed max")

# --- Death test ---
func test_player_dies_at_zero_hp() -> void:
	watch_signals(EventBus)
	player.current_shield = 0
	player.take_damage(100)
	assert_signal_emitted(EventBus, "player_died", "player_died signal should fire at 0 HP")
