# Этап 13 — main menu + pause

## Что сделано

### Main menu

- Сцена `scenes/menus/main_menu.tscn` + `scripts/ui/main_menu.gd`
- Title **Zombie Stronghold**, крупная **PLAY** → `scenes/battle/battle.tscn`
- **HOW TO PLAY** — overlay с краткими правилами (placement / типы / волны)
- **SOUND: ON/OFF** — mute через `Sfx.set_muted` (Master bus)
- `project.godot` `run/main_scene` → main menu (battle только через PLAY)

### Pause (battle HUD)

- Кнопка **PAUSE** top-left (рядом с HP/Wave, в стороне от type select)
- Overlay: **RESUME** / **RESTART** / **MAIN MENU** / mute
- `get_tree().paused = true`; `PauseOverlay.process_mode = WHEN_PAUSED`
- Placement / ghost / waves стопаются на паузе

### Win / Lose

- **RESTART** — как раньше (`reload_current_scene`)
- **MAIN MENU** — возврат в меню
- Pause button скрывается на result overlay

### Audio

- `Sfx.is_muted()` / `Sfx.set_muted()` — без поломки procedural SFX pool
- Mute переживает смену сцен (autoload)

## Flows

```
Main Menu --PLAY--> Battle
Main Menu --HOW TO PLAY--> overlay --> GOT IT
Battle --PAUSE--> Pause Overlay --RESUME--> Battle
Pause / Result --RESTART--> Battle (reload)
Pause / Result --MAIN MENU--> Main Menu
```

## Как проверить (F5)

1. Godot 4.7 → открыть проект → **F5** → сначала **main menu** (не battle).
2. **HOW TO PLAY** → overlay → **GOT IT**.
3. **PLAY** → battle: waves, placement, BASIC/CANNON, ghost, SFX — без регрессий.
4. **PAUSE** (top-left) → игра стоп; **RESUME** → продолжение.
5. Pause → **RESTART** → бой с нуля; Pause → **MAIN MENU** → меню.
6. Дойти до VICTORY / DEFEAT → **RESTART** и **MAIN MENU** работают.
7. Mute на меню/паузе глушит SFX; переключение сцен сохраняет mute.

Headless smoke:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 2
```

Опционально проверить загрузку меню:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/menus/main_menu.tscn --quit-after 2
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/battle/battle.tscn --quit-after 2
```

## Долги

- Placeholder UI (Labels/Buttons), без отдельного theme resource.
- Mute только Master on/off (нет volume slider / SFX bus).
- iOS debug по-прежнему blocked (нет Team ID).
- Package ID placeholder.
- Нет экономики слотов турелей — закрыто на этапе 14 (`docs/stage14.md`).

## Рекомендация этап 14

~~Простая экономика / стоимость турелей~~ → сделано: `docs/stage14.md`.
