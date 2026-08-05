extends Node

## Persistent meta currency (Stars) + permanent upgrades between runs.
## Save: user://meta_progress.cfg — survives app restart; defaults if missing.

const SAVE_PATH := "user://meta_progress.cfg"
const SECTION := "meta"

signal changed

## Retire with wall alive: base + bonus from remaining wall HP ratio (0..1).
const VICTORY_BASE := 15
const VICTORY_HP_BONUS_MAX := 10
## Defeat / retire: Stars per wave reached.
const DEFEAT_PER_WAVE := 3
## Extra Stars per wave beyond 5 (long-run reward).
const ENDLESS_EXTRA_PER_WAVE := 2
## Build-cost discount per level (replaces obsolete +1 max turrets).
const BUILD_DISCOUNT_PER_LEVEL := 0.10

enum UpgradeId { START_SCRAP, WALL_HP, TURRET_DMG, MAX_TURRETS, ABILITY_CD }

## Per-level effect values.
const START_SCRAP_PER_LEVEL := 25
const WALL_HP_PER_LEVEL := 20
const TURRET_DMG_PER_LEVEL := 0.05
## Legacy enum name MAX_TURRETS → Build Cost −10% (save key unchanged).
const MAX_TURRETS_PER_LEVEL := 1
## Ability cooldown reduction per level (0.15 = −15%).
const ABILITY_CD_PER_LEVEL := 0.15

## Caps (inclusive max level).
const CAPS := {
	UpgradeId.START_SCRAP: 4,
	UpgradeId.WALL_HP: 5,
	UpgradeId.TURRET_DMG: 5,
	UpgradeId.MAX_TURRETS: 1,
	UpgradeId.ABILITY_CD: 2,
}

## Cost tables indexed by current level → cost to buy next.
const COSTS := {
	UpgradeId.START_SCRAP: [8, 12, 18, 28],
	UpgradeId.WALL_HP: [8, 12, 18, 25, 35],
	UpgradeId.TURRET_DMG: [10, 15, 22, 30, 40],
	UpgradeId.MAX_TURRETS: [40],
	UpgradeId.ABILITY_CD: [15, 25],
}

const LABELS := {
	UpgradeId.START_SCRAP: "Starting Scrap +25",
	UpgradeId.WALL_HP: "Wall Max HP +20",
	UpgradeId.TURRET_DMG: "Turret Damage +5%",
	UpgradeId.MAX_TURRETS: "Build Cost −10%",
	UpgradeId.ABILITY_CD: "Ability CD −15%",
}

var stars: int = 0
var levels: Dictionary = {
	UpgradeId.START_SCRAP: 0,
	UpgradeId.WALL_HP: 0,
	UpgradeId.TURRET_DMG: 0,
	UpgradeId.MAX_TURRETS: 0,
	UpgradeId.ABILITY_CD: 0,
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


func calc_endless_defeat_stars(waves_reached: int) -> int:
	## Defeat in endless: 3×wave + 2×max(0, wave−5). Difficulty mult applied by caller.
	var w := maxi(0, waves_reached)
	var base := w * DEFEAT_PER_WAVE
	var endless_extra := maxi(0, w - 5) * ENDLESS_EXTRA_PER_WAVE
	return base + endless_extra


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
	## Obsolete (unlimited placement). Kept for API compat; always 0 effect.
	return 0


## Place-cost multiplier (1.0 = full price, 0.9 at Build Cost −10%).
func get_build_cost_mult() -> float:
	var discount := float(get_level(UpgradeId.MAX_TURRETS)) * BUILD_DISCOUNT_PER_LEVEL
	return maxf(0.5, 1.0 - discount)


## Returns cooldown multiplier (1.0 = full CD, 0.7 = −30% at max).
func get_ability_cd_mult() -> float:
	var reduction := float(get_level(UpgradeId.ABILITY_CD)) * ABILITY_CD_PER_LEVEL
	return maxf(0.5, 1.0 - reduction)


## Unified run payout (defeat or retire). Long runs get extra after wave 5.
func calc_run_stars(waves_reached: int) -> int:
	return calc_endless_defeat_stars(waves_reached)


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
			return "−%d%% cost" % int(round(float(lvl) * BUILD_DISCOUNT_PER_LEVEL * 100.0))
		UpgradeId.ABILITY_CD:
			return "−%d%% CD" % int(round(float(lvl) * ABILITY_CD_PER_LEVEL * 100.0))
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
		UpgradeId.ABILITY_CD:
			return "lvl_ability_cd"
	return "lvl_unknown"
