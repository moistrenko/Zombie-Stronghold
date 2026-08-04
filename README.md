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
│   ├── menus/             # main menu (run/main_scene)
│   ├── battle/            # 3D боевая сцена (через PLAY)
│   ├── units/             # турели 3D
│   ├── enemies/
│   └── ui/
├── scripts/{battle,units,enemies,ui,autoload}
├── resources/
├── docs/
└── builds/
```

**Naming:** `snake_case`. Main scene: `scenes/menus/main_menu.tscn` → PLAY → battle.

## MVP vertical slice

- [x] Боевая сцена 3D (стена снизу, спавн сверху)
- [x] Стена с HP, урон при контакте
- [x] Турели 3D (Basic + Cannon), автоатака + placement по тапу
- [x] 3 типа зомби (basic + runner + brute mini-boss) к стене, HP
- [x] Спавн волн 1–5 (микс с волны 2; Brute на 4–5)
- [x] Победа / поражение UI (+ MAIN MENU)
- [x] HUD (HP + волна X/5 + Scrap + слоты + BUILD/UPGRADE/SELL + type select + pause)
- [x] Main menu + pause overlay — см. `docs/stage13.md`
- [x] Scrap economy (стоимость турелей + награды за киллы) — см. `docs/stage14.md`
- [x] 5 волн + мини-босс Brute — см. `docs/stage15.md`
- [x] Sell + 1-level upgrade (режимы BUILD/UPGRADE/SELL) — см. `docs/stage16.md`
- [x] Meta progression (Stars + shop + persist) — см. `docs/stage17.md`
- [x] Debug APK собран; Android smoke **PASS** (владелец) — см. `docs/stage8.md`
- [x] Android **Release AAB** preset + prep docs — см. `docs/stage18_android_aab.md`
- [ ] Package ID placeholder — сменить до первого Play upload — см. `docs/package_id.md`
- [x] iOS export prep: пресет + чеклист — см. `docs/stage9_ios_export.md`
- [ ] iOS debug-прогон — **BLOCKED** (нет Team ID / signing) — см. `docs/stage10_blocked.md`
- [x] Ghost placement UX — см. `docs/stage10b_ghost.md`
- [x] Store assets checklist + placeholders — см. `docs/stage10b_store_assets.md`
- [x] Game-feel polish (hit/kill/fire/wall/place + SFX) — см. `docs/stage12.md`

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
- **Этап 12** — game-feel polish: hit/kill/muzzle/wall flash, place pulse, procedural SFX autoload. См. `docs/stage12.md`.
- **Этап 13** — main menu + pause + MAIN MENU с result overlay. См. `docs/stage13.md`.
- **Этап 14** — Scrap economy: стоимость Basic/Cannon, награды за киллы, HUD. См. `docs/stage14.md`.
- **Этап 15** — 5 волн + мини-босс Brute (preview на 4, climax на 5). См. `docs/stage15.md`.
- **Этап 16** — sell (55% refund) + 1-level upgrade + режимы BUILD/UPGRADE/SELL. См. `docs/stage16.md`.
- **Этап 17** — meta Stars + Meta Shop (4 permanent upgrades) + `user://` persist. См. `docs/stage17.md`.
- **Этап 18** — Android release AAB preset + keystore/version/package hygiene. См. `docs/stage18_android_aab.md`, `docs/package_id.md`.
- Старый `docs/stage3.md` (2D турель) — устарел.
