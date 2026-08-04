# Этап 10 — BLOCKED: нет Apple Team ID / signing

Дата проверки: 2026-08-03. Android smoke у владельца — **PASS** (не блокер). iOS debug-прогон без аккаунта невозможен.

## Что проверено на машине

| Пункт | Факт |
|-------|------|
| `export_presets.cfg` → `application/app_store_team_id` | пусто |
| `security find-identity -v -p codesigning` | `0 valid identities found` |
| Provisioning Profiles | каталога нет |
| Xcode Accounts | нет |
| Export Templates 4.7.1 | ок (`ios.zip`) |
| Xcode.app | 16.4 установлен |
| `xcode-select -p` | снова может быть `/Library/Developer/CommandLineTools` — перед экспортом: `sudo xcode-select -s /Applications/Xcode.app` |

Godot **не экспортирует** iOS без Team ID (ошибка этапа 9: `App Store Team ID not specified`).

---

## Что вписать владельцу (точные поля)

### A) Apple Membership → Team ID

1. Открыть [developer.apple.com/account](https://developer.apple.com/account) (нужен [Apple Developer Program](https://developer.apple.com/programs/) для device / TestFlight; для первого Simulator/My Mac часто хватает Apple ID в Xcode, но **Team ID всё равно нужен** Godot).
2. **Membership details** / уголок аккаунта → скопировать **Team ID** = ровно **10** символов (`A–Z`, `0–9`), пример вида `ABCDE12XYZ`.
3. **Не** вставлять отображаемое имя команды («John Appleseed») — Godot ждёт код.

Скрин-ориентир: на странице Membership / Certificates рядом с именем команды — поле **Team ID**.

### B) Xcode → аккаунт и сертификат

1. Xcode → **Settings → Accounts** → **+** → Apple ID.
2. Select Team → **Manage Certificates…** → **+** → **Apple Development** (создаст identity в Keychain).
3. Проверка:

```bash
sudo xcode-select -s /Applications/Xcode.app
security find-identity -v -p codesigning   # ожидается ≥1 "Apple Development"
```

4. (Опционально) Identifiers → App ID = `com.yourstudio.zombiestronghold` — см. stage9.

### C) Godot preset (без паролей в git)

В **Project → Export… → iOS Debug**:

| Поле UI | Ключ в `export_presets.cfg` | Значение |
|---------|-----------------------------|----------|
| App Store Team ID | `application/app_store_team_id` | ваш 10-символьный Team ID |
| Identifier | `application/bundle_identifier` | уже `com.yourstudio.zombiestronghold` |
| Code Sign → Debug | `application/code_sign_identity_debug` | уже `Apple Development` |
| Export Method Debug | `application/export_method_debug` | `1` (Development) |
| Export Project Only | `application/export_project_only` | `true` для первого Xcode-проекта |
| Provisioning UUID Debug/Release | `application/provisioning_profile_uuid_*` | **пусто** при Automatic signing |

**Политика секретов**

- **Team ID** — не пароль; можно держать в `export_presets.cfg` в репо (попадёт в бинарь). Если владелец против коммита — править **только локально** и не `git add` это поле / не пушить изменение.
- **Пароли, .p12, .mobileprovision, UUID профилей** — никогда в git. UUID → локально или env (`GODOT_IOS_PROVISIONING_PROFILE_UUID_DEBUG` / `GODOT_APPLE_PLATFORM_*`); секреты Godot → `export_credentials.cfg` (уже в `.gitignore`).

Локальный one-shot без правки файла в редакторе (если когда-нибудь появится env для Team ID в вашей сборке — иначе UI/пресет):

```bash
# Team ID задаётся в Export UI / export_presets.cfg — отдельного стандартного GODOT_* env в 4.7.1 для Team ID нет.
# UUID профиля (если manual):
export GODOT_IOS_PROVISIONING_PROFILE_UUID_DEBUG="<uuid>"
```

### D) Export → Run (после Team ID)

```bash
sudo xcode-select -s /Applications/Xcode.app
mkdir -p builds/ios
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path . \
  --export-debug "iOS Debug" builds/ios/ZombieStronghold
open builds/ios/ZombieStronghold.xcodeproj
```

В Xcode: **Signing & Capabilities** → Team → **Automatically manage signing** → Run:

| Таргет | Renderer | Заметка |
|--------|----------|---------|
| iOS Simulator | Compatibility | smoke UI/input; не Metal |
| **My Mac** (Apple Silicon) | Metal / mobile | предпочтительно для этапа 10 |
| Device | Metal / mobile | Developer Mode; ideal |

**Не** копировать Android `--rendering-method gl_compatibility` в iOS preset.

Smoke (зафиксировать потом в `docs/stage10.md`): landscape, placement, волны+HUD, win/lose+Restart.

TestFlight / App Store submit — **не** делать.

---

## Параллельный этап **10b** (пока ждём Apple)

На выбор главного агента / владельца:

### 10b-A — UX ghost placement (**рекомендация**)

- Android уже smoke **PASS**; ghost-превью зоны/турели улучшает UX на живом APK сразу.
- Не зависит от Apple; не ломает export.
- Scope: превью при таче/драге в placement-зоне, без расширения геймплея (слоты/экономика — вне).

### 10b-B — Store assets checklist

- Иконка 1024×1024, feature graphic (Play), заготовка Privacy Policy URL, age-rating заметки.
- Ближе к Google Play (первый стор); полезно, но можно отложить до prep публикации.
- Чеклист-база: [`docs/store_blockers.md`](store_blockers.md).

**Рекомендация исполнителя:** **10b-A (ghost placement)** — продукт на Android уже играбелен; App Store всё равно третий в очереди. Если владелец целится в листинг Play на этой неделе — брать **10b-B**.

**Статус:** **10b-A** и **10b-B** выполнены — `docs/stage10b_ghost.md`, `docs/stage10b_store_assets.md`. Далее: этап 10 после Team ID **или** этап 11 (Play Console / контент).

---

## Следующий шаг после разблокировки

Владелец вписывает Team ID → исполнитель: Export + Run (My Mac или device) → дописать `docs/stage10.md` (pass/fail) → этап 11.
