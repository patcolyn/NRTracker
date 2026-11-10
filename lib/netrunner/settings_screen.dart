import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import 'changelog.dart';
import 'fonts.dart';
import 'game.dart';
import 'widgets.dart';

/// 'Default' is stored as a fixed key; show it translated
String layoutDisplayName(AppLocalizations l, String name) => switch (name) {
      GameNotifier.defaultProfileName => l.layoutDefault,
      GameNotifier.corpSoloProfileName => l.layoutCorpSolo,
      GameNotifier.runnerSoloProfileName => l.layoutRunnerSolo,
      _ => name,
    };

String? _builtInSubtitle(AppLocalizations l, String name) => switch (name) {
      GameNotifier.defaultProfileName => l.layoutDefaultSubtitle,
      GameNotifier.corpSoloProfileName => l.layoutCorpSoloSubtitle,
      GameNotifier.runnerSoloProfileName => l.layoutRunnerSoloSubtitle,
      _ => null,
    };

/// Settings home: one button per section. Everything saves immediately and survives New game
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameNotifier>();
    final l = AppLocalizations.of(context);
    void open(String title, List<Widget> Function(BuildContext context, GameNotifier game, AppLocalizations l) body) =>
        Navigator.push(context, MaterialPageRoute<void>(builder: (_) => _SectionPage(title: title, body: body)));
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(l.settingsTitle), backgroundColor: const Color(0xFF111111)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionButton(
            icon: Icons.dashboard_customize_outlined,
            title: l.headerLayouts,
            subtitle: _isLayoutSelected(game, game.activeProfile)
                ? layoutDisplayName(l, game.activeProfile)
                : l.layoutCustom,
            onTap: () => open(l.headerLayouts, _layoutsSection),
          ),
          _SectionButton(icon: Icons.people_outline, title: l.headerMode, onTap: () => open(l.headerMode, _modeSection)),
          _SectionButton(
            icon: Icons.sports_esports_outlined,
            title: l.headerGame,
            onTap: () => open(l.headerGame, _gameSection),
          ),
          _SectionButton(
            icon: Icons.palette_outlined,
            title: l.headerAppearance,
            onTap: () => open(l.headerAppearance, _appearanceSection),
          ),
          _SectionButton(
            icon: Icons.add_circle_outline,
            title: l.headerAddedCounters,
            onTap: () => open(l.headerAddedCounters, _countersSection),
          ),
          _SectionButton(icon: Icons.info_outline, title: l.menuAbout, onTap: () => showAboutAppDialog(context)),
        ],
      ),
    );
  }
}

class _SectionButton extends StatelessWidget {
  const _SectionButton({required this.icon, required this.title, required this.onTap, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: subtitle == null ? null : Text(subtitle!),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
          ),
        ),
      );
}

class _SectionPage extends StatelessWidget {
  const _SectionPage({required this.title, required this.body});

  final String title;
  final List<Widget> Function(BuildContext context, GameNotifier game, AppLocalizations l) body;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameNotifier>();
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(title), backgroundColor: const Color(0xFF111111)),
      body: ListView(children: [...body(context, game, l), const SizedBox(height: 24)]),
    );
  }
}

Future<void> showAboutAppDialog(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(l.appTitle)),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) => Text(
              snap.hasData ? 'v${snap.data!.version}' : '',
              style: const TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(child: LinkText(l.aboutBody)),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(onPressed: () => _showChangelog(dialogContext), child: Text(l.changelog)),
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l.close)),
      ],
    ),
  );
}

Future<void> _showChangelog(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.changelog),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (version, entries) in changelog) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text('v$version', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              for (final e in entries) Text('• $e'),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l.close)),
      ],
    ),
  );
}

/// Only selected while it's loaded and unchanged
bool _isLayoutSelected(GameNotifier game, String name) =>
    name == game.activeProfile && game.layoutChanges(name).isEmpty;

