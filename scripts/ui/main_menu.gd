extends Control

## Touch-friendly main menu: PLAY → battle, meta shop, How to play.
## Difficulty select removed (stage 27) — runs always use baseline Normal.

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"

@onready var play_button: Button = $Center/MenuPanel/Buttons/PlayButton
@onready var shop_button: Button = $Center/MenuPanel/Buttons/ShopButton
@onready var how_to_button: Button = $Center/MenuPanel/Buttons/HowToButton
@onready var mute_button: Button = $MuteButton
@onready var stars_label: Label = $StarsLabel
@onready var how_to_overlay: Control = $HowToOverlay
@onready var how_to_close: Button = $HowToOverlay/Panel/VBox/CloseButton
@onready var shop_overlay: Control = $ShopOverlay
@onready var shop_stars_label: Label = $ShopOverlay/Panel/VBox/ShopStars
@onready var shop_close: Button = $ShopOverlay/Panel/VBox/CloseButton
@onready var reset_meta_button: Button = $ShopOverlay/Panel/VBox/ResetButton

var _upgrade_buttons: Dictionary = {}


func _ready() -> void:
	how_to_overlay.visible = false
	shop_overlay.visible = false
	play_button.pressed.connect(_on_play_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	how_to_button.pressed.connect(_on_how_to_pressed)
	how_to_close.pressed.connect(_on_how_to_close)
	shop_close.pressed.connect(_on_shop_close)
	reset_meta_button.pressed.connect(_on_reset_meta)
	mute_button.pressed.connect(_on_mute_pressed)
	_bind_upgrade_buttons()
	if MetaProgress:
		MetaProgress.changed.connect(_refresh_meta_ui)
	if DifficultySettings:
		DifficultySettings.set_difficulty(DifficultySettings.Difficulty.NORMAL)
	_refresh_mute_label()
	_refresh_meta_ui()


func _bind_upgrade_buttons() -> void:
	_upgrade_buttons[MetaProgress.UpgradeId.START_SCRAP] = $ShopOverlay/Panel/VBox/Upgrades/BtnStartScrap
	_upgrade_buttons[MetaProgress.UpgradeId.WALL_HP] = $ShopOverlay/Panel/VBox/Upgrades/BtnWallHp
	_upgrade_buttons[MetaProgress.UpgradeId.TURRET_DMG] = $ShopOverlay/Panel/VBox/Upgrades/BtnTurretDmg
	_upgrade_buttons[MetaProgress.UpgradeId.MAX_TURRETS] = $ShopOverlay/Panel/VBox/Upgrades/BtnMaxTurrets
	_upgrade_buttons[MetaProgress.UpgradeId.ABILITY_CD] = $ShopOverlay/Panel/VBox/Upgrades/BtnAbilityCd
	for id in _upgrade_buttons.keys():
		var btn: Button = _upgrade_buttons[id]
		btn.pressed.connect(_on_buy_upgrade.bind(id))


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE)


func _on_shop_pressed() -> void:
	_refresh_meta_ui()
	shop_overlay.visible = true


func _on_shop_close() -> void:
	shop_overlay.visible = false


func _on_how_to_pressed() -> void:
	how_to_overlay.visible = true


func _on_how_to_close() -> void:
	how_to_overlay.visible = false


func _on_mute_pressed() -> void:
	if Sfx:
		Sfx.set_muted(not Sfx.is_muted())
	_refresh_mute_label()


func _on_buy_upgrade(id: MetaProgress.UpgradeId) -> void:
	if MetaProgress == null:
		return
	if MetaProgress.try_buy(id):
		if Sfx:
			Sfx.play_place()
	else:
		if Sfx:
			Sfx.play_hit()
	_refresh_meta_ui()


func _on_reset_meta() -> void:
	if MetaProgress == null:
		return
	MetaProgress.reset_meta()
	if Sfx:
		Sfx.play_defeat()
	_refresh_meta_ui()


func _refresh_mute_label() -> void:
	var muted := Sfx != null and Sfx.is_muted()
	mute_button.text = "SOUND: OFF" if muted else "SOUND: ON"


func _refresh_meta_ui() -> void:
	var star_count := 0
	if MetaProgress:
		star_count = MetaProgress.stars
	stars_label.text = "Stars: %d" % star_count
	if shop_stars_label:
		shop_stars_label.text = "Stars: %d" % star_count

	if MetaProgress == null:
		return

	for id in _upgrade_buttons.keys():
		var btn: Button = _upgrade_buttons[id]
		var lvl := MetaProgress.get_level(id)
		var cap := MetaProgress.get_cap(id)
		var label := MetaProgress.label_for(id)
		var effect := MetaProgress.effect_summary(id)
		if MetaProgress.is_maxed(id):
			btn.text = "%s\nLv %d/%d · MAX  (%s)" % [label, lvl, cap, effect]
			btn.disabled = true
		else:
			var cost := MetaProgress.get_next_cost(id)
			btn.text = "%s\nLv %d/%d · %d★  (%s)" % [label, lvl, cap, cost, effect]
			btn.disabled = not MetaProgress.can_buy(id)
