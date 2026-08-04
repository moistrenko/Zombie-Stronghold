extends Node3D

@export var attack_range: float = 12.0
@export var fire_interval: float = 0.7
@export var damage: int = 15
@export var projectile_scene: PackedScene

var _cooldown: float = 0.0


func _ready() -> void:
	add_to_group("turrets")


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0:
		return

	var target := _find_nearest_zombie()
	if target == null:
		return

	_fire_at(target)
	_cooldown = fire_interval


func _find_nearest_zombie() -> Node3D:
	var nearest: Node3D = null
	var best_dist := attack_range

	for node in get_tree().get_nodes_in_group("zombies"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		var dist := global_position.distance_to(node.global_position)
		if dist <= best_dist:
			best_dist = dist
			nearest = node as Node3D

	return nearest


func _fire_at(target: Node3D) -> void:
	if projectile_scene == null:
		push_error("Turret: projectile_scene is not assigned")
		return

	var projectile: Node3D = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector3(0.0, 0.6, 0.0)
	if projectile.has_method("setup"):
		projectile.setup(target, damage)