List<Widget> _layoutsSection(BuildContext context, GameNotifier game, AppLocalizations l) => [
      for (final name in game.profileNames)
        ListTile(
          leading: Icon(
            _isLayoutSelected(game, name) ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: _isLayoutSelected(game, name) ? Theme.of(context).colorScheme.primary : null,
          ),
          title: Text(layoutDisplayName(l, name)),
          subtitle: GameNotifier.isBuiltIn(name)
              ? Text(_builtInSubtitle(l, name)!)
              : (game.profileDescription(name).isEmpty ? null : Text(game.profileDescription(name))),
          trailing: GameNotifier.isBuiltIn(name)
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: l.editLayoutDescription,
                      onPressed: () => _editLayoutDescription(context, name),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l.deleteLayout,
                      onPressed: () => _confirmDeleteLayout(context, name),
                    ),
                  ],
                ),
          onTap: () => _loadLayout(context, name),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => _showSaveLayoutDialog(context),
              icon: const Icon(Icons.save_outlined),
              label: Text(l.saveAsNewLayout),
            ),
            if (!GameNotifier.isBuiltIn(game.activeProfile))
              OutlinedButton.icon(
                onPressed: () => _confirmUpdateLayout(context, game.activeProfile),
                icon: const Icon(Icons.update),
                label: Text(l.updateLayoutButton(game.activeProfile)),
              ),
          ],
        ),
      ),
    ];

/// Mode settings, also used in the ☰ menu. [compact] drops the descriptions and uses a single
/// SideCycleSwitch instead of the switch + side picker
class ModeSettings extends StatelessWidget {
  const ModeSettings({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameNotifier>();
    final l = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: compact ? _compactModeSection(game, l) : _modeSection(context, game, l),
    );
  }
}

/// off -> Corp -> Runner -> off
void _cycleMode(GameNotifier game) {
  if (!game.onePlayer) {
    game.setTrackedSide(Side.corp);
    game.setOnePlayer(true);
  } else if (game.trackedSide == Side.corp) {
    game.setTrackedSide(Side.runner);
  } else {
    game.setOnePlayer(false);
  }
}

// Opponent's counters goes above the mode switch, and only shows in one-player mode
List<Widget> _compactModeSection(GameNotifier game, AppLocalizations l) => [
      if (game.onePlayer)
        SwitchListTile(
          secondary: const Icon(Icons.visibility_outlined),
          title: Text(l.showOpponentCounters),
          value: game.showOpponent,
          onChanged: game.setShowOpponent,
        ),
      ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(l.onePlayerMode),
        trailing: SideCycleSwitch(side: game.onePlayer ? game.trackedSide : null, onTap: () => _cycleMode(game)),
        onTap: () => _cycleMode(game),
      ),
    ];

/// Three-way switch: off, Corp or Runner, with the side name in the track
/// Always the default blue/red, not the user's side colours
class SideCycleSwitch extends StatelessWidget {
  const SideCycleSwitch({super.key, required this.side, required this.onTap});

  /// null = off
  final Side? side;
  final VoidCallback onTap;

