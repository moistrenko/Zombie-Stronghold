# Этап 16 — Sell + simple upgrade

## Что сделано

- Режимы взаимодействия **BUILD / UPGRADE / SELL** — взаимно исключающие крупные кнопки внизу HUD (`ModeBar`).
- **Sell:** в режиме SELL placement отключён, ghost скрыт; тап рядом с турелью продаёт её.
- **Upgrade (1 уровень):** в режиме UPGRADE тап по турели тратит Scrap и бафает урон/дальность; повторный апгрейд запрещён.
- Type select BASIC/CANNON активен только в BUILD (в других режимах TypeBar приглушён).
- Пауза, волны, win/lose, kill-scrap — без изменений.

## Mode UX

| Режим | Поведение |
|-------|-----------|
| **BUILD** (default) | Ghost placement как раньше; тап/release ставит турель |
| **UPGRADE** | Ghost скрыт; тап в радиусе ~1.9 юнита у турели → upgrade |
| **SELL** | Ghost скрыт; тап у турели → sell + refund |

Подсказка в `SelectedLabel`:

- `BUILD: Basic (50)` / `BUILD: Cannon (90)`
- `UPGRADE: tap turret (30 / 50)`
- `SELL: tap turret (55% refund)`

## Sell — refund

| Правило | Значение |
|---------|----------|
| Ratio | **55%** от `base_cost` покупки |
| Basic | floor(50 × 0.55) = **27** Scrap |
| Cannon | floor(90 × 0.55) = **49** Scrap |
| Upgrade spent | **не** возвращается |
| Slot | освобождается (`turret count--`) |
| SFX | `play_hit` |

Sell → rebuild невыгоден (теряешь 45% + весь upgrade), экономика не ломается.

## Upgrade — cost + stats

| Тип | Upgrade cost | Бонусы (один раз) | Визуал |
|-----|--------------|-------------------|--------|
| Basic | **30** | damage ×1.4, range ×1.15 | scale 1.18 + тёплый tint |
| Cannon | **50** | damage ×1.4, range ×1.15 | то же |

Примеры после апгрейда:

| Турель | damage | range | fire_interval |
|--------|--------|-------|---------------|
| Basic base → up | 15 → **21** | 12 → **13.8** | 0.7 (без изменений) |
| Cannon base → up | 40 → **56** | 13 → **14.95** | 1.4 (без изменений) |

Нельзя апгрейднуть дважды. Не хватает Scrap / уже upgraded → no-op + flash Scrap (красный).

Vs Brute: апгрейд помогает (особенно Cannon), но 2× Basic + Cannon без апгрейдов по-прежнему проходимы при фокусе.

## Экономика (сводка)

| Параметр | Значение |
|----------|----------|
| Start Scrap | 100 |
| Basic / Cannon place | 50 / 90 |
| Basic / Cannon upgrade | 30 / 50 |
| Sell refund | 55% base_cost |
| Kill / between-wave | как этап 15 (12/18/45; +12) |
| max_turrets | 3 |

## Как проверить (F5)

1. Godot 4.7 → **F5** → main menu → **PLAY**.
2. Внизу HUD: **BUILD** (active) / **UPGRADE** / **SELL**.
3. BUILD: поставить Basic → Scrap 50; слот 1/3.
4. SELL → тап по турели → Scrap +27 (итого 77), слот 0/3; ghost не появляется.
5. BUILD → поставить снова → UPGRADE → тап → Scrap −30; турель крупнее + теплее цвет; повторный тап — flash Scrap, без эффекта.
6. Cannon: place 90 → upgrade 50 → sell refund 49 (upgrade потерян).
7. Pause / волны / VICTORY-DEFEAT / MAIN MENU без регрессий.

Headless smoke:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/menus/main_menu.tscn --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/battle/battle.tscn --quit-after 2
```

## Долги

- Нет meta progression между ранами.
- Нет prioritize-boss / target modes.
- Upgrade только 1 уровень; нет дерева/веток.
- Sell/upgrade без отдельного confirm (осознанно для mobile speed).
- Баланс sell/upgrade не прогнан длинным playtest.

## Рекомендация этап 17

Meta progression между ранами (persistent scrap / unlock) **или** Android AAB prep **или** polish/art pass (meshes, Brute VFX).
