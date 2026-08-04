# Этап 18 — Android AAB prep + package ID hygiene

Release-path hygiene (не геймплей). Цель: подготовить **release App Bundle** для Google Play Closed Testing, не публикуя в стор.

Связанные доки:

- Play Console prep: [`stage11_play_console_prep.md`](stage11_play_console_prep.md)
- Store assets: [`stage10b_store_assets.md`](stage10b_store_assets.md)
- Package ID decision: [`package_id.md`](package_id.md)
- Debug APK (этап 7–8): [`stage7_android_export.md`](stage7_android_export.md), [`stage8.md`](stage8.md)
- Блокеры: [`store_blockers.md`](store_blockers.md)

---

## APK debug vs AAB release

| | **APK (debug)** | **AAB (release)** |
|--|-----------------|-------------------|
| Файл | `.apk` | `.aab` (Android App Bundle) |
| Пресет | **Android Debug** | **Android Release AAB** |
| Назначение | `adb install`, эмулятор, внутренний smoke | Upload в **Play Console** (новые приложения → AAB обязателен) |
| Подпись | Debug keystore (Editor Settings) | **Release keystore** (локально, вне git) |
| Сборка | Prebuilt export template (`use_gradle_build=false`) | **Gradle build** + Export Format = App Bundle |
| Play | Не для production upload | Closed / open / production tracks |

Debug APK **не заменяет** AAB для store release.

---

## Godot 4.7 — пресет Android Release / App Bundle

В репозитории уже есть пресет **`Android Release AAB`** →  
`builds/android/zombie_stronghold_release.aab`.

### Одноразово на машине: Gradle template

AAB в Godot 4.7 требует Gradle:

1. Export templates **4.7.1** установлены (этап 8).
2. **Project → Install Android Build Template…**  
   Создаёт `android/build/` (в `.gitignore` — не коммитить артефакты Gradle).
3. В пресете **Android Release AAB**:
   - **Gradle Build → Use Gradle Build** = on (`use_gradle_build=true`)
   - **Export Format** = **Android App Bundle** (`export_format=1`)
4. **Architectures:** primary **arm64-v8a** (как debug).  
   `armeabi-v7a` / x86 — выкл. Включать `armeabi-v7a` только если нужна поддержка старых 32-bit устройств (увеличит размер).

SDK для Gradle (Godot 4.7 docs ориентир): platform-tools, build-tools, platforms; для стабильного Gradle часто нужны также **NDK** + **CMake** через `sdkmanager`.

### Keystore в пресете

Поля `keystore/release*` в закоммиченном `export_presets.cfg` **пустые** (намеренно).

Заполнить **локально** (Editor → Project → Export → Android Release AAB) **или** через env (см. ниже) — **не коммитить** пароли / пути с секретами / `export_credentials.cfg`.

---

## Release keystore (локально, NEVER commit)

### Создать keystore

Вариант A — под gitignored `builds/` (удобно для локальных проб):

```bash
mkdir -p builds/keystore
keytool -genkeypair -v \
  -keystore builds/keystore/zombie_stronghold_release.keystore \
  -alias zombie_stronghold \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass 'REPLACE_ME' -keypass 'REPLACE_ME' \
  -dname "CN=Zombie Stronghold,O=YourStudio,C=US"
```

Вариант B — вне репозитория (рекомендуется для **настоящего** Play upload):

```bash
mkdir -p ~/godot-keys
keytool -genkeypair -v \
  -keystore ~/godot-keys/zombie_stronghold_release.keystore \
  -alias zombie_stronghold \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass 'REPLACE_ME' -keypass 'REPLACE_ME' \
  -dname "CN=Zombie Stronghold,O=YourStudio,C=US"
```

**Важно:**

- Пароль keystore и key в Godot сейчас должны **совпадать**.
- Файл + пароль = контроль над обновлениями приложения. Бэкап вне git (password manager / offline).
- `*.keystore`, `builds/`, `export_credentials.cfg` — в `.gitignore`.
- Локальный keystore под `builds/keystore/` годится для **проверки пайплайна**; перед первым Play upload лучше завести «боевой» keystore вне репо и включить Play App Signing.

### Заполнить в Editor

**Project → Export → Android Release AAB → Keystore:**

- Release → путь к `.keystore`
- Release User → alias (`zombie_stronghold`)
- Release Password → пароль

Либо CLI env (перекрывают пресет):

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$HOME/godot-keys/zombie_stronghold_release.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="zombie_stronghold"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD='REPLACE_ME'
```

---

## version/code и version/name

В **обоих** Android-пресетах (`export_presets.cfg`):

| Поле | Сейчас | Когда bump |
|------|--------|------------|
| `version/name` | `0.1.0` | Видимая версия (semver ок) |
| `version/code` | `1` | **Целое**, строго ↑ при каждом upload в Play |

Перед каждым upload в Play: увеличить `version/code` минимум на 1.  
`version/name` можно оставить или поднять вместе с релизом.

Синхронизировать с iOS `application/short_version` / `application/version` когда дойдёте до App Store.

---

## Package ID — сменить до первого Play upload

Текущий placeholder: **`com.yourstudio.zombiestronghold`**.

После первого upload в Play Console смена Application ID для того же листинга **практически невозможна** (новый app / потеря обновлений).

**Не выдумывать** финальный домен без решения владельца. Чеклист: [`package_id.md`](package_id.md).

TODO-маркеры: `project.godot`, `export_presets.cfg`, этот документ, `package_id.md`.

---

## Экспорт AAB (Editor / CLI)

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

# После Install Android Build Template + заполненного release keystore:
mkdir -p builds/android
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path . \
  --export-release "Android Release AAB" \
  builds/android/zombie_stronghold_release.aab
```

Editor: **Project → Export → Android Release AAB → Export Project**  
(снять Export With Debug / использовать release).

Debug APK по-прежнему:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path . \
  --export-debug "Android Debug" \
  builds/android/zombie_stronghold_debug.apk
```

---

## Результат попытки сборки (этап 18)

| Поле | Значение |
|------|----------|
| Цель | `builds/android/zombie_stronghold_release.aab` |
| Статус | *(заполняется при прогоне)* |
| Блокер | *(если есть)* |

Не публиковать в Play из этого этапа.

---

## Closed testing track — короткий чеклист

1. [ ] Финальный **package ID** выбран и проставлен везде ([`package_id.md`](package_id.md)).
2. [ ] Release keystore создан, бэкап есть, пути **не** в git.
3. [ ] `version/code` / `version/name` актуальны.
4. [ ] Собран **signed release AAB**.
5. [ ] Play Console: app создан, листинг-черновик + privacy URL ([`stage11_play_console_prep.md`](stage11_play_console_prep.md)).
6. [ ] Store assets (icon / feature / screenshots) — [`stage10b_store_assets.md`](stage10b_store_assets.md).
7. [ ] Content rating (IARC) пройден.
8. [ ] Upload AAB → track **Closed testing** → добавить тестеров (email / Google Group).
9. [ ] Проверить установку из Play (internal/closed), не только `adb`.
10. [ ] **Не** продвигать в Production, пока closed smoke не ок.

---

## Owner action items (кратко)

См. итоговую таблицу этапа в README / summary исполнителя. Главное: решить package ID → боевой keystore вне git → Install Android Build Template → заполнить release keystore → bump version → export AAB → Closed testing (без Production).
