# Этап 2 — wall HP + 1 zombie walk

## Что сделано

- **Wall** (`scripts/battle/wall.gd`): `max_hp` / `current_hp` (100), `take_damage(amount)`, сигнал `hp_changed`, при HP ≤ 0 — `print("defeat")`, красный цвет, сигнал `destroyed`.
- **HUD**: `Label` «Wall HP: X / Y» на боевой сцене (`HUD/HpLabel`).
- **Zombie** (`scenes/enemies/zombie.tscn` + `scripts/enemies/zombie.gd`): зелёный плейсхолдер, идёт влево с постоянной скоростью, при касании фронта стены наносит урон и `queue_free()`.
- **Battle** (`scripts/battle/battle.gd`): при старте спавнит **одного** зомби в `SpawnPoint` и вызывает `setup(wall)`.

Числа по умолчанию:

| Параметр | Значение |
|----------|----------|
| Wall `max_hp` | 100 |
| Zombie `move_speed` | 120 px/s |
| Zombie `contact_damage` | 10 |

**Не сделано:** турели, пули, волны, win/lose UI, APK.

## Как проверить вручную

1. Открыть `project.godot` в Godot 4.3+.
2. Нажать **F5** (Run Project).
3. Справа появляется зелёный прямоугольник-зомби и едет влево к стене (~8 с).
4. В углу слева сверху: `Wall HP: 100 / 100` → после удара `90 / 100`.
5. Стена слегка краснеет; зомби исчезает.
6. Чтобы увидеть `defeat`: временно поставить `contact_damage = 100` на зомби или заспавнить 10 раз — в Output: `defeat`, стена тёмно-красная.

## Долги

- Один зомби за запуск; повторный урон / волны — этап 3+.
- Нет коллизий (только сравнение X с `get_front_x()`).
- Defeat только через `print`, без UI.
