# assets/store — листинг-ассеты

Сюда кладём файлы для **Google Play / RuStore / App Store**.  
Чеклист размеров и текстов: [`docs/stage10b_store_assets.md`](../../docs/stage10b_store_assets.md).

```
assets/store/
├── README.md                 ← этот файл
├── icons/
│   ├── icon_512.png          ← Play / RuStore hi-res (placeholder)
│   └── icon_1024.png         ← App Store (placeholder)
├── feature_graphic/
│   └── feature_graphic_1024x500.png  ← Play feature graphic, без alpha (placeholder)
├── screenshots/
│   ├── phone/                ← landscape phone (положить 2+ кадра)
│   ├── tablet/               ← опционально
│   └── ios/                  ← кадры под App Store
└── copy/
    ├── short_ru.txt / short_en.txt
    └── full_ru.txt / full_en.txt
```

## Правила

- Placeholders **не** финальный маркетинг — заменить перед submit.
- Скрины: **landscape**, реальный геймплей (не мокапы с чужими ассетами).
- Не класть сюда keystore, `.p12`, provisioning, пароли.
- Package ID `com.yourstudio.zombiestronghold` — placeholder до прода.

## Быстрая генерация скринов

1. Запустить игру (F5 или Android APK).  
2. Снять 2–4 кадра: старт/зона, бой с турелями, победа или поражение.  
3. Сохранить как `screenshot_01.png` … в `screenshots/phone/` (желательно ~1920×1080).
