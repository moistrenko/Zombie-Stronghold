# Этап 9 — iOS export prep

## Итог (машина исполнителя)

| Компонент | Статус |
|-----------|--------|
| Mac + Xcode | **частично** — Xcode **16.4** установлен (`/Applications/Xcode.app`); iPhoneOS SDK на месте |
| `xcode-select` | Убедиться, что указывает на Xcode: `sudo xcode-select -s /Applications/Xcode.app` (если активны только Command Line Tools — экспорт Godot падает) |
| Export Templates 4.7.1 | **да** — `~/Library/Application Support/Godot/export_templates/4.7.1.stable/` (`ios.zip`) |
| Apple Developer / Team ID | **нет** на машине исполнителя |
| Code signing identities | **0** (`security find-identity -v -p codesigning`) |
| Provisioning profiles | **нет** |
| IPA / открытие в Xcode | **не собрано** — Godot CLI: `App Store Team ID not specified` (ожидаемо; сертификатов тоже нет) |
| Preset | **да** — `export_presets.cfg` → **iOS Debug** (без секретов) |

Чеклист ниже — чтобы владелец довёл до симулятора / device. Публикация в App Store / TestFlight **не** цель этого этапа.

Официальный док Godot: [Exporting for iOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html).

---

## Идентификаторы и мобильные требования

| Поле | Значение |
|------|----------|
| App name | **Zombie Stronghold** |
| Bundle ID (предложение) | **com.yourstudio.zombiestronghold** — тот же reverse-DNS, что Android `package/unique_name` |
| short_version / version | `0.1.0` / `0.1.0` (синхрон с Android `version/name`) |
| Orientation | **landscape** — `window/handheld/orientation=0` в `project.godot` |
| Touch placement | тап в зону у стены → турель (макс. 3); без ghost-превью (не этот этап) |
| Renderer (проект) | **`mobile`** (`renderer/rendering_method="mobile"`) |
| Renderer (iOS device) | **Metal** (драйвер по умолчанию на iOS). **Не** копировать Android debug `command_line/extra_args="--rendering-method gl_compatibility"` |
| Renderer (iOS Simulator) | только **Compatibility** (`gl_compatibility`) — ограничение Godot/Apple; для Metal smoke предпочтительны **device** или **My Mac** (Apple Silicon) |
| min iOS | **14.0** (Metal + дефолт Godot 4.7) |
| ABI | **arm64** |
| Preset | `export_presets.cfg` → **iOS Debug** |
| Export path | `builds/ios/ZombieStronghold` (Xcode project; `builds/` в `.gitignore`) |

Placeholder Bundle ID сменить до публикации в App Store на ID домена, которым владеете.

---

## Отличия от Android (важно)

| Android | iOS |
|---------|-----|
| Godot → **APK/AAB «в один клик»** | Godot → **Xcode project** (+ опционально IPA через Xcode/`xcodebuild`) |
| Debug keystore локально | **Apple Team ID** + сертификат Development/Distribution + provisioning |
| `adb install` | Xcode Run / Device / Simulator; для IPA — Archive |
| `gl_compatibility` ок для эмулятора | На device — **Metal / mobile**; Compatibility — в основном симулятор |

Секреты (`.p12`, `.mobileprovision`, Team ID в credentials) — **только локально**, не в git. Уже в `.gitignore`: `*.p12`, `*.mobileprovision`, `*.ipa`, `export_credentials.cfg`, `builds/`.

---

## Чеклист установки (macOS)

### 1) Mac + Xcode (минимум под Godot 4.7.1)

Godot **не** фиксирует жёсткий floor Xcode в доках 4.7; практический минимум:

1. macOS с актуальным **Xcode** из App Store (на машине исполнителя проверено: **Xcode 16.4** — ок для SDK/сборок 2025–2026).
2. Один раз открыть Xcode → принять лицензию → **Settings → Platforms** → установить **iOS**.
3. **Settings → Locations → Command Line Tools** → выбрать установленный Xcode.
4. В Terminal:

```bash
sudo xcode-select -s /Applications/Xcode.app
xcodebuild -version          # ожидается Xcode 16.x (или новее)
xcrun --sdk iphoneos --show-sdk-version
```

Если `xcode-select -p` → `/Library/Developer/CommandLineTools`, экспорт Godot на iOS обычно **ломается**.

### 2) Apple Developer Account

