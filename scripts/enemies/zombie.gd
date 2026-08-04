extends Node3D

## Movement plane: XZ (Y up). Toward wall = +Z (down the screen).

@export var move_speed: float = 3.0
@export var contact_damage: int = 10
@export var max_hp: int = 30

var current_hp: int = 30

var _wall: Node = null
var _has_hit: bool = false
var _is_dead: bool = false


func _ready() -> void:
	add_to_group("zombies")
	current_hp = max_hp


func setup(wall: Node) -> void:
	_wall = wall


func take_damage(amount: int) -> void:
	if _is_dead or _has_hit:
		return

	current_hp = maxi(0, current_hp - amount)
	if current_hp <= 0:
		_die()


func _die() -> void:
	_is_dead = true
	queue_free()


func _process(delta: float) -> void:
	if _has_hit or _is_dead or _wall == null:
		return

	# Toward wall at bottom of screen: +Z
	position.z += move_speed * delta

	var front_z: float = _wall.global_position.z
	if _wall.has_method("get_front_z"):
		front_z = _wall.get_front_z()

	if global_position.z >= front_z:
		_hit_wall()


func _hit_wall() -> void:
	if _is_dead:
		return
	_has_hit = true
	if _wall != null and _wall.has_method("take_damage"):
		_wall.take_damage(contact_damage)
	queue_free()
