# Этап 17 — Light meta progression between runs

## Что сделано

- **Stars** — meta currency, начисляются в конце рана (win/lose overlay).
- **Meta Shop** на main menu: 4 постоянных апгрейда за Stars.
- Бонусы применяются при старте battle (autoload `MetaProgress`).
- Persist через `ConfigFile` → `user://meta_progress.cfg` (переживает restart).
- **RESET META** в Meta Shop (и описано в How to play) для тестов.
- Battle systems (waves, scrap, sell/upgrade, pause) без изменений логики.

## Earn rules (Stars)

| Исход | Формула | Диапазон (5 волн) |
|-------|---------|-------------------|
| **Victory** | `15 + floor(hp_ratio × 10)` | 15–25 |
| **Defeat** | `3 × waves_reached` | 3–15 (wave 1–5) |

`hp_ratio` = current wall HP / max HP на момент победы.  
`waves_reached` = номер волны, активной когда стена пала (минимум 1).

На overlay: `+N Stars`. Баланс сохраняется сразу в `user://`.

## Upgrades (permanent)

| Upgrade | Эффект / уровень | Cap | Costs (по порядку) |
|---------|------------------|-----|---------------------|
| Starting Scrap +25 | +25 Scrap | 4 | 8, 12, 18, 28 |
| Wall Max HP +20 | +20 max HP | 5 | 8, 12, 18, 25, 35 |
| Turret Damage +5% | ×1.05 global на place | 5 | 10, 15, 22, 30, 40 |
| +1 Max Turrets | max_turrets 3→4 | 1 | 40 |

Не хватает Stars → кнопка disabled. Maxed → `MAX`.

## Применение в battle

| Бонус | Где |
|-------|-----|
| Start Scrap | `start_scrap += bonus` до HUD |
| Wall HP | `wall.apply_max_hp_bonus()` |
| Turret dmg | множитель на `damage` при place |
| Max turrets | `max_turrets += bonus` |

Без сейва / headless → defaults (0 Stars, lvl 0).

## Save path

```
user://meta_progress.cfg
```

Секция `[meta]`: `stars`, `lvl_start_scrap`, `lvl_wall_hp`, `lvl_turret_dmg`, `lvl_max_turrets`.

**Сброс:** Meta Shop → **RESET META**, либо удалить файл в user data Godot.

## Autoload

`MetaProgress` → `scripts/autoload/meta_progress.gd` (рядом с `Sfx`).

## Как проверить (F5)

1. Godot 4.7 → **F5** → main menu: **Stars: 0**, кнопки **PLAY / META SHOP / HOW TO PLAY**.
2. PLAY → пройти до VICTORY или DEFEAT → overlay показывает `+N Stars`.
3. MAIN MENU → Stars обновлены → META SHOP → купить Starting Scrap (если хватает).
4. PLAY снова → Scrap старт = 100 + 25×lvl; Wall HP / dmg / slots по купленным.
5. META SHOP → RESET META → Stars 0, уровни 0.
6. Pause / sell / upgrade / волны — без регрессий.

Headless smoke:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/menus/main_menu.tscn --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/battle/battle.tscn --quit-after 2
```

## Долги

- ~~Нет difficulty select~~ → сделано в stage 19. Endless ещё нет.
- Meta балансировка не прогнана длинным playtest.
- Нет confirm на Reset Meta (осознанно для быстрых тестов).
- Turret dmg meta применяется на place; in-run upgrade множит уже бафнутый base (OK для light meta).
- iOS signing / store submit по-прежнему вне scope.

## Рекомендация этап 18

Android AAB prep + package id hygiene **или** art/VFX polish (meshes, Brute telegraph) **или** difficulty select (Normal/Hard).
