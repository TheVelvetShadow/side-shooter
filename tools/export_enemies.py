"""
export_enemies.py — reads Enemies sheet from data/game_data.xlsx,
writes data/enemies.json keyed by enemy_id.

Run from repo root:
    python3 tools/export_enemies.py
"""

import json
import os
import openpyxl

XLSX_PATH = os.path.join(os.path.dirname(__file__), "..", "data", "game_data.xlsx")
JSON_PATH = os.path.join(os.path.dirname(__file__), "..", "data", "enemies.json")

# Column indices (0-based) from row 1 header
COL = {
    "enemy_id":              0,
    "first_ante":            1,
    "first_level":           2,
    "enemy_type":            3,
    "movement_type":         4,
    "wave_amplitude":        5,
    "wave_frequency":        6,
    "dart_interval":         7,
    "dart_speed_mult":       8,
    "spawn_behaviour":       9,
    "spawn_weight":         10,
    "spawn_amount":         11,
    "hp":                   12,
    # index 13 = "Base HP" — skip
    "contact_damage":       14,
    "entry_speed":          15,
    "speed":                16,
    "xp_value":             17,
    "gem_count":            18,
    "weapon_drop_chance":   19,
    "fire_interval":        20,
    "bullet_speed":         21,
    "shoot_pattern":        22,
    "enemy_bullet_strength":23,
    "hp_scale":             24,
    "damage_scale":         25,
    "armor_type":           26,
}

INT_FIELDS    = {"first_ante", "first_level", "spawn_weight", "spawn_amount",
                 "hp", "contact_damage", "xp_value", "gem_count",
                 "enemy_bullet_strength"}
FLOAT_FIELDS  = {"wave_amplitude", "wave_frequency", "dart_interval",
                 "dart_speed_mult", "entry_speed", "speed",
                 "weapon_drop_chance", "fire_interval", "bullet_speed",
                 "hp_scale", "damage_scale"}
STR_FIELDS    = {"enemy_id", "enemy_type", "movement_type",
                 "spawn_behaviour", "shoot_pattern", "armor_type"}


def _default(field: str):
    if field == "shoot_pattern":
        return "none"
    if field in INT_FIELDS:
        return 0
    if field in FLOAT_FIELDS:
        return 0.0
    return ""


def process_row(row) -> dict:
    result = {}
    for field, col_idx in COL.items():
        raw = row[col_idx]
        if raw is None:
            result[field] = _default(field)
        elif field in INT_FIELDS:
            result[field] = int(raw)
        elif field in FLOAT_FIELDS:
            result[field] = float(raw)
        else:
            result[field] = str(raw).strip()
    return result


def main():
    wb = openpyxl.load_workbook(XLSX_PATH, data_only=True)
    ws = wb["Enemies"]

    enemies = {}
    for row in ws.iter_rows(min_row=2, values_only=True):
        enemy_id = row[COL["enemy_id"]]
        # Skip blank rows and legend/notes rows
        if not enemy_id or not str(enemy_id).startswith("enemy") and not str(enemy_id).startswith("boss"):
            continue
        data = process_row(row)
        eid = data.pop("enemy_id")
        enemies[eid] = data

    out_path = os.path.normpath(JSON_PATH)
    with open(out_path, "w") as f:
        json.dump(enemies, f, indent=2)

    print(f"Wrote {len(enemies)} enemies to {out_path}")
    for eid, d in enemies.items():
        print(f"  {eid}: {d['enemy_type']} / {d['movement_type']} / spawn={d['spawn_behaviour']}")


if __name__ == "__main__":
    main()
