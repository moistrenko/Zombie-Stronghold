extends SceneTree
## Headless art prep: chroma green #00FF00 (+ soft white fallback) → alpha, resize for mobile.
## Supports horizontal N-frame strips AND grid sheets (cols×rows). Grids are normalized
## into a single horizontal strip so SpriteFrames always slice left→right.
## Run:
##   Godot --headless --path . -s res://scripts/tools/process_art.gd
## Then import, then:
##   Godot --headless --path . -s res://scripts/tools/build_sprite_frames.gd

const WHITE_THRESH := 0.92
## Chroma green #00FF00 soft key: high G, low R/B, soft edge by green dominance.
const GREEN_DOM_HARD := 0.35
const GREEN_DOM_SOFT := 0.12
const GREEN_G_MIN := 0.45

## Sprite sheets: cols×rows layout. Output is always a horizontal strip of (cols*rows) frames.
const SHEETS := {
	"res://assets/art/zombies/zombie_basic_run_sheet.png": {
		"out": "res://assets/art/zombies/processed/zombie_basic_run_sheet.png",
		"max_w": 2048, "cols": 4, "rows": 2,
	},
	"res://assets/art/zombies/zombie_runner_run_sheet.png": {
		"out": "res://assets/art/zombies/processed/zombie_runner_run_sheet.png",
		"max_w": 2048, "cols": 4, "rows": 2,
	},
	"res://assets/art/zombies/zombie_brute_walk_sheet.png": {
		"out": "res://assets/art/zombies/processed/zombie_brute_walk_sheet.png",
		"max_w": 2048, "cols": 4, "rows": 2,
	},
	"res://assets/art/zombies/zombie_basic_run_8f.png": {
		"out": "res://assets/art/zombies/processed/zombie_basic_run_8f.png",
		"max_w": 2048, "cols": 4, "rows": 2,
	},
	"res://assets/art/zombies/zombie_runner_run_8f.png": {
		"out": "res://assets/art/zombies/processed/zombie_runner_run_8f.png",
		"max_w": 2048, "cols": 4, "rows": 2,
	},
	"res://assets/art/zombies/zombie_brute_walk_8f.png": {
		"out": "res://assets/art/zombies/processed/zombie_brute_walk_8f.png",
		"max_w": 2048, "cols": 4, "rows": 2,
	},
	"res://assets/art/zombies/zombie_basic_attack_6f.png": {
		"out": "res://assets/art/zombies/processed/zombie_basic_attack_6f.png",
		"max_w": 1536, "cols": 3, "rows": 2,
	},
	"res://assets/art/zombies/zombie_runner_attack_6f.png": {
		"out": "res://assets/art/zombies/processed/zombie_runner_attack_6f.png",
		"max_w": 1536, "cols": 3, "rows": 2,
	},
	"res://assets/art/zombies/zombie_brute_attack_6f.png": {
		"out": "res://assets/art/zombies/processed/zombie_brute_attack_6f.png",
		"max_w": 1536, "cols": 3, "rows": 2,
	},
	"res://assets/art/turrets/turret_basic_fire_sheet.png": {
		"out": "res://assets/art/turrets/processed/turret_basic_fire_sheet.png",
		"max_w": 1536, "cols": 3, "rows": 2,
	},
	"res://assets/art/turrets/turret_cannon_fire_sheet.png": {
		"out": "res://assets/art/turrets/processed/turret_cannon_fire_sheet.png",
		"max_w": 1536, "cols": 3, "rows": 2,
	},
	"res://assets/art/turrets/turret_basic_anim_6f.png": {
		"out": "res://assets/art/turrets/processed/turret_basic_anim_6f.png",
		"max_w": 1536, "cols": 3, "rows": 2,
	},
	"res://assets/art/turrets/turret_cannon_anim_6f.png": {
		"out": "res://assets/art/turrets/processed/turret_cannon_anim_6f.png",
		"max_w": 1536, "cols": 3, "rows": 2,
	},
}

