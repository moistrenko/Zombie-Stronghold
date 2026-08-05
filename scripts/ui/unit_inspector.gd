extends Control

## Mini tooltip near a placed unit: Sell / Upgrade / upgrade (i) / X.

signal closed
signal sell_pressed
signal upgrade_pressed
signal upgrade_info_pressed

@export var camera_path: NodePath

var _panel: PanelContainer
var _title: Label
var _sell_btn: Button
var _upgrade_btn: Button
var _upgrade_preview: TextureRect
var _upgrade_price: Label
var _upgrade_info: Button
var _upgrade_section: Control
var _upgrade_stats_panel: PanelContainer
var _upgrade_stats_body: Label
var _target: Node3D
var _camera: Camera3D
var _type_id: int = 0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	if camera_path != NodePath():
		_camera = get_node_or_null(camera_path) as Camera3D


func set_camera(cam: Camera3D) -> void:
	_camera = cam


func is_open() -> bool:
	return visible and is_instance_valid(_target)


func get_target() -> Node3D:
	if is_instance_valid(_target):
		return _target
	return null


func show_unit(unit: Node3D, type_id: int, scrap: int, sell_refund: int, upgrade_cost: int) -> void:
	if unit == null or not is_instance_valid(unit):
		hide_inspector()
		return
	_target = unit
	_type_id = type_id
	_title.text = PlaceableCatalog.display_name(type_id)
	_sell_btn.text = "SELL\n+%d" % sell_refund

	var can_up: bool = PlaceableCatalog.can_upgrade_type(type_id)
	var already: bool = false
	if "is_upgraded" in unit:
		already = bool(unit.get("is_upgraded"))
	if unit.has_method("can_upgrade"):
		can_up = can_up and bool(unit.can_upgrade())

	_upgrade_section.visible = true
	_upgrade_stats_panel.visible = false
	if not PlaceableCatalog.can_upgrade_type(type_id):
		_upgrade_btn.text = "NO UPGRADE"
		_upgrade_btn.disabled = true
		_upgrade_price.text = "—"
		_upgrade_info.disabled = true
		_upgrade_preview.modulate = Color(0.5, 0.5, 0.5, 0.7)
	elif already:
		_upgrade_btn.text = "UPGRADED"
		_upgrade_btn.disabled = true
		_upgrade_price.text = "MAX"
		_upgrade_info.disabled = false
		_upgrade_preview.modulate = Color(1.05, 0.9, 0.65, 1.0)
	else:
		_upgrade_btn.text = "UPGRADE"
		_upgrade_btn.disabled = scrap < upgrade_cost
		_upgrade_price.text = "%d scrap" % upgrade_cost
		_upgrade_price.add_theme_color_override(
			"font_color",
			Color(0.85, 0.95, 0.55, 1.0) if scrap >= upgrade_cost else Color(1.0, 0.4, 0.35, 1.0)
		)
		_upgrade_info.disabled = false
		_upgrade_preview.modulate = PlaceableCatalog.icon_modulate(type_id)

	var path: String = PlaceableCatalog.icon_path(type_id)
	if path != "":
		_upgrade_preview.texture = load(path) as Texture2D
		_upgrade_preview.visible = true
	else:
		_upgrade_preview.texture = null
		_upgrade_preview.visible = false

	visible = true
	_reposition()


func refresh_economy(scrap: int, sell_refund: int, upgrade_cost: int) -> void:
	if not is_open():
		return
	show_unit(_target, _type_id, scrap, sell_refund, upgrade_cost)


func hide_inspector() -> void:
	var was := visible
	visible = false
	_target = null
	_upgrade_stats_panel.visible = false
	if was:
		closed.emit()


func _process(_delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(_target):
		hide_inspector()
		return
	_reposition()


func _reposition() -> void:
	if _camera == null or not is_instance_valid(_target):
		return
	var world := _target.global_position + Vector3(0.0, 1.4, 0.0)
	var screen := _camera.unproject_position(world)
	var size := _panel.size
	if size.x < 10.0:
		size = _panel.get_combined_minimum_size()
	var pos := screen + Vector2(-size.x * 0.5, -size.y - 12.0)
	pos.x = clampf(pos.x, 8.0, 720.0 - size.x - 8.0)
	pos.y = clampf(pos.y, 90.0, 1280.0 - size.y - 240.0)
	_panel.position = pos


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.custom_minimum_size = Vector2(280, 200)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.12, 0.96)
	style.border_color = Color(0.55, 0.7, 0.45, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", 22)
	header.add_child(_title)
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(44, 40)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(hide_inspector)
	header.add_child(close_btn)

	_sell_btn = Button.new()
	_sell_btn.custom_minimum_size = Vector2(0, 56)
	_sell_btn.focus_mode = Control.FOCUS_NONE
	_sell_btn.add_theme_font_size_override("font_size", 20)
	_sell_btn.pressed.connect(func(): sell_pressed.emit())
	vbox.add_child(_sell_btn)

	_upgrade_section = VBoxContainer.new()
	_upgrade_section.add_theme_constant_override("separation", 4)
	vbox.add_child(_upgrade_section)

	var up_row := HBoxContainer.new()
	up_row.add_theme_constant_override("separation", 6)
	_upgrade_section.add_child(up_row)

	_upgrade_preview = TextureRect.new()
	_upgrade_preview.custom_minimum_size = Vector2(48, 48)
	_upgrade_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_upgrade_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_upgrade_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	up_row.add_child(_upgrade_preview)

	var up_col := VBoxContainer.new()
	up_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up_row.add_child(up_col)

	_upgrade_btn = Button.new()
	_upgrade_btn.custom_minimum_size = Vector2(0, 48)
	_upgrade_btn.focus_mode = Control.FOCUS_NONE
	_upgrade_btn.add_theme_font_size_override("font_size", 18)
	_upgrade_btn.pressed.connect(func(): upgrade_pressed.emit())
	up_col.add_child(_upgrade_btn)

	var price_row := HBoxContainer.new()
	up_col.add_child(price_row)
	_upgrade_price = Label.new()
	_upgrade_price.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrade_price.add_theme_font_size_override("font_size", 16)
	price_row.add_child(_upgrade_price)

	_upgrade_info = Button.new()
	_upgrade_info.text = "i"
	_upgrade_info.custom_minimum_size = Vector2(36, 36)
	_upgrade_info.focus_mode = Control.FOCUS_NONE
	_upgrade_info.pressed.connect(_on_upgrade_info)
	price_row.add_child(_upgrade_info)

	_upgrade_stats_panel = PanelContainer.new()
	_upgrade_stats_panel.visible = false
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.14, 0.16, 0.18, 0.98)
	st.set_content_margin_all(8)
	_upgrade_stats_panel.add_theme_stylebox_override("panel", st)
	_upgrade_section.add_child(_upgrade_stats_panel)
	_upgrade_stats_body = Label.new()
	_upgrade_stats_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_upgrade_stats_body.add_theme_font_size_override("font_size", 16)
	_upgrade_stats_panel.add_child(_upgrade_stats_body)


func _on_upgrade_info() -> void:
	if _upgrade_stats_panel.visible:
		_upgrade_stats_panel.visible = false
		return
	var lines: PackedStringArray = PlaceableCatalog.upgrade_preview_lines(_type_id)
	_upgrade_stats_body.text = "After upgrade:\n" + "\n".join(lines)
	_upgrade_stats_panel.visible = true
	upgrade_info_pressed.emit()
	# Panel size may change — nudge next frame.
	await get_tree().process_frame
	_reposition()
