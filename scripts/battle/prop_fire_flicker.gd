extends Sprite3D
## Subtle fire modulate pulse for burning wreck / debris props.

@export var speed: float = 3.6
@export var amplitude: float = 0.07

var _base: Color = Color.WHITE
var _phase: float = 0.0


func _ready() -> void:
	_base = modulate
	_phase = global_position.x * 0.7 + global_position.z * 0.35


func _process(delta: float) -> void:
	_phase += delta * speed
	var pulse := 1.0 + sin(_phase) * amplitude + sin(_phase * 2.17 + 0.8) * amplitude * 0.45
	modulate = Color(
		clampf(_base.r * pulse, 0.0, 1.35),
		clampf(_base.g * (0.94 + pulse * 0.06), 0.0, 1.2),
		clampf(_base.b * (0.88 + pulse * 0.08), 0.0, 1.1),
		_base.a
	)
