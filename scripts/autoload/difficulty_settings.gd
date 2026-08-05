extends Node

## Stage 27: difficulty select removed. Always baseline Normal (1.0 multipliers).
## Kept as a thin stub so wave_manager / battle call sites stay stable.

signal changed

enum Difficulty { EASY, NORMAL, HARD }

var current: Difficulty = Difficulty.NORMAL


func _ready() -> void:
	current = Difficulty.NORMAL


func load_save() -> void:
	current = Difficulty.NORMAL


func save() -> void:
	pass


func set_difficulty(_value: Difficulty) -> void:
	current = Difficulty.NORMAL
	changed.emit()


func label() -> String:
	return "Normal"


func get_enemy_hp_mult() -> float:
	return 1.0


func get_enemy_speed_mult() -> float:
	return 1.0


func get_contact_dmg_mult() -> float:
	return 1.0


func get_scrap_reward_mult() -> float:
	return 1.0


func get_start_scrap_bonus() -> int:
	return 0


func scale_stars(base_amount: int, _is_win: bool) -> int:
	return maxi(0, base_amount)
