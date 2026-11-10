import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit; // material.dart doesn't export this
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_graphics/vector_graphics.dart';

import '../l10n/app_localizations.dart';
import 'fonts.dart';
import 'game.dart';

String counterTypeLabel(AppLocalizations l, CounterType t) => switch (t) {
      CounterType.agenda => l.counterAgenda,
      CounterType.badPublicity => l.counterBadPublicity,
      CounterType.tags => l.counterTags,
      CounterType.coreDamage => l.counterCoreDamage,
      CounterType.mu => l.counterMu,
      CounterType.handSize => l.counterHandSize,
      CounterType.recurringCredit => l.counterRecurringCredit,
      CounterType.genericBlue => l.counterGenericBlue,
      CounterType.genericGreen => l.counterGenericGreen,
      CounterType.virus => l.counterVirus,
      CounterType.advancement => l.counterAdvancement,
      CounterType.advancementReverse => l.counterAdvancementReverse,
    };

/// What a functional counter does, for the add counters list
String? counterTypeHint(AppLocalizations l, CounterType t) => switch (t) {
      CounterType.agenda => l.counterAgendaHint,
      CounterType.badPublicity => l.counterBadPublicityHint,
      CounterType.coreDamage => l.counterCoreDamageHint,
      CounterType.handSize => l.counterHandSizeHint,
      CounterType.recurringCredit => l.counterRecurringCreditHint,
      _ => null,
    };

IconData? materialIconFor(CounterType t) => t == CounterType.handSize ? Icons.back_hand : null;

/// NSG symbol, or a Material icon for types that don't have one
class CounterIcon extends StatelessWidget {
  const CounterIcon(this.type, {super.key, required this.color, this.size = 24});

  final CounterType type;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final m = materialIconFor(type);
    return m != null ? Icon(m, color: color, size: size) : NsgIcon(type.icon, color: color, size: size);
  }
}

String counterTitle(AppLocalizations l, ExtraCounter c) => c.name.isEmpty ? counterTypeLabel(l, c.type) : c.name;

String sideName(AppLocalizations l, Side s) => s == Side.corp ? l.sideCorp : l.sideRunner;
String sideNameUpper(AppLocalizations l, Side s) => s == Side.corp ? l.sideCorpUpper : l.sideRunnerUpper;

/// Counter colours are the official NSG token colours
class NrColors {
  static const click = Color(0xFF00BBF2);
  static const clickSpent = Color(0xFFA7A9AC);
  static const tag = Color(0xFFF3BD1F);
  static const coreDamage = Color(0xFFE82C2E);
  static const badPublicity = Color(0xFF1AAE4F);
  static const runFund = Color(0xFF22C55E);
  static const run = Color(0xFFDC2626);

  /// Colour choices in Settings
  static const palette = <Color>[
    Color(0xFF3B82F6), // Corp default
    Color(0xFFEF4444), // Runner default
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFF97316),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFF64748B),
    Color(0xFFE5E7EB),
  ];

  static Color counter(CounterType type) => switch (type) {
        CounterType.agenda || CounterType.mu || CounterType.handSize => Colors.white,
        CounterType.badPublicity => badPublicity,
        CounterType.tags => tag,
        CounterType.coreDamage => coreDamage,
        CounterType.recurringCredit => Colors.white,
        CounterType.genericBlue => const Color(0xFF744E9F), // NSG's 'blue' token
        CounterType.genericGreen => const Color(0xFF9ECB3B),
        CounterType.virus => const Color(0xFFF47B29),
        CounterType.advancement || CounterType.advancementReverse => Colors.white,
      };
}

/// Faction glyphs: assets/nsg/glyphs/NSG_<KEY>.webp
const corpFactions = <String, String>{
  'HB': 'Haas-Bioroid',
  'JINTEKI': 'Jinteki',
  'NBN': 'NBN',
  'WEYLAND': 'Weyland Consortium',
};
const runnerFactions = <String, String>{
  'ANARCH': 'Anarch',
  'CRIMINAL': 'Criminal',
  'SHAPER': 'Shaper',
  'ADAM': 'Adam',
  'APEX': 'Apex',
  'SUNNY': 'Sunny Lebeau',
};

/// Greyscale, with blacks lifted to mid-grey so dark glyphs like Apex and Weyland still show up on black
const greyscale = ColorFilter.matrix(<double>[
  0.1382, 0.4649, 0.0469, 0, 89, //
  0.1382, 0.4649, 0.0469, 0, 89, //
  0.1382, 0.4649, 0.0469, 0, 89, //
  0, 0, 0, 1, 0, //
]);