  static const width = 96.0;
  static const height = 32.0;
  static const _thumb = 24.0;
  static const _duration = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final on = side != null;
    final track = switch (side) {
      Side.corp => const Color(GameNotifier.defaultCorpColor),
      Side.runner => const Color(GameNotifier.defaultRunnerColor),
      null => Colors.white24,
    };
    final label = switch (side) {
      Side.corp => l.sideCorp,
      Side.runner => l.sideRunner,
      null => '',
    };
    return Semantics(
      button: true,
      toggled: on,
      label: on ? '${l.onePlayerMode}: $label' : l.onePlayerMode,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: _duration,
          width: width,
          height: height,
          padding: const EdgeInsets.all((height - _thumb) / 2),
          decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(height / 2)),
          child: Stack(
            children: [
              Positioned.fill(
                right: _thumb + 4,
                left: 6,
                child: AnimatedOpacity(
                  duration: _duration,
                  opacity: on ? 1 : 0,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedAlign(
                duration: _duration,
                curve: Curves.easeOut,
                alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: _thumb,
                  height: _thumb,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> _modeSection(BuildContext context, GameNotifier game, AppLocalizations l) => [
      SwitchListTile(
        secondary: const Icon(Icons.person_outline),
        title: Text(l.onePlayerMode),
        subtitle: Text(l.onePlayerModeSubtitle),
        value: game.onePlayer,
        onChanged: game.setOnePlayer,
      ),
      if (game.onePlayer)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SegmentedButton<Side>(
            segments: [
              ButtonSegment(value: Side.corp, label: Text(l.sideCorp)),
              ButtonSegment(value: Side.runner, label: Text(l.sideRunner)),
            ],
            selected: {game.trackedSide},
            onSelectionChanged: (s) => game.setTrackedSide(s.first),
          ),
        ),
      if (game.onePlayer)
        SwitchListTile(
          secondary: const Icon(Icons.visibility_outlined),
          title: Text(l.showOpponentCounters),
          subtitle: Text(l.showOpponentCountersSubtitle),
          value: game.showOpponent,
          onChanged: game.setShowOpponent,
        ),
    ];

List<Widget> _gameSection(BuildContext context, GameNotifier game, AppLocalizations l) => [
      SwitchListTile(
        secondary: const Icon(Icons.timer_outlined),
        title: Text(l.autoEndTurn),
        value: game.autoEndTurn,
        onChanged: game.setAutoEndTurn,
      ),
      _StepperTile(
        icon: Icons.emoji_events_outlined,
        title: l.agendaToWin,
        value: game.agendaMax,
        onChanged: game.setAgendaMax,
      ),
      SwitchListTile(
        secondary: const Icon(Icons.exposure),
        title: Text(l.counterButtons),
        subtitle: Text(l.counterButtonsSubtitle),
        value: game.counterButtons,
        onChanged: game.setCounterButtons,
      ),
    ];

List<Widget> _appearanceSection(BuildContext context, GameNotifier game, AppLocalizations l) => [
      const _LanguageTile(),
      for (final side in Side.values) ...[
        ListTile(
          title: Text(side == Side.corp ? l.corpColour : l.runnerColour),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in NrColors.palette)
                  GestureDetector(
                    onTap: () => game.setColor(side, c.toARGB32()),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: game.colorValue(side) == c.toARGB32() ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                _CustomColourButton(side: side),
              ],
            ),
          ),
        ),
        ListTile(
          title: Text(side == Side.corp ? l.corpFactionGlyph : l.runnerFactionGlyph),
          trailing: DropdownButton<String>(
            value: game.faction(side),
            items: [
              DropdownMenuItem(value: '', child: Text(l.factionNone)),
              for (final e in (side == Side.corp ? corpFactions : runnerFactions).entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => game.setFaction(side, v ?? ''),
          ),
        ),
        ListTile(
          title: Text(side == Side.corp ? l.corpFont : l.runnerFont),
          trailing: DropdownButton<String>(
            value: game.font(side),
            items: [
              for (final e in sideFonts.entries)
                DropdownMenuItem(
                  value: e.key,
                  child: Text(
                    e.key == defaultSideFont ? l.fontDefault : e.value,
                    style: TextStyle(fontFamily: e.key),
                  ),
                ),
            ],
            onChanged: (v) => game.setFont(side, v ?? defaultSideFont),
          ),
        ),
      ],
      // 0 = always use the 5-credit icon
      SwitchListTile(
        secondary: const Icon(Icons.toll_outlined),
        title: Text(l.creditIconFrom),
        subtitle: Text(l.creditIconSubtitle),
        value: game.creditIcon,
        onChanged: game.setCreditIcon,
      ),
      if (game.creditIcon)
        _StepperTile(
          icon: Icons.tune,
          title: l.creditIconAt,
          subtitle: l.creditIconFromSubtitle,
          value: game.creditIconThreshold,
          onChanged: game.setCreditIconThreshold,
        ),
      SwitchListTile(
        secondary: const Icon(Icons.animation),
        title: Text(l.creditAnimation),
        subtitle: Text(l.creditAnimationSubtitle),
        value: game.creditAnimation,
        onChanged: game.setCreditAnimation,
      ),
    ];

List<Widget> _countersSection(BuildContext context, GameNotifier game, AppLocalizations l) => [
      // Hint in header grey so it doesn't look like a list item
      ListTile(
        dense: true,
        leading: const Icon(Icons.open_with, color: Colors.white54),
        title: Text(l.dragHint, style: const TextStyle(color: Colors.white54)),
      ),
      if (game.extras.isEmpty)
        ListTile(
          title: Text(l.noCountersYet),
          subtitle: Text(l.noCountersYetSubtitle),
        ),
      for (final c in game.extras)
        ListTile(
          leading: CounterIcon(c.type, color: NrColors.counter(c.type), size: 28),
          title: Text(counterTitle(l, c)),
          subtitle: Text(l.addedCounterSubtitle(sideName(l, c.side), counterTypeLabel(l, c.type))),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l.remove,
            onPressed: () => game.removeExtra(c.id),
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: FilledButton.icon(
          onPressed: () => showAddCounterDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l.addCounter),
        ),
      ),
      if (game.extras.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: game.removeAllExtras,
            icon: const Icon(Icons.delete_sweep_outlined),
            label: Text(l.removeAllCounters),
          ),
        )
    ];

/// System default plus every app_<code>.arb, each named in its own language. Not saved in layouts
class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameNotifier>();
    final l = AppLocalizations.of(context);
    final tags = [for (final loc in AppLocalizations.supportedLocales) loc.toLanguageTag()];
    return ListTile(
      leading: const Icon(Icons.translate),
      title: Text(l.language),
      trailing: DropdownButton<String>(
        value: tags.contains(game.language) ? game.language : '',
        items: [
          DropdownMenuItem(value: '', child: Text(l.languageSystem)),
          for (final loc in AppLocalizations.supportedLocales)
            DropdownMenuItem(value: loc.toLanguageTag(), child: Text(lookupAppLocalizations(loc).languageName)),
        ],
        onChanged: (v) => game.setLanguage(v ?? ''),
      ),
    );
  }
}

