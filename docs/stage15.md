# Этап 15 — 5 волн + мини-босс (Brute)

## Что сделано

- Волны расширены до **5** (ранние 1–3 почти как раньше; 4–5 нарастают).
- Мини-босс **Brute** (`scenes/enemies/zombie_brute.tscn`): крупный фиолетовый меш, высокий HP, медленный, высокий contact damage; тот же `zombie.gd`, группа `zombies`, scrap за kill.
- Preview Brute на **волне 4** (последний в рецепте); кульминация на **волне 5**.
- Победа: все 5 волн заспавнены + группа `zombies` пуста (логика `battle.gd` без изменений).
- HUD: `Wave X/5` (и статусы `next…` / `clear!`) через существующий `wave_changed` / `status_changed`.
- Between-wave Scrap: **12** (было 10) — чуть больше запаса на длинный прогон.

Экономика турелей (start / costs / kill basic+runner) **без изменений** — см. `docs/stage14.md`.

## Волны

| Волна | Состав | Интервал |
|-------|--------|----------|
| 1 | 3× basic | 1.2 с |
| 2 | basic, runner, basic, runner, basic | 1.0 с |
| 3 | basic, runner, runner, basic, runner, basic, runner, basic | 0.85 с |
| 4 | basic, runner, basic, runner, runner, basic, runner, **brute** | 0.8 с |
| 5 | basic, runner, runner, basic, runner, basic, runner, basic, runner, **brute** | 0.7 с |

Пауза между волнами: **2.0 с**. Between-wave Scrap начисляется после спавна волн 1–4 (4×12 = **48** за прогон).

## Brute (мини-босс)

| Параметр | Значение |
|----------|----------|
| `max_hp` | **200** |
| `move_speed` | **1.65** |
| `contact_damage` | **30** |
| `scrap_reward` | **45** |
| Визуал | 1.35×2.1×1.35, фиолетовый |

### Почему убиваемсфокусированным огнём

Оценка окна огня до стены (~8 с при скорости 1.65):

| Билд | DPS (примерно) | Урон за окно focus |
|------|----------------|--------------------|
| 3× Basic | ~64 | ~500+ |
| 2× Basic + 1× Cannon | ~71 | ~550+ |
| 1× Basic (слабый) | ~21 | ~170 — Brute доходит |

HP **200** → 2 Basic + Cannon или 3 Basic убивают Brute, если эскорт не отвлекает слишком сильно. Слабый билд / утечки runners → урон стене / DEFEAT на 4–5 — OK.

## Экономика (твики этапа 15)

| Параметр | Было (14) | Стало (15) |
|----------|-----------|------------|
| Start Scrap | 100 | 100 |
| Basic / Cannon cost | 50 / 90 | 50 / 90 |
| Kill basic / runner | 12 / 18 | 12 / 18 |
| Kill brute | — | **45** |
| Between-waves | 10 | **12** |
| max_turrets | 3 | 3 |

## Как проверить (F5)

1. Godot 4.7 → **F5** → main menu → **PLAY**.
2. HUD: **Wave 1/5**; Scrap **100**; pause / type select на месте.
3. Волны 1–3: привычный микс basic/runner; между волнами Scrap +12.
4. Волна 4: крупный фиолетовый **Brute** в конце состава.
5. Волна 5: плотнее + Brute снова; при хорошем билде (2 Basic + Cannon / 3 Basic) — убить босса → **VICTORY**.
6. Слабый билд / мало турелей → ожидаемо **DEFEAT** на поздних волнах.
7. RESTART / MAIN MENU без регрессий economy / pause / SFX.

Headless smoke:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/menus/main_menu.tscn --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/battle/battle.tscn --quit-after 2
```

## Долги

- ~~Нет sell / upgrade / shop.~~ → этап 16 (`docs/stage16.md`).
- Brute — placeholder mesh/color; нет отдельной анимации/SFX босса.
- Turrets всегда бьют nearest — нет prioritize-boss.
- Баланс 4–5 волн не прогнан autotest’ом (только headless load + ручной F5).
- iOS / package id — без изменений.

## Рекомендация этап 16

Sell/upgrade турелей **или** meta progression между боями **или** Android AAB + финальный package id.
