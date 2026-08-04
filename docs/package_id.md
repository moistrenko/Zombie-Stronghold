# Package / Application ID — decision checklist

**Status:** undecided — placeholder kept on purpose.

**Current placeholder:** `com.yourstudio.zombiestronghold`

**TODO (owner):** choose a final reverse-DNS Application ID **before the first Google Play upload**. After the first upload, changing the ID for the same Play listing is effectively impossible (new app, lost update path, broken deep links / store URL).

Do **not** invent a production company domain in-repo without an owner decision.

---

## What to pick

1. Prefer a domain you control (or will control): `com.<yourcompany>.zombiestronghold`.
2. All-lowercase, letters / digits / underscores in segments; classic Java package style.
3. Same ID for Android Play + (usually) iOS Bundle ID unless stores require a split.
4. Check Play Console / App Store Connect that the ID is free.
5. Avoid `com.example.*`, `com.godot.*`, and generic `com.yourstudio.*` for production.

---

## Where to replace (after decision)

| Location | Field / text |
|----------|----------------|
| `export_presets.cfg` → **Android Debug** | `package/unique_name` |
| `export_presets.cfg` → **Android Release AAB** | `package/unique_name` |
| `export_presets.cfg` → **iOS Debug** | `application/bundle_identifier` |
| Google Play Console | Application ID (set at app creation; must match AAB) |
| App Store Connect / Xcode | Bundle ID (when iOS unblocked) |
| RuStore listing (later) | package name must match signed build |
| Docs / store copy mentioning the ID | `docs/package_id.md`, stage7/8/9/11/18, `assets/store/`, privacy draft |

Optional project note: `project.godot` carries a TODO comment only (Godot does not store Android package name in `project.godot` itself).

---

## Files that currently contain the placeholder string

Single checklist for search/replace when the owner decides:

```
export_presets.cfg
docs/package_id.md
docs/stage18_android_aab.md
docs/stage7_android_export.md
docs/stage8.md
docs/stage9_ios_export.md
docs/stage10_blocked.md
docs/stage10b_store_assets.md
docs/stage11.md
docs/stage11_play_console_prep.md
docs/stage1.md
docs/store_blockers.md
docs/privacy_policy_draft.md
assets/store/README.md
project.godot          # TODO comment only
```

Quick scan after change:

```bash
rg -n 'com\.yourstudio\.zombiestronghold' .
```

---

## Decision log

| Date | Decision | Notes |
|------|----------|-------|
| — | *pending* | Keep `com.yourstudio.zombiestronghold` until owner picks final ID |
