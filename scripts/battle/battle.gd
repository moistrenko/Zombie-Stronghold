extends Node3D

## Tap/click ground (XZ, y=0) to place turrets in the wall strip.
## Ghost preview: mouse move / touch drag; place on mouse click or touch release.
## HUD buttons select Basic vs Cannon before placing (shared max_turrets cap).

enum TurretType { BASIC, CANNON }

@export var zombie_scene: PackedScene
@export var zombie_runner_scene: PackedScene
@export var turret_scene: PackedScene
@export var turret_cannon_scene: PackedScene
@export var max_turrets: int = 3
@export var min_turret_distance: float = 2.0
@export var placement_z_min: float = 2.0
@export var placement_z_max: float = 5.5
@export var placement_x_min: float = -6.0
@export var placement_x_max: float = 6.0

@onready var wall: Node3D = $Wall
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var hp_label: Label = $HUD/HpLabel
@onready var wave_label: Label = $HUD/WaveLabel
@onready var turrets_label: Label = $HUD/TurretsLabel
@onready var selected_label: Label = $HUD/SelectedLabel
@onready var btn_basic: Button = $HUD/TypeBar/BtnBasic
@onready var btn_cannon: Button = $HUD/TypeBar/BtnCannon
@onready var result_overlay: Control = $HUD/ResultOverlay
@onready var result_title: Label = $HUD/ResultOverlay/Center/ResultTitle
@onready var restart_button: Button = $HUD/ResultOverlay/Center/RestartButton
@onready var camera: Camera3D = $Camera3D
@onready var wave_manager: Node = $WaveManager

var _game_over: bool = false
var _waves_finished: bool = false
var _placed_turrets: Array[Node3D] = []
var _selected_type: TurretType = TurretType.BASIC

var _ghost: Node3D
var _ghost_meshes: Array[MeshInstance3D] = []
var _mat_valid: StandardMaterial3D
var _mat_invalid: StandardMaterial3D
var _touch_tracking: bool = false
var _active_touch_index: int = -1


func _ready() -> void:
	camera.current = true
	result_overlay.visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	btn_basic.pressed.connect(_on_select_basic)
	btn_cannon.pressed.connect(_on_select_cannon)
	_setup_ghost()
	_refresh_type_ui()
	_update_turrets_label()

	if wall.has_signal("hp_changed"):
		wall.hp_changed.connect(_on_wall_hp_changed)
	if wall.has_signal("destroyed"):
		wall.destroyed.connect(_on_wall_destroyed)

	_on_wall_hp_changed(wall.current_hp, wall.max_hp)

	wave_manager.setup(self, wall, spawn_point, {
		"basic": zombie_scene,
		"runner": zombie_runner_scene,
	})
	wave_manager.wave_changed.connect(_on_wave_changed)
	wave_manager.status_changed.connect(_on_wave_status)
	wave_manager.waves_finished.connect(_on_waves_finished)
	wave_manager.start_waves()


func _process(_delta: float) -> void:
	if _game_over:
		return
	if _waves_finished and get_tree().get_nodes_in_group("zombies").is_empty():
		_show_result(true)


func _unhandled_input(event: InputEvent) -> void:
	if _game_over or result_overlay.visible:
		_hide_ghost()
		_touch_tracking = false
		_active_touch_index = -1
		return

	# Touch: press/drag = ghost; release = place if valid.
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touch_tracking = true
			_active_touch_index = touch.index
			_update_ghost_at(touch.position)
		elif touch.index == _active_touch_index:
			var ground_pos: Variant = _raycast_ground(touch.position)
			if typeof(ground_pos) == TYPE_VECTOR3:
				_try_place_turret(ground_pos as Vector3)
			_touch_tracking = false
			_active_touch_index = -1
			_hide_ghost()
		return

	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _touch_tracking and drag.index == _active_touch_index:
			_update_ghost_at(drag.position)
		return

	# Mouse: move = ghost; left click = place (editor / desktop).
	# With emulate_mouse_from_touch=false, mobile won't synthesize these.
	if event is InputEventMouseMotion and not _touch_tracking:
		_update_ghost_at((event as InputEventMouseMotion).position)
		return

	if event is InputEventMouseButton and not _touch_tracking:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			var ground_pos: Variant = _raycast_ground(mouse.position)
			if typeof(ground_pos) == TYPE_VECTOR3:
				_try_place_turret(ground_pos as Vector3)
			_update_ghost_at(mouse.position)


func _on_select_basic() -> void:
	_selected_type = TurretType.BASIC
	_refresh_type_ui()
	_rebuild_ghost_meshes()


func _on_select_cannon() -> void:
	_selected_type = TurretType.CANNON
	_refresh_type_ui()
	_rebuild_ghost_meshes()


func _refresh_type_ui() -> void:
	var type_name := "Basic" if _selected_type == TurretType.BASIC else "Cannon"
	selected_label.text = "Selected: %s" % type_name
	btn_basic.disabled = _selected_type == TurretType.BASIC
	btn_cannon.disabled = _selected_type == TurretType.CANNON


func _selected_turret_scene() -> PackedScene:
	if _selected_type == TurretType.CANNON:
		return turret_cannon_scene
	return turret_scene


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

	_apply_ghost_material(_mat_valid)


func _apply_ghost_material(mat: StandardMaterial3D) -> void:
	for mesh_inst in _ghost_meshes:
		mesh_inst.material_override = mat


func _hide_ghost() -> void:
	if _ghost != null:
		_ghost.visible = false


func _update_ghost_at(screen_pos: Vector2) -> void:
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
	if _is_far_enough(pos):
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


func _try_place_turret(pos: Vector3) -> void:
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

	var turret: Node3D = scene.instantiate()
	add_child(turret)
	turret.global_position = Vector3(pos.x, 0.0, pos.z)
	_placed_turrets.append(turret)
	_update_turrets_label()


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


func _on_wall_hp_changed(current_hp: int, max_hp: int) -> void:
	hp_label.text = "Wall HP: %d / %d" % [current_hp, max_hp]


func _on_wave_changed(current_wave: int, total_waves: int) -> void:
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

	result_title.text = "VICTORY" if is_win else "DEFEAT"
	result_overlay.visible = true


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
