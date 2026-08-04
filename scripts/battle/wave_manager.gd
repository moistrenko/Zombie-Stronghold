extends Node

signal wave_changed(current_wave: int, total_waves: int)
signal status_changed(text: String)
signal waves_finished

## Each wave is an array of enemy type keys ("basic", "runner").
var wave_recipes: Array = [
	["basic", "basic", "basic"],
	["basic", "runner", "basic", "runner", "basic"],
	["basic", "runner", "runner", "basic", "runner", "basic", "runner", "basic"],
]
@export var spawn_intervals: Array[float] = [1.2, 1.0, 0.85]
@export var pause_between_waves: float = 2.0
@export var spawn_x_spread: float = 2.5

var _enemy_scenes: Dictionary = {}
var _wall: Node3D
var _spawn_point: Marker3D
var _spawn_parent: Node3D

var _active: bool = false
var _spawning_done: bool = false


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
	_run_waves()


func stop_waves() -> void:
	_active = false


func is_spawning_done() -> bool:
	return _spawning_done


func _run_waves() -> void:
	var total := wave_recipes.size()
	for wave_index in total:
		if not _active:
			return

		var wave_number := wave_index + 1
		wave_changed.emit(wave_number, total)
		status_changed.emit("Wave %d/%d" % [wave_number, total])

		var recipe: Array = wave_recipes[wave_index]
		var interval: float = spawn_intervals[mini(wave_index, spawn_intervals.size() - 1)]

		for type_key in recipe:
			if not _active:
				return
			_spawn_enemy(str(type_key))
			await get_tree().create_timer(interval).timeout

		if wave_index < total - 1:
			if not _active:
				return
			status_changed.emit("Wave %d/%d — next..." % [wave_number, total])
			await get_tree().create_timer(pause_between_waves).timeout

	if not _active:
		return

	_spawning_done = true
	status_changed.emit("Wave %d/%d — clear!" % [total, total])
	waves_finished.emit()


func _spawn_enemy(type_key: String) -> void:
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
	_spawn_parent.add_child(enemy)

	var offset_x := randf_range(-spawn_x_spread, spawn_x_spread)
	var pos := _spawn_point.global_position
	pos.x += offset_x
	enemy.global_position = pos

	if enemy.has_method("setup"):
		enemy.setup(_wall)
