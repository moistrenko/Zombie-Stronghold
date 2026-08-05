# Этап 24 — Infinite run + expanded defenses

## Что сделано

1. **Truly endless waves** from Wave 1 — no campaign end, no CLAIM VICTORY gate. Defeat = wall HP ≤ 0. Optional **RETIRE (Stars)** in Pause.
2. **Unlimited placement** — limit = scrap + build zone + min distance only (no `max_turrets`).
3. **Defense assortment**: Basic, Cannon, Support, Tesla, Sniper + Mines + Fence (barricade).
4. Meta **+1 Max Turrets** reworked → **Build Cost −10%** (same save key `lvl_max_turrets`).
5. Economy bump: start scrap **130**, between-waves **15** (+2/wave after 5).

## Wave scaling (infinite)

All waves use the same procedural loop (`wave_manager.gd`):

| Param | Formula | Notes |
|-------|---------|-------|
| Count | `clamp(3 + floor((w−1)×1.35), 3, 48)` | Soft early, caps at 48 |
| HP mult | `1 + 0.055×(w−1)` | Stacks with difficulty HP mult |
| Interval | `max(0.28, 1.15 − 0.045×(w−1))` | Faster spawns over time |
| Mix | W1 basic only; runners from W2; brutes from W4 | Chances rise with depth |

HUD: **`Wave N`** (never `/5`). Between waves: wait field clear → scrap payout → next.

## Placement rules

| Rule | Value |
|------|-------|
| Hard unit cap | **none** (except Support) |
| Support cap | **max_supports = 1** (aura stacking) |
| Min distance | **1.6** (all placeables) |
| Turret/Support/Fence zone X | **[−5, 5]** |
| Turret/Support/Fence zone Z | **[2.0, 5.5]** |
| Mine zone Z | **[0.8, 5.5]** (slightly forward toward spawn) |
| Sell refund | **55%** of paid base cost (upgrade scrap not refunded) |

HUD: `Units: N` (count only). Ghost valid/invalid for all types.

## Defense table

### Turrets / Support

| Type | Cost | Range | RoF (s) | Damage | Notes |
|------|------|-------|---------|--------|-------|
| **Basic** | 50 | 12 | 0.7 | 15 | Projectile |
| **Cannon** | 90 | 13 | 1.4 | 40 | Heavy projectile |
| **Support** | 70 | aura **4** | — | — | +**20%** dmg to nearby turrets; **+2 scrap / 5s**. No shots. Upgrade: radius×1.25, +10% aura, drip +1 |
| **Tesla** | 75 | 9 | 0.9 | 18 | Arc: **2** chain jumps, falloff ×0.7, radius 3.5. Upgrade: +1 jump |
| **Sniper** | 110 | 18 | 2.2 | 70 | Long-range slow fire |

Upgrade costs (base): Basic 30 / Cannon 50 / Support 40 / Tesla 45 / Sniper 55.  
Meta **Turret Damage +5%** applies to shooting turrets on place. Support aura stacks multiplicatively on effective damage.

### Non-turret defenses

| Type | Cost | Stats | Behavior |
|------|------|-------|----------|
| **Mine** | 25 | trigger 1.25, dmg **45** | Arms 0.35s; one-shot; consumed. No upgrade. Forward strip OK |
| **Fence** | 45 | HP **80**, half-width **1.35**, slow ×**0.35** | Blocks/chews zombies in X strip; contact DPS every 0.45s. Upgrade: HP×1.4, wider, slower |

Visuals: Support/Tesla/Sniper = tinted existing turret sprites; Mine = red cylinder; Fence = brown box.

## Stars (run end)

| Exit | Formula |
|------|---------|
| **Defeat** | `3×wave + 2×max(0, wave−5)` × difficulty defeat mult |
| **Retire** | same + `floor(hp_ratio × 10)` HP bonus × difficulty victory mult |

Pause → **RETIRE (Stars)** → overlay `RETIRED`. Wall death → `DEFEAT`.

## Meta changes

| Upgrade | Was | Now |
|---------|-----|-----|
| `MAX_TURRETS` / `lvl_max_turrets` | +1 max turrets (cap 1, cost 40★) | **Build Cost −10%** on place/upgrade costs (cap 1, cost 40★) |

Other upgrades unchanged (Start Scrap, Wall HP, Turret Dmg, Ability CD).

## Как проверить (F5)

1. F5 → menu upright → PLAY.
2. HUD: `Wave 1`, `Units: 0`, `Scrap: 130`; two rows BASIC/CANNON/SUPPORT/TESLA + SNIPER/MINE/FENCE.
3. Place freely beyond 3 units if scrap allows; no N/3 cap.
4. Support greens nearby turrets (+dmg); scrap ticks every ~5s.
5. Tesla arcs; Sniper long shots; Mine pops; Fence slows/blocks until chewed.
6. Waves never stop at 5; runners/brutes appear as documented.
7. Pause → RETIRE → Stars; or die → DEFEAT + Stars by wave.
8. Meta Shop: **Build Cost −10%** (not max turrets).

Headless smoke:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/menus/main_menu.tscn --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/battle/battle.tscn --quit-after 2
```

## Файлы

- `scripts/battle/battle.gd`, `wave_manager.gd`
- `scripts/units/turret.gd`, `support.gd`, `mine.gd`, `barricade.gd`
- `scripts/enemies/zombie.gd`
- `scripts/autoload/meta_progress.gd`
- `scenes/units/support.tscn`, `turret_tesla.tscn`, `turret_sniper.tscn`, `mine.tscn`, `barricade.tscn`
- `scenes/units/turret.tscn`, `turret_cannon.tscn`
- `scenes/battle/battle.tscn`, `scenes/menus/main_menu.tscn`
- `docs/stage24.md`, `README.md`

## Долги

- Tesla has no bolt VFX (instant chain damage only).
- Support / Tesla / Sniper reuse tinted Basic/Cannon art — dedicated sprites later.
- Fence collision is soft (Z front + X strip), not a physics body.
- Late-game count cap 48 + HP growth may need Hard playtest balance.
- EndlessOverlay nodes still in `battle.tscn` but unused (hidden).
- Safe-area: two-row TypeBar may crowd notch devices with AbilityBar.

## Stage 25 recommendation

**Achievements / milestones** (wave 10/25/50 badges, Stars) **or** second ability slot **or** dedicated Support/Tesla art + Tesla bolt VFX — if store-facing, prefer **portrait RuStore/Play screenshots** of the new defense HUD.
