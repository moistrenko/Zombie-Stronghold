extends Node3D

@export var attack_range: float = 12.0
@export var fire_interval: float = 0.7
@export var damage: int = 15
@export var projectile_scene: PackedScene
@export var upgrade_cost: int = 30
## Tesla / Arc: chain lightning jumps (0 = normal projectile turret).
@export var chain_jumps: int = 0
@export var chain_radius: float = 3.5
@export var chain_damage_mult: float = 0.7

## Set by battle on place (Basic 50 / Cannon 90 / …). Used for sell refund.
var base_cost: int = 50
var is_upgraded: bool = false
var unit_kind: StringName = &"basic"

var _cooldown: float = 0.0
var _sprite: AnimatedSprite3D
var _yaw: Node3D
var _barrel: Node3D
var _muzzle: MeshInstance3D
var _muzzle_mat: StandardMaterial3D
var _flash_left: float = 0.0
var _base_modulate: Color = Color.WHITE
var _visual_scale: float = 1.0
var _firing: bool = false
var _aura_damage_mult: float = 1.0


func _ready() -> void:
	add_to_group("turrets")
	add_to_group("placeables")
	_yaw = get_node_or_null("YawPivot") as Node3D
	_barrel = get_node_or_null("YawPivot/Barrel") as Node3D
	if _barrel == null:
		_barrel = get_node_or_null("Barrel") as Node3D
	_sprite = get_node_or_null("YawPivot/AnimatedSprite3D") as AnimatedSprite3D
	if _sprite == null:
		_sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if _sprite != null:
		_base_modulate = _sprite.modulate
		_sprite.animation_finished.connect(_on_sprite_animation_finished)
		if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(&"idle"):
			_sprite.play(&"idle")
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
	if chain_jumps > 0:
		chain_jumps += 1
		chain_radius *= 1.1
	_visual_scale = 1.18
	scale = Vector3.ONE * _visual_scale
	_apply_upgrade_tint()
	play_place_pulse()


func set_aura_damage_mult(mult: float) -> void:
	_aura_damage_mult = maxf(1.0, mult)


func get_effective_damage() -> int:
	return maxi(1, int(round(float(damage) * _aura_damage_mult)))


func _apply_upgrade_tint() -> void:
	if _sprite != null:
		_base_modulate = Color(
			minf(1.0, _base_modulate.r * 1.05 + 0.08),
			minf(1.0, _base_modulate.g * 0.95),
			minf(1.0, _base_modulate.b * 0.7),
			1.0
		)
		_sprite.modulate = _base_modulate


func _setup_muzzle() -> void:
	_muzzle_mat = StandardMaterial3D.new()
	_muzzle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_muzzle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_muzzle_mat.albedo_color = Color(1.0, 0.85, 0.35, 0.0)
	_muzzle_mat.emission_enabled = true
	_muzzle_mat.emission = Color(1.0, 0.8, 0.3, 1.0)
	_muzzle_mat.emission_energy_multiplier = 0.0

	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36

	_muzzle = MeshInstance3D.new()
	_muzzle.name = "MuzzleFlash"
	_muzzle.mesh = sphere
	_muzzle.material_override = _muzzle_mat
	_muzzle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_muzzle.visible = false

	if _barrel != null:
		_barrel.add_child(_muzzle)
		_muzzle.position = Vector3(0.0, 0.0, -0.15)
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
	if _sprite != null and not _firing:
		_sprite.modulate = _base_modulate.lerp(Color(1.35, 1.2, 0.85, 1.0), t)
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


func _aim_yaw_at(target: Node3D) -> void:
	if _yaw == null or target == null:
		return
	var look := target.global_position
	look.y = _yaw.global_position.y
	if look.distance_squared_to(_yaw.global_position) < 0.0001:
		return
	_yaw.look_at(look, Vector3.UP)


func _fire_at(target: Node3D) -> void:
	_aim_yaw_at(target)
	var dmg := get_effective_damage()

	if chain_jumps > 0:
		_arc_attack(target, dmg)
	else:
		if projectile_scene == null:
			push_error("Turret: projectile_scene is not assigned")
			return
		var projectile: Node3D = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		if _barrel != null:
			projectile.global_position = _barrel.global_position
		else:
			projectile.global_position = global_position + Vector3(0.0, 0.6, 0.0)
		if projectile.has_method("setup"):
			projectile.setup(target, dmg)

	_flash_left = 0.08
	_play_fire_anim()
	if Sfx:
		Sfx.play_shoot()


func _arc_attack(primary: Node3D, base_dmg: int) -> void:
	var hit: Array[Node3D] = []
	var current: Node3D = primary
	var dmg := base_dmg
	var origin := global_position

	for _i in range(chain_jumps + 1):
		if current == null or not is_instance_valid(current):
			break
		if current.has_method("take_damage"):
			current.take_damage(dmg)
		hit.append(current)
		origin = current.global_position
		dmg = maxi(1, int(round(float(dmg) * chain_damage_mult)))
		current = _find_chain_target(origin, hit)


func _find_chain_target(from: Vector3, exclude: Array[Node3D]) -> Node3D:
	var nearest: Node3D = null
	var best := chain_radius
	for node in get_tree().get_nodes_in_group("zombies"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		var z := node as Node3D
		if z in exclude:
			continue
		if z.has_method("is_targetable") and not z.is_targetable():
			continue
		var dist := from.distance_to(z.global_position)
		if dist <= best:
			best = dist
			nearest = z
	return nearest


func _play_fire_anim() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	if not _sprite.sprite_frames.has_animation(&"fire"):
		return
	_firing = true
	_sprite.play(&"fire")


func _on_sprite_animation_finished() -> void:
	if _sprite == null:
		return
	if StringName(_sprite.animation) == &"fire":
		_firing = false
		if _sprite.sprite_frames.has_animation(&"idle"):
			_sprite.play(&"idle")
		_sprite.modulate = _base_modulate


func play_place_pulse() -> void:
	var base := Vector3.ONE * _visual_scale
	var peak := base * 1.18
	var tween := create_tween()
	tween.tween_property(self, "scale", peak, 0.07)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", base, 0.12)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
