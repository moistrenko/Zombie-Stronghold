extends Node3D

## Tap/click ground (XZ, y=0) to place turrets in the wall strip.
## Modes: BUILD (ghost place) / UPGRADE / SELL — mutually exclusive HUD toggles.
## Ghost preview: mouse move / touch drag; place on mouse click or touch release.
## HUD buttons select Basic vs Cannon before placing (shared max_turrets + Scrap cost).

enum TurretType { BASIC, CANNON }
enum InteractMode { BUILD, UPGRADE, SELL }

const MAIN_MENU_SCENE := "res://scenes/menus/main_menu.tscn"
## Sell refund = floor(base_cost * SELL_REFUND_RATIO). Upgrade scrap is not refunded.
const SELL_REFUND_RATIO := 0.55

@export var zombie_scene: PackedScene
@export var zombie_runner_scene: PackedScene
@export var zombie_brute_scene: PackedScene
@export var turret_scene: PackedScene
@export var turret_cannon_scene: PackedScene
@export var max_turrets: int = 3
@export var min_turret_distance: float = 2.0
@export var placement_z_min: float = 2.0
@export var placement_z_max: float = 5.5
@export var placement_x_min: float = -6.0
@export var placement_x_max: float = 6.0
@export var start_scrap: int = 100
@export var basic_turret_cost: int = 50
@export var cannon_turret_cost: int = 90
@export var scrap_between_waves: int = 12
@export var basic_upgrade_cost: int = 30
@export var cannon_upgrade_cost: int = 50
@export var interact_tap_radius: float = 1.9

@onready var wall: Node3D = $Wall
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var hp_label: Label = $HUD/HpLabel
@onready var wave_label: Label = $HUD/WaveLabel
@onready var scrap_label: Label = $HUD/ScrapLabel
@onready var turrets_label: Label = $HUD/TurretsLabel
@onready var selected_label: Label = $HUD/SelectedLabel
@onready var btn_basic: Button = $HUD/TypeBar/BtnBasic
@onready var btn_cannon: Button = $HUD/TypeBar/BtnCannon
@onready var btn_mode_build: Button = $HUD/ModeBar/BtnBuild
@onready var btn_mode_upgrade: Button = $HUD/ModeBar/BtnUpgrade
@onready var btn_mode_sell: Button = $HUD/ModeBar/BtnSell
@onready var type_bar: HBoxContainer = $HUD/TypeBar
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
@onready var camera: Camera3D = $Camera3D
@onready var wave_manager: Node = $WaveManager

var _game_over: bool = false
var _waves_finished: bool = false
var _placed_turrets: Array[Node3D] = []
var _selected_type: TurretType = TurretType.BASIC
var _mode: InteractMode = InteractMode.BUILD
var _scrap: int = 0
var _current_wave: int = 0
var _turret_damage_mult: float = 1.0

var _ghost: Node3D
var _ghost_meshes: Array[MeshInstance3D] = []
var _mat_valid: StandardMaterial3D
var _mat_invalid: StandardMaterial3D
var _touch_tracking: bool = false
var _active_touch_index: int = -1

var _camera_base_pos: Vector3
var _shake_time: float = 0.0
var _shake_strength: float = 0.0
var _turrets_label_base_modulate: Color = Color.WHITE
var _scrap_label_base_modulate: Color = Color.WHITE