void tick() => HapticFeedback.selectionClick();

/// Text with [label](url) links, for the About text. Adds https:// if the URL has no scheme
class LinkText extends StatefulWidget {
  const LinkText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  State<LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<LinkText> {
  static final _link = RegExp(r'\[([^\]]+)\]\(([^)\s]+)\)');

  /// Text and link pieces in order. Recognizer is null for plain text
  final List<(String, TapGestureRecognizer?)> _parts = [];

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(LinkText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _parse();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  void _clear() {
    for (final (_, r) in _parts) {
      r?.dispose();
    }
    _parts.clear();
  }

  void _parse() {
    _clear();
    final text = widget.text;
    var last = 0;
    for (final m in _link.allMatches(text)) {
      if (m.start > last) _parts.add((text.substring(last, m.start), null));
      final url = m.group(2)!;
      final uri = Uri.parse(url.contains('://') ? url : 'https://$url');
      _parts.add((
        m.group(1)!,
        TapGestureRecognizer()..onTap = () => launchUrl(uri, mode: LaunchMode.externalApplication),
      ));
      last = m.end;
    }
    if (last < text.length) _parts.add((text.substring(last), null));
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final linkStyle = TextStyle(color: accent, decoration: TextDecoration.underline, decorationColor: accent);
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          for (final (text, recognizer) in _parts)
            TextSpan(text: text, style: recognizer == null ? null : linkStyle, recognizer: recognizer),
        ],
      ),
    );
  }
}

/// Tinted NSG symbol. The SVGs are compiled at build time, see pubspec, so there's no SVG parser at runtime
class NsgIcon extends StatelessWidget {
  const NsgIcon(this.name, {super.key, required this.color, this.size = 24});

  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => VectorGraphic(
        loader: AssetBytesLoader('assets/nsg/$name.svg'),
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
}

/// Round +/- button. 42x36 touch area, 30dp disc. Long-press is for the max on X/Y counters
class StepButton extends StatelessWidget {
  const StepButton({super.key, required this.icon, required this.onTap, this.onLongPress});

  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          tick();
          onTap();
        },
        onLongPress: onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onLongPress!();
              },
        child: SizedBox(
          width: 42,
          height: 36,
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.16),
              ),
              child: Icon(icon, size: 22, color: Colors.white),
            ),
          ),
        ),
      );
}

/// A counter: [-] icon value [+], or a tap/swipe tile when buttons are off
/// Dragging to reorder/remove is handled by DraggableCounter in tracker_screen.dart
class CounterChip extends StatefulWidget {
  const CounterChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.display,
    required this.onDelta,
    this.lit = false,
    this.name = '',
    this.onLongDelta,
    this.warn = false,
    this.buttons = true,
    this.tapDelta = 1,
    this.materialIcon,
    this.litColor,
    this.tileWidth,
  });

  /// Outer height, border included
  static const tileHeight = 40.0;

  /// Without a name label
  static const buttonChipHeight = 36.0 + 2 * border;

  /// Always drawn, just transparent when not lit, so sizes subtract it to keep the outer size exact
  static const border = 2.0;

  final String icon;
  final String label;
  final Color color;
  final String display;
  final ValueChanged<int> onDelta;
  final bool lit;
  final String name;

  /// Long-press on -/+, for the max on X/Y counters
  final ValueChanged<int>? onLongDelta;

  /// Shows the value in red, e.g. MU over the limit
  final bool warn;

  final bool buttons;

  /// Tap action in swipe mode
  final int tapDelta;

  /// Overrides [icon], e.g. hand size
  final IconData? materialIcon;

  /// Highlight colour if different from [color]
  final Color? litColor;

  /// Fixed outer width, or null to size to content
  final double? tileWidth;

  Widget symbol(double size) =>
      materialIcon != null ? Icon(materialIcon, color: color, size: size) : NsgIcon(icon, color: color, size: size);

  @override
  State<CounterChip> createState() => _CounterChipState();
}