const SINGLES := {
	"res://assets/art/turrets/turret_basic_idle.png":
		{"out": "res://assets/art/turrets/processed/turret_basic_idle.png", "max_w": 768, "key": true},
	"res://assets/art/turrets/turret_cannon_idle.png":
		{"out": "res://assets/art/turrets/processed/turret_cannon_idle.png", "max_w": 768, "key": true},
	"res://assets/art/environment/prop_car_overturned_burning.png":
		{"out": "res://assets/art/environment/processed/prop_car_overturned_burning.png", "max_w": 1280, "key": true},
	"res://assets/art/environment/prop_truck_side_wreck.png":
		{"out": "res://assets/art/environment/processed/prop_truck_side_wreck.png", "max_w": 1280, "key": true},
	"res://assets/art/environment/prop_burning_debris.png":
		{"out": "res://assets/art/environment/processed/prop_burning_debris.png", "max_w": 768, "key": true},
	"res://assets/art/environment/prop_ruins_barrier.png":
		{"out": "res://assets/art/environment/processed/prop_ruins_barrier.png", "max_w": 1024, "key": true},
	"res://assets/art/environment/prop_ruins_skyline.png":
		{"out": "res://assets/art/environment/processed/prop_ruins_skyline.png", "max_w": 1280, "key": true},
	"res://assets/art/environment/wall_fortress_gate_v1.png":
		{"out": "res://assets/art/environment/processed/wall_fortress_gate_v1.png", "max_w": 1536, "key": true},
	"res://assets/art/environment/wall_rampart_top_v1.png":
		{"out": "res://assets/art/environment/processed/wall_rampart_top_v1.png", "max_w": 1536, "key": true},
	"res://assets/art/environment/ground_asphalt_apocalypse.png":
		{"out": "res://assets/art/environment/processed/ground_asphalt_apocalypse.png", "max_w": 1024, "key": false},
	"res://assets/art/environment/sky_apocalypse.png":
		{"out": "res://assets/art/environment/processed/sky_apocalypse.png", "max_w": 1024, "key": false},
	"res://assets/art/ui/main_menu_bg_v1.png":
		{"out": "res://assets/art/ui/processed/main_menu_bg_v1.png", "max_w": 1024, "key": false},
	"res://assets/art/ui/menu_zombies_layer_v1.png":
		{"out": "res://assets/art/ui/processed/menu_zombies_layer_v1.png", "max_w": 1536, "key": true},
	"res://assets/art/ui/menu_cars_layer_v1.png":
		{"out": "res://assets/art/ui/processed/menu_cars_layer_v1.png", "max_w": 1536, "key": true},
}


func _init() -> void:
	_ensure_dirs()
	for src: String in SHEETS.keys():
		var cfg: Dictionary = SHEETS[src]
		_process_sheet(
			src,
			String(cfg["out"]),
			int(cfg["max_w"]),
			int(cfg["cols"]),
			int(cfg["rows"])
		)
	for src: String in SINGLES.keys():
		var cfg: Dictionary = SINGLES[src]
		_process_image(src, String(cfg["out"]), int(cfg["max_w"]), bool(cfg["key"]))
	print("process_art: done (run --import, then build_sprite_frames.gd)")
	quit()


func _ensure_dirs() -> void:
	for d: String in [
		"res://assets/art/zombies/processed",
		"res://assets/art/turrets/processed",
		"res://assets/art/environment/processed",
		"res://assets/art/ui/processed",
		"res://resources/sprites",
	]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))


func _process_sheet(src_res: String, out_res: String, max_w: int, cols: int, rows: int) -> void:
	var abs_src := ProjectSettings.globalize_path(src_res)
	var img := Image.new()
	var err := img.load(abs_src)
	if err != OK:
		push_error("process_art: failed to load %s (%s)" % [src_res, error_string(err)])
		return

	_key_chroma_green(img)
	_key_near_white(img)

	# Normalize any cols×rows grid into a single horizontal strip (N = cols*rows).
	var strip := _grid_to_horizontal_strip(img, cols, rows)
	_resize_strip(strip, max_w, cols * rows)

	var abs_out := ProjectSettings.globalize_path(out_res)
	err = strip.save_png(abs_out)
	if err != OK:
		push_error("process_art: failed to save %s (%s)" % [out_res, error_string(err)])
		return
	print(
		"process_art: wrote ", out_res, " ", strip.get_width(), "x", strip.get_height(),
		" (", cols * rows, "f strip from ", cols, "x", rows, ")"
	)


