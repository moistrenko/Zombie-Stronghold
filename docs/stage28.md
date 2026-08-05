# Этап 28 — Apocalyptic main menu background

## Что сделано

1. **UI art pipeline** — `process_art.gd` SINGLES now includes:
   - `main_menu_bg_v1.png` → `assets/art/ui/processed/` (no chroma key, max_w 1024)
   - `menu_zombies_layer_v1.png` / `menu_cars_layer_v1.png` → processed with **chroma green key** (max_w 1536)
2. **Main menu redesign** — full-bleed portrait backdrop + layered TextureRects:
   - **Bg** — `KEEP_ASPECT_COVERED` stretch, full viewport
   - **Zombies** — mid plate (lower ~78% of screen), soft opacity, slow sway
   - **Cars** — foreground bottom strip (~620px), fire modulate pulse + stronger sway
   - Light **scrim** for title/button readability
3. **UI chrome** — semi-transparent panel behind PLAY / META SHOP / HOW TO PLAY; dark gold-bordered button styles; title with heavy outline + shadow. Mute + Stars remain; meta shop / play flows unchanged from stage 27.
4. Idle motion via `scripts/ui/menu_bg_layers.gd` (parallax sway offsets + warm pulse on cars).

## Layer composition (back → front)

| Layer | Texture | Layout | Motion |
|-------|---------|--------|--------|
| Bg | `processed/main_menu_bg_v1.png` | Full-bleed cover | none |
| Zombies | `processed/menu_zombies_layer_v1.png` | Mid/lower cover strip | slow XY sway (~7×4 px) |
| Cars | `processed/menu_cars_layer_v1.png` | Bottom cover strip | stronger sway + fire modulate |
| Scrim | ColorRect 28% black | Full | none |
| Chrome | Title + MenuPanel buttons | Center | none |

Cars/zombies sources are **landscape** 1536×1024 chroma plates; bottom-weighted strips keep left/right wreck framing without extreme side crop on 720×1280.

## Pipeline

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://scripts/tools/process_art.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
```

## Как проверить (F5)

1. Main menu shows apocalyptic skyline backdrop (not flat ColorRect).
2. Burning cars frame bottom L/R; zombie horde visible mid; title readable.
3. Subtle idle sway + fire brightness pulse on cars layer.
4. PLAY → battle; META SHOP buy/reset; How to play; mute — all still work.
5. Overlay panels (shop / how-to) still dim and close correctly.

Headless smoke:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/menus/main_menu.tscn --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/battle/battle.tscn --quit-after 2
```

## Файлы

- `assets/art/ui/main_menu_bg_v1.png`, `menu_zombies_layer_v1.png`, `menu_cars_layer_v1.png` (source)
- `assets/art/ui/processed/*` (+ `.import`)
- `scripts/tools/process_art.gd` (UI paths + `ui/processed` dir)
- `scripts/ui/menu_bg_layers.gd`
- `scripts/ui/main_menu.gd` (button paths under MenuPanel)
- `scenes/menus/main_menu.tscn`
- `docs/stage28.md`, `README.md`

## Техдолг / Stage 29

- Soft green fringe remains on keyed layers (tighten green key or paint-clean sources).
- Landscape plates vs portrait bg — optional re-export of true portrait layer art for perfect alignment.
- Dedicated Mine/Fence bar icons (carried from stage 27).
- **Stage 29 recommendation:** audio/VFX polish (place/sell/upgrade + ability telegraph) and/or meta run summary / personal-best wave on the result screen.
