extends Node3D

## Fence segment — slows / blocks zombies in a narrow X strip until HP runs out.

@export var max_hp: int = 80
@export var half_width: float = 1.35
@export var slow_mult: float = 0.35
@export var chew_interval: float = 0.45
@export var upgrade_cost: int = 30

var current_hp: int = 80
var base_cost: int = 45
var is_upgraded: bool = false
var unit_kind: StringName = &"barricade"

var _mesh: MeshInstance3D
var _base_color: Color = Color(0.45, 0.38, 0.3, 1.0)
var _chew_timers: Dictionary = {} # zombie instance_id -> time


func _ready() -> void:
	add_to_group("placeables")
	add_to_group("barricades")
	current_hp = max_hp
	_mesh = get_node_or_null("MeshInstance3D") as MeshInstance3D
	_apply_tint(_base_color)


func setup_economy(cost: int) -> void:
	base_cost = cost


func can_upgrade() -> bool:
	return not is_upgraded


func apply_upgrade() -> void:
	if is_upgraded:
		return
	is_upgraded = true
	max_hp = int(round(float(max_hp) * 1.4))
	current_hp = max_hp
	half_width *= 1.15
	slow_mult = minf(slow_mult, 0.28)
	scale = Vector3(scale.x * 1.12, scale.y * 1.1, scale.z)
	_base_color = Color(0.55, 0.48, 0.32, 1.0)
	_apply_tint(_base_color)
	play_place_pulse()


func get_front_z() -> float:
	return global_position.z - 0.35


func covers_x(x: float) -> bool:
	return absf(x - global_position.x) <= half_width


func take_damage(amount: int) -> void:
	if current_hp <= 0:
		return
	current_hp = maxi(0, current_hp - amount)
	_flash_hit()
	if current_hp <= 0:
		_destroy()


func register_chew(zombie: Node3D, delta: float, contact_damage: int) -> void:
	if current_hp <= 0 or not is_instance_valid(zombie):
		return
	var id := zombie.get_instance_id()
	var t: float = float(_chew_timers.get(id, 0.0)) + delta
	if t >= chew_interval:
		t = 0.0
		take_damage(maxi(1, contact_damage))
	_chew_timers[id] = t


func _flash_hit() -> void:
	_apply_tint(Color(1.0, 0.55, 0.4, 1.0))
	var tween := create_tween()
	tween.tween_callback(_apply_tint.bind(_base_color)).set_delay(0.12)


func _destroy() -> void:
	if Sfx:
		Sfx.play_hit()
	var tween := create_tween()
	tween.tween_property(self, "scale", scale * Vector3(1.0, 0.05, 1.0), 0.18)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func _apply_tint(color: Color) -> void:
	if _mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	_mesh.material_override = mat


func play_place_pulse() -> void:
	var base := scale
	var peak := base * 1.12
	var tween := create_tween()
	tween.tween_property(self, "scale", peak, 0.07)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", base, 0.12)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
