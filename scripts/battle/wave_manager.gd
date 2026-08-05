extends Node

signal wave_changed(current_wave: int, total_waves: int)
signal status_changed(text: String)
signal enemy_killed(scrap_amount: int)
signal between_waves

## Truly infinite run from wave 1. total_waves always 0 (HUD shows "Wave N").
## Scaling (documented in docs/stage24.md):
##   count   = clamp(3 + floor((w-1) * 1.35), 3, 48)
##   hp_mult = 1 + 0.055 * (w-1)          (soft early, keeps climbing)
##   interval= max(0.28, 1.15 - 0.045*(w-1))
##   mix: runners from w2, brutes from w4; chances rise with wave.

@export var pause_between_waves: float = 2.0
@export var spawn_x_spread: float = 2.0
@export var base_count: int = 3
@export var count_per_wave: float = 1.35
@export var max_count: int = 48
@export var base_interval: float = 1.15
@export var interval_decay: float = 0.045
@export var min_interval: float = 0.28
@export var hp_per_wave: float = 0.055

var _enemy_scenes: Dictionary = {}
var _wall: Node3D
var _spawn_point: Marker3D
var _spawn_parent: Node3D

var _active: bool = false
var _spawning_done: bool = false
var _current_wave: int = 0


func setup(
	spawn_parent: Node3D,
	wall: Node3D,
	spawn_point: Marker3D,
	enemy_scenes: Dictionary
) -> void:
	_spawn_parent = spawn_parent
	_wall = wall
	_spawn_point = spawn_point
	_enemy_scenes = enemy_scenes


func start_waves() -> void:
	_active = true
	_spawning_done = false
	_current_wave = 0
	_run_infinite()


## Kept for API compat; redirects into the same infinite loop.
func start_endless(from_wave: int = 1) -> void:
	_active = true
	_spawning_done = false
	_current_wave = maxi(0, from_wave - 1)
	_run_infinite()


func stop_waves() -> void:
	_active = false


func is_spawning_done() -> bool:
	return _spawning_done


func is_endless() -> bool:
	return true


func get_current_wave_number() -> int:
	return _current_wave


func _run_infinite() -> void:
	while _active:
		_current_wave += 1
		_spawning_done = false

		var hp_mult := _hp_mult_for(_current_wave)
		var count := _count_for(_current_wave)
		var interval := _interval_for(_current_wave)
		var recipe := _build_recipe(count, _current_wave)

		# total_waves = 0 → HUD "Wave N" (no campaign fraction).
		wave_changed.emit(_current_wave, 0)
		status_changed.emit("Wave %d" % _current_wave)

		for type_key in recipe:
			if not _active:
				return
			_spawn_enemy(str(type_key), hp_mult)
			await get_tree().create_timer(interval).timeout

		if not _active:
			return

		_spawning_done = true
		while _active and not get_tree().get_nodes_in_group("zombies").is_empty():
			await get_tree().create_timer(0.25).timeout
		if not _active:
			return

		between_waves.emit()
		status_changed.emit("Wave %d — next..." % _current_wave)
		await get_tree().create_timer(pause_between_waves).timeout


func _count_for(wave: int) -> int:
	var n := base_count + int(floor(float(maxi(0, wave - 1)) * count_per_wave))
	return clampi(n, 3, max_count)


func _interval_for(wave: int) -> float:
	return maxf(min_interval, base_interval - interval_decay * float(maxi(0, wave - 1)))


func _hp_mult_for(wave: int) -> float:
	return 1.0 + hp_per_wave * float(maxi(0, wave - 1))


func _build_recipe(count: int, wave: int) -> Array:
	var recipe: Array = []
	var n := maxi(3, count)
	var depth := maxi(0, wave - 1)

	# Teaching curve: wave 1 basics only; runners from 2; brutes from 4.
	for i in n:
		if wave <= 1:
			recipe.append("basic")
			continue
		var roll := randf()
		var brute_chance := 0.0
		var runner_chance := 0.0
		if wave >= 4:
			brute_chance = clampf(0.06 + 0.025 * float(depth - 3), 0.06, 0.30)
		if wave >= 2:
			runner_chance = clampf(0.22 + 0.018 * float(depth), 0.22, 0.48)
		if roll < brute_chance:
			recipe.append("brute")
		elif roll < brute_chance + runner_chance:
			recipe.append("runner")
		else:
			recipe.append("basic")

	if wave >= 4 and not recipe.has("brute"):
		recipe[n - 1] = "brute"
	if wave == 2 and not recipe.has("runner"):
		recipe[mini(1, n - 1)] = "runner"
	return recipe


func _spawn_enemy(type_key: String, hp_mult: float = 1.0) -> void:
	if not _enemy_scenes.has(type_key):
		push_error("WaveManager: unknown enemy type '%s'" % type_key)
		return
	if _spawn_parent == null:
		push_error("WaveManager: missing spawn parent")
		return

	var scene: PackedScene = _enemy_scenes[type_key]
	if scene == null:
		push_error("WaveManager: null scene for type '%s'" % type_key)
		return

	var enemy: Node3D = scene.instantiate()
	_apply_difficulty_stats(enemy, hp_mult)
	_spawn_parent.add_child(enemy)

	var offset_x := randf_range(-spawn_x_spread, spawn_x_spread)
	var pos := _spawn_point.global_position
	pos.x += offset_x
	enemy.global_position = pos

	if enemy.has_method("setup"):
		enemy.setup(_wall)
	if enemy.has_signal("killed"):
		enemy.killed.connect(_on_enemy_killed)


func _apply_difficulty_stats(enemy: Node3D, wave_hp_mult: float = 1.0) -> void:
	var hp_m := 1.0
	var spd_m := 1.0
	var dmg_m := 1.0
	var scrap_m := 1.0
	if DifficultySettings:
		hp_m = DifficultySettings.get_enemy_hp_mult()
		spd_m = DifficultySettings.get_enemy_speed_mult()
		dmg_m = DifficultySettings.get_contact_dmg_mult()
		scrap_m = DifficultySettings.get_scrap_reward_mult()
	hp_m *= maxf(1.0, wave_hp_mult)
	if "max_hp" in enemy:
		enemy.set("max_hp", maxi(1, int(round(float(enemy.get("max_hp")) * hp_m))))
	if "move_speed" in enemy:
		enemy.set("move_speed", maxf(0.1, float(enemy.get("move_speed")) * spd_m))
	if "contact_damage" in enemy:
		enemy.set("contact_damage", maxi(1, int(round(float(enemy.get("contact_damage")) * dmg_m))))
	if "scrap_reward" in enemy:
		enemy.set("scrap_reward", maxi(1, int(round(float(enemy.get("scrap_reward")) * scrap_m))))


func _on_enemy_killed(scrap_amount: int) -> void:
	enemy_killed.emit(scrap_amount)