/// The + button after the swatches. Takes on the custom colour when one is set
class _CustomColourButton extends StatelessWidget {
  const _CustomColourButton({required this.side});

  final Side side;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameNotifier>();
    final l = AppLocalizations.of(context);
    final current = Color(game.colorValue(side));
    final custom = !NrColors.palette.any((c) => c.toARGB32() == current.toARGB32());
    final ring = custom ? current : Colors.white38;
    return Tooltip(
      message: l.customColour,
      child: GestureDetector(
        onTap: () async {
          final picked = await showDialog<Color>(
            context: context,
            builder: (_) => _ColourPickerDialog(initial: current),
          );
          if (picked != null) game.setColor(side, picked.toARGB32());
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // same tint as the active half
            color: custom ? current.withValues(alpha: 0.20) : Colors.transparent,
            border: Border.all(color: ring, width: 3),
          ),
          child: Icon(Icons.add, size: 22, color: ring),
        ),
      ),
    );
  }
}

/// Custom colour: 2D picker, or hex/RGB/HSL inputs. Returns null on cancel
class _ColourPickerDialog extends StatefulWidget {
  const _ColourPickerDialog({required this.initial});

  final Color initial;

  @override
  State<_ColourPickerDialog> createState() => _ColourPickerDialogState();
}

class _ColourPickerDialogState extends State<_ColourPickerDialog> {
  late int _r, _g, _b;

  // Kept separately so hue and saturation survive greys
  late double _h, _s, _l;

  late double _hv, _sv, _vv;

  /// false = 2D picker, true = hex/RGB/HSL
  bool _values = false;

  @override
  void initState() {
    super.initState();
    _setRgb((widget.initial.r * 255).round(), (widget.initial.g * 255).round(), (widget.initial.b * 255).round());
  }

  Color get _color => Color.fromARGB(255, _r, _g, _b);

  void _setRgb(int r, int g, int b, {bool syncHsv = true}) {
    _r = r.clamp(0, 255);
    _g = g.clamp(0, 255);
    _b = b.clamp(0, 255);
    final hsl = HSLColor.fromColor(_color);
    final first = !_hslReady;
    if (first || hsl.saturation > 0) _h = hsl.hue;
    if (first || (hsl.lightness > 0 && hsl.lightness < 1)) _s = hsl.saturation;
    _l = hsl.lightness;
    if (syncHsv) _syncHsv(first);
    _hslReady = true;
  }

