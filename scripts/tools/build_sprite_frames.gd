extends SceneTree
## Build SpriteFrames .tres that reference imported processed PNGs (external, small).
## Sheets are horizontal N-frame strips (process_art normalizes grids → strips).
## Run after process_art + import:
##   Godot --headless --path . -s res://scripts/tools/build_sprite_frames.gd


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://resources/sprites"))
	# Prefer processed *_8f / *_6f if present; fall back to legacy sheet names.
	# Walk FPS lowered for stage-26 shuffle (slow move). Attack = 6f loop.
	_build_zombie(
		_first_existing([
			"res://assets/art/zombies/processed/zombie_basic_run_8f.png",
			"res://assets/art/zombies/processed/zombie_basic_run_sheet.png",
		]),
		"res://assets/art/zombies/processed/zombie_basic_attack_6f.png",
		"res://resources/sprites/zombie_basic_frames.tres",
		"run", 8.0, 8
	)
	_build_zombie(
		_first_existing([
			"res://assets/art/zombies/processed/zombie_runner_run_8f.png",
			"res://assets/art/zombies/processed/zombie_runner_run_sheet.png",
		]),
		"res://assets/art/zombies/processed/zombie_runner_attack_6f.png",
		"res://resources/sprites/zombie_runner_frames.tres",
		"run", 9.0, 8
	)
	_build_zombie(
		_first_existing([
			"res://assets/art/zombies/processed/zombie_brute_walk_8f.png",
			"res://assets/art/zombies/processed/zombie_brute_walk_sheet.png",
		]),
		"res://assets/art/zombies/processed/zombie_brute_attack_6f.png",
		"res://resources/sprites/zombie_brute_frames.tres",
		"walk", 7.0, 8
	)
	_build_turret(
		"res://assets/art/turrets/processed/turret_basic_idle.png",
		_first_existing([
			"res://assets/art/turrets/processed/turret_basic_anim_6f.png",
			"res://assets/art/turrets/processed/turret_basic_fire_sheet.png",
		]),
		"res://resources/sprites/turret_basic_frames.tres",
		6
	)
	_build_turret(
		"res://assets/art/turrets/processed/turret_cannon_idle.png",
		_first_existing([
			"res://assets/art/turrets/processed/turret_cannon_anim_6f.png",
			"res://assets/art/turrets/processed/turret_cannon_fire_sheet.png",
		]),
		"res://resources/sprites/turret_cannon_frames.tres",
		6
	)
	print("build_sprite_frames: done")
	quit()


func _first_existing(paths: Array) -> String:
	for p in paths:
		var path := String(p)
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			return path
	return String(paths[0]) if paths.size() > 0 else ""


func _tex(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var res := load(path)
	if res is Texture2D:
		return res as Texture2D
	push_error("missing texture %s" % path)
	return null


func _add_strip_anim(
		sf: SpriteFrames,
		tex: Texture2D,
		anim: String,
		fps: float,
		loop: bool,
		frames: int
) -> void:
	if tex == null:
		return
	if sf.has_animation(anim):
		sf.remove_animation(anim)
	sf.add_animation(anim)
	sf.set_animation_speed(anim, fps)
	sf.set_animation_loop(anim, loop)
	var fw := tex.get_width() / frames
	var fh := tex.get_height()
	for i in frames:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * fw, 0, fw, fh)
		atlas.filter_clip = true
		sf.add_frame(anim, atlas)


func _build_zombie(
		move_path: String,
		attack_path: String,
		out_path: String,
		move_anim: String,
		move_fps: float,
		move_frames: int
) -> void:
	var move_tex := _tex(move_path)
	if move_tex == null:
		return
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	_add_strip_anim(sf, move_tex, move_anim, move_fps, true, move_frames)
	var attack_tex := _tex(attack_path)
	if attack_tex != null:
		_add_strip_anim(sf, attack_tex, "attack", 10.0, true, 6)
	var err := ResourceSaver.save(sf, out_path)
	var has_atk := attack_tex != null
	print(
		"saved ", out_path,
		" move=", move_anim, "/", move_frames, "@", move_fps,
		" attack=", has_atk, " err=", err
	)


func _build_turret(idle_path: String, fire_path: String, out_path: String, fire_frames: int) -> void:
	var idle_tex := _tex(idle_path)
	var fire_tex := _tex(fire_path)
	if fire_tex == null:
		return
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")

	var fw := fire_tex.get_width() / fire_frames
	var fh := fire_tex.get_height()

	# Idle: subtle 2-frame loop from start of strip (or single idle texture fallback).
	sf.add_animation("idle")
	sf.set_animation_speed("idle", 4.0)
	sf.set_animation_loop("idle", true)
	var idle_count := mini(2, fire_frames)
	for i in idle_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = fire_tex
		atlas.region = Rect2(i * fw, 0, fw, fh)
		atlas.filter_clip = true
		sf.add_frame("idle", atlas)
	# Keep classic idle tex as extra frame if available (helps ghost parity).
	if idle_tex != null:
		sf.add_frame("idle", idle_tex)

	sf.add_animation("fire")
	sf.set_animation_speed("fire", 17.0)
	sf.set_animation_loop("fire", false)
	for i in fire_frames:
		var atlas := AtlasTexture.new()
		atlas.atlas = fire_tex
		atlas.region = Rect2(i * fw, 0, fw, fh)
		atlas.filter_clip = true
		sf.add_frame("fire", atlas)

	var err := ResourceSaver.save(sf, out_path)
	print("saved ", out_path, " fire_frames=", fire_frames, " err=", err)
