extends Control

## Portrait-friendly type stats tooltip. Close via X, outside tap, or toggle.

signal closed

var _title: Label
var _body: Label
var _cost_label: Label
var _open_type: int = -1
var _panel: PanelContainer


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func is_open() -> bool:
	return visible


func get_open_type() -> int:
	return _open_type


func toggle(type_id: int, cost: int) -> void:
	if visible and _open_type == type_id:
		hide_panel()
		return
	show_type(type_id, cost)


func show_type(type_id: int, cost: int) -> void:
	_open_type = type_id
	_title.text = PlaceableCatalog.display_name(type_id)
	var lines: PackedStringArray = PlaceableCatalog.base_stats_lines(type_id)
	_body.text = "\n".join(lines)
	_cost_label.text = "Cost: %d scrap" % cost
	visible = true


func hide_panel() -> void:
	if not visible:
		return
	visible = false
	_open_type = -1
	closed.emit()


func _build() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.02, 0.03, 0.05, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.custom_minimum_size = Vector2(520, 360)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -260.0
	_panel.offset_top = -220.0
	_panel.offset_right = 260.0
	_panel.offset_bottom = 200.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.14, 0.97)
	style.border_color = Color(0.45, 0.55, 0.4, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", 32)
	header.add_child(_title)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(56, 48)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.pressed.connect(hide_panel)
	header.add_child(close_btn)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 22)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_body)

	_cost_label = Label.new()
	_cost_label.add_theme_font_size_override("font_size", 24)
	_cost_label.add_theme_color_override("font_color", Color(0.85, 0.95, 0.55, 1.0))
	vbox.add_child(_cost_label)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			hide_panel()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			hide_panel()