  bool _hslReady = false;

  /// Hue/saturation are undefined for greys and black, so keep the old ones
  void _syncHsv(bool first) {
    final hsv = HSVColor.fromColor(_color);
    if (first || (hsv.saturation > 0 && hsv.value > 0)) _hv = hsv.hue;
    if (first || hsv.value > 0) _sv = hsv.saturation;
    _vv = hsv.value;
  }

  void _setHsl(double h, double s, double l) {
    _h = h.clamp(0, 360).toDouble();
    _s = s.clamp(0, 1).toDouble();
    _l = l.clamp(0, 1).toDouble();
    final c = HSLColor.fromAHSL(1, _h % 360, _s, _l).toColor();
    _r = (c.r * 255).round();
    _g = (c.g * 255).round();
    _b = (c.b * 255).round();
    _syncHsv(false);
  }

  void _setHsv(double h, double s, double v) {
    _hv = h.clamp(0, 360).toDouble();
    _sv = s.clamp(0, 1).toDouble();
    _vv = v.clamp(0, 1).toDouble();
    final c = HSVColor.fromAHSV(1, _hv % 360, _sv, _vv).toColor();
    _setRgb((c.r * 255).round(), (c.g * 255).round(), (c.b * 255).round(), syncHsv: false);
  }

  String get _hex =>
      [_r, _g, _b].map((v) => v.toRadixString(16).padLeft(2, '0')).join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = _color;
    // Swatch plus a mock-up of a half in that colour
    final preview = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.9), width: 2),
            ),
          ),
        ),
      ],
    );

    final Widget content;
    if (_values) {
      content = SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            preview,
            const SizedBox(height: 8),
            _HexField(
              hex: _hex,
              label: l.colourHex,
              onChanged: (v) => setState(() {
                _setRgb((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF);
              }),
            ),
            _ChannelRow(label: l.colourRed, value: _r, max: 255, onChanged: (v) => setState(() => _setRgb(v, _g, _b))),
            _ChannelRow(label: l.colourGreen, value: _g, max: 255, onChanged: (v) => setState(() => _setRgb(_r, v, _b))),
            _ChannelRow(label: l.colourBlue, value: _b, max: 255, onChanged: (v) => setState(() => _setRgb(_r, _g, v))),
            const Divider(),
            _ChannelRow(
              label: l.colourHue,
              value: _h.round(),
              max: 360,
              onChanged: (v) => setState(() => _setHsl(v.toDouble(), _s, _l)),
            ),
            _ChannelRow(
              label: l.colourSaturation,
              value: (_s * 100).round(),
              max: 100,
              onChanged: (v) => setState(() => _setHsl(_h, v / 100, _l)),
            ),
            _ChannelRow(
              label: l.colourLightness,
              value: (_l * 100).round(),
              max: 100,
              onChanged: (v) => setState(() => _setHsl(_h, _s, v / 100)),
            ),
          ],
        ),
        ),
      );
    } else {
      // Not scrollable, so dragging in the square doesn't scroll the dialog
      final squareHeight = (MediaQuery.sizeOf(context).height * 0.28).clamp(90.0, 220.0);
      content = SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            preview,
            const SizedBox(height: 10),
            SizedBox(
              height: squareHeight,
              child: _SaturationValueSquare(
                hue: _hv,
                saturation: _sv,
                value: _vv,
                onChanged: (s, v) => setState(() => _setHsv(_hv, s, v)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 28,
              child: _HueBar(hue: _hv, onChanged: (h) => setState(() => _setHsv(h, _sv, _vv))),
            ),
          ],
        ),
      );
    }

    return AlertDialog(
      title: Text(l.customColour),
      // Wider than the default dialog
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: content,
      actions: [
        // Mode toggle on the left, Cancel/Select on the right, all on one line
        SizedBox(
          width: double.maxFinite,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: TextButton.icon(
                  onPressed: () => setState(() => _values = !_values),
                  icon: Icon(_values ? Icons.palette_outlined : Icons.tune),
                  label: Text(
                    _values ? l.colourModePicker : l.colourModeValues,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: () => Navigator.pop(context, color), child: Text(l.select)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Saturation left to right, brightness bottom to top
class _SaturationValueSquare extends StatelessWidget {
  const _SaturationValueSquare({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  final double hue;
  final double saturation;
  final double value;
  final void Function(double saturation, double value) onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          void pick(Offset p) => onChanged(
                (p.dx / size.width).clamp(0.0, 1.0),
                1 - (p.dy / size.height).clamp(0.0, 1.0),
              );
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => pick(d.localPosition),
            onPanStart: (d) => pick(d.localPosition),
            onPanUpdate: (d) => pick(d.localPosition),
            child: CustomPaint(
              size: size,
              painter: _SaturationValuePainter(hue: hue, saturation: saturation, value: value),
            ),
          );
        },
      );
}

class _SaturationValuePainter extends CustomPainter {
  _SaturationValuePainter({required this.hue, required this.saturation, required this.value});

  final double hue;
  final double saturation;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, HSVColor.fromAHSV(1, hue % 360, 1, 1).toColor()],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    canvas.restore();
    final c = Offset(saturation * size.width, (1 - value) * size.height);
    canvas.drawCircle(c, 10, Paint()..color = HSVColor.fromAHSV(1, hue % 360, saturation, value).toColor());
    canvas.drawCircle(
      c,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
    canvas.drawCircle(
      c,
      11.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black54,
    );
  }

  @override
  bool shouldRepaint(_SaturationValuePainter old) =>
      old.hue != hue || old.saturation != saturation || old.value != value;
}

class _HueBar extends StatelessWidget {
  const _HueBar({required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          void pick(Offset p) => onChanged((p.dx / size.width).clamp(0.0, 1.0) * 360);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => pick(d.localPosition),
            onPanStart: (d) => pick(d.localPosition),
            onPanUpdate: (d) => pick(d.localPosition),
            child: CustomPaint(size: size, painter: _HuePainter(hue: hue)),
          );
        },
      );
}

class _HuePainter extends CustomPainter {
  _HuePainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2)),
      Paint()
        ..shader = LinearGradient(
          colors: [for (var h = 0; h <= 360; h += 60) HSVColor.fromAHSV(1, (h % 360).toDouble(), 1, 1).toColor()],
        ).createShader(rect),
    );
    final x = (hue / 360).clamp(0.0, 1.0) * size.width;
    final thumb = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, size.height / 2), width: 8, height: size.height + 6),
      const Radius.circular(4),
    );
    canvas.drawRRect(thumb, Paint()..color = HSVColor.fromAHSV(1, hue % 360, 1, 1).toColor());
    canvas.drawRRect(
      thumb,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_HuePainter old) => old.hue != hue;
}

