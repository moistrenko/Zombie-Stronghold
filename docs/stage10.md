# Этап 10 — первый iOS debug-прогон

## Статус: **BLOCKED**

| Проверка | Результат |
|----------|-----------|
| Team ID в пресете / env | **нет** (`application/app_store_team_id=""`) |
| Signing identities | **0** |
| Xcode Accounts | **нет** (`~/Library/Developer/Xcode/UserData/Accounts` отсутствует) |
| Export → Xcode | **не выполнялся** — Godot требует Team ID |
| Simulator / My Mac / device | **не гоняли** |
| Smoke-test | **n/a** |

Разблокировка и поля для владельца: **[`docs/stage10_blocked.md`](stage10_blocked.md)**.

Параллельный трек, пока ждём Apple: **этап 10b** (рекомендация в blocked-доке).

После появления Team ID — повторить чеклист экспорта из [`docs/stage9_ios_export.md`](stage9_ios_export.md) §§5–7 и дописать сюда: путь экспорта, таргет, pass/fail, баги.
