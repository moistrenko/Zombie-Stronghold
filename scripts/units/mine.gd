extends Node3D

## Proximity mine — one-shot damage when a zombie enters trigger radius.

@export var trigger_radius: float = 1.25
@export var damage: int = 45
@export var arm_delay: float = 0.35

var base_cost: int = 25
var unit_kind: StringName = &"mine"
var is_upgraded: bool = false

var _armed: bool = false
var _spent: bool = false
var _arm_left: float = 0.0
var _mesh: MeshInstance3D
var _base_color: Color = Color(0.85, 0.25, 0.18, 1.0)


func _ready() -> void:
	add_to_group("placeables")
	add_to_group("mines")
	_mesh = get_node_or_null("MeshInstance3D") as MeshInstance3D
	_arm_left = arm_delay
	_armed = false


func setup_economy(cost: int) -> void:
	base_cost = cost


func can_upgrade() -> bool:
	return false


func apply_upgrade() -> void:
	pass


func _process(delta: float) -> void:
	if _spent:
		return
	if not _armed:
		_arm_left = maxf(0.0, _arm_left - delta)
		if _arm_left <= 0.0:
			_armed = true
		return

	var target := _find_trigger_zombie()
	if target == null:
		return
	_detonate(target)


func _find_trigger_zombie() -> Node3D:
	var best: Node3D = null
	var best_d := trigger_radius
	for node in get_tree().get_nodes_in_group("zombies"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		if node.has_method("is_targetable") and not node.is_targetable():
			continue
		var z := node as Node3D
		var d := Vector3(global_position.x, 0.0, global_position.z)\
				.distance_to(Vector3(z.global_position.x, 0.0, z.global_position.z))
		if d <= best_d:
			best_d = d
			best = z
	return best


func _detonate(target: Node3D) -> void:
	if _spent:
		return
	_spent = true
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)
	if Sfx:
		Sfx.play_kill()
	_play_boom()


func _play_boom() -> void:
	if _mesh != null:
		var mat := _mesh.get_active_material(0)
		if mat is StandardMaterial3D:
			var m := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			m.emission_enabled = true
			m.emission = Color(1.0, 0.55, 0.15, 1.0)
			m.emission_energy_multiplier = 4.0
			_mesh.material_override = m
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 1.6, 0.08)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3.ONE * 0.05, 0.12)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func play_place_pulse() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 1.25, 0.07)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3.ONE, 0.12)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
