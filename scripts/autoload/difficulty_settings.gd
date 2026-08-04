extends Node

## Run difficulty (Easy / Normal / Hard). Persist last pick across launches.
## Battle reads multipliers; meta upgrades stack on top.
## Save: user://difficulty.cfg — independent of MetaProgress reset.

const SAVE_PATH := "user://difficulty.cfg"
const SECTION := "settings"

signal changed

enum Difficulty { EASY, NORMAL, HARD }

const LABELS := {
	Difficulty.EASY: "Easy",
	Difficulty.NORMAL: "Normal",
	Difficulty.HARD: "Hard",
}

## Final multipliers (documented in docs/stage19.md).
const HP_MULT := {
	Difficulty.EASY: 0.85,
	Difficulty.NORMAL: 1.0,
	Difficulty.HARD: 1.25,
}
const SPEED_MULT := {
	Difficulty.EASY: 0.9,
	Difficulty.NORMAL: 1.0,
	Difficulty.HARD: 1.1,
}
const CONTACT_MULT := {
	Difficulty.EASY: 0.85,
	Difficulty.NORMAL: 1.0,
	Difficulty.HARD: 1.2,
}
const SCRAP_REWARD_MULT := {
	Difficulty.EASY: 1.1,
	Difficulty.NORMAL: 1.0,
	Difficulty.HARD: 0.9,
}
## Easy only: breathing room at run start (meta start-scrap stacks on top).
const START_SCRAP_BONUS := {
	Difficulty.EASY: 25,
	Difficulty.NORMAL: 0,
	Difficulty.HARD: 0,
}
const STARS_VICTORY_MULT := {
	Difficulty.EASY: 0.85,
	Difficulty.NORMAL: 1.0,
	Difficulty.HARD: 1.15,
}
const STARS_DEFEAT_MULT := {
	Difficulty.EASY: 0.85,
	Difficulty.NORMAL: 1.0,
	Difficulty.HARD: 1.1,
}

var current: Difficulty = Difficulty.NORMAL


func _ready() -> void:
	load_save()


func load_save() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		current = Difficulty.NORMAL
		return
	var raw := int(cfg.get_value(SECTION, "difficulty", int(Difficulty.NORMAL)))
	if raw < 0 or raw > int(Difficulty.HARD):
		current = Difficulty.NORMAL
	else:
		current = raw as Difficulty


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "difficulty", int(current))
	cfg.save(SAVE_PATH)


func set_difficulty(value: Difficulty) -> void:
	if current == value:
		return
	current = value
	save()
	changed.emit()


func label() -> String:
	return str(LABELS.get(current, "Normal"))


func get_enemy_hp_mult() -> float:
	return float(HP_MULT.get(current, 1.0))


func get_enemy_speed_mult() -> float:
	return float(SPEED_MULT.get(current, 1.0))


func get_contact_dmg_mult() -> float:
	return float(CONTACT_MULT.get(current, 1.0))


func get_scrap_reward_mult() -> float:
	return float(SCRAP_REWARD_MULT.get(current, 1.0))


func get_start_scrap_bonus() -> int:
	return int(START_SCRAP_BONUS.get(current, 0))


func scale_stars(base_amount: int, is_win: bool) -> int:
	if base_amount <= 0:
		return 0
	var mult := float(STARS_VICTORY_MULT.get(current, 1.0)) if is_win \
			else float(STARS_DEFEAT_MULT.get(current, 1.0))
	return maxi(1, int(floor(float(base_amount) * mult)))
