extends Node3D

## Infinite-run battle: bottom build bar + unit inspector (no BUILD/UPGRADE/SELL modes).
## Ghost follows pointer only while a placeable type is selected.
## Tap placed unit → inspector (sell / upgrade). Wall-on placement preserved (stage 26).

const MAIN_MENU_SCENE := "res://scenes/menus/main_menu.tscn"
## Sell refund = floor(base_cost * SELL_REFUND_RATIO). Upgrade scrap is not refunded.
const SELL_REFUND_RATIO := 0.55
const GHOST_BASIC_TEX := "res://assets/art/turrets/processed/turret_basic_idle.png"
const GHOST_CANNON_TEX := "res://assets/art/turrets/processed/turret_cannon_idle.png"

@export var zombie_scene: PackedScene
@export var zombie_runner_scene: PackedScene
@export var zombie_brute_scene: PackedScene
@export var turret_scene: PackedScene
@export var turret_cannon_scene: PackedScene
@export var support_scene: PackedScene
@export var turret_tesla_scene: PackedScene
@export var turret_sniper_scene: PackedScene
@export var mine_scene: PackedScene
@export var barricade_scene: PackedScene
@export var min_place_distance: float = 1.6
## Approach strip (mines / fences) — before the gate, on the path.
@export var approach_z_min: float = 0.8
@export var approach_z_max: float = 4.9
@export var fence_z_min: float = 2.0
## Wall-top rampart strip for turrets / support / tesla / sniper.
@export var wall_z_min: float = 5.35
@export var wall_z_max: float = 6.2
## Legacy aliases (kept so older docs / overrides still read).
@export var placement_z_min: float = 5.35
@export var placement_z_max: float = 6.2
@export var mine_z_min: float = 0.8
@export var placement_x_min: float = -5.0
@export var placement_x_max: float = 5.0
@export var wall_place_y: float = 1.35
## Soft cap: only one Support beacon (aura stacking would dominate).
@export var max_supports: int = 1
@export var start_scrap: int = 130
@export var basic_turret_cost: int = 50
@export var cannon_turret_cost: int = 90
@export var support_cost: int = 70
@export var tesla_cost: int = 75
@export var sniper_cost: int = 110
@export var mine_cost: int = 25
@export var barricade_cost: int = 45
@export var scrap_between_waves: int = 15
@export var endless_scrap_bump: int = 2
@export var basic_upgrade_cost: int = 30
@export var cannon_upgrade_cost: int = 50
@export var support_upgrade_cost: int = 40
@export var tesla_upgrade_cost: int = 45
@export var sniper_upgrade_cost: int = 55
@export var barricade_upgrade_cost: int = 30
@export var interact_tap_radius: float = 1.9
## Wall Repair: restore this much HP.
@export var repair_heal: int = 20
@export var repair_cooldown: float = 32.0
@export var repair_charges: int = 3
## Slow Pulse: speed mult + duration.
@export var slow_speed_mult: float = 0.5
@export var slow_duration: float = 3.5
@export var slow_cooldown: float = 30.0

@onready var wall: Node3D = $Wall
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var hp_label: Label = $HUD/HpLabel
@onready var wave_label: Label = $HUD/WaveLabel
@onready var scrap_label: Label = $HUD/ScrapLabel
@onready var turrets_label: Label = $HUD/TurretsLabel
@onready var selected_label: Label = $HUD/SelectedLabel
@onready var build_bar: Control = $HUD/BuildBar
@onready var type_info_panel: Control = $HUD/TypeInfoPanel
@onready var unit_inspector: Control = $HUD/UnitInspector
@onready var btn_repair: Button = $HUD/AbilityBar/BtnRepair
@onready var btn_slow: Button = $HUD/AbilityBar/BtnSlow
@onready var repair_cd_overlay: ColorRect = $HUD/AbilityBar/BtnRepair/CdOverlay
@onready var repair_cd_label: Label = $HUD/AbilityBar/BtnRepair/CdLabel
@onready var slow_cd_overlay: ColorRect = $HUD/AbilityBar/BtnSlow/CdOverlay
@onready var slow_cd_label: Label = $HUD/AbilityBar/BtnSlow/CdLabel
@onready var result_overlay: Control = $HUD/ResultOverlay
@onready var result_title: Label = $HUD/ResultOverlay/Center/ResultTitle
@onready var result_stars_label: Label = $HUD/ResultOverlay/Center/StarsLabel
@onready var restart_button: Button = $HUD/ResultOverlay/Center/RestartButton
@onready var result_menu_button: Button = $HUD/ResultOverlay/Center/MenuButton
@onready var pause_button: Button = $HUD/PauseButton
@onready var pause_overlay: Control = $HUD/PauseOverlay
@onready var resume_button: Button = $HUD/PauseOverlay/Center/ResumeButton
@onready var pause_restart_button: Button = $HUD/PauseOverlay/Center/RestartButton
@onready var pause_menu_button: Button = $HUD/PauseOverlay/Center/MenuButton
@onready var pause_mute_button: Button = $HUD/PauseOverlay/Center/MuteButton
@onready var pause_retire_button: Button = $HUD/PauseOverlay/Center/RetireButton
@onready var camera: Camera3D = $Camera3D
@onready var wave_manager: Node = $WaveManager

