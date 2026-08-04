# Этап 12 — game-feel polish (feedback)

## Что сделано

Визуальный и звуковой фидбек без новых игровых систем (типы врагов/турелей, экономика, волны — без изменений).

### Visual

| Событие | Фидбек |
|---------|--------|
| Hit по зомби | Короткий flash/emission + scale punch (`zombie.gd`, basic + runner) |
| Kill | Kill pop: яркий burst → scale-down → `queue_free` (~0.2 с) |
| Turret fire | Emissive pulse на корпусе + muzzle flash у ствола |
| Projectile | Чуть ярче emission + короткий trail-капсула |
| Wall damage | Сильный red flash + emission; мягкий camera shake (~0.14 с); мигание `Wall HP` |
| Placement | Pulse scale турели + зелёный blink `Turrets N/3` |

### Audio

Autoload **`Sfx`** (`scripts/autoload/sfx.gd`) — procedural `AudioStreamWAV` (без внешних ассетов), пул `AudioStreamPlayer`, bus Master.

| Звук | Когда |
|------|--------|
| place | Успешная постановка турели |
| shoot | Выстрел турели |
| hit | Попадание (не летальное) |
| kill | Смерть зомби |
| wall_hit | Урон стене |
| victory / defeat | Экран результата |

Работает на mobile export (нет editor-only API).

## Как проверить (F5)

1. Godot 4.7 → открыть проект → **F5** (`scenes/battle/battle.tscn`).
2. Поставить турель в синюю зону → слышен place blip, турель слегка «пульсирует», `Turrets` мигает зелёным.
3. Дождаться выстрела → muzzle flash + shoot SFX; снаряд с коротким trail.
4. Попадание по зомби → flash/punch + hit SFX; kill → pop + kill SFX.
5. Дать зомби дойти до стены (или без турелей) → яркий flash стены + лёгкий shake + wall_hit SFX.
6. Дойти до **VICTORY** / **DEFEAT** → соответствующий jingle.
7. Placement / type select / ghost / волны 1–3 — без регрессий.

Headless smoke (если Godot установлен):

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 2
```

## Долги

- Placeholder procedural SFX (не финальные ассеты).
- Нет отдельного Audio bus mixer / volume UI.
- iOS debug по-прежнему blocked (нет Team ID).
- Package ID placeholder.
- Нет экономики / меню / паузы.

## Рекомендация этап 13

Main menu + pause **или** простая экономика слотов турелей **или** release AAB prep с финальным package id.
