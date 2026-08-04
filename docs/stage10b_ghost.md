# Этап 10b-A — UX ghost placement

## Что сделано

Полупрозрачный **ghost** турели в точке на плоскости `y = 0` перед постановкой.

| Файл | Изменение |
|------|-----------|
| `scripts/battle/battle.gd` | ghost mesh (body+barrel), валид/невалид цвет, touch + mouse |
| `project.godot` | `pointing/emulate_mouse_from_touch=false` (нет двойной постановки touch+mouse) |
| Волны / win-lose / max 3 / дистанция 2 | без изменений правил |

Правила зоны как на этапе 6: X `[-6, 6]`, Z `[2, 5.5]`, `max_turrets=3`, `min_turret_distance=2`.

### Визуал

| Состояние | Поведение |
|-----------|-----------|
| Вне placement-зоны / нет hit по земле / лимит 3 | ghost **скрыт** |
| В зоне, слишком близко к другой турели | ghost **красный** полупрозрачный |
| В зоне, лимит и дистанция ок | ghost **зелёный** полупрозрачный |

### Touch vs mouse

| Устройство | Ghost | Постановка |
|------------|-------|------------|
| **Touch** | press + drag | **release** в валидной точке; невалидный release — не ставить |
| **Mouse (F5)** | движение курсора | **ЛКМ click** (как раньше по смыслу клика) |

Ghost не в группе `turrets`, без `turret.gd` — не стреляет.

---

## Как проверить (F5)

1. Курсор над синей полосой → зелёный ghost следует за мышью.
2. Курсор вне полосы → ghost исчезает (не красный).
3. Поставить турель → рядом в зоне ghost красный; дальше снова зелёный.
4. Три турели → ghost больше не показывается; клики не ставят.
5. Волны / VICTORY / DEFEAT / RESTART — как раньше; после RESTART ghost снова работает.
6. Клик вне зоны — ничего не ставится.

---

## Android (владельцу)

Пересобрать debug APK **не обязательно** для приёмки логики (хватит F5). Для эмулятора/устройства:

```bash
# как в docs/stage8.md
godot --headless --path . --export-debug "Android Debug" builds/android/zombie_stronghold_debug.apk
adb install -r builds/android/zombie_stronghold_debug.apk
```

Проверка тача: палец в зоне → ghost; отпустить в зелёной точке → турель; отпустить в красной / вне зоны → без постановки.

---

## Риски регрессии

- Touch ставит на **release**, не на press — короткий tap всё ещё ок; свайп из зоны наружу и отпускание вне — не ставит.
- `emulate_mouse_from_touch=false` — Control/HUD (RESTART) по-прежнему получают touch нативно; если где-то слушали только mouse в world — проверить.
- Не ломает Android export preset / iOS docs.

## Следующий шаг

**10b-B** выполнен (`docs/stage10b_store_assets.md`). Далее: **этап 10** после Team ID **или** этап **11** (Play Console / контент) — см. рекомендацию в store assets doc.