var _game_over: bool = false
var _placed_units: Array[Node3D] = []
## -1 = no place mode (ghost hidden).
var _selected_type: int = -1
var _scrap: int = 0
var _current_wave: int = 0
var _turret_damage_mult: float = 1.0
var _build_cost_mult: float = 1.0

var _ghost: Node3D
var _ghost_sprite: Sprite3D
var _ghost_mesh: MeshInstance3D
var _ghost_mod_valid: Color = Color(0.35, 1.0, 0.65, 0.55)
var _ghost_mod_invalid: Color = Color(1.0, 0.32, 0.28, 0.55)
var _touch_tracking: bool = false
var _active_touch_index: int = -1

var _camera_base_pos: Vector3
var _shake_time: float = 0.0
var _shake_strength: float = 0.0
var _turrets_label_base_modulate: Color = Color.WHITE
var _scrap_label_base_modulate: Color = Color.WHITE

## Active abilities (portrait HUD).
var _ability_cd_mult: float = 1.0
var _repair_cd_left: float = 0.0
var _repair_charges_left: int = 0
var _repair_cd_max: float = 32.0
var _slow_cd_left: float = 0.0
var _slow_cd_max: float = 30.0
var _slow_active_left: float = 0.0


func _ready() -> void:
	camera.current = true
	_camera_base_pos = camera.position
	_turrets_label_base_modulate = turrets_label.modulate
	_scrap_label_base_modulate = scrap_label.modulate
	_apply_meta_bonuses()
	_scrap = start_scrap
	_init_abilities()
	result_overlay.visible = false
	if has_node("HUD/EndlessOverlay"):
		$HUD/EndlessOverlay.visible = false
	pause_overlay.visible = false
	get_tree().paused = false
	restart_button.pressed.connect(_on_restart_pressed)
	result_menu_button.pressed.connect(_on_main_menu_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	pause_restart_button.pressed.connect(_on_restart_pressed)
	pause_menu_button.pressed.connect(_on_main_menu_pressed)
	pause_mute_button.pressed.connect(_on_pause_mute_pressed)
	if pause_retire_button:
		pause_retire_button.pressed.connect(_on_retire_pressed)
	btn_repair.pressed.connect(_on_repair_pressed)
	btn_slow.pressed.connect(_on_slow_pressed)

	if unit_inspector.has_method("set_camera"):
		unit_inspector.set_camera(camera)
	build_bar.type_selected.connect(_on_build_type_selected)
	build_bar.type_deselected.connect(_on_build_type_deselected)
	build_bar.type_info_requested.connect(_on_type_info_requested)
	type_info_panel.closed.connect(_on_type_info_closed)
	unit_inspector.closed.connect(_on_inspector_closed)
	unit_inspector.sell_pressed.connect(_on_inspector_sell)
	unit_inspector.upgrade_pressed.connect(_on_inspector_upgrade)

	_refresh_pause_mute_label()
	_setup_ghost()
	_refresh_build_bar_economy()
	_update_hint_label()
	_update_units_label()
	_update_scrap_label()
	_refresh_ability_ui()

	if wall.has_signal("hp_changed"):
		wall.hp_changed.connect(_on_wall_hp_changed)
	if wall.has_signal("destroyed"):
		wall.destroyed.connect(_on_wall_destroyed)
	if wall.has_signal("damaged"):
		wall.damaged.connect(_on_wall_damaged)

	_on_wall_hp_changed(wall.current_hp, wall.max_hp)

	wave_manager.setup(self, wall, spawn_point, {
		"basic": zombie_scene,
		"runner": zombie_runner_scene,
		"brute": zombie_brute_scene,
	})
	wave_manager.wave_changed.connect(_on_wave_changed)
	wave_manager.status_changed.connect(_on_wave_status)
	wave_manager.enemy_killed.connect(_on_enemy_killed)
	wave_manager.between_waves.connect(_on_between_waves)
	wave_manager.start_waves()


func _process(delta: float) -> void:
	_update_camera_shake(delta)
	_update_abilities(delta)
	if Engine.get_process_frames() % 30 == 0:
		_prune_placed()


func _unhandled_input(event: InputEvent) -> void:
	if _game_over or result_overlay.visible or pause_overlay.visible or get_tree().paused:
		_hide_ghost()
		_touch_tracking = false
		_active_touch_index = -1
		return
	if type_info_panel.visible:
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touch_tracking = true
			_active_touch_index = touch.index
			if _is_placing():
				_update_ghost_at(touch.position)
			else:
				_hide_ghost()
		elif touch.index == _active_touch_index:
			_handle_tap(touch.position)
			_touch_tracking = false
			_active_touch_index = -1
			if not _is_placing():
				_hide_ghost()
		return

	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _touch_tracking and drag.index == _active_touch_index and _is_placing():
			_update_ghost_at(drag.position)
		return

	if event is InputEventMouseMotion and not _touch_tracking:
		if _is_placing():
			_update_ghost_at((event as InputEventMouseMotion).position)
		else:
			_hide_ghost()
		return

	if event is InputEventMouseButton and not _touch_tracking:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			_handle_tap(mouse.position)
			if _is_placing():
				_update_ghost_at(mouse.position)


func _is_placing() -> bool:
	return _selected_type >= 0


func _handle_tap(screen_pos: Vector2) -> void:
	# Prefer inspecting an existing unit when not placing (or when tapping near one).
	var near := _find_unit_near(screen_pos)
	if near != null:
		if _is_placing():
			# Opening inspector cancels place mode (clean UX).
			_cancel_place_mode()
		_open_inspector(near)
		return

	if unit_inspector.is_open():
		# Empty tap closes inspector; does not place while inspector was open.
		unit_inspector.hide_inspector()
		_update_hint_label()
		return

	if _is_placing():
		var ground_pos: Variant = _raycast_ground(screen_pos)
		if typeof(ground_pos) == TYPE_VECTOR3:
			var pos := ground_pos as Vector3
			if _is_in_placement_zone(pos) and _is_far_enough(pos):
				_try_place(pos)
				return
		# Invalid / empty tap cancels place mode.
		_cancel_place_mode()
		return


func _cancel_place_mode() -> void:
	_selected_type = -1
	_hide_ghost()
	if build_bar.has_method("clear_selection"):
		build_bar.clear_selection()
	_update_hint_label()


func _on_build_type_selected(type_id: int) -> void:
	if unit_inspector.is_open():
		unit_inspector.hide_inspector()
	if type_info_panel.visible and type_info_panel.get_open_type() != type_id:
		type_info_panel.hide_panel()
	_selected_type = type_id
	_rebuild_ghost_meshes()
	_update_hint_label()


func _on_build_type_deselected() -> void:
	_selected_type = -1
	_hide_ghost()
	_update_hint_label()


func _on_type_info_requested(type_id: int) -> void:
	type_info_panel.toggle(type_id, _cost_for(type_id))


func _on_type_info_closed() -> void:
	pass


func _on_inspector_closed() -> void:
	_update_hint_label()


func _open_inspector(unit: Node3D) -> void:
	var type_id: int = PlaceableCatalog.resolve_unit_id(unit)
	unit_inspector.show_unit(
		unit,
		type_id,
		_scrap,
		_sell_refund_for(unit),
		_upgrade_cost_for(unit)
	)
	_update_hint_label()


func _on_inspector_sell() -> void:
	var unit: Node3D = unit_inspector.get_target() as Node3D
	if unit == null:
		return
	var refund := _sell_refund_for(unit)
	unit_inspector.hide_inspector()
	_placed_units.erase(unit)
	unit.queue_free()
	_update_units_label()
	_add_scrap(refund)
	if Sfx:
		Sfx.play_hit()
	turrets_label.modulate = Color(1.0, 0.75, 0.45, 1.0)
	var tween := create_tween()
	tween.tween_property(turrets_label, "modulate", _turrets_label_base_modulate, 0.35)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_refresh_build_bar_economy()
	_update_hint_label()


func _on_inspector_upgrade() -> void:
	var unit: Node3D = unit_inspector.get_target() as Node3D
	if unit == null:
		return
	if unit.has_method("can_upgrade") and not unit.can_upgrade():
		_flash_cannot_afford()
		return
	var cost := _upgrade_cost_for(unit)
	if _scrap < cost:
		_flash_cannot_afford()
		return
	_scrap -= cost
	_update_scrap_label()
	if unit.has_method("apply_upgrade"):
		unit.apply_upgrade()
	if Sfx:
		Sfx.play_place()
	turrets_label.modulate = Color(0.7, 0.9, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(turrets_label, "modulate", _turrets_label_base_modulate, 0.35)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_open_inspector(unit)
	_refresh_build_bar_economy()


func _update_hint_label() -> void:
	if unit_inspector.is_open():
		selected_label.text = "Inspector open — Sell / Upgrade, or tap empty to close"
	elif _is_placing():
		selected_label.text = "Place %s (%d) — tap zone · same button / empty cancels" % [
			PlaceableCatalog.display_name(_selected_type),
			_cost_for(_selected_type),
		]
	else:
		selected_label.text = "Select a defense below · tap a placed unit to inspect"


func _scene_for(t: int) -> PackedScene:
	match t:
		PlaceableCatalog.Id.BASIC:
			return turret_scene
		PlaceableCatalog.Id.CANNON:
			return turret_cannon_scene
		PlaceableCatalog.Id.SUPPORT:
			return support_scene
		PlaceableCatalog.Id.TESLA:
			return turret_tesla_scene
		PlaceableCatalog.Id.SNIPER:
			return turret_sniper_scene
		PlaceableCatalog.Id.MINE:
			return mine_scene
		PlaceableCatalog.Id.BARRICADE:
			return barricade_scene
	return null


func _base_cost_for(t: int) -> int:
	match t:
		PlaceableCatalog.Id.BASIC:
			return basic_turret_cost
		PlaceableCatalog.Id.CANNON:
			return cannon_turret_cost
		PlaceableCatalog.Id.SUPPORT:
			return support_cost
		PlaceableCatalog.Id.TESLA:
			return tesla_cost
		PlaceableCatalog.Id.SNIPER:
			return sniper_cost
		PlaceableCatalog.Id.MINE:
			return mine_cost
		PlaceableCatalog.Id.BARRICADE:
			return barricade_cost
	return 50


func _cost_for(t: int) -> int:
	return maxi(1, int(floor(float(_base_cost_for(t)) * _build_cost_mult)))


func _can_afford(t: int) -> bool:
	return _scrap >= _cost_for(t)


func _unit_base_cost(unit: Node3D) -> int:
	if "base_cost" in unit:
		return int(unit.get("base_cost"))
	return basic_turret_cost


func _upgrade_cost_for(unit: Node3D) -> int:
	if "upgrade_cost" in unit:
		return maxi(1, int(floor(float(unit.get("upgrade_cost")) * _build_cost_mult)))
	return basic_upgrade_cost


func _sell_refund_for(unit: Node3D) -> int:
	return int(floor(float(_unit_base_cost(unit)) * SELL_REFUND_RATIO))


func _refresh_build_bar_economy() -> void:
	var costs := {}
	var afford := {}
	for id in PlaceableCatalog.ALL_IDS:
		costs[id] = _cost_for(id)
		afford[id] = _can_afford(id)
	build_bar.setup_costs(costs)
	build_bar.set_affordability(afford)


func _setup_ghost() -> void:
	_ghost = Node3D.new()
	_ghost.name = "PlaceGhost"
	_ghost.visible = false
	add_child(_ghost)


func _rebuild_ghost_meshes() -> void:
	if _ghost == null or not _is_placing():
		return

	for child in _ghost.get_children():
		_ghost.remove_child(child)
		child.free()
	_ghost_sprite = null
	_ghost_mesh = null

	match _selected_type:
		PlaceableCatalog.Id.MINE:
			_build_ghost_cylinder(0.55, 0.18, Color(0.85, 0.25, 0.18, 0.55))
		PlaceableCatalog.Id.BARRICADE:
			_build_ghost_box(Vector3(2.6, 1.1, 0.35), Color(0.45, 0.38, 0.3, 0.55))
		_:
			_build_ghost_sprite()

	if _ghost.visible:
		var pos := _ghost.global_position
		if _is_far_enough(pos) and _can_afford(_selected_type):
			_apply_ghost_tint(_ghost_mod_valid)
		else:
			_apply_ghost_tint(_ghost_mod_invalid)
	else:
		_apply_ghost_tint(_ghost_mod_valid)


func _build_ghost_sprite() -> void:
	var tex_path := GHOST_BASIC_TEX
	var pixel_size := 0.00235
	var sprite_y := 0.95
	var mod := Color(1, 1, 1, 1)
	match _selected_type:
		PlaceableCatalog.Id.CANNON:
			tex_path = GHOST_CANNON_TEX
			pixel_size = 0.0029
			sprite_y = 1.15
		PlaceableCatalog.Id.SUPPORT:
			mod = Color(0.45, 1.0, 0.55, 1.0)
			pixel_size = 0.0021
			sprite_y = 0.85
		PlaceableCatalog.Id.TESLA:
			mod = Color(0.35, 0.85, 1.0, 1.0)
		PlaceableCatalog.Id.SNIPER:
			tex_path = GHOST_CANNON_TEX
			mod = Color(0.75, 0.45, 1.0, 1.0)
			pixel_size = 0.0027
			sprite_y = 1.2

	var sprite := Sprite3D.new()
	sprite.name = "GhostSprite"
	sprite.texture = load(tex_path) as Texture2D
	sprite.pixel_size = pixel_size
	sprite.position = Vector3(0.0, sprite_y, 0.0)
	sprite.rotation_degrees = Vector3(-25.0, 0.0, 0.0)
	sprite.shaded = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.modulate = mod
	_ghost.add_child(sprite)
	_ghost_sprite = sprite


func _build_ghost_cylinder(radius: float, height: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var mi := MeshInstance3D.new()
	mi.name = "GhostMesh"
	mi.mesh = mesh
	mi.position = Vector3(0.0, height * 0.5, 0.0)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	_ghost.add_child(mi)
	_ghost_mesh = mi


func _build_ghost_box(size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.name = "GhostMesh"
	mi.mesh = mesh
	mi.position = Vector3(0.0, size.y * 0.5, 0.0)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	_ghost.add_child(mi)
	_ghost_mesh = mi


func _apply_ghost_tint(mod: Color) -> void:
	if _ghost_sprite != null:
		_ghost_sprite.modulate = mod
	if _ghost_mesh != null and _ghost_mesh.material_override is StandardMaterial3D:
		var m := _ghost_mesh.material_override as StandardMaterial3D
		m.albedo_color = Color(mod.r, mod.g, mod.b, mod.a)


func _hide_ghost() -> void:
	if _ghost != null:
		_ghost.visible = false


func _update_ghost_at(screen_pos: Vector2) -> void:
	if not _is_placing():
		_hide_ghost()
		return

	if _selected_type == PlaceableCatalog.Id.SUPPORT and _support_count() >= max_supports:
		_hide_ghost()
		return

	var ground_pos: Variant = _raycast_ground(screen_pos)
	if typeof(ground_pos) != TYPE_VECTOR3:
		_hide_ghost()
		return

	var pos := ground_pos as Vector3
	if not _is_in_placement_zone(pos):
		_hide_ghost()
		return

	_ghost.visible = true
	_ghost.global_position = Vector3(pos.x, _place_y_for_selected(), pos.z)
	if _is_far_enough(pos) and _can_afford(_selected_type):
		_apply_ghost_tint(_ghost_mod_valid)
	else:
		_apply_ghost_tint(_ghost_mod_invalid)


func _raycast_ground(screen_pos: Vector2) -> Variant:
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.0001:
		return null
	var t := -from.y / dir.y
	if t < 0.0:
		return null
	return from + dir * t


func _find_unit_near(screen_pos: Vector2) -> Node3D:
	var ground_pos: Variant = _raycast_ground(screen_pos)
	if typeof(ground_pos) != TYPE_VECTOR3:
		return null

	var pos := ground_pos as Vector3
	var nearest: Node3D = null
	var best := interact_tap_radius
	for unit in _placed_units:
		if not is_instance_valid(unit):
			continue
		var flat := Vector3(unit.global_position.x, 0.0, unit.global_position.z)
		var dist := Vector3(pos.x, 0.0, pos.z).distance_to(flat)
		if dist <= best:
			best = dist
			nearest = unit
	return nearest


func _try_place(pos: Vector3) -> void:
	if not _is_placing():
		return

	var scene := _scene_for(_selected_type)
	if scene == null:
		push_error("Battle: selected placeable scene is not assigned")
		return

	if not _is_in_placement_zone(pos):
		return

	if not _is_far_enough(pos):
		return

	if _selected_type == PlaceableCatalog.Id.SUPPORT and _support_count() >= max_supports:
		_flash_cannot_afford()
		return

	var cost := _cost_for(_selected_type)
	if _scrap < cost:
		_flash_cannot_afford()
		return

	_scrap -= cost
	_update_scrap_label()

	var unit: Node3D = scene.instantiate()
	add_child(unit)
	unit.global_position = Vector3(pos.x, _place_y_for_selected(), pos.z)
	if "unit_kind" in unit:
		unit.set("unit_kind", PlaceableCatalog.kind_for(_selected_type))
	if unit.has_method("setup_economy"):
		unit.setup_economy(cost)
	if "upgrade_cost" in unit:
		match _selected_type:
			PlaceableCatalog.Id.BASIC:
				unit.set("upgrade_cost", basic_upgrade_cost)
			PlaceableCatalog.Id.CANNON:
				unit.set("upgrade_cost", cannon_upgrade_cost)
			PlaceableCatalog.Id.SUPPORT:
				unit.set("upgrade_cost", support_upgrade_cost)
			PlaceableCatalog.Id.TESLA:
				unit.set("upgrade_cost", tesla_upgrade_cost)
			PlaceableCatalog.Id.SNIPER:
				unit.set("upgrade_cost", sniper_upgrade_cost)
			PlaceableCatalog.Id.BARRICADE:
				unit.set("upgrade_cost", barricade_upgrade_cost)
	_apply_meta_damage_to_turret(unit)
	if unit.has_signal("scrap_drip"):
		unit.scrap_drip.connect(_add_scrap)
	unit.tree_exited.connect(_on_unit_tree_exited.bind(unit))
	_placed_units.append(unit)
	_update_units_label()
	_play_place_feedback(unit)
	_refresh_build_bar_economy()


func _on_unit_tree_exited(unit: Node3D) -> void:
	_placed_units.erase(unit)
	_update_units_label()
	if unit_inspector.is_open() and unit_inspector.get_target() == unit:
		unit_inspector.hide_inspector()


func _is_wall_defense(t: int) -> bool:
	return PlaceableCatalog.is_wall_defense(t)


func _place_y_for_selected() -> float:
	if _is_wall_defense(_selected_type):
		if wall != null and wall.has_method("get_rampart_y"):
			return float(wall.call("get_rampart_y"))
		return wall_place_y
	return 0.0


func _is_in_placement_zone(pos: Vector3) -> bool:
	if pos.x < placement_x_min or pos.x > placement_x_max:
		return false
	if _is_wall_defense(_selected_type):
		var z0 := wall_z_min if wall_z_min > 0.0 else placement_z_min
		var z1 := wall_z_max if wall_z_max > 0.0 else placement_z_max
		return pos.z >= z0 and pos.z <= z1
	if _selected_type == PlaceableCatalog.Id.MINE:
		return pos.z >= mine_z_min and pos.z <= approach_z_max
	if _selected_type == PlaceableCatalog.Id.BARRICADE:
		return pos.z >= fence_z_min and pos.z <= approach_z_max
	return false


func _is_far_enough(pos: Vector3) -> bool:
	for unit in _placed_units:
		if not is_instance_valid(unit):
			continue
		var flat := Vector3(pos.x, 0.0, pos.z)
		var other := Vector3(unit.global_position.x, 0.0, unit.global_position.z)
		if flat.distance_to(other) < min_place_distance:
			return false
	return true


func _support_count() -> int:
	var n := 0
	for unit in _placed_units:
		if is_instance_valid(unit) and unit.is_in_group("supports"):
			n += 1
	return n


func _prune_placed() -> void:
	var before := _placed_units.size()
	_placed_units = _placed_units.filter(func(t): return is_instance_valid(t))
	if _placed_units.size() != before:
		_update_units_label()


func _update_units_label() -> void:
	_placed_units = _placed_units.filter(func(t): return is_instance_valid(t))
	turrets_label.text = "Units: %d" % _placed_units.size()


func _update_scrap_label() -> void:
	scrap_label.text = "Scrap: %d" % _scrap
	_refresh_build_bar_economy()
	if unit_inspector.is_open():
		var u: Node3D = unit_inspector.get_target() as Node3D
		if u != null:
			_open_inspector(u)


func _add_scrap(amount: int) -> void:
	if amount <= 0 or _game_over:
		return
	_scrap += amount
	_update_scrap_label()
	scrap_label.modulate = Color(0.75, 1.0, 0.55, 1.0)
	var tween := create_tween()
	tween.tween_property(scrap_label, "modulate", _scrap_label_base_modulate, 0.3)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _flash_cannot_afford() -> void:
	scrap_label.modulate = Color(1.0, 0.35, 0.3, 1.0)
	var tween := create_tween()
	tween.tween_property(scrap_label, "modulate", _scrap_label_base_modulate, 0.35)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_enemy_killed(scrap_amount: int) -> void:
	_add_scrap(scrap_amount)


func _on_between_waves() -> void:
	var amount := scrap_between_waves + endless_scrap_bump * maxi(0, _current_wave - 5)
	_add_scrap(amount)


func _play_place_feedback(unit: Node3D) -> void:
	if unit.has_method("play_place_pulse"):
		unit.play_place_pulse()
	if Sfx:
		Sfx.play_place()

	turrets_label.modulate = Color(0.55, 1.0, 0.7, 1.0)
	var tween := create_tween()
	tween.tween_property(turrets_label, "modulate", _turrets_label_base_modulate, 0.35)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_wall_hp_changed(current_hp: int, max_hp: int) -> void:
	hp_label.text = "Wall HP: %d / %d" % [current_hp, max_hp]


func _on_wall_damaged(_amount: int) -> void:
	_shake_time = 0.14
	_shake_strength = 0.12
	hp_label.modulate = Color(1.0, 0.45, 0.4, 1.0)
	var tween := create_tween()
	tween.tween_property(hp_label, "modulate", Color.WHITE, 0.28)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _update_camera_shake(delta: float) -> void:
	if _shake_time <= 0.0:
		camera.position = _camera_base_pos
		return
	_shake_time = maxf(0.0, _shake_time - delta)
	var falloff := clampf(_shake_time / 0.14, 0.0, 1.0)
	var s := _shake_strength * falloff
	camera.position = _camera_base_pos + Vector3(
		randf_range(-s, s),
		randf_range(-s * 0.5, s * 0.5),
		randf_range(-s, s)
	)


func _on_wave_changed(current_wave: int, _total_waves: int) -> void:
	_current_wave = current_wave
	wave_label.text = "Wave %d" % current_wave


func _on_wave_status(text: String) -> void:
	wave_label.text = text


func _on_wall_destroyed() -> void:
	_show_result(false, false)


func _on_retire_pressed() -> void:
	if _game_over:
		return
	pause_overlay.visible = false
	_set_paused(false)
	_show_result(true, true)


func _show_result(is_retire: bool, _from_retire_btn: bool = false) -> void:
	if _game_over:
		return
	_game_over = true
	_slow_active_left = 0.0
	_clear_slow_on_zombies()
	wave_manager.stop_waves()
	_hide_ghost()
	_cancel_place_mode()
	if unit_inspector.is_open():
		unit_inspector.hide_inspector()
	if type_info_panel.visible:
		type_info_panel.hide_panel()
	_shake_time = 0.0
	camera.position = _camera_base_pos
	_set_paused(false)
	pause_overlay.visible = false
	if has_node("HUD/EndlessOverlay"):
		$HUD/EndlessOverlay.visible = false
	pause_button.visible = false
	_refresh_ability_ui()

	var earned := _award_run_stars(is_retire)
	if is_retire:
		result_title.text = "RETIRED"
	else:
		result_title.text = "DEFEAT"
	if result_stars_label:
		result_stars_label.text = "+%d Stars · Wave %d" % [earned, maxi(1, _current_wave)]
		result_stars_label.visible = true
	result_overlay.visible = true
	if Sfx:
		if is_retire:
			Sfx.play_victory()
		else:
			Sfx.play_defeat()


func _apply_meta_bonuses() -> void:
	if MetaProgress == null:
		_turret_damage_mult = 1.0
		_ability_cd_mult = 1.0
		_build_cost_mult = 1.0
		return
	start_scrap += MetaProgress.get_start_scrap_bonus()
	_turret_damage_mult = MetaProgress.get_turret_damage_mult()
	_ability_cd_mult = MetaProgress.get_ability_cd_mult()
	_build_cost_mult = MetaProgress.get_build_cost_mult()
	if wall.has_method("apply_max_hp_bonus"):
		wall.apply_max_hp_bonus(MetaProgress.get_wall_hp_bonus())


func _init_abilities() -> void:
	_repair_charges_left = repair_charges
	_repair_cd_max = repair_cooldown * _ability_cd_mult
	_slow_cd_max = slow_cooldown * _ability_cd_mult
	_repair_cd_left = 0.0
	_slow_cd_left = 0.0
	_slow_active_left = 0.0


func _update_abilities(delta: float) -> void:
	if _game_over:
		return
	var dirty := false
	if _repair_cd_left > 0.0:
		_repair_cd_left = maxf(0.0, _repair_cd_left - delta)
		dirty = true
	if _slow_cd_left > 0.0:
		_slow_cd_left = maxf(0.0, _slow_cd_left - delta)
		dirty = true
	if _slow_active_left > 0.0:
		_slow_active_left = maxf(0.0, _slow_active_left - delta)
		if _slow_active_left <= 0.0:
			_clear_slow_on_zombies()
		else:
			_apply_slow_to_zombies()
		dirty = true
	if dirty:
		_refresh_ability_ui()


func _abilities_blocked() -> bool:
	return _game_over or result_overlay.visible or pause_overlay.visible or get_tree().paused


func _on_repair_pressed() -> void:
	if _abilities_blocked():
		return
	if _repair_charges_left <= 0 or _repair_cd_left > 0.0:
		return
	if not wall.has_method("repair"):
		return
	if wall.current_hp <= 0 or wall.current_hp >= wall.max_hp:
		_flash_cannot_afford()
		return

	var healed: int = wall.repair(repair_heal)
	if healed <= 0:
		return

	_repair_charges_left -= 1
	_repair_cd_left = _repair_cd_max
	hp_label.modulate = Color(0.45, 1.0, 0.55, 1.0)
	var tween := create_tween()
	tween.tween_property(hp_label, "modulate", Color.WHITE, 0.35)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if Sfx:
		Sfx.play_ability_repair()
	_refresh_ability_ui()


func _on_slow_pressed() -> void:
	if _abilities_blocked():
		return
	if _slow_cd_left > 0.0:
		return

	_slow_cd_left = _slow_cd_max
	_slow_active_left = slow_duration
	_apply_slow_to_zombies()
	if Sfx:
		Sfx.play_ability_slow()
	_refresh_ability_ui()


func _apply_slow_to_zombies() -> void:
	for node in get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(node) and node.has_method("set_speed_mult"):
			node.set_speed_mult(slow_speed_mult)


func _clear_slow_on_zombies() -> void:
	for node in get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(node) and node.has_method("set_speed_mult"):
			node.set_speed_mult(1.0)


func _refresh_ability_ui() -> void:
	if btn_repair == null or btn_slow == null:
		return

	var repair_ready := _repair_charges_left > 0 and _repair_cd_left <= 0.0 and not _game_over
	btn_repair.disabled = not repair_ready
	if _repair_cd_left > 0.0:
		btn_repair.text = "REPAIR"
		repair_cd_label.text = "%d" % ceili(_repair_cd_left)
		repair_cd_label.visible = true
		repair_cd_overlay.visible = true
		repair_cd_overlay.modulate.a = clampf(_repair_cd_left / maxf(_repair_cd_max, 0.01), 0.35, 0.72)
	elif _repair_charges_left <= 0:
		btn_repair.text = "REPAIR\n0"
		repair_cd_label.text = "0"
		repair_cd_label.visible = true
		repair_cd_overlay.visible = true
		repair_cd_overlay.modulate.a = 0.55
	else:
		btn_repair.text = "REPAIR\n×%d" % _repair_charges_left
		repair_cd_label.visible = false
		repair_cd_overlay.visible = false

	var slow_ready := _slow_cd_left <= 0.0 and not _game_over
	btn_slow.disabled = not slow_ready
	if _slow_cd_left > 0.0:
		btn_slow.text = "SLOW"
		slow_cd_label.text = "%d" % ceili(_slow_cd_left)
		slow_cd_label.visible = true
		slow_cd_overlay.visible = true
		slow_cd_overlay.modulate.a = clampf(_slow_cd_left / maxf(_slow_cd_max, 0.01), 0.35, 0.72)
	elif _slow_active_left > 0.0:
		btn_slow.text = "SLOW\nON"
		slow_cd_label.text = "%.1f" % _slow_active_left
		slow_cd_label.visible = true
		slow_cd_overlay.visible = false
	else:
		btn_slow.text = "SLOW"
		slow_cd_label.visible = false
		slow_cd_overlay.visible = false


func _apply_meta_damage_to_turret(unit: Node3D) -> void:
	if _turret_damage_mult <= 1.0001:
		return
	if "damage" in unit and unit.is_in_group("turrets"):
		var base_dmg := int(unit.get("damage"))
		unit.set("damage", maxi(1, int(round(float(base_dmg) * _turret_damage_mult))))


func _award_run_stars(is_retire: bool) -> int:
	if MetaProgress == null:
		return 0
	var waves := maxi(1, _current_wave)
	var earned := MetaProgress.calc_run_stars(waves)
	if is_retire and wall.max_hp > 0 and wall.current_hp > 0:
		var ratio := float(wall.current_hp) / float(wall.max_hp)
		earned += int(floor(ratio * float(MetaProgress.VICTORY_HP_BONUS_MAX)))
	if DifficultySettings:
		earned = DifficultySettings.scale_stars(earned, is_retire)
	MetaProgress.add_stars(earned)
	return earned


func _on_pause_pressed() -> void:
	if _game_over or result_overlay.visible:
		return
	_hide_ghost()
	_touch_tracking = false
	_active_touch_index = -1
	pause_overlay.visible = true
	_refresh_pause_mute_label()
	_set_paused(true)


func _on_resume_pressed() -> void:
	pause_overlay.visible = false
	_set_paused(false)


func _on_restart_pressed() -> void:
	_set_paused(false)
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	_set_paused(false)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_pause_mute_pressed() -> void:
	if Sfx:
		Sfx.set_muted(not Sfx.is_muted())
	_refresh_pause_mute_label()


func _refresh_pause_mute_label() -> void:
	var muted := Sfx != null and Sfx.is_muted()
	pause_mute_button.text = "SOUND: OFF" if muted else "SOUND: ON"


func _set_paused(value: bool) -> void:
	get_tree().paused = value
