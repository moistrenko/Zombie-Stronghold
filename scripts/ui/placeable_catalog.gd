class_name PlaceableCatalog
extends RefCounted

## Shared placeable type ids + tooltip / icon metadata for Stage 27 HUD.

enum Id { BASIC, CANNON, SUPPORT, TESLA, SNIPER, MINE, BARRICADE }

const ALL_IDS: Array[int] = [
	Id.BASIC, Id.CANNON, Id.SUPPORT, Id.TESLA, Id.SNIPER, Id.MINE, Id.BARRICADE,
]

const ICON_BASIC := "res://assets/art/turrets/processed/turret_basic_idle.png"
const ICON_CANNON := "res://assets/art/turrets/processed/turret_cannon_idle.png"


static func display_name(id: int) -> String:
	match id:
		Id.BASIC:
			return "Basic"
		Id.CANNON:
			return "Cannon"
		Id.SUPPORT:
			return "Support"
		Id.TESLA:
			return "Tesla"
		Id.SNIPER:
			return "Sniper"
		Id.MINE:
			return "Mine"
		Id.BARRICADE:
			return "Fence"
	return "Unit"


static func short_name(id: int) -> String:
	match id:
		Id.BASIC:
			return "BASIC"
		Id.CANNON:
			return "CANNON"
		Id.SUPPORT:
			return "SUPPORT"
		Id.TESLA:
			return "TESLA"
		Id.SNIPER:
			return "SNIPER"
		Id.MINE:
			return "MINE"
		Id.BARRICADE:
			return "FENCE"
	return "UNIT"


static func icon_path(id: int) -> String:
	match id:
		Id.CANNON, Id.SNIPER:
			return ICON_CANNON
		Id.MINE, Id.BARRICADE:
			return ""
		_:
			return ICON_BASIC


static func icon_modulate(id: int) -> Color:
	match id:
		Id.SUPPORT:
			return Color(0.45, 1.0, 0.55, 1.0)
		Id.TESLA:
			return Color(0.35, 0.85, 1.0, 1.0)
		Id.SNIPER:
			return Color(0.75, 0.45, 1.0, 1.0)
		Id.MINE:
			return Color(0.85, 0.25, 0.18, 1.0)
		Id.BARRICADE:
			return Color(0.55, 0.45, 0.32, 1.0)
		_:
			return Color.WHITE


static func can_upgrade_type(id: int) -> bool:
	return id != Id.MINE


static func is_wall_defense(id: int) -> bool:
	match id:
		Id.BASIC, Id.CANNON, Id.SUPPORT, Id.TESLA, Id.SNIPER:
			return true
		_:
			return false


static func base_stats_lines(id: int) -> PackedStringArray:
	match id:
		Id.BASIC:
			return PackedStringArray([
				"Damage: 15",
				"Fire rate: 0.7s",
				"Range: 12",
				"Projectile turret",
			])
		Id.CANNON:
			return PackedStringArray([
				"Damage: 40",
				"Fire rate: 1.4s",
				"Range: 13",
				"Heavy projectile",
			])
		Id.SUPPORT:
			return PackedStringArray([
				"Effect: +20% turret damage aura",
				"Aura radius: 4",
				"Scrap drip: +2 / 5s",
				"Max 1 Support on the field",
			])
		Id.TESLA:
			return PackedStringArray([
				"Damage: 18",
				"Fire rate: 0.9s",
				"Range: 9",
				"Chain: 2 jumps (×0.7 falloff)",
			])
		Id.SNIPER:
			return PackedStringArray([
				"Damage: 70",
				"Fire rate: 2.2s",
				"Range: 18",
				"Long-range slow fire",
			])
		Id.MINE:
			return PackedStringArray([
				"Damage: 45 (one-shot)",
				"Trigger radius: 1.25",
				"Arms in 0.35s, then consumed",
				"No upgrade — sell only",
			])
		Id.BARRICADE:
			return PackedStringArray([
				"HP: 80",
				"Half-width: 1.35",
				"Slows zombies ×0.35 while blocking",
				"Chewed by contact damage",
			])
	return PackedStringArray()


static func upgrade_preview_lines(id: int) -> PackedStringArray:
	match id:
		Id.BASIC:
			return PackedStringArray([
				"Damage: 21 (+40%)",
				"Fire rate: 0.7s",
				"Range: 13.8 (+15%)",
			])
		Id.CANNON:
			return PackedStringArray([
				"Damage: 56 (+40%)",
				"Fire rate: 1.4s",
				"Range: 14.95 (+15%)",
			])
		Id.SUPPORT:
			return PackedStringArray([
				"Aura: +30% turret damage",
				"Aura radius: 5 (+25%)",
				"Scrap drip: +3 / 5s",
			])
		Id.TESLA:
			return PackedStringArray([
				"Damage: 25 (+40%)",
				"Fire rate: 0.9s",
				"Range: 10.35 (+15%)",
				"Chain: 3 jumps, radius ×1.1",
			])
		Id.SNIPER:
			return PackedStringArray([
				"Damage: 98 (+40%)",
				"Fire rate: 2.2s",
				"Range: 20.7 (+15%)",
			])
		Id.BARRICADE:
			return PackedStringArray([
				"HP: 112 (+40%)",
				"Half-width: 1.55 (+15%)",
				"Slow: ×0.28 (stronger)",
			])
		Id.MINE:
			return PackedStringArray(["No upgrade"])
	return PackedStringArray()


static func kind_for(id: int) -> StringName:
	match id:
		Id.BASIC:
			return &"basic"
		Id.CANNON:
			return &"cannon"
		Id.SUPPORT:
			return &"support"
		Id.TESLA:
			return &"tesla"
		Id.SNIPER:
			return &"sniper"
		Id.MINE:
			return &"mine"
		Id.BARRICADE:
			return &"barricade"
	return &"basic"


static func resolve_unit_id(unit: Node) -> int:
	if unit == null:
		return Id.BASIC
	if "unit_kind" in unit:
		match String(unit.get("unit_kind")):
			"basic":
				return Id.BASIC
			"cannon":
				return Id.CANNON
			"support":
				return Id.SUPPORT
			"tesla":
				return Id.TESLA
			"sniper":
				return Id.SNIPER
			"mine":
				return Id.MINE
			"barricade":
				return Id.BARRICADE
	if unit.is_in_group("supports"):
		return Id.SUPPORT
	if unit.is_in_group("mines"):
		return Id.MINE
	if unit.is_in_group("barricades"):
		return Id.BARRICADE
	if "chain_jumps" in unit and int(unit.get("chain_jumps")) > 0:
		return Id.TESLA
	if "attack_range" in unit and float(unit.get("attack_range")) >= 17.0:
		return Id.SNIPER
	if "fire_interval" in unit and float(unit.get("fire_interval")) >= 1.3:
		return Id.CANNON
	return Id.BASIC
