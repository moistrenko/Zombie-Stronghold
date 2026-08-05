extends Node3D

signal hp_changed(current_hp: int, max_hp: int)
signal destroyed
signal damaged(amount: int)

@export var max_hp: int = 100
## Local Z of the wall face toward the field (spawn is at more negative Z).
@export var front_offset_z: float = -0.5
## World Y for turrets sitting on the rampart / wall top.
@export var rampart_y: float = 1.35

const GATE_TEX := "res://assets/art/environment/processed/wall_fortress_gate_v1.png"
const RAMPART_TEX := "res://assets/art/environment/processed/wall_rampart_top_v1.png"

var current_hp: int = 100

@onready var _mesh: MeshInstance3D = $MeshInstance3D

var _gate_sprite: Sprite3D
var _rampart_sprite: Sprite3D
var _material: StandardMaterial3D
var _base_color := Color(0.48, 0.42, 0.36, 1.0)
var _gate_base_modulate := Color(1, 1, 1, 1)
var _flash_left: float = 0.0
var _flash_is_repair: bool = false


func _ready() -> void:
	current_hp = max_hp
	_setup_mesh_fallback()
	_setup_fortress_sprites()
	hp_changed.emit(current_hp, max_hp)


func _setup_mesh_fallback() -> void:
	## Keep a thin dark base volume under the sprite (depth cue); tint via material.
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.22, 0.18, 0.15, 0.85)
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.emission_enabled = true
	_material.emission = Color(0.9, 0.15, 0.1, 1.0)
	_material.emission_energy_multiplier = 0.0
	if _mesh != null:
		_mesh.material_override = _material
		_mesh.position = Vector3(0, -0.15, 0.05)
		_mesh.scale = Vector3(1.0, 0.55, 0.7)


func _setup_fortress_sprites() -> void:
	_gate_sprite = get_node_or_null("GateSprite") as Sprite3D
	if _gate_sprite == null:
		_gate_sprite = Sprite3D.new()
		_gate_sprite.name = "GateSprite"
		add_child(_gate_sprite)

	_configure_wall_sprite(_gate_sprite, GATE_TEX, Vector3(0, 0.35, -0.42), 0.0078)
	_gate_base_modulate = _gate_sprite.modulate

	_rampart_sprite = get_node_or_null("RampartSprite") as Sprite3D
	if _rampart_sprite == null and ResourceLoader.exists(RAMPART_TEX):
		_rampart_sprite = Sprite3D.new()
		_rampart_sprite.name = "RampartSprite"
		add_child(_rampart_sprite)
	if _rampart_sprite != null:
		_configure_wall_sprite(_rampart_sprite, RAMPART_TEX, Vector3(0, 1.15, -0.15), 0.0062)
		_rampart_sprite.modulate = Color(1, 1, 1, 0.92)


func _configure_wall_sprite(sprite: Sprite3D, tex_path: String, local_pos: Vector3, pixel_size: float) -> void:
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path) as Texture2D
	sprite.position = local_pos
	sprite.pixel_size = pixel_size
	## Fixed facing camera (+Z toward field / camera); not full billboard so gate stays "wall".
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.shaded = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.centered = true
	sprite.double_sided = true


func get_front_z() -> float:
	return global_position.z + front_offset_z


func get_rampart_y() -> float:
	return rampart_y


## Permanent meta bonus — call after _ready (children init first).
func apply_max_hp_bonus(bonus: int) -> void:
	if bonus <= 0:
		return
	max_hp += bonus
	current_hp = mini(current_hp + bonus, max_hp)
	hp_changed.emit(current_hp, max_hp)


func take_damage(amount: int) -> void:
	if current_hp <= 0:
		return

	current_hp = maxi(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	_flash_left = 0.22
	_flash_is_repair = false
	_apply_flash(1.0)
	_update_damage_tint()
	damaged.emit(amount)
	if Sfx:
		Sfx.play_wall_hit()

	if current_hp <= 0:
		_apply_destroyed_look()
		print("defeat")
		destroyed.emit()


## Restore up to `amount` HP. Returns actual healed. No-op if destroyed or already full.
func repair(amount: int) -> int:
	if current_hp <= 0 or amount <= 0 or current_hp >= max_hp:
		return 0
	var before := current_hp
	current_hp = mini(max_hp, current_hp + amount)
	var healed := current_hp - before
	if healed <= 0:
		return 0
	hp_changed.emit(current_hp, max_hp)
	_flash_left = 0.28
	_flash_is_repair = true
	_apply_flash(1.0)
	_update_damage_tint()
	return healed


func _process(delta: float) -> void:
	if _flash_left <= 0.0 or current_hp <= 0:
		return
	_flash_left = maxf(0.0, _flash_left - delta)
	var dur := 0.28 if _flash_is_repair else 0.22
	var t := clampf(_flash_left / dur, 0.0, 1.0)
	_apply_flash(t)
	if t <= 0.0:
		_flash_is_repair = false
		_update_damage_tint()


func _apply_flash(strength: float) -> void:
	if _flash_is_repair:
		var repair_flash := Color(0.55, 1.0, 0.65, 1.0)
		if _gate_sprite != null:
			_gate_sprite.modulate = _gate_base_modulate.lerp(repair_flash, strength)
		if _material != null:
			_material.emission = Color(0.25, 0.95, 0.4, 1.0)
			_material.emission_energy_multiplier = 2.8 * strength
	else:
		var hit_flash := Color(1.0, 0.35, 0.28, 1.0)
		if _gate_sprite != null:
			_gate_sprite.modulate = _gate_base_modulate.lerp(hit_flash, strength)
		if _material != null:
			_material.emission = Color(1.0, 0.2, 0.12, 1.0)
			_material.emission_energy_multiplier = 3.8 * strength


func _base_damage_color() -> Color:
	if current_hp <= 0:
		return Color(0.35, 0.08, 0.08, 1.0)
	var t := 1.0 - (float(current_hp) / float(max_hp))
	return _base_color.lerp(Color(0.7, 0.2, 0.15, 1.0), t)


func _update_damage_tint() -> void:
	var t := 0.0
	if current_hp > 0 and max_hp > 0:
		t = 1.0 - (float(current_hp) / float(max_hp))
	var gate_tint := Color.WHITE.lerp(Color(1.0, 0.55, 0.45, 1.0), t * 0.65)
	_gate_base_modulate = gate_tint
	if _gate_sprite != null and _flash_left <= 0.0:
		_gate_sprite.modulate = gate_tint
	if _material != null:
		_material.albedo_color = Color(0.22, 0.18, 0.15, 0.85).lerp(Color(0.45, 0.12, 0.1, 0.9), t)
		if current_hp > 0:
			_material.emission_energy_multiplier = 0.0


func _apply_destroyed_look() -> void:
	if _gate_sprite != null:
		_gate_sprite.modulate = Color(0.45, 0.12, 0.1, 1.0)
	if _rampart_sprite != null:
		_rampart_sprite.modulate = Color(0.4, 0.12, 0.1, 0.85)
	if _material != null:
		_material.albedo_color = Color(0.35, 0.08, 0.08, 0.95)
		_material.emission_energy_multiplier = 1.2
