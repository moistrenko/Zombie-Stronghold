extends Node3D

@export var attack_range: float = 12.0
@export var fire_interval: float = 0.7
@export var damage: int = 15
@export var projectile_scene: PackedScene

## Set by battle on place (Basic 50 / Cannon 90). Used for sell refund.
var base_cost: int = 50
var is_upgraded: bool = false

var _cooldown: float = 0.0
var _body_mats: Array[StandardMaterial3D] = []
var _muzzle: MeshInstance3D
var _muzzle_mat: StandardMaterial3D
var _flash_left: float = 0.0
var _base_emission: float = 0.0
var _visual_scale: float = 1.0


func _ready() -> void:
	add_to_group("turrets")
	_cache_materials()
	_setup_muzzle()


func setup_economy(cost: int) -> void:
	base_cost = cost


func can_upgrade() -> bool:
	return not is_upgraded


func apply_upgrade() -> void:
	if is_upgraded:
		return
	is_upgraded = true
	# +40% damage, +15% range — helps vs Brute without being mandatory.
	damage = maxi(1, int(round(float(damage) * 1.4)))
	attack_range *= 1.15
	_visual_scale = 1.18
	scale = Vector3.ONE * _visual_scale
	_apply_upgrade_tint()
	play_place_pulse()


func _apply_upgrade_tint() -> void:
	for mat in _body_mats:
		# Warmer / brighter so upgraded turrets read at a glance.
		mat.albedo_color = mat.albedo_color.lerp(Color(1.0, 0.85, 0.35, 1.0), 0.35)
		mat.emission = mat.albedo_color.lightened(0.25)
		_base_emission = 0.35
		mat.emission_energy_multiplier = _base_emission


func _cache_materials() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			var mesh_inst := child as MeshInstance3D
			var src: Material = mesh_inst.get_active_material(0)
			var mat: StandardMaterial3D
			if src is StandardMaterial3D:
				mat = (src as StandardMaterial3D).duplicate() as StandardMaterial3D
			else:
				mat = StandardMaterial3D.new()
				mat.albedo_color = Color(0.35, 0.55, 0.85, 1.0)
			mat.emission_enabled = true
			mat.emission = mat.albedo_color.lightened(0.35)
			mat.emission_energy_multiplier = 0.0
			mesh_inst.material_override = mat
			_body_mats.append(mat)


func _setup_muzzle() -> void:
	_muzzle_mat = StandardMaterial3D.new()
	_muzzle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_muzzle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_muzzle_mat.albedo_color = Color(1.0, 0.85, 0.35, 0.0)
	_muzzle_mat.emission_enabled = true
	_muzzle_mat.emission = Color(1.0, 0.8, 0.3, 1.0)
	_muzzle_mat.emission_energy_multiplier = 0.0

	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44

	_muzzle = MeshInstance3D.new()
	_muzzle.name = "MuzzleFlash"
	_muzzle.mesh = sphere
	_muzzle.material_override = _muzzle_mat
	_muzzle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_muzzle.visible = false

	var barrel := get_node_or_null("Barrel") as Node3D
	if barrel != null:
		barrel.add_child(_muzzle)
		_muzzle.position = Vector3(0.0, 0.0, -0.55)
	else:
		add_child(_muzzle)
		_muzzle.position = Vector3(0.0, 0.9, -1.0)


func _process(delta: float) -> void:
	_update_flash(delta)

	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0:
		return

	var target := _find_nearest_zombie()
	if target == null:
		return

	_fire_at(target)
	_cooldown = fire_interval


func _update_flash(delta: float) -> void:
	if _flash_left <= 0.0:
		return
	_flash_left = maxf(0.0, _flash_left - delta)
	var t := clampf(_flash_left / 0.08, 0.0, 1.0)
	for mat in _body_mats:
		mat.emission_energy_multiplier = lerpf(_base_emission, 2.4, t)
	if _muzzle_mat != null:
		_muzzle_mat.albedo_color.a = 0.85 * t
		_muzzle_mat.emission_energy_multiplier = 3.0 * t
		_muzzle.visible = t > 0.02
		_muzzle.scale = Vector3.ONE * lerpf(0.4, 1.2, t)


func _find_nearest_zombie() -> Node3D:
	var nearest: Node3D = null
	var best_dist := attack_range

	for node in get_tree().get_nodes_in_group("zombies"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		if node.has_method("is_targetable") and not node.is_targetable():
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

	_flash_left = 0.08
	if Sfx:
		Sfx.play_shoot()


func play_place_pulse() -> void:
	var base := Vector3.ONE * _visual_scale
	var peak := base * 1.18
	var tween := create_tween()
	tween.tween_property(self, "scale", peak, 0.07)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", base, 0.12)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
