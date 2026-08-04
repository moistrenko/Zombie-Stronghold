extends Node3D

@export var move_speed: float = 14.0
@export var damage: int = 15
@export var hit_radius: float = 0.6

var _target: Node3D = null
var _direction: Vector3 = Vector3(0.0, 0.0, -1.0)
var _trail: MeshInstance3D
var _trail_mat: StandardMaterial3D


func _ready() -> void:
	_setup_trail()


func _setup_trail() -> void:
	_trail_mat = StandardMaterial3D.new()
	_trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_mat.albedo_color = Color(1.0, 0.85, 0.25, 0.45)
	_trail_mat.emission_enabled = true
	_trail_mat.emission = Color(0.95, 0.75, 0.15, 1.0)
	_trail_mat.emission_energy_multiplier = 1.8

	var capsule := CapsuleMesh.new()
	capsule.radius = 0.08
	capsule.height = 0.55

	_trail = MeshInstance3D.new()
	_trail.name = "Trail"
	_trail.mesh = capsule
	_trail.material_override = _trail_mat
	_trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_trail.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_trail.position = Vector3(0.0, 0.0, 0.28)
	add_child(_trail)

	var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh != null:
		var src: Material = mesh.get_active_material(0)
		if src is StandardMaterial3D:
			var mat := (src as StandardMaterial3D).duplicate() as StandardMaterial3D
			mat.emission_energy_multiplier = 2.4
			mesh.material_override = mat


func setup(target: Node3D, damage_override: int = -1) -> void:
	_target = target
	if damage_override >= 0:
		damage = damage_override
	if is_instance_valid(_target):
		_direction = (_target.global_position - global_position).normalized()
		if _direction.length_squared() < 0.0001:
			_direction = Vector3(0.0, 0.0, -1.0)
	_orient_to_direction()


func _process(delta: float) -> void:
	if is_instance_valid(_target):
		if _target.has_method("is_targetable") and not _target.is_targetable():
			_target = null
		else:
			_direction = (_target.global_position - global_position).normalized()
			if global_position.distance_to(_target.global_position) <= hit_radius:
				_apply_hit()
				return
	else:
		_target = null

	global_position += _direction * move_speed * delta
	_orient_to_direction()

	if absf(global_position.x) > 20.0 or global_position.y < -2.0 or global_position.y > 20.0 \
			or absf(global_position.z) > 20.0:
		queue_free()


func _orient_to_direction() -> void:
	if _direction.length_squared() < 0.0001:
		return
	if absf(_direction.dot(Vector3.UP)) > 0.98:
		return
	look_at(global_position + _direction, Vector3.UP)


func _apply_hit() -> void:
	if is_instance_valid(_target) and _target.has_method("take_damage"):
		_target.take_damage(damage)
	queue_free()
