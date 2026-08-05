extends Node3D

## Movement plane: XZ (Y up). Toward wall = +Z (down the screen).
## At the gate: stop, loop attack anim, deal 1 HP per strike (not one-shot contact).

signal killed(scrap_amount: int)

@export var move_speed: float = 1.1
## Legacy / barricade chew damage. Gate hits always deal `gate_hit_damage` (1).
@export var contact_damage: int = 1
@export var gate_hit_damage: int = 1
@export var attack_interval: float = 1.0
@export var max_hp: int = 30
@export var scrap_reward: int = 12
@export var move_animation: StringName = &"run"
@export var attack_animation: StringName = &"attack"

var current_hp: int = 30

var _wall: Node = null
var _is_attacking: bool = false
var _attack_timer: float = 0.0
var _is_dead: bool = false
## Temporary speed multiplier (abilities / slow pulse). 1.0 = normal.
var _speed_mult: float = 1.0
## Extra slow from barricades (multiplicative with ability slow).
var _barricade_slow: float = 1.0

var _sprite: AnimatedSprite3D
var _base_modulate: Color = Color.WHITE
var _base_scale: Vector3 = Vector3.ONE
var _sprite_base_y: float = 0.0
var _hit_flash_left: float = 0.0
var _scale_punch: float = 0.0
var _bob_t: float = 0.0


func _ready() -> void:
	add_to_group("zombies")
	current_hp = max_hp
	_base_scale = scale
	_setup_visual()


func _setup_visual() -> void:
	_sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if _sprite == null:
		return

	_base_modulate = _sprite.modulate
	_sprite_base_y = _sprite.position.y
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.shaded = false
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(move_animation):
		_sprite.play(move_animation)


func setup(wall: Node) -> void:
	_wall = wall


func set_speed_mult(mult: float) -> void:
	_speed_mult = maxf(0.05, mult)


func get_speed_mult() -> float:
	return _speed_mult * _barricade_slow


func is_targetable() -> bool:
	## Stay targetable while chewing the gate (turrets can finish them off).
	return not _is_dead


func take_damage(amount: int) -> void:
	if _is_dead:
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
	if _sprite != null:
		_sprite.modulate = Color(1.35, 1.15, 0.95, 1.0)


func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	_is_attacking = false
	killed.emit(scrap_reward)
	if Sfx:
		Sfx.play_kill()
	_play_kill_feedback()


func _play_kill_feedback() -> void:
	# Kill pop: brief bright burst + scale punch, then shrink and free.
	if _sprite != null:
		_sprite.pause()
		_sprite.modulate = Color(1.6, 1.25, 0.55, 1.0)

	var tween := create_tween()
	tween.tween_property(self, "scale", _base_scale * 1.35, 0.06)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(self, "scale", _base_scale * 0.05, 0.14)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if _sprite != null:
		tween.tween_property(_sprite, "modulate:a", 0.0, 0.14)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	_update_hit_visual(delta)
	_update_bob(delta)

	if _is_dead or _wall == null:
		return

	if _is_attacking:
		_process_gate_attack(delta)
		return

	var barricade := _find_blocking_barricade()
	_barricade_slow = 1.0
	if barricade != null:
		var slow := 1.0
		if "slow_mult" in barricade:
			slow = float(barricade.get("slow_mult"))
		_barricade_slow = clampf(slow, 0.05, 1.0)
		var front_z: float = barricade.global_position.z
		if barricade.has_method("get_front_z"):
			front_z = barricade.get_front_z()
		if global_position.z >= front_z:
			global_position.z = front_z
			if barricade.has_method("register_chew"):
				barricade.register_chew(self, delta, contact_damage)
			return

	# Toward wall at bottom of screen: +Z
	position.z += move_speed * get_speed_mult() * delta

	var wall_front_z: float = _wall.global_position.z
	if _wall.has_method("get_front_z"):
		wall_front_z = _wall.get_front_z()

	if global_position.z >= wall_front_z:
		global_position.z = wall_front_z
		_begin_gate_attack()


func _begin_gate_attack() -> void:
	if _is_dead or _is_attacking:
		return
	_is_attacking = true
	_attack_timer = attack_interval * 0.35
	if _sprite != null and _sprite.sprite_frames != null:
		if _sprite.sprite_frames.has_animation(attack_animation):
			_sprite.play(attack_animation)
		elif _sprite.sprite_frames.has_animation(move_animation):
			_sprite.play(move_animation)


func _process_gate_attack(delta: float) -> void:
	## Slow still applies while attacking (interval stretched).
	var interval := maxf(0.25, attack_interval / maxf(0.05, get_speed_mult()))
	_attack_timer += delta
	if _attack_timer < interval:
		return
	_attack_timer = 0.0
	if _wall != null and _wall.has_method("take_damage"):
		_wall.take_damage(maxi(1, gate_hit_damage))


func _find_blocking_barricade() -> Node3D:
	var best: Node3D = null
	var best_z := INF
	for node in get_tree().get_nodes_in_group("barricades"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		var b := node as Node3D
		if b.has_method("covers_x") and not b.covers_x(global_position.x):
			continue
		if "current_hp" in b and int(b.get("current_hp")) <= 0:
			continue
		var fz: float = b.global_position.z
		if b.has_method("get_front_z"):
			fz = b.get_front_z()
		# Only interact with barricades ahead / under us (toward wall = +Z).
		if fz < global_position.z - 0.8:
			continue
		if fz < best_z:
			best_z = fz
			best = b
	return best


func _update_bob(delta: float) -> void:
	if _sprite == null or _is_dead or _is_attacking:
		return
	# Gentle shuffle bob matched to slow walk speeds.
	_bob_t += delta * (4.0 + move_speed * get_speed_mult() * 1.2)
	_sprite.position.y = _sprite_base_y + sin(_bob_t) * 0.03


func _update_hit_visual(delta: float) -> void:
	if _scale_punch > 0.0:
		_scale_punch = maxf(0.0, _scale_punch - delta * 3.5)
		var punch := 1.0 + _scale_punch * 0.35
		if not _is_dead:
			scale = _base_scale * punch

	if _hit_flash_left > 0.0 and not _is_dead:
		_hit_flash_left = maxf(0.0, _hit_flash_left - delta)
		if _sprite != null:
			var t := clampf(_hit_flash_left / 0.12, 0.0, 1.0)
			_sprite.modulate = Color(1.35, 1.15, 0.95, 1.0).lerp(_base_modulate, 1.0 - t)
