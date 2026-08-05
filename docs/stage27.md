# Этап 27 — Placement / upgrade / sell UX rebuild + difficulty removed

## Что сделано

1. **Removed** BUILD / UPGRADE / SELL mode bar and map-tap upgrade/sell modes.
2. **Bottom build bar** — large buttons for all placeables (Basic, Cannon, Support, Tesla, Sniper, Mine, Fence): icon, price corner, **(i)** info.
3. **Place mode** — select a type → dim silhouette ghost follows pointer; tap valid zone to spend scrap and place. Tap same button again, or empty/invalid ground, **cancels** place mode. Selection stays after a successful place (chain-build).
4. **Type info (i)** — portrait panel with damage/effect, fire rate, range, special notes, cost. Close via X, outside tap, or second tap on **(i)**.
5. **Placed unit inspector** — tap a placed unit → mini tooltip near it: **X**, **Sell** (55% refund), **Upgrade** (preview + price; disabled if maxed / unaffordable / Mine). Upgrade **(i)** shows post-upgrade stats. Only one inspector at a time.
6. **Inspector vs place** — opening inspector cancels place mode; picking a build type closes the inspector. Empty tap while inspector open closes it (no place that frame).
7. **Abilities** — REPAIR / SLOW moved to **left**, above the build bar (no overlap).
8. **Difficulty select removed** — Easy/Normal/Hard UI gone from main menu; `DifficultySettings` stub always returns **Normal** (1.0 multipliers). No Diff label on battle HUD / pause.
9. Preserved stage 26: wall-top placement, gate attack, slow shuffle speeds, endless waves, arsenal.

## UX flows

| Action | Result |
|--------|--------|
| Tap bar type (not i) | Enter place mode, highlight button, show ghost |
| Tap same type again | Cancel place mode |
| Tap valid zone while placing | Place, spend scrap, keep type selected |
| Tap empty/invalid while placing | Cancel place mode |
| Tap **(i)** on bar | Type stats tooltip |
| Tap placed unit | Open inspector (cancels place mode) |
| Inspector **Sell** | Refund `floor(base_cost × 0.55)`, remove unit |
| Inspector **Upgrade** | Spend upgrade cost, apply 1-level buff |
| Inspector upgrade **(i)** | Toggle post-upgrade stats |
| Tap empty (inspector open) | Close inspector |
| HUD buttons | `mouse_filter` STOP — do not place through UI |

## Which types upgrade

| Type | Sell | Upgrade | Upgrade effect (existing stage 16/24) |
|------|------|---------|----------------------------------------|
| Basic / Cannon / Tesla / Sniper | Yes | Yes (1 level) | +40% dmg, +15% range (+ Tesla chain) |
| Support | Yes | Yes | Aura +10%, radius ×1.25, drip +1 |
| Fence | Yes | Yes | HP ×1.4, wider, stronger slow |
| Mine | Yes | **No** | One-shot only |

Upgrade scrap is not refunded on sell.

## Difficulty (addon)

- Menu DiffBar removed; How-to no longer mentions Easy/Hard.
- Autoload kept as thin Normal-only stub (avoids churn in `wave_manager`).
- Stars / enemy mults no longer vary by difficulty pick.

## Как проверить (F5)

1. Menu: no Easy/Normal/Hard; PLAY → battle.
2. Bottom bar shows 7 types with prices; unaffordable price turns red.
3. Tap BASIC → ghost on wall strip; place → scrap drops; ghost remains for next place.
4. Tap BASIC again → cancel; no ghost.
5. Tap **(i)** on CANNON → stats panel; tap outside / X / i again → close.
6. Tap placed turret → inspector with Sell refund + Upgrade price; upgrade once → disabled “UPGRADED”; upgrade (i) shows after stats.
7. Tap Mine placed → Sell works, Upgrade disabled.
8. REPAIR / SLOW on left above bar; pause has no Difficulty line.
9. Wall-on turrets + approach mines/fences still work; gate chew 1 HP.

Headless smoke:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/menus/main_menu.tscn --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/battle/battle.tscn --quit-after 2
```

## Файлы

- `scripts/ui/placeable_catalog.gd` — type ids, icons, tooltip lines
- `scripts/ui/build_bar.gd` + `scenes/ui/build_bar.tscn`
- `scripts/ui/type_info_panel.gd` + `scenes/ui/type_info_panel.tscn`
- `scripts/ui/unit_inspector.gd` + `scenes/ui/unit_inspector.tscn`
- `scripts/battle/battle.gd`, `scenes/battle/battle.tscn`
- `scripts/ui/main_menu.gd`, `scenes/menus/main_menu.tscn`
- `scripts/autoload/difficulty_settings.gd` (Normal stub)
- `scripts/units/turret.gd` (`unit_kind` default `basic`)

## Техдолг / Stage 28

- Dedicated art for Mine/Fence bar icons (color swatches for now).
- Per-type upgrade preview silhouettes (tinted idle reuse).
- Optional: drag-to-place vs tap-to-place preference; long-press info.
- **Stage 28 recommendation:** audio/VFX polish for place/sell/upgrade + ability telegraph, or meta run summary / personal-best wave on result screen.
