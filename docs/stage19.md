# Этап 19 — Difficulty select (Easy / Normal / Hard)

## Что сделано

- Main menu: крупные кнопки **EASY / NORMAL / HARD** (default **Normal**).
- Выбор сохраняется между запусками (`user://difficulty.cfg`).
- Множители врагов применяются на spawn (wave recipes без переписывания).
- Scrap / Stars scale по сложности; meta upgrades стекаются сверху.
- HUD: `Diff: …`; pause overlay: `Difficulty: …`.
- How to play кратко упоминает difficulty.

## Final multipliers

| | Easy | Normal | Hard |
|--|------|--------|------|
| Enemy HP | ×0.85 | ×1.0 | ×1.25 |
| Enemy speed | ×0.9 | ×1.0 | ×1.1 |
| Contact damage | ×0.85 | ×1.0 | ×1.2 |
| Kill scrap | ×1.1 | ×1.0 | ×0.9 |
| Start scrap bonus | **+25** | 0 | 0 |
| Stars (victory) | ×0.85 | ×1.0 | ×1.15 |
| Stars (defeat) | ×0.85 | ×1.0 | ×1.1 |

Stars: `maxi(1, floor(base × mult))` если base > 0.  
Meta start-scrap / wall HP / turret dmg / max turrets применяются **до** difficulty start-scrap и **поверх** enemy mults (независимы).

## Persistence

```
user://difficulty.cfg
```

Секция `[settings]`: `difficulty` = `0` Easy / `1` Normal / `2` Hard.

Отдельно от `user://meta_progress.cfg`. **RESET META** difficulty не трогает.

## Autoload

`DifficultySettings` → `scripts/autoload/difficulty_settings.gd` (рядом с `MetaProgress`).

## Применение в battle

| Эффект | Где |
|--------|-----|
| Enemy HP / speed / contact / scrap | `wave_manager._apply_difficulty_stats` до `add_child` |
| Start scrap +25 (Easy) | `battle._apply_difficulty_bonuses` после meta |
| Stars scale | `battle._award_run_stars` после `MetaProgress.calc_*` |
| HUD / pause label | `battle._refresh_difficulty_labels` |

## Как проверить (F5)

1. Godot 4.7 → **F5** → main menu: **NORMAL** disabled (selected), EASY / HARD доступны.
2. Tap **HARD** → PLAY → HUD показывает `Diff: Hard`; pause → `Difficulty: Hard`.
3. Зомби ощутимо толще/быстрее (HP ×1.25, speed ×1.1); kill scrap чуть ниже.
4. MAIN MENU → выбор HARD всё ещё активен после возврата / restart редактора.
5. Easy → Scrap старт 125 (без meta); враги слабее.
6. Meta shop upgrades + Hard — оба эффекта на месте.

Headless smoke:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/menus/main_menu.tscn --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/battle/battle.tscn --quit-after 2
```

## Долги

- Нет endless / custom difficulty sliders.
- Баланс multipliers — стартовый тюнинг; нужен playtest на устройстве.
- Difficulty не на result overlay (только HUD + pause).
- Package ID placeholder / store upload — вне scope (stage 18 debt).

## Рекомендация этап 20

Art/VFX polish (meshes, Brute telegraph) **или** RuStore prep (listing copy + screenshots) **или** endless mode after wave 5.