func _ready() -> void:
	camera.current = true
	_camera_base_pos = camera.position
	_turrets_label_base_modulate = turrets_label.modulate
	_scrap_label_base_modulate = scrap_label.modulate
	_apply_meta_bonuses()
	_scrap = start_scrap
	result_overlay.visible = false
	pause_overlay.visible = false
	get_tree().paused = false
	restart_button.pressed.connect(_on_restart_pressed)
	result_menu_button.pressed.connect(_on_main_menu_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	pause_restart_button.pressed.connect(_on_restart_pressed)
	pause_menu_button.pressed.connect(_on_main_menu_pressed)
	pause_mute_button.pressed.connect(_on_pause_mute_pressed)
	btn_basic.pressed.connect(_on_select_basic)
	btn_cannon.pressed.connect(_on_select_cannon)
	btn_mode_build.pressed.connect(_on_mode_build)
	btn_mode_upgrade.pressed.connect(_on_mode_upgrade)
	btn_mode_sell.pressed.connect(_on_mode_sell)
	_refresh_pause_mute_label()
	_setup_ghost()
	_refresh_mode_ui()
	_update_turrets_label()
	_update_scrap_label()

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
	wave_manager.waves_finished.connect(_on_waves_finished)
	wave_manager.enemy_killed.connect(_on_enemy_killed)
	wave_manager.between_waves.connect(_on_between_waves)
	wave_manager.start_waves()


func _process(delta: float) -> void:
	_update_camera_shake(delta)

	if _game_over:
		return
	if _waves_finished and get_tree().get_nodes_in_group("zombies").is_empty():
		_show_result(true)


func _unhandled_input(event: InputEvent) -> void:
	if _game_over or result_overlay.visible or pause_overlay.visible or get_tree().paused:
		_hide_ghost()
		_touch_tracking = false
		_active_touch_index = -1
		return

	# Touch: press/drag = ghost (BUILD only); release = place / upgrade / sell.
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touch_tracking = true
			_active_touch_index = touch.index
			if _mode == InteractMode.BUILD:
				_update_ghost_at(touch.position)
			else:
				_hide_ghost()
		elif touch.index == _active_touch_index:
			_handle_tap(touch.position)
			_touch_tracking = false
			_active_touch_index = -1
			_hide_ghost()
		return

	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _touch_tracking and drag.index == _active_touch_index and _mode == InteractMode.BUILD:
			_update_ghost_at(drag.position)
		return

	# Mouse: move = ghost; left click = place / upgrade / sell (editor / desktop).
	if event is InputEventMouseMotion and not _touch_tracking:
		if _mode == InteractMode.BUILD:
			_update_ghost_at((event as InputEventMouseMotion).position)
		else:
			_hide_ghost()
		return

	if event is InputEventMouseButton and not _touch_tracking:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			_handle_tap(mouse.position)
			if _mode == InteractMode.BUILD:
				_update_ghost_at(mouse.position)


func _handle_tap(screen_pos: Vector2) -> void:
	match _mode:
		InteractMode.BUILD:
			var ground_pos: Variant = _raycast_ground(screen_pos)
			if typeof(ground_pos) == TYPE_VECTOR3:
				_try_place_turret(ground_pos as Vector3)
		InteractMode.UPGRADE:
			_try_upgrade_at(screen_pos)
		InteractMode.SELL:
			_try_sell_at(screen_pos)


func _on_select_basic() -> void:
	_selected_type = TurretType.BASIC
	if _mode != InteractMode.BUILD:
		_set_mode(InteractMode.BUILD)
	else:
		_refresh_type_ui()
		_rebuild_ghost_meshes()


func _on_select_cannon() -> void:
	_selected_type = TurretType.CANNON
	if _mode != InteractMode.BUILD:
		_set_mode(InteractMode.BUILD)
	else:
		_refresh_type_ui()
		_rebuild_ghost_meshes()


func _on_mode_build() -> void:
	_set_mode(InteractMode.BUILD)


func _on_mode_upgrade() -> void:
	_set_mode(InteractMode.UPGRADE)


func _on_mode_sell() -> void:
	_set_mode(InteractMode.SELL)


func _set_mode(mode: InteractMode) -> void:
	_mode = mode
	_hide_ghost()
	_touch_tracking = false
	_active_touch_index = -1
	_refresh_mode_ui()


func _refresh_mode_ui() -> void:
	btn_mode_build.disabled = _mode == InteractMode.BUILD
	btn_mode_upgrade.disabled = _mode == InteractMode.UPGRADE
	btn_mode_sell.disabled = _mode == InteractMode.SELL
	type_bar.modulate = Color(1, 1, 1, 1) if _mode == InteractMode.BUILD else Color(1, 1, 1, 0.45)
	_refresh_type_ui()


func _refresh_type_ui() -> void:
	btn_basic.text = "BASIC · %d" % basic_turret_cost
	btn_cannon.text = "CANNON · %d" % cannon_turret_cost
	btn_basic.disabled = _mode != InteractMode.BUILD or _selected_type == TurretType.BASIC
	btn_cannon.disabled = _mode != InteractMode.BUILD or _selected_type == TurretType.CANNON

	match _mode:
		InteractMode.BUILD:
			var type_name := "Basic" if _selected_type == TurretType.BASIC else "Cannon"
			var cost := _selected_turret_cost()
			selected_label.text = "BUILD: %s (%d)" % [type_name, cost]
		InteractMode.UPGRADE:
			selected_label.text = "UPGRADE: tap turret (%d / %d)" % [basic_upgrade_cost, cannon_upgrade_cost]
		InteractMode.SELL:
			selected_label.text = "SELL: tap turret (%d%% refund)" % int(SELL_REFUND_RATIO * 100.0)


func _selected_turret_scene() -> PackedScene:
	if _selected_type == TurretType.CANNON:
		return turret_cannon_scene
	return turret_scene


func _selected_turret_cost() -> int:
	if _selected_type == TurretType.CANNON:
		return cannon_turret_cost
	return basic_turret_cost


func _can_afford_selected() -> bool:
	return _scrap >= _selected_turret_cost()


func _turret_base_cost(turret: Node3D) -> int:
	if "base_cost" in turret:
		return int(turret.get("base_cost"))
	return basic_turret_cost


func _upgrade_cost_for(turret: Node3D) -> int:
	if _turret_base_cost(turret) >= cannon_turret_cost:
		return cannon_upgrade_cost
	return basic_upgrade_cost


func _sell_refund_for(turret: Node3D) -> int:
	return int(floor(float(_turret_base_cost(turret)) * SELL_REFUND_RATIO))


func _setup_ghost() -> void:
	_mat_valid = StandardMaterial3D.new()
	_mat_valid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_valid.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_valid.albedo_color = Color(0.25, 0.85, 0.55, 0.45)

	_mat_invalid = StandardMaterial3D.new()
	_mat_invalid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_invalid.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_invalid.albedo_color = Color(0.95, 0.25, 0.22, 0.45)

	_ghost = Node3D.new()
	_ghost.name = "TurretGhost"
	_ghost.visible = false
	add_child(_ghost)
	_rebuild_ghost_meshes()


func _rebuild_ghost_meshes() -> void:
	if _ghost == null:
		return

	for child in _ghost.get_children():
		_ghost.remove_child(child)
		child.free()
	_ghost_meshes.clear()

	var body_size := Vector3(1.0, 1.2, 1.0)
	var body_y := 0.6
	var barrel_size := Vector3(0.25, 0.25, 0.9)
	var barrel_pos := Vector3(0.0, 0.9, -0.55)
	if _selected_type == TurretType.CANNON:
		body_size = Vector3(1.35, 1.5, 1.35)
		body_y = 0.75
		barrel_size = Vector3(0.4, 0.4, 1.2)
		barrel_pos = Vector3(0.0, 1.05, -0.7)

	var body_mesh := BoxMesh.new()
	body_mesh.size = body_size
	var body := MeshInstance3D.new()
	body.mesh = body_mesh
	body.position = Vector3(0.0, body_y, 0.0)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ghost.add_child(body)
	_ghost_meshes.append(body)

	var barrel_mesh := BoxMesh.new()
	barrel_mesh.size = barrel_size
	var barrel := MeshInstance3D.new()
	barrel.mesh = barrel_mesh
	barrel.position = barrel_pos
	barrel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ghost.add_child(barrel)
	_ghost_meshes.append(barrel)

	if _ghost.visible:
		var pos := _ghost.global_position
		if _is_far_enough(pos) and _can_afford_selected():
			_apply_ghost_material(_mat_valid)
		else:
			_apply_ghost_material(_mat_invalid)
	else:
		_apply_ghost_material(_mat_valid)


func _apply_ghost_material(mat: StandardMaterial3D) -> void:
	for mesh_inst in _ghost_meshes:
		mesh_inst.material_override = mat


func _hide_ghost() -> void:
	if _ghost != null:
		_ghost.visible = false


func _update_ghost_at(screen_pos: Vector2) -> void:
	if _mode != InteractMode.BUILD:
		_hide_ghost()
		return

	if _placed_turrets.size() >= max_turrets:
		_hide_ghost()
		return

	var ground_pos: Variant = _raycast_ground(screen_pos)
	if typeof(ground_pos) != TYPE_VECTOR3:
		_hide_ghost()
		return

	var pos := ground_pos as Vector3
	# Outside blue strip: hide (not red). Inside + too close / other fail: red.
	if not _is_in_placement_zone(pos):
		_hide_ghost()
		return

	_ghost.visible = true
	_ghost.global_position = Vector3(pos.x, 0.0, pos.z)
	if _is_far_enough(pos) and _can_afford_selected():
		_apply_ghost_material(_mat_valid)
	else:
		_apply_ghost_material(_mat_invalid)


func _raycast_ground(screen_pos: Vector2) -> Variant:
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.0001:
		return null

	# Intersect infinite plane y = 0 (XZ ground).
	var t := -from.y / dir.y
	if t < 0.0:
		return null

	return from + dir * t


func _find_turret_near(screen_pos: Vector2) -> Node3D:
	var ground_pos: Variant = _raycast_ground(screen_pos)
	if typeof(ground_pos) != TYPE_VECTOR3:
		return null

	var pos := ground_pos as Vector3
	var nearest: Node3D = null
	var best := interact_tap_radius
	for turret in _placed_turrets:
		if not is_instance_valid(turret):
			continue
		var flat := Vector3(turret.global_position.x, 0.0, turret.global_position.z)
		var dist := Vector3(pos.x, 0.0, pos.z).distance_to(flat)
		if dist <= best:
			best = dist
			nearest = turret
	return nearest


func _try_place_turret(pos: Vector3) -> void:
	if _mode != InteractMode.BUILD:
		return

	var scene := _selected_turret_scene()
	if scene == null:
		push_error("Battle: selected turret scene is not assigned")
		return

	if _placed_turrets.size() >= max_turrets:
		return

	if not _is_in_placement_zone(pos):
		return

	if not _is_far_enough(pos):
		return

	var cost := _selected_turret_cost()
	if _scrap < cost:
		_flash_cannot_afford()
		return

	_scrap -= cost
	_update_scrap_label()

	var turret: Node3D = scene.instantiate()
	add_child(turret)
	turret.global_position = Vector3(pos.x, 0.0, pos.z)
	if turret.has_method("setup_economy"):
		turret.setup_economy(cost)
	_apply_meta_damage_to_turret(turret)
	_placed_turrets.append(turret)
	_update_turrets_label()
	_play_place_feedback(turret)


func _try_upgrade_at(screen_pos: Vector2) -> void:
	var turret := _find_turret_near(screen_pos)
	if turret == null:
		return

	if turret.has_method("can_upgrade") and not turret.can_upgrade():
		# Already upgraded — soft feedback via scrap flash pattern.
		_flash_cannot_afford()
		return

	var cost := _upgrade_cost_for(turret)
	if _scrap < cost:
		_flash_cannot_afford()
		return

	_scrap -= cost
	_update_scrap_label()
	if turret.has_method("apply_upgrade"):
		turret.apply_upgrade()
	if Sfx:
		Sfx.play_place()
	turrets_label.modulate = Color(0.7, 0.9, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(turrets_label, "modulate", _turrets_label_base_modulate, 0.35)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _try_sell_at(screen_pos: Vector2) -> void:
	var turret := _find_turret_near(screen_pos)
	if turret == null:
		return

	var refund := _sell_refund_for(turret)
	_placed_turrets.erase(turret)
	turret.queue_free()
	_update_turrets_label()
	_add_scrap(refund)
	if Sfx:
		Sfx.play_hit()
	turrets_label.modulate = Color(1.0, 0.75, 0.45, 1.0)
	var tween := create_tween()
	tween.tween_property(turrets_label, "modulate", _turrets_label_base_modulate, 0.35)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _is_in_placement_zone(pos: Vector3) -> bool:
	return pos.x >= placement_x_min and pos.x <= placement_x_max \
			and pos.z >= placement_z_min and pos.z <= placement_z_max


func _is_far_enough(pos: Vector3) -> bool:
	for turret in _placed_turrets:
		if not is_instance_valid(turret):
			continue
		var flat := Vector3(pos.x, 0.0, pos.z)
		var other := Vector3(turret.global_position.x, 0.0, turret.global_position.z)
		if flat.distance_to(other) < min_turret_distance:
			return false
	return true


func _update_turrets_label() -> void:
	# Clean invalid refs (should not happen in MVP).
	_placed_turrets = _placed_turrets.filter(func(t): return is_instance_valid(t))
	turrets_label.text = "Turrets: %d/%d" % [_placed_turrets.size(), max_turrets]


func _update_scrap_label() -> void:
	scrap_label.text = "Scrap: %d" % _scrap


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
	_add_scrap(scrap_between_waves)


func _play_place_feedback(turret: Node3D) -> void:
	if turret.has_method("play_place_pulse"):
		turret.play_place_pulse()
	if Sfx:
		Sfx.play_place()

	turrets_label.modulate = Color(0.55, 1.0, 0.7, 1.0)
	var tween := create_tween()
	tween.tween_property(turrets_label, "modulate", _turrets_label_base_modulate, 0.35)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_wall_hp_changed(current_hp: int, max_hp: int) -> void:
	hp_label.text = "Wall HP: %d / %d" % [current_hp, max_hp]


func _on_wall_damaged(_amount: int) -> void:
	# Mild mobile-safe shake — short and small.
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


func _on_wave_changed(current_wave: int, total_waves: int) -> void:
	_current_wave = current_wave
	wave_label.text = "Wave %d/%d" % [current_wave, total_waves]


func _on_wave_status(text: String) -> void:
	wave_label.text = text


func _on_waves_finished() -> void:
	_waves_finished = true


func _on_wall_destroyed() -> void:
	_show_result(false)


func _show_result(is_win: bool) -> void:
	if _game_over:
		return
	_game_over = true
	wave_manager.stop_waves()
	_hide_ghost()
	_shake_time = 0.0
	camera.position = _camera_base_pos
	_set_paused(false)
	pause_overlay.visible = false
	pause_button.visible = false

	var earned := _award_run_stars(is_win)
	result_title.text = "VICTORY" if is_win else "DEFEAT"
	if result_stars_label:
		result_stars_label.text = "+%d Stars" % earned
		result_stars_label.visible = true
	result_overlay.visible = true
	if Sfx:
		if is_win:
			Sfx.play_victory()
		else:
			Sfx.play_defeat()


func _apply_meta_bonuses() -> void:
	# Headless / missing autoload → safe defaults (no bonus).
	if MetaProgress == null:
		_turret_damage_mult = 1.0
		return
	start_scrap += MetaProgress.get_start_scrap_bonus()
	max_turrets += MetaProgress.get_max_turrets_bonus()
	_turret_damage_mult = MetaProgress.get_turret_damage_mult()
	if wall.has_method("apply_max_hp_bonus"):
		wall.apply_max_hp_bonus(MetaProgress.get_wall_hp_bonus())


func _apply_meta_damage_to_turret(turret: Node3D) -> void:
	if _turret_damage_mult <= 1.0001:
		return
	if "damage" in turret:
		var base_dmg := int(turret.get("damage"))
		turret.set("damage", maxi(1, int(round(float(base_dmg) * _turret_damage_mult))))


func _award_run_stars(is_win: bool) -> int:
	if MetaProgress == null:
		return 0
	var earned := 0
	if is_win:
		var ratio := 0.0
		if wall.max_hp > 0:
			ratio = float(wall.current_hp) / float(wall.max_hp)
		earned = MetaProgress.calc_victory_stars(ratio)
	else:
		earned = MetaProgress.calc_defeat_stars(maxi(1, _current_wave))
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
