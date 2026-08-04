extends Node3D

signal hp_changed(current_hp: int, max_hp: int)
signal destroyed
signal damaged(amount: int)

@export var max_hp: int = 100
## Local Z of the wall face toward the field (spawn is at more negative Z).
@export var front_offset_z: float = -0.5

var current_hp: int = 100

@onready var _mesh: MeshInstance3D = $MeshInstance3D

var _material: StandardMaterial3D
var _base_color := Color(0.48, 0.42, 0.36, 1.0)
var _flash_left: float = 0.0


func _ready() -> void:
	current_hp = max_hp
	_material = StandardMaterial3D.new()
	_material.albedo_color = _base_color
	_material.emission_enabled = true
	_material.emission = Color(0.9, 0.15, 0.1, 1.0)
	_material.emission_energy_multiplier = 0.0
	_mesh.material_override = _material
	hp_changed.emit(current_hp, max_hp)


func get_front_z() -> float:
	return global_position.z + front_offset_z


## Permanent meta bonus — call after _ready (children init first).
func apply_max_hp_bonus(bonus: int) -> void:
	if bonus <= 0:
		return
	max_hp += bonus
	current_hp = mini(current_hp + bonus, max_hp)
	hp_changed.emit(current_hp, max_hp)


func take_damage(amount: int) -> void:
	if current_hp <= 0:
		return

	current_hp = maxi(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	_flash_left = 0.22
	_apply_flash(1.0)
	_update_damage_tint()
	damaged.emit(amount)
	if Sfx:
		Sfx.play_wall_hit()

	if current_hp <= 0:
		_material.albedo_color = Color(0.35, 0.08, 0.08, 1.0)
		_material.emission_energy_multiplier = 1.2
		print("defeat")
		destroyed.emit()


func _process(delta: float) -> void:
	if _flash_left <= 0.0 or current_hp <= 0:
		return
	_flash_left = maxf(0.0, _flash_left - delta)
	var t := clampf(_flash_left / 0.22, 0.0, 1.0)
	_apply_flash(t)
	if t <= 0.0:
		_update_damage_tint()


func _apply_flash(strength: float) -> void:
	if _material == null:
		return
	var damaged_color := _base_damage_color()
	_material.albedo_color = damaged_color.lerp(Color(1.0, 0.25, 0.18, 1.0), strength)
	_material.emission = Color(1.0, 0.2, 0.12, 1.0)
	_material.emission_energy_multiplier = 3.8 * strength


func _base_damage_color() -> Color:
	if current_hp <= 0:
		return Color(0.35, 0.08, 0.08, 1.0)
	var t := 1.0 - (float(current_hp) / float(max_hp))
	return _base_color.lerp(Color(0.7, 0.2, 0.15, 1.0), t)


func _update_damage_tint() -> void:
	if _material == null:
		return
	_material.albedo_color = _base_damage_color()
	if current_hp > 0:
		_material.emission_energy_multiplier = 0.0
