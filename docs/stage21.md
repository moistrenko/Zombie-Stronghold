# Этап 21 — Chroma green art + Endless + Portrait

## Что сделано

1. **Art v2 chroma key** — исходники с solid green `#00FF00`; `process_art.gd` кейит зелёный (soft edge) + soft white fallback.
2. **Endless mode** — после очистки волны 5 (стена жива): выбор CLAIM VICTORY / ENTER ENDLESS.
3. **Portrait-first** — viewport **720×1280**, `window/handheld/orientation=1` (portrait); HUD/меню/камера под вертикаль.

## Part A — Green key pipeline

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://scripts/tools/process_art.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://scripts/tools/build_sprite_frames.gd
```

| Key | Rule |
|-----|------|
| Chroma green | High G (≥0.45), dominance `G − max(R,B)`: ≥0.35 → alpha 0; 0.12–0.35 → soft edge |
| White fallback | RGB ≥ 0.92 → soft alpha (как этап 20) |
| Ground / sky | **не** кейятся |

### Green spill (долг)

- Мягкий край может слегка «съесть» насыщенный зелёный на спрайтах (если есть в art).
- При заметном ореоле на F5: подкрутить `GREEN_DOM_SOFT` / `GREEN_DOM_HARD` в `process_art.gd` и перепрогнать pipeline.

## Part B — Endless

### Trigger UX

После волны 5, когда поле пусто и стена жива → overlay **VICTORY!**:

- **CLAIM VICTORY** → обычный win + Stars (как раньше).
- **ENTER ENDLESS** → волны 6+ без мгновенного VICTORY.

Pause / MAIN MENU / placement / sell / upgrade / meta shop **не ломаются**.

### Scaling (wave 6+)

| Param | Rule |
|-------|------|
| Count | `10 + 2×(wave−6)` (min 6) |
| Spawn interval | `0.65 − 0.04×(wave−6)`, floor **0.32** |
| Endless HP mult | `1.0 + 0.08×(wave−5)` × difficulty HP mult |
| Mix | basic / runner / brute (brute chance растёт с depth; ≥1 brute/wave) |
| Scrap between waves | `12 + 2×max(0, wave−5)` |
| HUD | `Wave N (endless)` |

Difficulty Easy/Normal/Hard multipliers (HP/speed/dmg/scrap/stars) **применяются** и в endless.

### Stars

| Outcome | Formula (before difficulty star mult) |
|---------|----------------------------------------|
| Claim Victory (wave 5) | `15 + floor(hp_ratio × 10)` |
| Campaign defeat | `3 × waves_reached` |
| Endless defeat (wall) | `3 × N + 2 × max(0, N − 5)` |

Затем `DifficultySettings.scale_stars(...)`. Endless death uses **defeat** star mult.

## Portrait / vertical mobile

| Setting | Value |
|---------|-------|
| Viewport | **720 × 1280** |
| Stretch | `canvas_items` + `expand` |
| Handheld orientation | **`1` = portrait** (`DisplayServer.SCREEN_PORTRAIT`) |
| Android/iOS export | Inherit project orientation (portrait); presets comment in `export_presets.cfg` |

### Camera

- Position ≈ `(0, 22, 16)`, pitch ≈ **55°**, FOV **58°** (taller playfield read).
- Wall bottom / spawn top (+Z) unchanged.
- Placement X ±5; props ~±6.0–6.5 (lane not crushed).

### UI reflow

- Battle: compact top status; TypeBar under selected line; ModeBar ≤ ~696px wide, large touch (≥76–88h).
- Overlays (result / endless / pause): tall centered columns, ~400×88 buttons.
- Main menu / shop / how-to: narrower panels (±320–330), taller vertical stack; Diff buttons fill width.

## Как проверить

1. Editor: Project → window should be portrait 720×1280.
2. F5 → menu upright; PLAY → wall bottom, lane readable, no green/white boxes on sprites.
3. Clear wave 5 → CLAIM vs ENDLESS; endless HUD `Wave N (endless)`; die → ENDLESS OVER + Stars.
4. Pause / shop / sell / upgrade still work.

Headless smoke:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/battle/battle.tscn --quit-after 2
```

## Файлы

- `scripts/tools/process_art.gd`, `build_sprite_frames.gd`
- `assets/art/**/processed/*`, `resources/sprites/*.tres`
- `scripts/battle/wave_manager.gd`, `battle.gd`
- `scripts/autoload/meta_progress.gd`
- `scenes/battle/battle.tscn`, `scenes/menus/main_menu.tscn`
- `project.godot`, `export_presets.cfg`
- `docs/stage21.md`, `README.md`

## Долги

- Fine-tune camera FOV/prop scale on real phone notches / safe areas.
- Store screenshot docs still mention landscape (stage10b) — update when regenerating store assets.
- Green spill / soft-edge on character highlights if art uses green accents.
- Endless balance (count/HP) needs playtest beyond wave ~12.
- Optional: award partial Stars when entering endless (currently Stars only on claim or death).

## Stage 22 recommendation

**Active ability** (e.g. wall repair pulse or temporary slow) — high juice, fits portrait one-thumb UX, doesn't require second lane art. Alternative: support unit (repair drone) if ability feels too HUD-heavy.
