# Блокеры публикации (Play / App Store / RuStore)

Не блокер разработки MVP, но закрывать параллельно с контентом.

**Детальный чеклист ассетов и заготовки:** [`docs/stage10b_store_assets.md`](stage10b_store_assets.md) · папка [`assets/store/`](../assets/store/) · privacy draft [`docs/privacy_policy_draft.md`](privacy_policy_draft.md).

1. **Аккаунты разработчика**
   - Google Play Console (разовый взнос)
   - Apple Developer Program (годовая подписка) — для App Store / TestFlight
   - RuStore Console — отдельная регистрация юр/физлица

2. **Privacy Policy** — обязательна; публичный HTTPS URL (черновик: `privacy_policy_draft.md`).

3. **Иконка + feature graphic / скриншоты** — размеры и placeholders в `assets/store/` (см. stage10b_store_assets).

4. **Возрастной рейтинг** — IARC (Play), App Store questionnaire, RuStore; зомби/насилие → ориентир **Teen / 12+**.

5. **Подписание билдов** — Android release keystore (вне git; prep этап 18); iOS certificates + provisioning (этап 10 blocked без Team ID).

6. **Контентные/правовые** — оригинальные или лицензированные ассеты; политики RuStore/регионов по насилию.

7. **Название / пакет** — сменить placeholder `com.yourstudio.zombiestronghold` **до первого Play upload** (потом нельзя легко); чеклист: [`package_id.md`](package_id.md).

8. **Release AAB** — пресет **Android Release AAB** готов; нужен Gradle template + release keystore локально → Closed testing. См. [`stage18_android_aab.md`](stage18_android_aab.md).

---

## App Store (этап 9+)

Пока **не публикуем**. Prep: `docs/stage9_ios_export.md`, блокер: `docs/stage10_blocked.md`.

| Блокер | Что нужно |
|--------|-----------|
| **Icons** | 1024×1024 — `assets/store/icons/icon_1024.png` (placeholder) |
| **Privacy** | URL с draft + App Privacy labels |
| **Age rating** | questionnaire → обычно 12+ |
| **Signing** | Apple Team + Distribution |
| **Bundle ID** | не `com.yourstudio…` на проде |
