extends Node

## Persistent meta currency (Stars) + permanent upgrades between runs.
## Save: user://meta_progress.cfg — survives app restart; defaults if missing.

const SAVE_PATH := "user://meta_progress.cfg"
const SECTION := "meta"

signal changed

## Victory: base + bonus from remaining wall HP ratio (0..1).
const VICTORY_BASE := 15
const VICTORY_HP_BONUS_MAX := 10
## Defeat: consolation per wave reached (wave that was active when wall fell).
const DEFEAT_PER_WAVE := 3

enum UpgradeId { START_SCRAP, WALL_HP, TURRET_DMG, MAX_TURRETS }

## Per-level effect values.
const START_SCRAP_PER_LEVEL := 25
const WALL_HP_PER_LEVEL := 20
const TURRET_DMG_PER_LEVEL := 0.05
const MAX_TURRETS_PER_LEVEL := 1

## Caps (inclusive max level).
const CAPS := {
	UpgradeId.START_SCRAP: 4,
	UpgradeId.WALL_HP: 5,
	UpgradeId.TURRET_DMG: 5,
	UpgradeId.MAX_TURRETS: 1,
}

## Cost tables indexed by current level → cost to buy next.
const COSTS := {
	UpgradeId.START_SCRAP: [8, 12, 18, 28],
	UpgradeId.WALL_HP: [8, 12, 18, 25, 35],
	UpgradeId.TURRET_DMG: [10, 15, 22, 30, 40],
	UpgradeId.MAX_TURRETS: [40],
}

const LABELS := {
	UpgradeId.START_SCRAP: "Starting Scrap +25",
	UpgradeId.WALL_HP: "Wall Max HP +20",
	UpgradeId.TURRET_DMG: "Turret Damage +5%",
	UpgradeId.MAX_TURRETS: "+1 Max Turrets",
}

var stars: int = 0
var levels: Dictionary = {
	UpgradeId.START_SCRAP: 0,
	UpgradeId.WALL_HP: 0,
	UpgradeId.TURRET_DMG: 0,
	UpgradeId.MAX_TURRETS: 0,
}


func _ready() -> void:
	load_save()


func load_save() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		# Fresh install / missing file — keep defaults.
		return
	stars = int(cfg.get_value(SECTION, "stars", 0))
	for id in UpgradeId.values():
		var key := _level_key(id)
		levels[id] = clampi(int(cfg.get_value(SECTION, key, 0)), 0, int(CAPS[id]))


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "stars", stars)
	for id in UpgradeId.values():
		cfg.set_value(SECTION, _level_key(id), int(levels.get(id, 0)))
	cfg.save(SAVE_PATH)


func reset_meta() -> void:
	stars = 0
	for id in UpgradeId.values():
		levels[id] = 0
	save()
	changed.emit()


func add_stars(amount: int) -> void:
	if amount <= 0:
		return
	stars += amount
	save()
	changed.emit()


func calc_victory_stars(hp_ratio: float) -> int:
	var ratio := clampf(hp_ratio, 0.0, 1.0)
	return VICTORY_BASE + int(floor(ratio * float(VICTORY_HP_BONUS_MAX)))


func calc_defeat_stars(waves_reached: int) -> int:
	return maxi(0, waves_reached) * DEFEAT_PER_WAVE


func get_level(id: UpgradeId) -> int:
	return int(levels.get(id, 0))


func get_cap(id: UpgradeId) -> int:
	return int(CAPS[id])


func is_maxed(id: UpgradeId) -> bool:
	return get_level(id) >= get_cap(id)


func get_next_cost(id: UpgradeId) -> int:
	if is_maxed(id):
		return -1
	var table: Array = COSTS[id]
	var lvl := get_level(id)
	if lvl < 0 or lvl >= table.size():
		return -1
	return int(table[lvl])


func can_buy(id: UpgradeId) -> bool:
	var cost := get_next_cost(id)
	return cost > 0 and stars >= cost


func try_buy(id: UpgradeId) -> bool:
	if not can_buy(id):
		return false
	var cost := get_next_cost(id)
	stars -= cost
	levels[id] = get_level(id) + 1
	save()
	changed.emit()
	return true


func get_start_scrap_bonus() -> int:
	return get_level(UpgradeId.START_SCRAP) * START_SCRAP_PER_LEVEL


func get_wall_hp_bonus() -> int:
	return get_level(UpgradeId.WALL_HP) * WALL_HP_PER_LEVEL


func get_turret_damage_mult() -> float:
	return 1.0 + float(get_level(UpgradeId.TURRET_DMG)) * TURRET_DMG_PER_LEVEL


func get_max_turrets_bonus() -> int:
	return get_level(UpgradeId.MAX_TURRETS) * MAX_TURRETS_PER_LEVEL


func label_for(id: UpgradeId) -> String:
	return str(LABELS.get(id, "Upgrade"))


func effect_summary(id: UpgradeId) -> String:
	var lvl := get_level(id)
	match id:
		UpgradeId.START_SCRAP:
			return "+%d Scrap" % (lvl * START_SCRAP_PER_LEVEL)
		UpgradeId.WALL_HP:
			return "+%d HP" % (lvl * WALL_HP_PER_LEVEL)
		UpgradeId.TURRET_DMG:
			return "+%d%% dmg" % int(round(float(lvl) * TURRET_DMG_PER_LEVEL * 100.0))
		UpgradeId.MAX_TURRETS:
			return "+%d slot" % (lvl * MAX_TURRETS_PER_LEVEL)
	return ""


func _level_key(id: UpgradeId) -> String:
	match id:
		UpgradeId.START_SCRAP:
			return "lvl_start_scrap"
		UpgradeId.WALL_HP:
			return "lvl_wall_hp"
		UpgradeId.TURRET_DMG:
			return "lvl_turret_dmg"
		UpgradeId.MAX_TURRETS:
			return "lvl_max_turrets"
	return "lvl_unknown"
