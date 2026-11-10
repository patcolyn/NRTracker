import 'package:flutter/widgets.dart';

// Fonts you can pick per side in Settings > Appearance
//
// Adding one:
//   1. Drop the Regular .ttf, plus Bold if it has one, into assets/fonts/<name>/ with its licence
//      Latin-script fonts only
//   2. Register the family in pubspec.yaml under flutter > fonts
//   3. Add it to sideFonts below

/// Family name as in pubspec.yaml -> name shown in Settings, in display order
/// Urbanist is the app font and is labelled with the fontDefault string instead
const sideFonts = <String, String>{
  'Urbanist': 'Urbanist',
  'Cinzel': 'Cinzel',
  'Monoton': 'Monoton',
  'NovaCut': 'Nova Cut',
  'Oxanium': 'Oxanium',
  'ShareTechMono': 'Share Tech Mono',
  'Shojumaru': 'Shojumaru',
  'Wallpoet': 'Wallpoet',
  'ComicRelief': 'Comic Relief',
  'MaterialDings': 'MaterialDings',
};

/// Used when nothing's been picked, or a saved font has since been removed
const defaultSideFont = 'Urbanist';

/// Fonts with no real bold, or that look better without it. Bold text uses regular weight for these
const noBoldFonts = {'Monoton', 'Shojumaru', 'Wallpoet', 'ComicRelief', 'MaterialDings'};

String resolveSideFont(String? family) => sideFonts.containsKey(family) ? family! : defaultSideFont;

/// Carries the 'bold' weight for the side's font down to the text in that half
class SideFontScope extends InheritedWidget {
  const SideFontScope({super.key, required this.bold, required super.child});

  final FontWeight bold;

  @override
  bool updateShouldNotify(SideFontScope oldWidget) => bold != oldWidget.bold;
}

/// Use this instead of FontWeight.w700 for text inside a side's half
FontWeight boldWeight(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<SideFontScope>()?.bold ?? FontWeight.w700;
