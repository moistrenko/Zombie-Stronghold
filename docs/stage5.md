# Этап 5 — волны 1–3 + win/lose (touch)

## Что сделано

- **WaveManager** (`scripts/battle/wave_manager.gd`) — дочерний узел battle, не autoload.
- 3 волны со спавном из `SpawnPoint` + разброс по X (±2.5).
- HUD: Wall HP + Wave status.
- **Victory**: все волны отспавнены и группа `zombies` пуста.
- **Defeat**: сигнал `wall.destroyed` (HP ≤ 0).
- Overlay на весь экран + крупная кнопка **RESTART** → `reload_current_scene()` (тач, без хоткеев).
- Одна турель без placement; оси/камера без изменений.

### Параметры волн

| Волна | Зомби | Интервал спавна |
|-------|-------|-----------------|
| 1 | 3 | 1.2 с |
| 2 | 5 | 1.0 с |
| 3 | 8 | 0.85 с |

- Пауза между волнами: **2.0 с**
- Разброс X: **±2.5**

### Win / Lose / Restart

1. `battle.gd` слушает `destroyed` и поллит очистку после `waves_finished`.
2. `_show_result(win)` стопит WaveManager, показывает `ResultOverlay`.
3. `RestartButton.pressed` → перезагрузка `battle.tscn`.

## Как проверить (F5)

1. Godot → F5.
2. HUD: `Wave 1/3`, зомби идут волнами; турель стреляет.
3. Если стена устояла до конца — **VICTORY** + RESTART.
4. Для **DEFEAT**: временно поднять `zombie_counts` / снизить turret damage, либо дождаться утечек на волне 3.
5. Тап/клик **RESTART** — бой с начала.

## Баланс / долги

- Волна 1 должна быть проходима одной турелью.
- Волна 3 на грани: часть зомби может дойти, стена потеряет HP — ок для MVP.
- Нет placement / магазина / меню вне боя.
- Win-check через `_process` + группу (достаточно для этапа).
