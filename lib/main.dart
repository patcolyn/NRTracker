import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'l10n/app_localizations.dart';
import 'netrunner/game.dart';
import 'netrunner/tracker_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _keepScreenReady();
  runApp(ChangeNotifierProvider<GameNotifier>(
    create: (_) => GameNotifier()..load(),
    child: const NrTrackerApp(),
  ));
}

/// Stays on for the whole game, portrait only (the cover screen is portrait), no system bars
void _keepScreenReady() {
  WakelockPlus.enable();
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

final _theme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  fontFamily: 'Urbanist',
  colorScheme: const ColorScheme.dark(primary: Color(0xFF00BBF2)),
);

/// 'en', 'pt-BR', 'zh-Hant-TW' -> Locale. Empty means follow the phone
Locale? _localeFromTag(String tag) {
  if (tag.isEmpty) return null;
  final p = tag.split('-');
  if (p.length == 1) return Locale(p[0]);
  if (p.length == 2) {
    return p[1].length == 4 ? Locale.fromSubtags(languageCode: p[0], scriptCode: p[1]) : Locale(p[0], p[1]);
  }
  return Locale.fromSubtags(languageCode: p[0], scriptCode: p[1], countryCode: p[2]);
}

/// Exact match first, then the same language, then English
Locale _pickLocale(Locale? wanted, Iterable<Locale> supported) {
  if (wanted != null) {
    for (final s in supported) {
      if (s.languageCode == wanted.languageCode && s.countryCode == wanted.countryCode) return s;
    }
    for (final s in supported) {
      if (s.languageCode == wanted.languageCode) return s;
    }
  }
  return const Locale('en');
}

class NrTrackerApp extends StatelessWidget {
  const NrTrackerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: const TrackerScreen(),
        theme: _theme,
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        locale: _localeFromTag(context.select<GameNotifier, String>((g) => g.language)),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: _pickLocale,
      );
}
