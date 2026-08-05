# Этап 25 — Battlefield backdrop polish

## Что сделано

1. **v3 environment art** reprocessed (green chroma key + resize): asphalt, sky, large car/truck, debris, barrier, **distant skyline**.
2. **Hero wrecks** — cars/truck scaled ~**2.2×** prior `pixel_size` so they dominate left/right flanks.
3. **Composition** — staggered props along both sides; center lane + placement zone (`|x|≲5`) kept clear.
4. **Distant skyline** — 2× fogged/darkened sprites deeper than spawn (z≈−15).
5. **Mood** — warmer key light, cool fill, richer fog; units stay readable.
6. **Juice** — `prop_fire_flicker.gd` subtle modulate pulse on burning props.

## Scale (`pixel_size`)

| Prop | Was | Now | ≈ factor |
|------|-----|-----|----------|
| Car hero (L) | 0.0028 | **0.0062** | ~2.2× |
| Truck hero (R) | 0.0030 | **0.0066** | ~2.2× |
| Car far L/R | 0.0026 | **0.0054 / 0.0055** | ~2.1× |
| Debris | 0.0020–0.0024 | **0.0029–0.0036** | medium-large |
| Barrier | 0.0025 | **0.0035** | ~1.4× |
| Skyline | — | **0.0088–0.0095** | new, fogged |

Processed max widths: car/truck/skyline **1280**, barrier **1024**, debris **768**.

## Prop layout (XZ ≈)

Lane free: props at **|x| ≥ ~6.5**. Placement zone unchanged.

| Prop | ≈ (x, z) |
|------|----------|
| Skyline L / R | (−5.5, −15.5), (5.8, −14.8) |
| Car hero L | (−7.4, −3.8) |
| Truck hero R | (7.5, −0.8) |
| Car far L / R | (−7.6, −8.2), (7.2, −9.2) |
| Debris | (−6.9, 0.6), (6.8, −5.2), (7.0, 1.8), (−6.6, 5.5), (6.5, 5.4) |
| Barriers | (−7.1, 3.4), (7.2, 3.0) |

Sky quad: z≈−20, y≈11. Ground plane 28×28, UV scale 5×5.

## Pipeline

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://scripts/tools/process_art.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://scripts/tools/build_sprite_frames.gd
```

`process_art.gd` SINGLES now includes `prop_ruins_skyline.png` with `key: true`.

## Как проверить (F5)

1. F5 → PLAY → warmer asphalt/sky, large wrecks on sides, faint skyline behind spawn.
2. Center lane + blue placement strip clear; no prop blocking |x| < 5.
3. Burning cars/debris show mild flicker; gameplay (waves/place/abilities) unchanged.
4. Pause / retire / defeat still work.

Headless smoke:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/menus/main_menu.tscn --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/battle/battle.tscn --quit-after 2
```

## Файлы

- `scripts/tools/process_art.gd`
- `scripts/battle/prop_fire_flicker.gd`
- `assets/art/environment/{,processed/}*` (+ `prop_ruins_skyline.png`)
- `scenes/battle/battle.tscn`
- `docs/stage25.md`, `README.md`

## Долги

- Billboard props still read as “cards” from extreme angles.
- Skyline is a flat cutout (no parallax / layered depth).
- Fire flicker is modulate-only (no flame VFX / particles).
- Chroma soft-key may thin bright yellow fire edges — tune if needed.
- Fill light + fog values are F5-tuned; Hard/endless late waves not visually re-checked.

## Stage 26 recommendation

Return to **gameplay**: **achievements / milestones** (wave 10/25/50 badges + Stars) **or** a **second ability slot** (e.g. Airstrike / Overclock). Prefer achievements if store listing needs retention hooks; ability slot if combat depth is the focus.
