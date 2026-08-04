extends Node3D

## Movement plane: XZ (Y up). Toward wall = +Z (down the screen).

signal killed(scrap_amount: int)

@export var move_speed: float = 3.0
@export var contact_damage: int = 10
@export var max_hp: int = 30
@export var scrap_reward: int = 12

var current_hp: int = 30

var _wall: Node = null
var _has_hit: bool = false
var _is_dead: bool = false

var _mesh: MeshInstance3D
var _material: StandardMaterial3D
var _base_color: Color = Color.WHITE
var _base_scale: Vector3 = Vector3.ONE
var _hit_flash_left: float = 0.0
var _scale_punch: float = 0.0


func _ready() -> void:
	add_to_group("zombies")
	current_hp = max_hp
	_base_scale = scale
	_setup_visual()


func _setup_visual() -> void:
	_mesh = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if _mesh == null:
		return

	var src: Material = _mesh.get_active_material(0)
	if src is StandardMaterial3D:
		_material = (src as StandardMaterial3D).duplicate() as StandardMaterial3D
	else:
		_material = StandardMaterial3D.new()
		_material.albedo_color = Color(0.35, 0.7, 0.32, 1.0)

	_base_color = _material.albedo_color
	_material.emission_enabled = true
	_material.emission = Color(0.0, 0.0, 0.0, 1.0)
	_material.emission_energy_multiplier = 0.0
	_mesh.material_override = _material


func setup(wall: Node) -> void:
	_wall = wall


func is_targetable() -> bool:
	return not _is_dead and not _has_hit


func take_damage(amount: int) -> void:
	if _is_dead or _has_hit:
		return

	current_hp = maxi(0, current_hp - amount)
	_play_hit_feedback()
	if current_hp <= 0:
		_die()
	elif Sfx:
		Sfx.play_hit()


func _play_hit_feedback() -> void:
	_hit_flash_left = 0.12
	_scale_punch = 0.22
	if _material != null:
		_material.albedo_color = Color(1.0, 0.95, 0.9, 1.0)
		_material.emission = Color(1.0, 0.55, 0.35, 1.0)
		_material.emission_energy_multiplier = 2.2


func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	killed.emit(scrap_reward)
	if Sfx:
		Sfx.play_kill()
	_play_kill_feedback()


func _play_kill_feedback() -> void:
	# Kill pop: brief bright burst + scale punch, then shrink and free.
	if _material != null:
		_material.albedo_color = Color(1.0, 0.85, 0.4, 1.0)
		_material.emission = Color(1.0, 0.7, 0.2, 1.0)
		_material.emission_energy_multiplier = 3.5

	var tween := create_tween()
	tween.tween_property(self, "scale", _base_scale * 1.35, 0.06)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(self, "scale", _base_scale * 0.05, 0.14)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if _material != null:
		tween.tween_property(_material, "emission_energy_multiplier", 0.0, 0.14)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	_update_hit_visual(delta)

	if _has_hit or _is_dead or _wall == null:
		return

	# Toward wall at bottom of screen: +Z
	position.z += move_speed * delta

	var front_z: float = _wall.global_position.z
	if _wall.has_method("get_front_z"):
		front_z = _wall.get_front_z()

	if global_position.z >= front_z:
		_hit_wall()


func _update_hit_visual(delta: float) -> void:
	if _scale_punch > 0.0:
		_scale_punch = maxf(0.0, _scale_punch - delta * 3.5)
		var punch := 1.0 + _scale_punch * 0.35
		if not _is_dead:
			scale = _base_scale * punch

	if _hit_flash_left > 0.0 and not _is_dead:
		_hit_flash_left = maxf(0.0, _hit_flash_left - delta)
		if _material != null:
			var t := clampf(_hit_flash_left / 0.12, 0.0, 1.0)
			_material.albedo_color = Color(1.0, 0.95, 0.9, 1.0).lerp(_base_color, 1.0 - t)
			_material.emission_energy_multiplier = 2.2 * t
			if t <= 0.0:
				_material.emission = Color(0.0, 0.0, 0.0, 1.0)


func _hit_wall() -> void:
	if _is_dead:
		return
	_has_hit = true
	if _wall != null and _wall.has_method("take_damage"):
		_wall.take_damage(contact_damage)
	queue_free()
