# Этап 11 — второй враг + вторая турель + Play Console prep

## Что сделано

- **Runner** (`scenes/enemies/zombie_runner.tscn`) — быстрый хрупкий враг (оранжевый, меньше меш); тот же `zombie.gd`, группа `zombies`.
- **Cannon** (`scenes/units/turret_cannon.tscn`) — медленная тяжёлая турель (оранжево-коричневый, крупнее); тот же `turret.gd` + общий projectile.
- HUD: две крупные кнопки **BASIC / CANNON** + `Selected: …` + `Turrets: N/3` (общий лимит 3).
- Ghost placement учитывает выбранный тип (размер силуэта).
- WaveManager спавнит микс типов по `wave_recipes`.
- Лёгкий чеклист Play Console: `docs/stage11_play_console_prep.md` (без публикации).

## Статы

### Враги

| | Basic (зелёный) | Runner (оранжевый) |
|--|-----------------|---------------------|
| `max_hp` | 30 | **18** |
| `move_speed` | 3.0 | **5.2** |
| `contact_damage` | 10 | **8** |
| Визуал | 0.8×1.4×0.8 | 0.55×1.0×0.55 |

### Турели (оба типа считают в `max_turrets = 3`)

| | Basic (синяя) | Cannon (оранжевая) |
|--|---------------|---------------------|
| `attack_range` | 12 | **13** |
| `fire_interval` | 0.7 с | **1.4 с** |
| `damage` | 15 | **40** |
| Projectile speed | 14 | 14 (общий scene) |
| Роль | стабильный DPS | медленный one-shot basic/runner |

## Волны

| Волна | Состав | Интервал |
|-------|--------|----------|
| 1 | 3× basic | 1.2 с |
| 2 | basic, runner, basic, runner, basic | 1.0 с |
| 3 | basic, runner, runner, basic, runner, basic, runner, basic | 0.85 с |

Пауза между волнами: 2.0 с.

## Баланс (задумка)

- Смесь Basic + Cannon у стены → волна 3 проходима с запасом HP.
- Только Cannon или плохая раскладка → runners чаще проскакивают и снимают HP.
- 0 турелей → DEFEAT.

## Как проверить (F5)

1. Godot → открыть проект → **F5** (main: `scenes/battle/battle.tscn`).
2. Сверху по центру HUD: кнопки **BASIC** / **CANNON**; справа `Selected: Basic`, `Turrets: 0/3`.
3. Нажать **CANNON** → `Selected: Cannon`; ghost в зоне крупнее.
4. Поставить смесь (напр. 2 Basic + 1 Cannon) в синюю полосу.
5. Волна 1 — только зелёные; с волны 2 появляются оранжевые runners.
6. Дойти до **VICTORY**; RESTART сбрасывает слоты и выбор на Basic.
7. Без турелей или слабая раскладка → ожидаемо урон стене / DEFEAT.

## Play Console

Только документ-чеклист: [`stage11_play_console_prep.md`](stage11_play_console_prep.md).  
Ассеты листинга: [`stage10b_store_assets.md`](stage10b_store_assets.md) / `assets/store/`.

## Долги

- Нет экономики / магазина / апгрейдов.
- iOS debug по-прежнему blocked (нет Team ID).
- Package ID placeholder `com.yourstudio.zombiestronghold`.
- Placeholder-меши; нет SFX/VFX пула снарядов.
- Нет headless autotest баланса — проверка руками F5 / Android smoke.
