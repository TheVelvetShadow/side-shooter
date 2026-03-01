extends Node

# Player signals
signal player_died
signal player_damaged(amount: int)
signal player_healed(amount: int)
signal player_shield_changed(current: int, maximum: int)
signal player_hp_changed(current: int, maximum: int)

# Weapon signals
signal bullet_fired(bullet_data: Dictionary)
signal bullet_bounced(bullet: Bullet, bounce_number: int)
signal weapon_picked_up(weapon_id: String)
signal weapon_equipped(slot: int, weapon_data: Dictionary)
signal weapon_tiered_up(slot: int, weapon_data: Dictionary)
signal weapon_xp_gained(slot: int, amount: int)
signal weapon_xp_updated(slot: int, current_xp: int, max_xp: int)

# Enemy signals
signal enemy_died(enemy_id: String, xp_value: int)
signal enemy_spawned(enemy_id: String)

# XP / progression signals
signal xp_gained(amount: int)
signal run_xp_gained(amount: int)
signal ship_levelled_up(new_level: int)
signal upgrade_chosen(upgrade_id: String)

# Game state signals
signal level_started(ante: int, level_in_ante: int)
signal level_completed(ante: int, level_in_ante: int)
signal ante_completed(ante: int)
signal wave_spawned(wave_index: int)
signal waves_exhausted()
signal game_over()
signal run_completed()