1. [Apple Developer Program](https://developer.apple.com/programs/) (годовая подписка) — для device + TestFlight/App Store.
2. В [developer.apple.com/account](https://developer.apple.com/account) скопировать **Team ID** (10 символов, напр. `ABCDE12XYZ`) — не имя команды.
3. В Xcode: **Settings → Accounts** → добавить Apple ID → Download Manual Profiles (по необходимости).

Без Team ID Godot **откажется** экспортировать iOS (поле обязательное).

### 3) Bundle ID

Рекомендация этапа: **`com.yourstudio.zombiestronghold`** (согласовано с Android).

1. [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) → Identifiers → **+** → App IDs → Bundle ID = то же значение.
2. В Godot Export → Application → **Identifier** = Bundle ID.
3. До стора можно оставить placeholder; перед App Store — домен, которым владеете.

### 4) Godot iOS export templates 4.7.1

Шаблоны **той же** версии, что редактор (`4.7.1.stable`):

1. **Editor → Manage Export Templates… → Download and Install**, или уже установлены (этап 8).
2. Проверка: `~/Library/Application Support/Godot/export_templates/4.7.1.stable/ios.zip` и `version.txt` → `4.7.1.stable`.

### 5) Export → Xcode project (debug flow)

```bash
mkdir -p builds/ios
```

В редакторе:

1. **Project → Export…**
2. Пресет **iOS Debug** (уже в `export_presets.cfg`) **или** Add → iOS.
3. Заполнить локально (не коммитить секреты):
   - **App Store Team ID** — 10 символов
   - **Identifier** — `com.yourstudio.zombiestronghold`
   - **Code Sign Identity Debug** — `Apple Development` (для automatic signing в Xcode)
   - **Export Method Debug** — Development
   - **Export Project Only** — `true` на первом прогоне (только `.xcodeproj`, без IPA)
4. **Export Project** → путь: папка `builds/ios/`, **File** без пробелов: `ZombieStronghold`  
   (имя Xcode-проекта ≠ имя папки Godot-проекта — иначе signing issues; см. док Godot).

CLI (после заполнения Team ID в пресете / env):

```bash
mkdir -p builds/ios
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path . \
  --export-debug "iOS Debug" builds/ios/ZombieStronghold
```

Provisioning UUID можно передать env (не писать в git):

```bash
export GODOT_IOS_PROVISIONING_PROFILE_UUID_DEBUG="<uuid>"
# или актуальные GODOT_APPLE_PLATFORM_* из доки вашей версии Godot
```

### 6) Signing в Xcode + симулятор / device

1. Открыть `builds/ios/ZombieStronghold.xcodeproj`.
2. Target → **Signing & Capabilities**:
   - Team = ваш Apple Team
   - **Automatically manage signing** = ON (для debug)
   - Bundle Identifier совпадает с Godot
3. **Симулятор:** выбрать iPhone simulator → Run.  
   Ожидание: Compatibility renderer; landscape; UI читаем. Metal на симуляторе — не рассчитывать.
4. **Device:** кабель / Developer Mode (iOS 16+) → Trust → выбрать устройство → Run.
5. **Apple Silicon Mac:** Run Destination **My Mac** — можно гонять Metal без симуляторных ограничений (удобно для smoke).

IPA (опционально, не обязательно на этапе 9):

- Xcode → Product → Archive → Distribute App, **или** снять Export Project Only и дать Godot собрать archive/IPA при валидном signing.

### 7) Smoke-test (когда билд заведётся)

Зеркало Android smoke (`docs/stage7_android_export.md` / `docs/stage8.md`):

- [ ] Старт без чёрного экрана / краша
- [ ] Landscape
- [ ] Тап в зону у стены → турель; `Turrets: N/3`
- [ ] Волны + HUD
- [ ] Win/Lose → **RESTART**

---

## Поля пресета (владелец добивает Signing в UI)

Уже в репо (`export_presets.cfg`, preset **iOS Debug**), **без** Team ID / UUID профилей:

| Ключ | Значение в репо | Владелец |
|------|-----------------|----------|
| `application/bundle_identifier` | `com.yourstudio.zombiestronghold` | сменить до стора при необходимости |
| `application/short_version` / `version` | `0.1.0` | бампить при релизах |
| `application/min_ios_version` | `14.0` | не ниже 14 для Metal |
| `application/targeted_device_family` | `2` (iPhone & iPad) | по желанию |
| `application/export_method_debug` | `1` (Development) | — |
| `application/code_sign_identity_debug` | `Apple Development` | обычно оставить |
| `application/export_project_only` | `true` | `false` когда нужен IPA из Godot |
| `architectures/arm64` | `true` | — |
| `application/app_store_team_id` | **пусто** | **обязательно** 10-символьный Team ID |
| `application/provisioning_profile_uuid_*` | **пусто** | при automatic — часто не нужны; при manual — UUID локально / env |

Первое открытие Export в редакторе может **дописать** недостающие ключи (иконки, privacy collected_data) — ок. **Не** коммитить заполненный Team ID / UUID / пароли, если политика репо — держать секреты вне git (`export_credentials.cfg`).

---

## Блокеры App Store (не публикуем сейчас)

Кратко; полный список — [`docs/store_blockers.md`](store_blockers.md):

1. **Icons** — App Store 1024×1024 (+ тёмная/tinted по требованиям Xcode); в пресете пока fallback на `icon.svg`.
2. **Privacy** — Privacy Policy URL; App Privacy / nutrition labels; usage descriptions только если реально нужны camera/mic/photos (у MVP — нет).
3. **Age rating** — questionnaire в App Store Connect; зомби/насилие → обычно 12+.
4. **Signing release** — Distribution cert + App Store provisioning (отдельно от debug Development).
5. **Аккаунт** — активный Apple Developer Program.

Этап 9 **не** включает загрузку в App Store Connect / TestFlight.

---

## Что осталось владельцу руками

1. Apple Developer Program + Team ID в пресете (локально).
2. `xcode-select` → Xcode; iOS platform в Xcode Settings.
3. Export **iOS Debug** → открыть `.xcodeproj` → Automatic signing → Run (симулятор / device / My Mac).
4. Ручной smoke (placement + Restart); при необходимости снять `export_project_only` и собрать IPA.
5. До стора: иконки, privacy, age rating — см. `store_blockers.md`.

---

## Риски

- Team ID пустой / «имя команды» вместо 10 символов → ошибка экспорта / JSON parse.
- Version Godot ≠ templates → битый iOS template.
- Симулятор + Metal/mobile → чёрный экран или fallback; не путать с багом геймплея.
- Имя экспортируемого Xcode-проекта со пробелами / совпадение с именем Godot-папки → signing pain.
- Не тащить Android `gl_compatibility` extra_args в iOS preset.

---

## Следующий шаг

Этап 10: **blocked** без Team ID — см. `docs/stage10_blocked.md`. После Team ID — Export + My Mac/device smoke → дописать `docs/stage10.md`. Параллель: этап **10b** (ghost placement или store assets).
