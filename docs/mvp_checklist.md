# MVP checklist (1–2 weeks)

Playable цикл: волна → победа/поражение. Desktop + debug APK.

- [ ] `project.godot` + display (portrait или landscape — зафиксировать в этапе 1)
- [ ] Сцена боя side-view (фон + стена)
- [ ] Стена с HP, урон при контакте зомби
- [ ] 1 турель: автоатака по ближайшему врагу
- [ ] 1 зомби: движение к стене, HP
- [x] Wave spawn (интервал + счётчик; 1–5 волн + Brute) — см. `docs/stage15.md`
- [x] Win / Lose + restart (+ MAIN MENU)
- [x] HUD: HP стены, волна, Scrap (+ pause)
- [x] Main menu → PLAY → battle — см. `docs/stage13.md`
- [x] Scrap / стоимость турелей — см. `docs/stage14.md`
- [x] Debug APK smoke-test (см. stage 8)
- [x] Release AAB prep (preset + docs; локальный AAB) — см. `docs/stage18_android_aab.md`
- [ ] Final package ID before Play — см. `docs/package_id.md`

- [x] Sell + simple upgrade (in-run) — см. `docs/stage16.md`
- [x] Meta progression между ранами (Stars + shop) — см. `docs/stage17.md`
- [x] Difficulty select (Easy / Normal / Hard) — см. `docs/stage19.md`

**Вне scope MVP slice:** мультиплеер, стор submit, IAP.
