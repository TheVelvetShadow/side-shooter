extends Node

# Player signals
signal player_died
signal player_damaged(amount: int)
signal player_healed(amount: int)
signal player_shield_changed(current: int, maximum: int)
signal player_hp_changed(current: int, maximum: int)

# Weapon signals
signal bullet_fired(bullet_data: Dictionary)
signal weapon_picked_up(weapon_id: String)
signal weapon_merged(weapon_id: String, new_tier: int)
signal weapon_equipped(slot: int, weapon_data: Dictionary)
signal weapon_slot_switched(active_slot: int)

# Enemy signals
signal enemy_died(enemy_id: String, xp_value: int)
signal enemy_spawned(enemy_id: String)

# XP / progression signals
signal xp_gained(amount: int)
signal run_xp_gained(amount: int)
signal ship_levelled_up(new_level: int)
signal upgrade_chosen(upgrade_id: String)

# Game state signals
signal level_started(level_number: int)
signal level_completed(level_number: int)
signal game_over()
signal run_completed()