/// Label, slider and number field for one channel
class _ChannelRow extends StatefulWidget {
  const _ChannelRow({required this.label, required this.value, required this.max, required this.onChanged});

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_ChannelRow> createState() => _ChannelRowState();
}

class _ChannelRowState extends State<_ChannelRow> {
  late final TextEditingController _text = TextEditingController(text: '${widget.value}');
  final _focus = FocusNode();

  @override
  void didUpdateWidget(_ChannelRow old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && _text.text != '${widget.value}') _text.text = '${widget.value}';
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(width: 22, child: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(
            child: Slider(
              value: widget.value.clamp(0, widget.max).toDouble(),
              max: widget.max.toDouble(),
              onChanged: (v) => widget.onChanged(v.round()),
            ),
          ),
          SizedBox(
            width: 52,
            child: TextField(
              controller: _text,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              decoration: const InputDecoration(isDense: true),
              onChanged: (t) {
                final v = int.tryParse(t);
                if (v != null) widget.onChanged(v.clamp(0, widget.max));
              },
              onSubmitted: (_) => _text.text = '${widget.value}',
            ),
          ),
        ],
      );
}

/// RRGGBB, # optional. Applies once 6 valid digits are in
class _HexField extends StatefulWidget {
  const _HexField({required this.hex, required this.label, required this.onChanged});

