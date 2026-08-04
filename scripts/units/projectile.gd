extends Node3D

@export var move_speed: float = 14.0
@export var damage: int = 15
@export var hit_radius: float = 0.6

var _target: Node3D = null
var _direction: Vector3 = Vector3(0.0, 0.0, -1.0)


func setup(target: Node3D, damage_override: int = -1) -> void:
	_target = target
	if damage_override >= 0:
		damage = damage_override
	if is_instance_valid(_target):
		_direction = (_target.global_position - global_position).normalized()
		if _direction.length_squared() < 0.0001:
			_direction = Vector3(0.0, 0.0, -1.0)


func _process(delta: float) -> void:
	if is_instance_valid(_target):
		_direction = (_target.global_position - global_position).normalized()
		if global_position.distance_to(_target.global_position) <= hit_radius:
			_apply_hit()
			return
	else:
		_target = null

	global_position += _direction * move_speed * delta

	if absf(global_position.x) > 20.0 or global_position.y < -2.0 or global_position.y > 20.0 \
			or absf(global_position.z) > 20.0:
		queue_free()


func _apply_hit() -> void:
	if is_instance_valid(_target) and _target.has_method("take_damage"):
		_target.take_damage(damage)
	queue_free()
