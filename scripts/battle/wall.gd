extends Node3D

signal hp_changed(current_hp: int, max_hp: int)
signal destroyed

@export var max_hp: int = 100
## Local Z of the wall face toward the field (spawn is at more negative Z).
@export var front_offset_z: float = -0.5

var current_hp: int = 100

@onready var _mesh: MeshInstance3D = $MeshInstance3D

var _material: StandardMaterial3D
var _base_color := Color(0.48, 0.42, 0.36, 1.0)


func _ready() -> void:
	current_hp = max_hp
	_material = StandardMaterial3D.new()
	_material.albedo_color = _base_color
	_mesh.material_override = _material
	hp_changed.emit(current_hp, max_hp)


func get_front_z() -> float:
	return global_position.z + front_offset_z


func take_damage(amount: int) -> void:
	if current_hp <= 0:
		return

	current_hp = maxi(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	_update_damage_tint()

	if current_hp <= 0:
		_material.albedo_color = Color(0.35, 0.08, 0.08, 1.0)
		print("defeat")
		destroyed.emit()


func _update_damage_tint() -> void:
	if current_hp <= 0 or _material == null:
		return
	var t := 1.0 - (float(current_hp) / float(max_hp))
	_material.albedo_color = _base_color.lerp(Color(0.7, 0.2, 0.15, 1.0), t)
