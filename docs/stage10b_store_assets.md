# Этап 10b-B — Store assets checklist

Единый чеклист листинга для **Google Play → RuStore → App Store**.  
Общие блокеры аккаунтов/подписи: [`docs/store_blockers.md`](store_blockers.md) (не дублируем).  
Файлы-заготовки: [`assets/store/`](../assets/store/).

**Не публикуем** на этом этапе. Аккаунты сторов не обязательны для заполнения ассетов.

Placeholder package / Bundle ID: `com.yourstudio.zombiestronghold` — **сменить перед продом**.

---

## Чеклист по типам ассетов

### 1) App icon

| Стор | Размер | Формат | Куда класть | Статус |
|------|--------|--------|-------------|--------|
| Google Play (hi-res) | **512×512** | 32-bit PNG + alpha, ≤1 MB; квадрат без скруглений (Play маскирует) | `assets/store/icons/icon_512.png` | placeholder |
| RuStore | **512×512** (уточнять в Console) | PNG/JPG | тот же / копия | placeholder |
| App Store | **1024×1024** | PNG, без альфы для Connect часто предпочтительно; без скруглений | `assets/store/icons/icon_1024.png` | placeholder |
| In-app / Godot | — | `icon.svg` / export launcher icons | отдельно от store hi-res | MVP ok |

Финальный маркетинг-арт — позже; спецификация важнее красоты.

### 2) Feature graphic / промо

| Стор | Размер | Формат | Куда | Статус |
|------|--------|--------|------|--------|
| Google Play | **1024×500** | JPEG или 24-bit PNG **без alpha** | `assets/store/feature_graphic/feature_graphic_1024x500.png` | placeholder |
| RuStore | баннер/обложка по Console | см. актуальную справку RuStore | `assets/store/feature_graphic/` | TODO |
| App Store | отдельного feature graphic нет; промо через скрины + optional preview video | — | — | n/a |

Safe zone: ключевой текст/смысл в центральных ~80%.

### 3) Скриншоты (игра **landscape**)

| Стор | Минимум | Рекомендация | Куда |
|------|---------|--------------|------|
| Play phone | ≥2 | 2–8 шт.; landscape **1920×1080** (16:9) или близко; JPEG/PNG без alpha; сторона 320–3840 | `assets/store/screenshots/phone/` |
| Play tablet 7"/10" | опционально | если целитесь в планшеты | `assets/store/screenshots/tablet/` |
| RuStore | обязательные скрины | 16:9 landscape ок | `assets/store/screenshots/phone/` |
| App Store iPhone | обычно 6.7"/6.5" наборы | landscape кадры геймплея | `assets/store/screenshots/ios/` |
| App Store iPad | если Universal | отдельно | `assets/store/screenshots/ios_ipad/` |

Снять с эмулятора/device (этап 8 smoke): mid-game, placement+ghost, win/lose. Пока папка пустая — README внутри.

### 4) Тексты листинга (заготовки)

Файлы: `assets/store/copy/short_ru.txt`, `short_en.txt`, `full_ru.txt`, `full_en.txt` (ниже в репо).

| Поле | Play | RuStore | App Store |
|------|------|---------|-----------|
| Short / subtitle | ≤80 символов (Play short) | краткое | Subtitle ≤30 |
| Full description | до ~4000 | полное | до ~4000 |
| Keywords | — | — | отдельно ≤100 символов |

### 5) Privacy Policy

- Черновик страницы: [`docs/privacy_policy_draft.md`](privacy_policy_draft.md)
- Нужен **публичный HTTPS URL** (GitHub Pages / сайт студии) — вписать в Play / RuStore / App Store Connect
- Пока аналитики/ads нет — формулировка «не собираем персональные данные» + контакт

### 6) Age rating

| Система | Ориентир для Zombie Stronghold |
|---------|--------------------------------|
| IARC / Play | **Teen (13+)** / насилие в игре (фэнтези) без реализма крови — честно отметить cartoon/fantasy violence |
| App Store | questionnaire → обычно **12+** |
| RuStore | возрастная категория по их форме; ориентир **12+** |

Кровь/расчленёнка в MVP нет (геометрия) — всё равно указать «насилие / зомби».

---

## Сменить перед публикацией

| # | Что | Сейчас | Действие |
|---|-----|--------|----------|
| 1 | Package / Bundle ID | `com.yourstudio.zombiestronghold` | заменить на ID домена студии; обновить Android preset + iOS Bundle ID + store listings |
| 2 | Ключи подписи Android | debug keystore | release keystore **вне git**; Play App Signing |
| 3 | iOS signing | нет Team ID | Apple Developer + Distribution (см. stage10_blocked) |
| 4 | Название студии / developer name | «yourstudio» placeholder | юр/бренд в Console |
| 5 | Контакт privacy | `privacy@example.com` в draft | реальный email / форма |
| 6 | Privacy Policy URL | нет | задеплоить draft на HTTPS |
| 7 | Иконки / feature / скрины | placeholders | финальный арт + реальные скрины |
| 8 | Название приложения в сторах | Zombie Stronghold | проверить коллизии имени |

---

## Порядок сторов (как в README)

1. **Google Play** — первый; нужны Console + listing assets + release AAB/APK  
2. **RuStore** — те же иконка/скрины/описания + своя регистрация  
3. **App Store** — после iOS Team ID / smoke (этап 10)

---

## Топ-5 блокеров реального submit

1. Нет **публичного Privacy Policy URL**  
2. **Package/Bundle** placeholder `com.yourstudio…`  
3. Нет **release signing** (Android keystore / Apple Team)  
4. Нет **финальных** icon + feature graphic + ≥2 landscape screenshots  
5. Нет **аккаунтов** Play Console / RuStore / Apple Developer (оплата + верификация)

---

## Следующий шаг (рекомендация этапа 11)

Параллельно возможны три трека — приоритет владельца:

| Трек | Когда брать |
|------|-------------|
| **Play Console setup** + финальные store assets | цель — скорый Soft Launch Android (**рекомендация**, первый стор) |
| **Геймплейный контент** (2-й зомби / 2-я турель / баланс) | MVP слишком тонкий для листинга |
| **Ждать Apple Team ID** → добить этап 10 | только если iOS приоритетнее Play |

**Рекомендация исполнителя:** этап **11 = Play Console prep + content depth** (минимум второй тип врага или вариация турели), store placeholders уже есть; iOS — как только появится Team ID.
