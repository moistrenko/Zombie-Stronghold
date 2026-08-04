# Этап 7 — Android debug export smoke-test

## Статус на машине исполнителя

**APK собран на машине владельца (этап 8):** `builds/android/zombie_stronghold_debug.apk`.  
Подробности toolchain и smoke: `docs/stage8.md`. Чеклист установки: ниже.

## Идентификаторы приложения

| Поле | Значение |
|------|----------|
| App name | **Zombie Stronghold** |
| Package / unique name | **com.yourstudio.zombiestronghold** (placeholder; сменить до публикации в сторы) |
| version/name | `0.1.0` |
| version/code | `1` |
| Orientation | **landscape** (`window/handheld/orientation=0`) |
| Renderer | **mobile** (под телефоны; см. `project.godot`) |
| ABI | **arm64-v8a** only (debug) |
| Permissions | минимум — в пресете все лишние `false` |
| Preset | `export_presets.cfg` → **Android Debug** |

Keystore/пароли в пресете **пустые** → Godot использует debug keystore из Editor Settings (не коммитить `.keystore`).

---

## Чеклист установки (macOS)

### 1) Godot

1. Скачать **Godot 4.7.x** (совпадает с `config/features` в проекте) с [godotengine.org](https://godotengine.org/download).
2. Открыть `project.godot`.
3. **Editor → Manage Export Templates… → Download and Install** — шаблоны **той же** версии, что редактор (4.7.x ≠ 4.3.x).

### 2) JDK

```bash
brew install openjdk@17
# затем в Editor Settings → Export → Android указать путь к java, либо:
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

Godot 4 обычно ожидает **JDK 17**.

### 3) Android SDK

1. Установить [Android Studio](https://developer.android.com/studio) (или command-line tools).
2. SDK Manager: **Android SDK Platform** (API 34+), **Build-Tools**, **Platform-Tools**.
3. В Godot: **Editor Settings → Export → Android**:
   - Android SDK Path → например `~/Library/Android/sdk`
   - Debug Keystore — см. ниже (или оставить автогенерацию Godot)

Док Godot: [Exporting for Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).

### 4) Debug keystore (локально, НЕ в git)

Если Godot ещё не создал debug keystore:

```bash
keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore ~/godot/android_debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
```

В Editor Settings → Export → Android:

- Debug Keystore → путь к файлу  
- Debug Keystore User → `androiddebugkey`  
- Debug Keystore Pass → `android`  

**Не коммитить** `*.keystore`, пароли, `export_credentials.cfg`.

### 5) Export APK

```bash
mkdir -p builds/android
```

В редакторе:

1. **Project → Export…**
2. Пресет **Android Debug** (уже в `export_presets.cfg`)
3. Проверить Package Unique Name / Name / arm64-v8a
4. **Export Project** → `builds/android/zombie_stronghold_debug.apk`

CLI (если Godot в PATH):

```bash
mkdir -p builds/android
godot --headless --path . --export-debug "Android Debug" builds/android/zombie_stronghold_debug.apk
```

### 6) Установка на устройство

```bash
adb devices
adb install -r builds/android/zombie_stronghold_debug.apk
```

Эмулятор: Android Studio AVD с **arm64** или Google APIs x86_64 (для x86_64 включите ABI в пресете временно).

---

## Smoke-test на устройстве / эмуляторе

- [ ] Приложение стартует **без чёрного экрана / краша**
- [ ] Ориентация **landscape**
- [ ] Тап в синюю зону у стены ставит турель; счётчик `Turrets: N/3`
- [ ] Тап вне зоны не ставит
- [ ] Волны идут; HUD (HP / Wave / Turrets) читаем
- [ ] Победа или поражение → overlay + **RESTART** тапом работает
- [ ] После Restart слоты турелей сбрасываются

---

## Риски

- **Версия Godot ≠ export templates** → экспорт падает или битый билд.
- **Только arm64-v8a** — старые 32-bit и некоторые эмуляторы не подойдут без x86_64.
- **Package placeholder** `com.yourstudio…` сменить до Play/RuStore.
- Первый открытый Export в редакторе может **переписать** `export_presets.cfg` — ок, не вставлять секреты обратно в файл.
- Renderer переключён на **mobile** для телефонов; десктоп F5 должен работать как раньше по геймплею.

---

## iOS

См. этап 9: `docs/stage9_ios_export.md` (preset **iOS Debug**, Bundle ID `com.yourstudio.zombiestronghold`).
