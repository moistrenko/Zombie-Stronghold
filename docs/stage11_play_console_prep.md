# Stage 11 — Google Play Console prep (light checklist)

Документ-заготовка. **Не публиковать** приложение на этом этапе. Реальный доступ к Play Console не требуется.

## 1. Аккаунт

- [ ] Создать Google Play Console developer account (разовый регистрационный взнос Google).
- [ ] Принять developer distribution agreement.
- [ ] Настроить организацию / контакт / платежный профиль (когда будете к релизу).

## 2. Черновик листинга (Draft app)

- [ ] Create app → название, язык по умолчанию, тип (Game), free/paid.
- [ ] Заполнить **short** / **full** description (черновики: `assets/store/copy/`).
- [ ] Загрузить иконку 512 и feature graphic (placeholders: `assets/store/`; чеклист: [`stage10b_store_assets.md`](stage10b_store_assets.md)).
- [ ] Добавить phone screenshots (landscape gameplay) — см. `assets/store/screenshots/phone/`.
- [ ] Privacy policy URL (черновик текста: [`privacy_policy_draft.md`](privacy_policy_draft.md) — нужен публичный URL перед submit).
- [ ] Content rating questionnaire — пройти, когда будет готов билд.

## 3. Package / Application ID

- Текущий placeholder в проекте: **`com.yourstudio.zombiestronghold`**.
- [ ] Перед первым upload в Play заменить на финальный ID студии (менять после первой публикации в том же приложении нельзя).
- [ ] Согласовать с Android export preset / `application/config/name` в Godot — не трогать ID в этом этапе без решения по бренду.

## 4. AAB vs APK (на потом)

| Формат | Когда |
|--------|--------|
| **AAB** (Android App Bundle) | Обязателен для **новых** приложений / production upload в Play Console. |
| **APK** | Удобен для внутренней debug/smoke раздачи; не замена AAB для store release. |

На этапе debug (см. `docs/stage7_android_export.md` / `docs/stage8.md`) APK ок.  
Для релиза позже: собрать **release AAB** signing keystore (хранить вне git).

## 5. Store assets

Полный чеклист размеров и copy: **[`docs/stage10b_store_assets.md`](stage10b_store_assets.md)**  
Папка ассетов: **`assets/store/`** (см. README там же).

## 6. Что сознательно не делаем сейчас

- Публикация / closed testing track upload.
- Смена package ID в репозитории.
- iOS / App Store Connect (Team ID blocked — `docs/stage10_blocked.md`).
- Финальный keystore / Play App Signing setup в CI.