  final String hex;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  State<_HexField> createState() => _HexFieldState();
}

class _HexFieldState extends State<_HexField> {
  late final TextEditingController _text = TextEditingController(text: widget.hex);
  final _focus = FocusNode();

  @override
  void didUpdateWidget(_HexField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && _text.text.toUpperCase() != widget.hex) _text.text = widget.hex;
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _text,
        focusNode: _focus,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(labelText: widget.label, prefixText: '#'),
        onChanged: (t) {
          final digits = t.replaceAll('#', '').trim();
          final v = digits.length == 6 ? int.tryParse(digits, radix: 16) : null;
          if (v != null) widget.onChanged(v);
        },
        onSubmitted: (_) => _text.text = widget.hex,
      );
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w700, color: Colors.white54),
        ),
      );
}

class _StepperTile extends StatelessWidget {
  const _StepperTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.remove), onPressed: () => onChanged(value - 1)),
            SizedBox(
              width: 28,
              child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            ),
            IconButton(icon: const Icon(Icons.add), onPressed: () => onChanged(value + 1)),
          ],
        ),
      );
}

/// Labels for the layout change list
String _settingLabel(AppLocalizations l, String key) => switch (key) {
      'onePlayer' => l.onePlayerMode,
      'trackedSide' => l.trackedSide,
      'showOpponent' => l.showOpponentCounters,
      'autoEndTurn' => l.autoEndTurn,
      'corpColor' => l.corpColour,
      'runnerColor' => l.runnerColour,
      'corpFaction' => l.corpFactionGlyph,
      'runnerFaction' => l.runnerFactionGlyph,
      'corpFont' => l.corpFont,
      'runnerFont' => l.runnerFont,
      'agendaMax' => l.agendaToWin,
      'creditIcon' => l.creditIconFrom,
      'creditIconThreshold' => '${l.creditIconFrom}: ${l.creditIconAt}',
      'creditAnimation' => l.creditAnimation,
      'counterButtons' => l.counterButtons,
      'counters' => l.changeCounters,
      'counterOrder' => l.changeCounterOrder,
      'counterMax' => l.changeCounterMax,
      _ => key,
    };

/// Asks first if loading would change anything, including reloading a layout you've since modified
Future<void> _loadLayout(BuildContext context, String name) async {
  final game = context.read<GameNotifier>();
  final l = AppLocalizations.of(context);
  final changes = game.layoutChanges(name);
  if (changes.isEmpty) {
    game.loadProfile(name);
    return;
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.loadLayoutTitle(layoutDisplayName(l, name))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.loadLayoutBody),
            const SizedBox(height: 8),
            for (final k in changes) Text('•  ${_settingLabel(l, k)}'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l.load)),
      ],
    ),
  );
  if (ok == true) game.loadProfile(name);
}

Future<void> _editLayoutDescription(BuildContext context, String name) {
  final game = context.read<GameNotifier>();
  final l = AppLocalizations.of(context);
  final controller = TextEditingController(text: game.profileDescription(name));
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.editDescriptionTitle(name)),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 1,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: l.layoutDescription),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            game.setProfileDescription(name, controller.text);
            Navigator.pop(dialogContext);
          },
          child: Text(l.save),
        ),
      ],
    ),
  );
}

/// Only deletes the saved layout; the current game is untouched
Future<void> _confirmDeleteLayout(BuildContext context, String name) async {
  final game = context.read<GameNotifier>();
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.deleteLayoutTitle(name)),
      content: Text(l.deleteLayoutBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l.delete)),
      ],
    ),
  );
  if (ok == true) game.deleteProfile(name);
}

Future<void> _confirmUpdateLayout(BuildContext context, String name) async {
  final game = context.read<GameNotifier>();
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.updateLayoutTitle(name)),
      content: Text(l.updateLayoutBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l.update)),
      ],
    ),
  );
  if (ok == true) game.saveProfile(name);
}

