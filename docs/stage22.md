# Этап 22 — Active abilities + smoother anims

## Что сделано

1. **Active abilities** (portrait one-thumb): **Wall Repair** + **Slow Pulse** with large right-edge HUD buttons, cooldown overlay (dim + timer text), disabled when on CD / out of charges.
2. **Meta hook**: Ability CD −15% (cap 2) in Meta Shop.
3. **Smoother animations**: 8-frame zombie strips + 6-frame turret strips; pipeline normalizes grids → horizontal strips; higher FPS; light sprite Y bob on zombies.

## Abilities

| Ability | Effect | Cooldown | Charges | Notes |
|---------|--------|----------|---------|-------|
| **REPAIR** | Restore **20** wall HP | **32 s** | **3 / run** | No-op at full HP / destroyed; green wall flash |
| **SLOW** | All zombies ×**0.5** speed for **3.5 s** | **30 s** | unlimited (CD only) | Applies to newly spawned while active |

Meta **Ability CD −15%** (levels 1–2, costs 15 / 25 ★) multiplies both CDs (×0.85 / ×0.70).

### UX (portrait 720×1280)

- `AbilityBar` — **right edge**, above ModeBar (`~−400…−140`), 128×112 buttons — does not block center placement lane or bottom BUILD/UPGRADE/SELL.
- Ready: `REPAIR ×N` / `SLOW`; on CD: dim overlay + seconds; Repair spent: `0` disabled.
- Blocked during pause / result / endless choice / game over.
- SFX: `Sfx.play_ability_repair()` / `play_ability_slow()` (procedural).

## Animation pipeline

Source sheets (also copied as legacy `*_sheet.png` names):

| File | Layout (source) | Processed | Frames / FPS |
|------|-----------------|-----------|--------------|
| `zombie_basic_run_8f.png` | 4×2 grid → strip | 8f horizontal | run @ **13** |
| `zombie_runner_run_8f.png` | 4×2 → strip | 8f | run @ **15** |
| `zombie_brute_walk_8f.png` | 4×2 → strip | 8f | walk @ **12** |
| `turret_basic_anim_6f.png` | 3×2 → strip | 6f | idle 2f@4 + fire 6f@**17** |
| `turret_cannon_anim_6f.png` | 3×2 → strip | 6f | idle 2f@4 + fire 6f@**17** |

`process_art.gd` chroma-keys green, rearranges any cols×rows grid into a **horizontal N-frame strip**, resizes.  
`build_sprite_frames.gd` slices strips left→right.

Zombie **bob**: small `sin` on sprite Y while moving.

Rebuild:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://scripts/tools/process_art.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://scripts/tools/build_sprite_frames.gd
```

## Как проверить (F5)

1. F5 → menu upright → PLAY.
2. Right side: **REPAIR ×3** / **SLOW** large buttons; ModeBar still usable.
3. Let wall take damage → REPAIR → HP +20, green flash, CD timer, charges −1.
4. SLOW during wave → zombies crawl (~half speed) ~3.5s; CD ~30s.
5. Pause / BUILD / UPGRADE / SELL / endless choice — unchanged.
6. Meta Shop → Ability CD −15% (if Stars); next run shorter CDs.
7. Anims: zombies 8-frame smoother run/walk; turrets subtler idle + smoother fire.

Headless smoke:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/menus/main_menu.tscn --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/battle/battle.tscn --quit-after 2
```

## Файлы

- `scripts/battle/battle.gd`, `wall.gd`
- `scripts/enemies/zombie.gd`
- `scripts/autoload/sfx.gd`, `meta_progress.gd`
- `scripts/ui/main_menu.gd`
- `scripts/tools/process_art.gd`, `build_sprite_frames.gd`
- `scenes/battle/battle.tscn`, `scenes/menus/main_menu.tscn`
- `assets/art/zombies/*_8f.png`, `assets/art/turrets/*_6f.png` (+ sheet aliases)
- `assets/art/**/processed/*`, `resources/sprites/*.tres`
- `docs/stage22.md`, `README.md`

## Долги

- Generated sheets may still be imperfect frame-to-frame consistency (AI art); re-gen if silhouettes jump.
- Cooldown overlay is text+dim, not true radial sweep.
- Repair charges not meta-upgradeable (+1 charge) — only CD reduction.
- Ability balance (20 HP / 3 charges / slow 3.5s) needs phone playtest vs Hard endless.
- Safe-area / notch: right AbilityBar may sit under gesture edge on some devices.

## Stage 23 recommendation

**Support unit** (repair drone / decoy) **or** achievements / daily — if abilities feel enough juice, prefer **RuStore portrait screenshots + store copy** (stage10b landscape docs still stale) before more combat systems.
