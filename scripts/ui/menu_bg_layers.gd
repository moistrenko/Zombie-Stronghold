extends Control
## Idle parallax sway + warm fire pulse for main-menu apocalypse layers.

@onready var zombies_layer: TextureRect = $ZombiesLayer
@onready var cars_layer: TextureRect = $CarsLayer

var _t: float = 0.0
var _cars_base: Color = Color.WHITE
var _z_off: Rect2 = Rect2()
var _c_off: Rect2 = Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if zombies_layer:
		_z_off = Rect2(
			zombies_layer.offset_left,
			zombies_layer.offset_top,
			zombies_layer.offset_right,
			zombies_layer.offset_bottom
		)
	if cars_layer:
		_cars_base = cars_layer.modulate
		_c_off = Rect2(
			cars_layer.offset_left,
			cars_layer.offset_top,
			cars_layer.offset_right,
			cars_layer.offset_bottom
		)


func _process(delta: float) -> void:
	_t += delta
	if zombies_layer:
		var zx := sin(_t * 0.32) * 7.0
		var zy := cos(_t * 0.24) * 4.0
		zombies_layer.offset_left = _z_off.position.x + zx
		zombies_layer.offset_top = _z_off.position.y + zy
		zombies_layer.offset_right = _z_off.size.x + zx
		zombies_layer.offset_bottom = _z_off.size.y + zy
	if cars_layer:
		var cx := sin(_t * 0.42 + 1.1) * 11.0
		var cy := cos(_t * 0.33 + 0.4) * 5.5
		cars_layer.offset_left = _c_off.position.x + cx
		cars_layer.offset_top = _c_off.position.y + cy
		cars_layer.offset_right = _c_off.size.x + cx
		cars_layer.offset_bottom = _c_off.size.y + cy
		var pulse := 1.0 + sin(_t * 2.9) * 0.07 + sin(_t * 5.2 + 0.8) * 0.035
		cars_layer.modulate = Color(
			clampf(_cars_base.r * pulse, 0.0, 1.4),
			clampf(_cars_base.g * (0.94 + pulse * 0.06), 0.0, 1.25),
			clampf(_cars_base.b * (0.88 + pulse * 0.08), 0.0, 1.15),
			_cars_base.a
		)