/// Saving under an existing name replaces it. Typing an existing name pulls in its description
Future<void> _showSaveLayoutDialog(BuildContext context) {
  final game = context.read<GameNotifier>();
  final l = AppLocalizations.of(context);
  final controller = TextEditingController();
  final descriptionController = TextEditingController();
  var descriptionEdited = false;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final name = controller.text.trim();
        final valid = name.isNotEmpty && !GameNotifier.isBuiltIn(name);
        final exists = game.profileNames.contains(name) && !GameNotifier.isBuiltIn(name);
        return AlertDialog(
          title: Text(l.saveLayoutTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.saveLayoutBody),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l.layoutName,
                  errorText: GameNotifier.isBuiltIn(name) ? l.layoutNameIsBuiltIn : null,
                  helperText: exists ? l.layoutReplacesExisting : null,
                ),
                onChanged: (text) => setState(() {
                  if (!descriptionEdited) descriptionController.text = game.profileDescription(text.trim());
                }),
              ),
              TextField(
                controller: descriptionController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l.layoutDescription),
                onChanged: (_) => descriptionEdited = true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l.cancel)),
            FilledButton(
              onPressed: valid
                  ? () {
                      game.saveProfile(name, description: descriptionController.text);
                      Navigator.pop(dialogContext);
                    }
                  : null,
              child: Text(exists ? l.replace : l.save),
            ),
          ],
        );
      },
    ),
  );
}

/// Pick a side, then one or more types. Changing side clears the selection. Naming only works with one
/// type selected. Unique and side-restricted types are filtered by GameNotifier.canAdd
Future<void> showAddCounterDialog(BuildContext context) {
  final game = context.read<GameNotifier>();
  final l = AppLocalizations.of(context);
  var side = game.onePlayer ? game.trackedSide : Side.corp;
  final selected = <CounterType>{};
  final nameController = TextEditingController();

  String? unavailableReason(CounterType t) {
    if (t.runnerOnly && side == Side.corp) return l.runnerOnly;
    if (t.corpOnly && side == Side.runner) return l.corpOnly;
    if (!game.canAdd(t, side)) return l.alreadyAdded;
    return null;
  }

  Widget tile(CounterType t, StateSetter setState) {
    final reason = unavailableReason(t);
    final hint = counterTypeHint(l, t);
    final on = selected.contains(t);
    return ListTile(
      dense: true,
      enabled: reason == null,
      selected: on,
      leading: CounterIcon(t, color: NrColors.counter(t), size: 26),
      title: Text(counterTypeLabel(l, t)),
      subtitle: reason != null ? Text(reason) : (hint == null ? null : Text(hint)),
      trailing: Icon(on ? Icons.check_box : Icons.check_box_outline_blank),
      onTap: () => setState(() => on ? selected.remove(t) : selected.add(t)),
    );
  }

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final canName = selected.length == 1;
        return AlertDialog(
          title: Text(l.addCountersTitle),
          contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: SegmentedButton<Side>(
                      segments: [
                        ButtonSegment(value: Side.corp, label: Text(l.sideCorp)),
                        ButtonSegment(value: Side.runner, label: Text(l.sideRunner)),
                      ],
                      selected: {side},
                      onSelectionChanged: (s) => setState(() {
                        side = s.first;
                        selected.clear();
                      }),
                    ),
                  ),
                  // Counters the app acts on, a divider, then the ones that just count
                  for (final t in CounterType.values.where((t) => t.functional)) tile(t, setState),
                  const Divider(),
                  for (final t in CounterType.values.where((t) => !t.functional)) tile(t, setState),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: TextField(
                      controller: nameController,
                      enabled: canName,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l.nameOptional,
                        helperText: canName ? null : l.nameNeedsSingle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l.cancel)),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () {
                      for (final t in CounterType.values.where(selected.contains)) {
                        game.addExtra(t, side, canName ? nameController.text : '');
                      }
                      Navigator.pop(dialogContext);
                    },
              child: Text(selected.length > 1 ? l.addCount(selected.length) : l.add),
            ),
          ],
        );
      },
    ),
  );
}
