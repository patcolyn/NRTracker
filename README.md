# NR Tracker

A credit and click tracker for Netrunner

- Credits, clicks, and turns for both sides
- Counters you can add, reorder and remove: agenda points, bad publicity, tags, core damage, MU, max hand size,
  recurring credits, and more
- One-player mode for tracking just your side
- Saved layouts, per-side colours, faction glyphs, and customisable fonts

## Build

### What you need

- [Flutter](https://docs.flutter.dev/get-started/install) (stable channel, Dart 3.11 or newer)
- [Android Studio](https://developer.android.com/studio) for the Android SDK
- JDK 17 or 21 (Android Studio's bundled Java is too new for this project's Gradle). Point Flutter at it with
  `flutter config --jdk-dir="<path to JDK>"`

Run `flutter doctor` to check everything is set up.

### Run it

With a phone connected over USB debugging, or an Android emulator running:

```
git clone https://github.com/patcolyn/NRTracker.git
cd NRTracker
flutter pub get
flutter run
```

`flutter run` builds a debug version and installs it on the connected phone. Hot reload works while it's running.

## Translating

All the app's text is in `lib/l10n/app_en.arb`. See [lib/l10n/README.md](lib/l10n/README.md) for how to add a
language.

## Credits

- Game symbols and faction glyphs by [Null Signal Games](https://nullsignal.games/), licensed under
  [CC BY-ND 4.0](https://creativecommons.org/licenses/by-nd/4.0/) (see `assets/nsg/ATTRIBUTION.md`)
- Fonts are under the SIL Open Font License, with each licence next to its font in `assets/fonts/`
- Based on [MTG Tracker](https://github.com/birkoss/mtg-tracker) by birkoss

This is a fan-made app, not affiliated with or endorsed by Null Signal Games.