class _CounterChipState extends State<CounterChip> {
  double _dragDx = 0;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final value = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 22),
      child: Text(
        w.display,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          height: 1.1,
          fontWeight: boldWeight(context),
          color: w.warn ? NrColors.coreDamage : Colors.white,
        ),
      ),
    );

    final Widget row;
    if (w.buttons) {
      final middle = FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(mainAxisSize: MainAxisSize.min, children: [w.symbol(26), const SizedBox(width: 4), value]),
      );
      row = SizedBox(
        width: w.tileWidth == null ? null : w.tileWidth! - 2 * CounterChip.border,
        child: Row(
          mainAxisSize: w.tileWidth == null ? MainAxisSize.min : MainAxisSize.max,
          children: [
            StepButton(
              icon: Icons.remove_rounded,
              onTap: () => w.onDelta(-1),
              onLongPress: w.onLongDelta == null ? null : () => w.onLongDelta!(-1),
            ),
            if (w.tileWidth == null) middle else Expanded(child: Center(child: middle)),
            StepButton(
              icon: Icons.add_rounded,
              onTap: () => w.onDelta(1),
              onLongPress: w.onLongDelta == null ? null : () => w.onLongDelta!(1),
            ),
          ],
        ),
      );
    } else {
      // Fixed-size tile. The name, if there is one, goes in small text on top
      final content = FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [w.symbol(24), const SizedBox(width: 5), value],
        ),
      );
      row = SizedBox(
        width: w.tileWidth == null ? null : w.tileWidth! - 2 * CounterChip.border,
        height: CounterChip.tileHeight - 2 * CounterChip.border,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: w.name.isEmpty
              ? Center(child: content)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      w.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9, height: 1.0, color: Colors.white70, letterSpacing: 0.3),
                    ),
                    Flexible(child: content),
                  ],
                ),
        ),
      );
    }

    final chip = Container(
      decoration: BoxDecoration(
        color: w.lit ? (w.litColor ?? w.color).withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: w.lit ? (w.litColor ?? w.color) : Colors.transparent, width: CounterChip.border),
      ),
      child: (w.name.isEmpty || !w.buttons)
          ? row
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: w.tileWidth == null ? 150 : w.tileWidth! - 2 * CounterChip.border - 16,
                    ),
                    child: Text(
                      w.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, height: 1.0, color: Colors.white70, letterSpacing: 0.5),
                    ),
                  ),
                ),
                row,
              ],
            ),
    );

    final semantic = Semantics(label: '${w.label}: ${w.display}', child: chip);
    if (w.buttons) return semantic;

    // Swipe mode: tap and swipe anywhere on the chip
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        tick();
        w.onDelta(w.tapDelta);
      },
      onHorizontalDragStart: (_) => _dragDx = 0,
      onHorizontalDragUpdate: (d) => _dragDx += d.delta.dx,
      onHorizontalDragEnd: (_) {
        if (_dragDx.abs() >= 16) {
          tick();
          w.onDelta(_dragDx > 0 ? 1 : -1);
        }
      },
      child: semantic,
    );
  }
}

/// Number with evenly spaced digits, so it doesn't change width as it counts. None of the side fonts have
/// tabular figures, so each digit gets a cell as wide as the widest one. Drawing digits separately loses kerning,
/// so the cells are pulled together by the font's typical digit kerning. Wallpoet really needs this
class MonoDigits extends StatelessWidget {
  const MonoDigits(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  /// Cell width and pitch, per style
  static final _metrics = <(TextStyle, TextScaler), (double, double)>{};

  static double _width(String text, TextStyle style, TextScaler scaler) {
    final p = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr, textScaler: scaler)
      ..layout();
    final w = p.width;
    p.dispose();
    return w;
  }

  /// Pitch = widest digit + median kerning over all digit pairs. Only ever tightens
  static (double, double) _measure(TextStyle style, TextScaler scaler) {
    final w = [for (var d = 0; d <= 9; d++) _width('$d', style, scaler)];
    final cell = w.fold<double>(0, (a, b) => a > b ? a : b);
    final kerns = [
      for (var a = 0; a <= 9; a++)
        for (var b = 0; b <= 9; b++) _width('$a$b', style, scaler) - w[a] - w[b],
    ]..sort();
    final kern = kerns[kerns.length ~/ 2];
    return (cell, kern < 0 ? cell + kern : cell);
  }

  static bool _isDigit(String ch) => ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39;

  @override
  Widget build(BuildContext context) {
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    if (_metrics.length > 32) _metrics.clear();
    final (cell, pitch) = _metrics.putIfAbsent((resolved, scaler), () => _measure(resolved, scaler));
    return Semantics(
      label: text, // read as one number
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final ch in text.split(''))
              if (_isDigit(ch))
                // Full-width cell centred in a narrower slot; the overhang is just side bearing
                SizedBox(
                  width: pitch,
                  child: OverflowBox(
                    fit: OverflowBoxFit.deferToChild,
                    minWidth: cell,
                    maxWidth: cell,
                    child: Text(ch, style: style, textAlign: TextAlign.center, softWrap: false),
                  ),
                )
              else
                Text(ch, style: style, softWrap: false),
          ],
        ),
      ),
    );
  }
}
