# Zombie Stronghold

Мобильный **3D** tower defense: защита стены крепости от волн зомби.

## Стек (зафиксировано)

**Godot 4.x + GDScript + 3D** (top-down / лёгкий наклон)

- Стена **внизу** экрана; враги идут **сверху вниз** (ось **+Z** к стене, плоскость **XZ**)
- Один экспорт → Android / iOS / desktop
- Бесплатный движок без роялти — Play / App Store / RuStore
- MVP: vertical slice → турель → волны

Альтернативы на этапе 0 (Unity и т.д.) отклонены. Ранний 2D side-view layout **снят** (pivot этап 3).

**Первый стор:** Google Play (Android). Затем RuStore, затем App Store.

## Структура репозитория

```
Zombie-Stronghold/
├── project.godot
├── assets/{art,audio,ui,store}
├── scenes/
│   ├── battle/            # 3D боевая сцена (main)
│   ├── units/             # турели 3D
│   ├── enemies/
│   ├── ui/
│   └── menus/
├── scripts/{battle,units,enemies,ui,autoload}
├── resources/
├── docs/
└── builds/
```

**Naming:** `snake_case`. Main scene: `scenes/battle/battle.tscn`.

## MVP vertical slice

- [x] Боевая сцена 3D (стена снизу, спавн сверху)
- [x] Стена с HP, урон при контакте
- [x] Турели 3D (Basic + Cannon), автоатака + placement по тапу
- [x] 2 типа зомби (basic + runner) к стене, HP
- [x] Спавн волн 1–3 (микс типов с волны 2)
- [x] Победа / поражение UI
- [x] HUD (HP + волна + слоты + выбор типа турели)
- [x] Debug APK собран; Android smoke **PASS** (владелец) — см. `docs/stage8.md`
- [x] iOS export prep: пресет + чеклист — см. `docs/stage9_ios_export.md`
- [ ] iOS debug-прогон — **BLOCKED** (нет Team ID / signing) — см. `docs/stage10_blocked.md`
- [x] Ghost placement UX — см. `docs/stage10b_ghost.md`
- [x] Store assets checklist + placeholders — см. `docs/stage10b_store_assets.md`

## Блокеры сторов

См. `docs/store_blockers.md`. Чеклист ассетов / copy / privacy draft: **`docs/stage10b_store_assets.md`** (`assets/store/`).

## Статус этапов

- **Этап 0** — стек/структура (изначально 2D; цель скорректирована на 3D).
- **Этап 1** — `project.godot` + первая battle-сцена.
- **Этап 2** — HP стены + 1 зомби (было 2D side-view).
- **Этап 3 (pivot)** — **3D foundation**: wall bottom, top→bottom, HP + 1 зомби. См. `docs/stage3_pivot_3d.md`.
- **Этап 4** — 1 турель 3D + снаряд, убивает зомби до стены. См. `docs/stage4.md`.
- **Этап 5** — волны 1–3 + win/lose touch UI. См. `docs/stage5.md`.
- **Этап 6** — placement турели по тапу (макс. 3). См. `docs/stage6.md`.
- **Этап 7** — Android debug export prep + smoke-test чеклист. См. `docs/stage7_android_export.md`.
- **Этап 8** — toolchain + APK + partial smoke на эмуляторе. См. `docs/stage8.md`.
- **Этап 9** — iOS export prep (Xcode, Bundle ID, templates, preset без секретов). См. `docs/stage9_ios_export.md`.
- **Этап 10** — iOS debug-прогон **blocked** (нет Apple Team). См. `docs/stage10.md` / `docs/stage10_blocked.md`.
- **Этап 10b-A** — ghost placement UX. См. `docs/stage10b_ghost.md`.
- **Этап 10b-B** — store assets checklist + placeholders. См. `docs/stage10b_store_assets.md`.
- **Этап 11** — 2-й враг (runner) + 2-я турель (cannon) + HUD type select + Play Console prep doc. См. `docs/stage11.md`.
- Старый `docs/stage3.md` (2D турель) — устарел.
