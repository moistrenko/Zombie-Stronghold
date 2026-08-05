# Этап 26 — Fortress wall, on-wall placement, gate attack, slow zombies

## Что сделано

1. **Fortress wall visual** — `Sprite3D` gate (`wall_fortress_gate_v1`) + optional rampart top; thin mesh base kept for depth. Gate hit flash (red) / repair flash (green).
2. **On-wall placement** — turrets / support / tesla / sniper place on the **rampart** (elevated Y), not on the ground strip in front.
3. **Gate attack loop** — zombies stop at the gate, play `attack` anim, deal **1 HP** per strike until dead or wall destroyed (no one-shot contact).
4. **Much slower move speeds** — shuffle walk; walk anim FPS lowered; Hard speed mult capped so it stays a crawl.

## Wall / gate

| Item | Value |
|------|-------|
| Wall node | `(0, 1, 6)` |
| Gate contact `front_z` | `wall.z + front_offset_z` (−0.5) → **≈5.5** |
| Visual | processed `wall_fortress_gate_v1.png` + `wall_rampart_top_v1.png` |
| Hit flash | gate modulate red ~0.22s |
| Rampart Y (units) | **1.35** |

## Placement zones

| Type | Zone | Z range | Y |
|------|------|---------|---|
| Basic / Cannon / Support / Tesla / Sniper | **Wall top** | **[5.35, 6.2]** | **1.35** (rampart) |
| Mine | Approach strip (before gate) | **[0.8, 4.9]** | 0 |
| Fence | Approach path (before gate) | **[2.0, 4.9]** | 0 |
| X (all) | — | **[−5, 5]** | — |

**Choice:** mines stay on the approach strip just before the gate (gameplay — tripwire on the path). Fences also stay on the path. Only shooting/support defenses sit on the wall.

Ghost + place snap to the same Y. Camera nudged (`y≈20.5`, `z≈14.5`, fov **60**) so the rampart strip is readable/clickable in portrait.

## Gate attack

| Type | Interval | Damage / hit |
|------|----------|--------------|
| Basic | **1.0 s** | **1** |
| Runner | **0.9 s** | **1** |
| Brute | **0.75 s** | **1** |

- On reach gate: stop move, loop `attack` SpriteFrames (6f @ 10 FPS).
- Still **targetable** while attacking (turrets can finish them).
- Slow ability stretches attack interval (`interval / speed_mult`).
- Barricade chew still uses `contact_damage` (base **1**, difficulty mult applies). Gate always uses `gate_hit_damage = 1` (not difficulty-scaled).

## Move speeds (Normal)

| Type | Was | Now |
|------|-----|-----|
| Basic | 3.0 | **1.1** |
| Runner | 5.2 | **1.5** |
| Brute | 1.65 | **0.8** |

Walk/run anim FPS: basic **8**, runner **9**, brute **7** (shuffle).

### Difficulty speed mult (updated)

| | Easy | Normal | Hard |
|--|------|--------|------|
| Speed | ×0.9 | ×1.0 | **×1.05** (was 1.1) |
| Contact (barricade chew only) | ×0.85 | ×1.0 | ×1.15 |

Hard basic ≈ **1.16**, runner ≈ **1.58** — still a shuffle, not a run.

## Art pipeline

```bash
# Copy sources into assets/art/{environment,zombies}/ then:
Godot --headless --path . -s res://scripts/tools/process_art.gd
Godot --headless --path . --import
Godot --headless --path . -s res://scripts/tools/build_sprite_frames.gd
```

New sheets: `zombie_*_attack_6f.png` (3×2 → 6f strip). Wall singles chroma-keyed.

## Как проверить (F5)

1. PLAY → fortress wall with closed gates at bottom; blue strip on wall top, brown approach strip.
2. Place BASIC on blue wall strip → turret sits elevated on rampart.
3. Place MINE/FENCE on brown approach → ground level before gate.
4. Let a zombie reach the gate → attack anim loops; Wall HP ticks −1 per strike (not −10/−30).
5. Speeds feel like a crawl; runner slightly faster than basic; Hard still slow.
6. SLOW ability while attacking → hits slow down; scrap/kill still work.

Headless smoke:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/menus/main_menu.tscn --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/battle/battle.tscn --quit-after 2
```

## Файлы

- `scripts/battle/wall.gd`, `battle.gd`
- `scripts/enemies/zombie.gd`
- `scripts/autoload/difficulty_settings.gd`
- `scripts/tools/process_art.gd`, `build_sprite_frames.gd`
- `scenes/battle/battle.tscn`
- `scenes/enemies/zombie.tscn`, `zombie_runner.tscn`, `zombie_brute.tscn`
- `assets/art/environment/wall_*.png` (+ processed)
- `assets/art/zombies/zombie_*_attack_6f.png` (+ processed)
- `resources/sprites/zombie_*_frames.tres`
- `docs/stage26.md`, `README.md`

## Tech debt

- Wall sprite facing is fixed (not billboard); may need per-device pixel_size tweak.
- Gate art may still show some chroma fringe — re-key if owner flags it.
- Approach/wall zone overlays are debug-ish translucents; can hide for release polish.
- Fence chew at 1 dmg/tick is much tankier vs old brute-30 model — may need fence HP retune later.
- No dedicated gate-open/break visual on defeat (tint only).

## Рекомендация — этап 27

**Boss / elite wave juice + wall breach VFX** — distinct gate-crack states at HP thresholds, stronger brute telegraphs, and a clear “breached” defeat beat so the new 1 HP/tick siege reads as drama rather than a slow drain.
