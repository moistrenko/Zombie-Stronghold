# Этап 1 — foundation Godot-проекта

## Что сделано

- Создан `project.godot` (Godot **4.3+**, `config_version=5`) в корне репозитория.
- Стартовая сцена: `res://scenes/battle/battle.tscn`.
- Экран:
  - viewport **1280×720**
  - ориентация **landscape** (`window/handheld/orientation=0`)
  - stretch: `canvas_items` + aspect `expand` (под разные мобильные соотношения)
- Имя приложения: **Zombie Stronghold**
- Package placeholder: `com.yourstudio.zombiestronghold` (зафиксирован в комментарии `project.godot`; в Export presets выставить при Android-экспорте)
- Боевая сцена-заглушка без геймплея:
  - корень `Battle` (`Node2D`)
  - `Camera2D` по центру viewport
  - `Wall` (`Polygon2D`) слева
  - `SpawnPoint` (`Marker2D` + маркер) справа
  - `Ground` (визуальный плейсхолдер пола)
- Иконка-заглушка: `icon.svg`
- Каркас папок и `.gitignore` (Godot `.godot/`, `builds/`, keystore) — уже с этапа 0, сохранены

**Не сделано (намеренно):** HP, турели, зомби, волны, win/lose, APK-экспорт.

## Как открыть

1. Установить [Godot 4.3+](https://godotengine.org/download) (или новее 4.x).
2. Godot → **Import** / Open → выбрать `project.godot` в корне этого репозитория.
3. Нажать **F5** (Run Project) — должна открыться сцена боя с серой стеной слева и красным маркером спавна справа.

> На машине исполнителя бинарник Godot не найден; проект собран вручную. После первого открытия редактор создаст папку `.godot/` (в git не коммитится).

## Версия Godot

Целевая: **4.3** (`config/features`). Точная версия редактора на CI/машине разработчика пока не зафиксирована — при установке записать сюда фактическую (например 4.3.x / 4.4.x).

## Следующий шаг (этап 2)

Добавить стену с HP и урон при контакте: скрипт на `Wall`, простой зомби-плейсхолдер, движущийся от `SpawnPoint` к стене (ещё без турелей и волн).
