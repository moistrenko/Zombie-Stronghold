# Этап 20 — Generated art + animations + apocalypse battlefield

## Что сделано

- Зомби (basic / runner / brute): цветные боксы заменены на `AnimatedSprite3D` + `SpriteFrames` (Y-billboard).
- Турели (basic / cannon): idle + fire sheets; `YawPivot` крутит спрайт к цели; короткий fire-цикл, затем idle; `Barrel` (Marker3D) — точка спавна снаряда.
- Ghost placement: силуэт idle-текстуры с green/red modulate.
- Battlefield: асфальт с UV tiling, props по бокам полосы, sky quad, тёплый DirectionalLight + лёгкий fog.
- White/light BG у исходных PNG: headless helper → `assets/art/.../processed/` с alpha.

## White BG → alpha

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://scripts/tools/process_art.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://scripts/tools/build_sprite_frames.gd
```

- Порог: RGB ≥ **0.92** → soft alpha (ближе к белому = прозрачнее).
- Resize: sheets ≤1024w, props ≤640–768, ground/sky ≤1024. Оригиналы в `assets/art/` не трогаем.
- Ground/sky **не** кейятся (полнокадровые текстуры).

## Анимации

| Resource | Anim | Frames | FPS | Loop |
|----------|------|--------|-----|------|
| `resources/sprites/zombie_basic_frames.tres` | `run` | 4 (2×2 sheet) | 8 | yes |
| `resources/sprites/zombie_runner_frames.tres` | `run` | 4 | 10 | yes |
| `resources/sprites/zombie_brute_frames.tres` | `walk` | 4 | 6 | yes |
| `resources/sprites/turret_basic_frames.tres` | `idle` / `fire` | 1 / 4 | 1 / 14 | yes / no |
| `resources/sprites/turret_cannon_frames.tres` | `idle` / `fire` | 1 / 4 | 1 / 14 | yes / no |

Hit/kill feedback: modulate + scale punch на спрайте (без mesh materials).

## Props layout (XZ)

Центр полосы (|x|≲6, placement z∈[2, 5.5]) свободен. Props на боках:

| Prop | ≈ position |
|------|------------|
| Car (burning) | (−8.2, −4.5), (7.2, −9) |
| Truck wreck | (8.6, −1.5) |
| Debris | (−7.8, 1.2), (7.5, −6.5), (−7.6, 5.8) |
| Ruins barrier | (−8.4, 4.2), (8.3, 3.8) |

Sky quad: z≈−18, y≈8.5. Ground UV scale 4×4.

## Как проверить (F5)

1. Godot 4.7 → **F5** → PLAY → asphalt + sky + wreck props по бокам.
2. Волна 1: basic zombie бежит (run loop), Y-billboard к камере.
3. Поставить Basic → idle спрайт; при выстреле yaw к зомби + fire frames → idle.
4. Cannon: то же, крупнее / медленнее fire.
5. Wave 2+: runner быстрее (10 fps); wave 4–5: brute walk (6 fps).
6. Hit flash / kill pop на спрайтах; scrap / upgrade / sell / pause / difficulty без регрессий.
7. Ghost: зелёный/красный силуэт турели в BUILD.

Headless smoke:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/battle/battle.tscn --quit-after 2
```

## Файлы

- `scripts/tools/process_art.gd`, `build_sprite_frames.gd`
- `assets/art/{zombies,turrets,environment}/processed/*`
- `resources/sprites/*.tres`
- `scripts/enemies/zombie.gd`, `scripts/units/turret.gd`, `scripts/battle/battle.gd`
- `scenes/enemies/*.tscn`, `scenes/units/turret*.tscn`, `scenes/battle/battle.tscn`

## Долги

- Sheet layout предполагается **2×2**; если генерация даст 1×4 — перерезать atlas.
- Keying soft-edge может съесть очень светлые блики на спрайтах.
- Turret без full Y-billboard (yaw важнее) — сбоку выглядит «карточкой».
- Нет отдельного death anim / dust VFX.
- Prop/sprite pixel_size — стартовый тюнинг под F5.

## Рекомендация этап 21

RuStore / Play listing polish (screenshots на новом art) **или** endless after wave 5 **или** Brute telegraph + death VFX.
