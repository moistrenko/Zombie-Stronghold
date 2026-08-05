extends Node3D

## Supply Beacon — no shots. Buffs nearby turrets + periodic scrap drip.

signal scrap_drip(amount: int)

@export var aura_radius: float = 4.0
@export var aura_damage_bonus: float = 0.20
@export var scrap_drip_amount: int = 2
@export var scrap_drip_interval: float = 5.0
@export var upgrade_cost: int = 40

var base_cost: int = 70
var is_upgraded: bool = false
var unit_kind: StringName = &"support"

var _drip_left: float = 0.0
var _sprite: AnimatedSprite3D
var _base_modulate: Color = Color(0.45, 1.0, 0.55, 1.0)
var _visual_scale: float = 1.0
var _buffed: Dictionary = {} # instance_id -> turret


func _ready() -> void:
	add_to_group("placeables")
	add_to_group("supports")
	_sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if _sprite == null:
		_sprite = get_node_or_null("YawPivot/AnimatedSprite3D") as AnimatedSprite3D
	if _sprite != null:
		_sprite.modulate = _base_modulate
		if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(&"idle"):
			_sprite.play(&"idle")
	_drip_left = scrap_drip_interval


func setup_economy(cost: int) -> void:
	base_cost = cost


func can_upgrade() -> bool:
	return not is_upgraded


func apply_upgrade() -> void:
	if is_upgraded:
		return
	is_upgraded = true
	aura_radius *= 1.25
	aura_damage_bonus += 0.10
	scrap_drip_amount += 1
	_visual_scale = 1.15
	scale = Vector3.ONE * _visual_scale
	_base_modulate = Color(0.55, 1.0, 0.7, 1.0)
	if _sprite != null:
		_sprite.modulate = _base_modulate
	play_place_pulse()


func _process(delta: float) -> void:
	_refresh_aura()
	_drip_left = maxf(0.0, _drip_left - delta)
	if _drip_left <= 0.0:
		_drip_left = scrap_drip_interval
		scrap_drip.emit(scrap_drip_amount)


func _refresh_aura() -> void:
	var keep: Dictionary = {}
	var mult := 1.0 + aura_damage_bonus
	for node in get_tree().get_nodes_in_group("turrets"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		if node == self:
			continue
		var t := node as Node3D
		var dist := Vector3(global_position.x, 0.0, global_position.z)\
				.distance_to(Vector3(t.global_position.x, 0.0, t.global_position.z))
		if dist <= aura_radius:
			if t.has_method("set_aura_damage_mult"):
				t.set_aura_damage_mult(mult)
			keep[t.get_instance_id()] = t

	# Clear buffs on turrets that left the aura (or were freed).
	for id in _buffed.keys():
		if keep.has(id):
			continue
		var old: Variant = _buffed[id]
		if is_instance_valid(old) and old.has_method("set_aura_damage_mult"):
			old.set_aura_damage_mult(1.0)
	_buffed = keep


func _exit_tree() -> void:
	for id in _buffed.keys():
		var old: Variant = _buffed[id]
		if is_instance_valid(old) and old.has_method("set_aura_damage_mult"):
			old.set_aura_damage_mult(1.0)
	_buffed.clear()


func play_place_pulse() -> void:
	var base := Vector3.ONE * _visual_scale
	var peak := base * 1.18
	var tween := create_tween()
	tween.tween_property(self, "scale", peak, 0.07)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", base, 0.12)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
