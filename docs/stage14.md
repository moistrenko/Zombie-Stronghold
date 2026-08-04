# Этап 14 — простая экономика (Scrap)

## Что сделано

- Валюта боя: **Scrap** (стартовый запас + награды за убийства + небольшой бонус между волнами).
- Стоимость размещения: **Basic** дешевле, **Cannon** дороже; общий лимит `max_turrets = 3` сохранён.
- Ghost: красный, если не хватает Scrap или турели слишком близко; скрыт при лимите слотов / вне зоны (как раньше).
- HUD: крупный `Scrap: N`, кнопки `BASIC · cost` / `CANNON · cost`, flash Scrap при недостатке средств.
- RESTART / reload сбрасывает Scrap на стартовое значение; MAIN MENU не трогает (новый бой стартует заново).

## Финальные числа

| Параметр | Значение |
|----------|----------|
| Start Scrap | **100** |
| Basic turret cost | **50** |
| Cannon turret cost | **90** |
| Kill reward (basic) | **12** (`zombie.gd` default `scrap_reward`) |
| Kill reward (runner) | **18** (`zombie_runner.tscn`) |
| Between-waves income | **10** (после спавна волны 1 и 2, перед паузой) |

Экспорты на `battle.gd`: `start_scrap`, `basic_turret_cost`, `cannon_turret_cost`, `scrap_between_waves`.

## Баланс (задумка)

- На старте: ровно **2 Basic** (100) **или** 1 Cannon (90) **или** 1 Basic; **не** 3 турели сразу и **не** 2 Cannon.
- Третья турель — после убийств / wave bonus (после волны 1 при 2 Basic: ~36 + 10 ≈ хватает на ещё один Basic).
- Полный прогон с разумной тратой (2 Basic + 1 Cannon ≈ 190) достижим за счёт киллов волны 2–3; волна 3 остаётся проходимой.
- Wall-hit зомби Scrap не дают (только `killed` при HP ≤ 0).

## Интеграция

- `zombie.gd` → `signal killed(scrap_amount)` + `@export scrap_reward`
- `wave_manager.gd` → `enemy_killed`, `between_waves`
- Pause / SFX / result overlay без изменений процесса; таймеры wave manager паузятся вместе с деревом

## Как проверить (F5)

1. Godot 4.7 → **F5** → main menu → **PLAY**.
2. Справа сверху: **Scrap: 100**; кнопки **BASIC · 50** / **CANNON · 90**.
3. Поставить 2 Basic → Scrap: 0; ghost в зоне красный (can't afford) / flash Scrap при тапе.
4. Пережить волну / убивать → Scrap растёт; поставить ещё турель или Cannon когда хватает.
5. Дойти до VICTORY / DEFEAT → **RESTART** → Scrap снова 100; **MAIN MENU** → PLAY → снова 100.
6. Pause / mute / type select — без регрессий.

Headless smoke:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/menus/main_menu.tscn --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/battle/battle.tscn --quit-after 2
```

## Долги

- Нет sell / upgrade / shop UI.
- Wave bonus начисляется после спавна волны (зомби ещё могут быть живы) — осознанно просто.
- Placeholder HUD labels.
- iOS debug / package id — без изменений.

## Рекомендация этап 15

→ Сделано: больше волн + мини-босс — см. `docs/stage15.md`.