func _process_image(src_res: String, out_res: String, max_w: int, key_bg: bool) -> void:
	var abs_src := ProjectSettings.globalize_path(src_res)
	var img := Image.new()
	var err := img.load(abs_src)
	if err != OK:
		push_error("process_art: failed to load %s (%s)" % [src_res, error_string(err)])
		return

	if key_bg:
		_key_chroma_green(img)
		_key_near_white(img)

	_resize_max_width(img, max_w)

	var abs_out := ProjectSettings.globalize_path(out_res)
	err = img.save_png(abs_out)
	if err != OK:
		push_error("process_art: failed to save %s (%s)" % [out_res, error_string(err)])
		return
	print("process_art: wrote ", out_res, " ", img.get_width(), "x", img.get_height())


func _grid_to_horizontal_strip(img: Image, cols: int, rows: int) -> Image:
	## If already a 1-row strip with matching frame count, return as-is (after even crop).
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var frames := cols * rows

	# Pure horizontal strip already (rows==1): just crop to even frame widths.
	if rows == 1:
		var fw := w / frames
		var usable_w := fw * frames
		if usable_w != w:
			img = img.get_region(Rect2i(0, 0, usable_w, h))
		return img

	var cell_w := w / cols
	var cell_h := h / rows
	var usable_w := cell_w * cols
	var usable_h := cell_h * rows
	var out := Image.create(cell_w * frames, cell_h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))

	var fi := 0
	for row in rows:
		for col in cols:
			var src_rect := Rect2i(col * cell_w, row * cell_h, cell_w, cell_h)
			if src_rect.end.x > usable_w or src_rect.end.y > usable_h:
				continue
			out.blit_rect(img, src_rect, Vector2i(fi * cell_w, 0))
			fi += 1
	return out


func _key_chroma_green(img: Image) -> void:
	## Soft-key pixels close to chroma green (high G, low R/B). Soft edge by green dominance.
	img.convert(Image.FORMAT_RGBA8)
	var data := img.get_data()
	var i := 0
	var n := data.size()
	var hard := GREEN_DOM_HARD
	var soft := GREEN_DOM_SOFT
	var span := hard - soft
	while i < n:
		var r := float(data[i]) / 255.0
		var g := float(data[i + 1]) / 255.0
		var b := float(data[i + 2]) / 255.0
		var a := int(data[i + 3])
		if a > 0 and g >= GREEN_G_MIN:
			var dom := g - maxf(r, b)
			if dom >= hard:
				data[i + 3] = 0
			elif dom >= soft and span > 0.0001:
				var t := (dom - soft) / span
				data[i + 3] = int(clampf(float(a) * (1.0 - t), 0.0, 255.0))
		i += 4
	img.set_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)


func _key_near_white(img: Image) -> void:
	img.convert(Image.FORMAT_RGBA8)
	var data := img.get_data()
	var thresh_i := int(WHITE_THRESH * 255.0)
	var denom := 255.0 - float(thresh_i)
	var i := 0
	var n := data.size()
	while i < n:
		var r: int = data[i]
		var g: int = data[i + 1]
		var b: int = data[i + 2]
		var a: int = data[i + 3]
		if a > 0 and r >= thresh_i and g >= thresh_i and b >= thresh_i:
			var m: int = mini(r, mini(g, b))
			data[i + 3] = int(clampf((255.0 - float(m)) / denom * 255.0, 0.0, 255.0))
		i += 4
	img.set_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)


func _resize_strip(img: Image, max_w: int, frames: int) -> void:
	if img.get_width() <= max_w:
		# Ensure width divisible by frame count for clean atlas splits.
		var w := img.get_width()
		var rem := w % frames
		if rem != 0:
			img.crop(w - rem, img.get_height())
		return
	var scale := float(max_w) / float(img.get_width())
	var new_w := max_w - (max_w % frames)
	var new_h := maxi(2, int(round(float(img.get_height()) * scale)))
	img.resize(new_w, new_h, Image.INTERPOLATE_LANCZOS)


func _resize_max_width(img: Image, max_w: int) -> void:
	if img.get_width() <= max_w:
		return
	var h := int(round(float(img.get_height()) * float(max_w) / float(img.get_width())))
	if max_w % 2 != 0:
		max_w -= 1
	if h % 2 != 0:
		h -= 1
	img.resize(max_w, maxi(2, h), Image.INTERPOLATE_LANCZOS)
