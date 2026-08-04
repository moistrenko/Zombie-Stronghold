# Этап 8 — toolchain + APK + smoke-test

## Итог

| Компонент | Статус |
|-----------|--------|
| JDK 17 | **да** — Homebrew `openjdk@17` (17.0.20) |
| Android SDK | **да** — `~/Library/Android/sdk` (platform-tools, build-tools 34.0.0, platforms android-34, emulator) |
| Export Templates 4.7.1 | **да** — `~/Library/Application Support/Godot/export_templates/4.7.1.stable/` |
| Debug keystore | **да** (локально, не в git) |
| APK | **да** — `builds/android/zombie_stronghold_debug.apk` (~27 MB) |
| Smoke-test | **частичный pass** на эмуляторе (см. ниже) |

## Пути / команды (без паролей)

### JDK

```bash
# установлен: brew install openjdk@17
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"
java -version   # openjdk 17.0.20
```

Godot Editor Settings → Export → Android → **Java SDK Path**:
`/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`

### Android SDK

```text
~/Library/Android/sdk
  platform-tools/
  build-tools/34.0.0/
  platforms/android-34/
  cmdline-tools/latest/
  emulator/
```

Godot **Android SDK Path**: `/Users/<user>/Library/Android/sdk`

AVD (создан для smoke): `zombie_api34_arm64` (API 34, google_apis, arm64-v8a).

### Debug keystore

```text
~/Library/Application Support/Godot/keystores/debug.keystore
alias: androiddebugkey
```

Не коммитить. В Editor Settings путь уже прописан; пароль — стандартный android debug (только локально).

### Export Templates

```text
~/Library/Application Support/Godot/export_templates/4.7.1.stable/
# version.txt → 4.7.1.stable
```

Скачано: `Godot_v4.7.1-stable_export_templates.tpz` (совпадает с Godot **4.7.1.stable**).

### Сборка APK

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export ANDROID_HOME=$HOME/Library/Android/sdk
mkdir -p builds/android
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path . \
  --export-debug "Android Debug" builds/android/zombie_stronghold_debug.apk
```

### Установка / запуск

```bash
adb install -r builds/android/zombie_stronghold_debug.apk
# НЕ стартовать com.godot.game.GodotApp напрямую (not exported).
adb shell am start -a android.intent.action.MAIN \
  -c android.intent.category.LAUNCHER -p com.yourstudio.zombiestronghold
# или: adb shell monkey -p com.yourstudio.zombiestronghold -c android.intent.category.LAUNCHER 1
```

## Правки проекта из-за экспорта / устройства

1. `project.godot`: `textures/vram_compression/import_etc2_astc=true` (обязательно для Android).
2. `project.godot`: восстановлен `window/handheld/orientation=0` (landscape).
3. `scripts/battle/battle.gd`: явный `Variant` для raycast (warning-as-error в 4.7).
4. `export_presets.cfg`: `command_line/extra_args="--rendering-method gl_compatibility"` — стабильный старт на эмуляторе SwiftShader; на реальном телефоне можно убрать и опереться на `mobile`/Vulkan.

Package: `com.yourstudio.zombiestronghold` · App: Zombie Stronghold.

## Smoke-test (эмулятор Pixel-like 2400×1080 landscape)

Скриншоты (локально, в `builds/` / gitignore): mid-game показал живой бой.

| Проверка | Результат |
|----------|-----------|
| Старт без краша | **pass** (pid живой; сцена видна) |
| Landscape | **pass** (скрин 2400×1080; manifest orientation landscape) |
| HUD читаем | **pass** — `Wall HP`, `Wave 2/3`, `Turrets: 0/3` |
| Волны идут | **pass** — Wave 2/3, зомби на поле, HP стены падает |
| Тап → турель в зоне | **не подтверждён** — первый запуск перекрыт системным «Viewing full screen / Got it»; автотапы попали в диалог → `Turrets: 0/3` |
| Win/Lose + Restart | **частично** — lose-путь вероятен (HP 60/100 при 0 турелях); overlay/Restart автотапом не закрыты |

**Вердикт:** smoke **partial pass** — APK playable на эмуляторе; placement + Restart нужно добить вручную (закрыть Got it → тап в синюю зону → 2–3 турели → дойти до VICTORY/DEFEAT → RESTART).

### Ручной дожим (владельцу, 2 минуты)

1. `adb install -r builds/android/zombie_stronghold_debug.apk` + launch LAUNCHER.
2. Нажать **Got it** на fullscreen hint.
3. Тапнуть 2–3 раза в полосу у стены → `Turrets: N/3`.
4. Дождаться win/lose → **RESTART**.

## Известные риски

- Эмулятор без `gl_compatibility` мог не удерживаться (Vulkan/SwiftShader).
- `am start …/GodotApp` → Permission Denial; нужен LAUNCHER / `GodotAppLauncher`.
- Только **arm64-v8a** в пресете.
- Immersive fullscreen hint мешает автотапам на первом запуске.

## Следующий шаг

Этап 9 выполнен: `docs/stage9_ios_export.md`. Далее — подпись Team ID владельцем и первый iOS debug-прогон (этап 10), либо ручной дожим Android smoke / ghost placement.
