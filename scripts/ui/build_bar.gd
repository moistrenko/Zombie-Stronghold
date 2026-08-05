extends Control

## Bottom placeable bar: icon + price + (i). Emits selection / info / cancel.

signal type_selected(type_id: int)
signal type_deselected
signal type_info_requested(type_id: int)

const BTN_MIN := Vector2(92, 108)
const SELECTED_BG := Color(0.22, 0.42, 0.28, 0.95)
const NORMAL_BG := Color(0.12, 0.14, 0.18, 0.92)
const UNAFFORD_PRICE := Color(1.0, 0.38, 0.32, 1.0)
const AFFORD_PRICE := Color(0.85, 0.95, 0.7, 1.0)

var _selected: int = -1
var _costs: Dictionary = {} # id -> int
var _affordable: Dictionary = {} # id -> bool
var _buttons: Dictionary = {} # id -> Panel
var _price_labels: Dictionary = {}
var _highlights: Dictionary = {}
var _row1: HBoxContainer
var _row2: HBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_layout()


func setup_costs(costs: Dictionary) -> void:
	_costs = costs.duplicate()
	_refresh_prices()


func set_affordability(affordable: Dictionary) -> void:
	_affordable = affordable.duplicate()
	_refresh_prices()


func get_selected() -> int:
	return _selected


func clear_selection() -> void:
	if _selected < 0:
		return
	_selected = -1
	_refresh_selection()
	type_deselected.emit()


func set_selected(type_id: int, emit_signal: bool = false) -> void:
	_selected = type_id
	_refresh_selection()
	if emit_signal and type_id >= 0:
		type_selected.emit(type_id)


func _build_layout() -> void:
	var panel := PanelContainer.new()
	panel.name = "BarPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.12, 0.92)
	style.border_color = Color(0.25, 0.3, 0.28, 1.0)
	style.set_border_width_all(2)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.name = "Rows"
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	_row1 = HBoxContainer.new()
	_row1.alignment = BoxContainer.ALIGNMENT_CENTER
	_row1.add_theme_constant_override("separation", 6)
	_row1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_row1)

	_row2 = HBoxContainer.new()
	_row2.alignment = BoxContainer.ALIGNMENT_CENTER
	_row2.add_theme_constant_override("separation", 6)
	_row2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_row2)

	var row1_ids: Array[int] = [
		PlaceableCatalog.Id.BASIC,
		PlaceableCatalog.Id.CANNON,
		PlaceableCatalog.Id.SUPPORT,
		PlaceableCatalog.Id.TESLA,
	]
	var row2_ids: Array[int] = [
		PlaceableCatalog.Id.SNIPER,
		PlaceableCatalog.Id.MINE,
		PlaceableCatalog.Id.BARRICADE,
	]
	for id in row1_ids:
		_row1.add_child(_make_type_button(id))
	for id in row2_ids:
		_row2.add_child(_make_type_button(id))


func _make_type_button(type_id: int) -> Control:
	var root := PanelContainer.new()
	root.custom_minimum_size = BTN_MIN
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := StyleBoxFlat.new()
	bg.bg_color = NORMAL_BG
	bg.border_color = Color(0.35, 0.4, 0.38, 1.0)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(6)
	bg.set_content_margin_all(4)
	root.add_theme_stylebox_override("panel", bg)
	_highlights[type_id] = bg

	var stack := Control.new()
	stack.custom_minimum_size = Vector2(84, 100)
	stack.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(stack)

	var tap := Button.new()
	tap.name = "Tap"
	tap.flat = true
	tap.set_anchors_preset(Control.PRESET_FULL_RECT)
	tap.mouse_filter = Control.MOUSE_FILTER_STOP
	tap.focus_mode = Control.FOCUS_NONE
	tap.pressed.connect(_on_type_pressed.bind(type_id))
	stack.add_child(tap)

	var icon_path: String = PlaceableCatalog.icon_path(type_id)
	if icon_path != "":
		var tex := load(icon_path) as Texture2D
		if tex != null:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.modulate = PlaceableCatalog.icon_modulate(type_id)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
			icon.offset_left = -28.0
			icon.offset_top = 6.0
			icon.offset_right = 28.0
			icon.offset_bottom = 58.0
			stack.add_child(icon)
	else:
		var swatch := ColorRect.new()
		swatch.color = PlaceableCatalog.icon_modulate(type_id)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swatch.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		swatch.offset_left = -18.0
		swatch.offset_top = 14.0
		swatch.offset_right = 18.0
		swatch.offset_bottom = 50.0
		stack.add_child(swatch)

	var name_lbl := Label.new()
	name_lbl.text = PlaceableCatalog.short_name(type_id)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	name_lbl.offset_left = -40.0
	name_lbl.offset_top = -42.0
	name_lbl.offset_right = 40.0
	name_lbl.offset_bottom = -24.0
	stack.add_child(name_lbl)

	var price := Label.new()
	price.name = "Price"
	price.text = "0"
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price.add_theme_font_size_override("font_size", 16)
	price.add_theme_color_override("font_color", AFFORD_PRICE)
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	price.offset_left = -52.0
	price.offset_top = -22.0
	price.offset_right = -4.0
	price.offset_bottom = -2.0
	stack.add_child(price)
	_price_labels[type_id] = price

	var info := Button.new()
	info.name = "Info"
	info.text = "i"
	info.custom_minimum_size = Vector2(28, 28)
	info.focus_mode = Control.FOCUS_NONE
	info.add_theme_font_size_override("font_size", 16)
	info.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	info.offset_left = -30.0
	info.offset_top = 2.0
	info.offset_right = -2.0
	info.offset_bottom = 30.0
	info.pressed.connect(_on_info_pressed.bind(type_id))
	stack.add_child(info)

	_buttons[type_id] = root
	return root


func _on_type_pressed(type_id: int) -> void:
	if _selected == type_id:
		clear_selection()
		return
	_selected = type_id
	_refresh_selection()
	type_selected.emit(type_id)


func _on_info_pressed(type_id: int) -> void:
	type_info_requested.emit(type_id)


func _refresh_selection() -> void:
	for id in _highlights.keys():
		var style: StyleBoxFlat = _highlights[id]
		if int(id) == _selected:
			style.bg_color = SELECTED_BG
			style.border_color = Color(0.55, 0.9, 0.55, 1.0)
		else:
			style.bg_color = NORMAL_BG
			style.border_color = Color(0.35, 0.4, 0.38, 1.0)


func _refresh_prices() -> void:
	for id in _price_labels.keys():
		var lbl: Label = _price_labels[id]
		var cost := int(_costs.get(id, 0))
		lbl.text = str(cost)
		var ok := bool(_affordable.get(id, true))
		lbl.add_theme_color_override("font_color", AFFORD_PRICE if ok else UNAFFORD_PRICE)
		var root: PanelContainer = _buttons.get(id)
		if root != null:
			root.modulate = Color(1, 1, 1, 1) if ok else Color(1, 0.85, 0.85, 0.85)
