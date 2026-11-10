# NR Tracker text (localisation)

All text shown in the app lives in **`app_en.arb`** (English). It's JSON: edit the values only (the text on the
right of each `"key": "value"` line), then rebuild (`flutter run`).

- Words in `{braces}` (e.g. `{round}`, `{name}`) are filled in by the app. Keep them, but you can move them.
- `\n` is a line break; `\"` is a double quote.
- In the About text (`aboutBody`), `[text](https://...)` makes a tappable link.
- The `"@key": {...}` entries are notes for translators and describe the placeholders; leave them as they are.

**Adding a language:** copy `app_en.arb` to `app_<code>.arb` (e.g. `app_de.arb`, `app_fr.arb`, `app_pt_BR.arb`), set
`"@@locale"` to that code, translate the values (including `languageName`, the language's own name) and rebuild. It then
shows up in Settings > Language. Missing keys fall back to English.

`app_localizations*.dart` in this folder are generated from the .arb files on every build; don't edit them.
