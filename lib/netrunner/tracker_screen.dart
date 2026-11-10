import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import 'fonts.dart';
import 'game.dart';
import 'settings_screen.dart';
import 'widgets.dart';

/// Main screen. Two-player: phone flat between the players, Corp half on top rotated 180 to face the far side
/// One-player: just the tracked side, optionally with a strip of the opponent's counters on top
class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loaded = context.select<GameNotifier, bool>((g) => g.loaded);
    final mode = context.select<GameNotifier, (bool, Side, bool)>((g) => (g.onePlayer, g.trackedSide, g.showOpponent));
    final onePlayer = mode.$1;
    final tracked = mode.$2;
    final showOpponent = mode.$3;
    final Widget body;
    if (!loaded) {
      body = const SizedBox.shrink();
    } else if (onePlayer) {
      body = Column(
        children: [
          if (showOpponent) OpponentStrip(side: opponentOf(tracked)),
          Expanded(child: SideHalf(side: tracked)),
          const DragDim(child: TurnBar()),
        ],
      );
    } else {
      body = const Column(
        children: [
          Expanded(
            child: RotatedBox(quarterTurns: 2, child: SideHalf(side: Side.corp)),
          ),
          DragDim(child: TurnBar()),
          Expanded(child: SideHalf(side: Side.runner)),
        ],
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: body),
    );
  }
}

/// Side name as a tab sitting in the half's left border. Half black, half the fill colour, so the border
/// looks like it's broken around it
class SideTab extends StatelessWidget {
  const SideTab({super.key, required this.text, required this.color, required this.fill});

  final String text;
  final Color color;

  /// The half's fill colour, for the inner half of the tab
  final Color fill;

  static const textHeight = 13.0;

  /// How far it sticks out past the border
  static const overhang = textHeight / 2;

  /// How far it reaches into the half. Content starts after this
  static const inset = overhang - 1;

  /// Centred on the 2dp left border. Scales down if it'd get closer than [bottom] to the bottom edge
  static Widget positioned({
    required double borderLeft,
    required double top,
    required double bottom,
    required Widget tab,
  }) =>
      Positioned(
        left: borderLeft + 1 - textHeight / 2,
        top: top,
        bottom: bottom,
        child: IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              // Text reads bottom to top, black half ends up outside
              child: RotatedBox(quarterTurns: 3, child: tab),
            ),
          ),
        ),
      );

  /// [accent] at [alpha] over black, as an opaque colour
  static Color fillOf(Color accent, double alpha) => Color.alphaBlend(accent.withValues(alpha: alpha), Colors.black);

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ExtraCounter?>(
        valueListenable: draggingCounter,
        builder: (context, dragged, child) => AnimatedOpacity(
          opacity: dragged != null ? 0.35 : 1,
          duration: const Duration(milliseconds: 150),
          child: child,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.black, fill, fill],
              stops: const [0, 0.5, 0.5, 1],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: textHeight,
                height: 1.0,
                fontWeight: boldWeight(context),
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      );
}

String? sideFontOrNull(GameNotifier game, Side side) => resolveSideFont(game.font(side));

/// Puts [child] in the side's font. Bold text inside should use boldWeight(context)
Widget withSideFont(GameNotifier game, Side side, Widget child) {
  final family = sideFontOrNull(game, side);
  if (family == null) return child;
  return SideFontScope(
    bold: noBoldFonts.contains(family) ? FontWeight.w400 : FontWeight.w700,
    child: DefaultTextStyle.merge(style: TextStyle(fontFamily: family), child: child),
  );
}

/// Rows reserved for counters: about 35% of the height, 1-6 rows
int counterBandRows(double height, {required bool buttons}) {
  final row = (buttons ? CounterChip.buttonChipHeight : CounterChip.tileHeight) + CounterArea.spacing;
  return ((height * 0.35 + CounterArea.spacing) / row).floor().clamp(1, 6);
}

/// One side: counter band at the top, credits in the middle with the faction glyph behind, clicks at the
/// bottom. The band scrolls when it's full
class SideHalf extends StatefulWidget {
  const SideHalf({super.key, required this.side});

  final Side side;

  @override
  State<SideHalf> createState() => _SideHalfState();
}

class _SideHalfState extends State<SideHalf> {
  /// Actual band height, reported by CounterArea
  double? _band;

  @override
  Widget build(BuildContext context) {
    final side = widget.side;
    final game = context.watch<GameNotifier>();
    final l = AppLocalizations.of(context);
    final accent = Color(game.colorValue(side));
    final isActive = game.active == side;
    final factionKey = game.faction(side);
    final showLoss = game.loserToShow == side;
    final runOnThisSide = side == Side.runner && game.runActive;
    final tint = isActive ? 0.20 : 0.08;
    const borderLeft = 6 + SideTab.overhang;
    return withSideFont(
      game,
      side,
      Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(borderLeft, 6, 6, 4),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: tint),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: isActive ? 0.9 : 0.3), width: 2),
          ),
          child: LayoutBuilder(
            builder: (context, outer) {
              final rows = counterBandRows(outer.maxHeight, buttons: game.counterButtons);
              final bandMax = CounterArea.bandHeight(rows, buttons: game.counterButtons);
              final band = min(_band ?? CounterArea.bandHeight(1, buttons: game.counterButtons), bandMax);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, area) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                // Credits and glyph are centred between the counter rows and the clicks
                                Positioned(
                                  top: band,
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    clipBehavior: Clip.none,
                                    children: [
                                      if (factionKey.isNotEmpty)
                                        IgnorePointer(
                                          child: Padding(
                                            padding: EdgeInsets.zero,
                                            child: OverflowBox(
                                              maxWidth: double.infinity,
                                              maxHeight: double.infinity,
                                              // 62% of the smaller side, but kept clear of the -/+ hints
                                              child: SizedBox.square(
                                                dimension: min(
                                                  min(outer.maxWidth, outer.maxHeight) * 0.62,
                                                  outer.maxWidth - 2 * (CreditsHero.hintClearance(outer.maxWidth) + 8),
                                                ),
                                                child: Opacity(
                                                  opacity: 0.14,
                                                  child: ColorFiltered(
                                                    colorFilter: greyscale,
                                                    child: Image.asset(
                                                      'assets/nsg/glyphs/NSG_$factionKey.webp',
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      CreditsHero(side: side),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: CounterArea(
                                    side: side,
                                    maxHeight: bandMax,
                                    onHeight: (h) {
                                      if (mounted && h != _band) setState(() => _band = h);
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      ClicksRow(side: side),
                      const SizedBox(height: 6),
                    ],
                  ),
                  // Dragging one of our counters: dim everything below the band
                  Positioned(top: band, left: 0, right: 0, bottom: 0, child: DragScrim(when: (d) => d.side == side)),
                  // Dragging the other side's counter: dim this whole half
                  DragScrim(when: (d) => d.side != side),
                  // Bin over the clicks while dragging. Two-player: on the dragged counter's half. One-player: tracked side
                  ValueListenableBuilder<ExtraCounter?>(
                    valueListenable: draggingCounter,
                    builder: (context, dragged, _) {
                      final show =
                          dragged != null && (game.onePlayer ? side == game.trackedSide : dragged.side == side);
                      return show
                          ? const Align(alignment: Alignment.bottomCenter, child: TrashTarget())
                          : const SizedBox.shrink();
                    },
                  ),
                  if (showLoss) LossOverlay(side: side),
                ],
              );
            },
          ),
        ),
        SideTab.positioned(
          borderLeft: borderLeft,
          top: 6 + 16, // clear of the rounded corner
          bottom: 4 + 16,
          tab: SideTab(
            text: sideNameUpper(l, side) + (runOnThisSide ? l.runSuffix : ''),
            color: runOnThisSide ? NrColors.runFund : accent,
            fill: SideTab.fillOf(accent, tint),
          ),
        ),
      ],
      ),
    );
  }
}

/// Counter currently being dragged, if any
final draggingCounter = ValueNotifier<ExtraCounter?>(null);

/// Everything in a side's counter band: Run button, the run-credits chip on the Corp-only screen, then the
/// counters
/// [tileWidth] is one column, [wideWidth] two. Null sizes to content
List<Widget> counterItems(
  BuildContext context,
  GameNotifier game,
  Side side, {
  double? tileWidth,
  double? wideWidth,
}) {
  final l = AppLocalizations.of(context);
  final buttons = game.counterButtons;
  final items = <Widget>[];
  final chipWidth = buttons ? wideWidth : tileWidth;

  // Run button shows once the Corp has bad publicity, and stays while a run is on
  final runButtonSide = game.onePlayer ? game.trackedSide : Side.runner;
  if (side == runButtonSide && (game.badPublicity >= 1 || game.runActive)) {
    items.add(RunButton(
      width: wideWidth,
      height: buttons ? CounterChip.buttonChipHeight : CounterChip.tileHeight,
      fontFamily: sideFontOrNull(game, side),
    ));
  }

  // Corp-only screen: show the Runner's run credits
  if (game.onePlayer && game.trackedSide == Side.corp && side == Side.corp && game.runActive) {
    items.add(CounterChip(
      icon: 'NSG_CREDIT',
      label: l.runnerRunCredits,
      color: NrColors.runFund,
      display: '+${game.runFund}',
      lit: true,
      name: l.runnerRunCredits,
      buttons: buttons,
      tileWidth: chipWidth,
      onDelta: (d) {
        if (d < 0) game.spendRunFund();
      },
    ));
  }

  // X/Y counters: long-press -/+ in button mode, hold-and-release in swipe mode, to change the max
  for (final c in game.extrasFor(side)) {
    items.add(DraggableCounter(
      key: ValueKey('counter-${c.id}'),
      counter: c,
      onHoldRelease: (!buttons && c.type.hasMax) ? (d) => game.addExtraMax(c.id, d) : null,
      child: CounterChip(
        icon: c.type.icon,
        label: counterTitle(l, c),
        color: NrColors.counter(c.type),
        display: c.type.hasMax ? '${c.value}/${c.max}' : '${c.value}',
        name: c.name,
        // Hand size: blue above 5, red below
        lit: c.type == CounterType.handSize ? c.value != defaultHandSize : c.type.litWhenPositive && c.value > 0,
        litColor: c.type == CounterType.handSize
            ? (c.value > defaultHandSize ? const Color(GameNotifier.defaultCorpColor) : NrColors.coreDamage)
            : null,
        warn: c.type == CounterType.mu && c.value > c.max,
        buttons: buttons,
        tileWidth: chipWidth,
        tapDelta: c.type.tapDelta,
        materialIcon: materialIconFor(c.type),
        onDelta: (d) => game.addExtraValue(c.id, d),
        onLongDelta: c.type.hasMax ? (d) => game.addExtraMax(c.id, d) : null,
      ),
    ));
  }
  return items;
}

/// Counter band. Equal columns as many as fit; chips are one column in swipe mode and two with buttons
/// Extra rows scroll a row at a time, with a small arrow and scroll bar on the left when that happens
class CounterArea extends StatefulWidget {
  const CounterArea({super.key, required this.side, required this.maxHeight, this.emptyText, this.onHeight});

  final Side side;

  final double maxHeight;

  /// So the credits can re-centre
  final ValueChanged<double>? onHeight;

  /// Opponent strip only
  final String? emptyText;

  static const spacing = 6.0;

  /// Outside the scroll view so a snapped row sits flush with no peeking
  static const padTop = 6.0;
  static const padBottom = 6.0;

  /// Clears the side tab
  static const padLeft = SideTab.inset + 6;
  static const minTileWidth = 72.0;
  static const gutterWidth = SideTab.inset + 6 + 20 + 2; // tab clearance + arrow + gap

  static double bandHeight(int rows, {required bool buttons}) {
    final row = buttons ? CounterChip.buttonChipHeight : CounterChip.tileHeight;
    return padTop + rows * row + (rows - 1) * spacing + padBottom;
  }

  @override
  State<CounterArea> createState() => _CounterAreaState();
}

class _CounterAreaState extends State<CounterArea> {
  final _scroll = ScrollController();
  final _wrapKey = GlobalKey();

  /// Top of each row, for snapping. Mutated in place on purpose: the physics object holds the same list,
  /// and Scrollable keeps the old physics instance around
  final List<double> _rowTops = [];
  bool _gutter = false;

  /// null until first layout
  double? _content;
  double? _reportedHeight;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() => setState(() {});

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Work out the rows from where the Wrap put its children, and whether they overflow
  void _measure() {
    if (!mounted) return;
    final wrap = _wrapKey.currentContext?.findRenderObject();
    if (wrap is! RenderBox || !wrap.hasSize) return;
    final spans = <(double, double)>[];
    wrap.visitChildren((child) {
      if (child is RenderBox && child.hasSize) {
        final top = (child.parentData! as BoxParentData).offset.dy;
        spans.add((top, top + child.size.height));
      }
    });
    spans.sort((a, b) => a.$1.compareTo(b.$1));
    final tops = <double>[];
    final bottoms = <double>[];
    for (final (top, bottom) in spans) {
      if (tops.isEmpty || top >= bottoms.last - 0.5) {
        tops.add(top);
        bottoms.add(bottom);
      } else if (bottom > bottoms.last) {
        bottoms[bottoms.length - 1] = bottom;
      }
    }
    // Showing the gutter can only add rows, never remove them, so this can't flip-flop
    final content = bottoms.isEmpty ? 0.0 : bottoms.last;
    final gutter = content > _maxViewport + 0.5;
    if (gutter != _gutter || content != _content || !listEquals(tops, _rowTops)) {
      setState(() {
        _gutter = gutter;
        _content = content;
        _rowTops
          ..clear()
          ..addAll(tops);
      });
    }
  }

  double get _maxViewport => widget.maxHeight - CounterArea.padTop - CounterArea.padBottom;

  /// One row's height until we've measured
  double _viewport(bool buttons) =>
      min(_content ?? (buttons ? CounterChip.buttonChipHeight : CounterChip.tileHeight), _maxViewport);

  IconData _arrow() {
    if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) return Icons.keyboard_arrow_down;
    final p = _scroll.position;
    if (p.pixels <= p.minScrollExtent + 1) return Icons.keyboard_arrow_down;
    if (p.pixels >= p.maxScrollExtent - 1) return Icons.keyboard_arrow_up;
    return Icons.unfold_more;
  }

  /// Fade the non-counter items while one of our counters is being dragged
  Widget _dimWhileDragging(Widget child) => ValueListenableBuilder<ExtraCounter?>(
        valueListenable: draggingCounter,
        builder: (context, dragged, child) => AnimatedOpacity(
          opacity: dragged != null && dragged.side == widget.side ? 0.35 : 1,
          duration: const Duration(milliseconds: 150),
          child: child,
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameNotifier>();
    final accent = Color(game.colorValue(widget.side));
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

    var thumbFraction = 1.0, thumbPosition = 0.0;
    if (_scroll.hasClients && _scroll.position.hasContentDimensions) {
      final p = _scroll.position;
      final total = p.maxScrollExtent + p.viewportDimension;
      if (total > 0) thumbFraction = p.viewportDimension / total;
      if (p.maxScrollExtent > 0) thumbPosition = (p.pixels / p.maxScrollExtent).clamp(0.0, 1.0);
    }

    final padLeft = _gutter ? 0.0 : CounterArea.padLeft;
    const padRight = 8.0;
    final viewport = _viewport(game.counterButtons);
    final height = CounterArea.padTop + viewport + CounterArea.padBottom;
    if (height != _reportedHeight && widget.onHeight != null) {
      _reportedHeight = height;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onHeight!(height);
      });
    }
    return Container(
      height: height,
      padding: const EdgeInsets.only(top: CounterArea.padTop, bottom: CounterArea.padBottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_gutter)
            // Arrow level with the first row, scroll bar underneath
            SizedBox(
              width: CounterArea.gutterWidth,
              height: viewport,
              child: Padding(
                padding: EdgeInsets.only(
                  left: SideTab.inset + 6,
                  top: ((game.counterButtons ? CounterChip.buttonChipHeight : CounterChip.tileHeight) - 20) / 2,
                  right: 2,
                ),
                child: Column(
                  children: [
                    Icon(_arrow(), size: 20, color: accent),
                    const SizedBox(height: 2),
                    Expanded(
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _ScrollBarPainter(
                            fraction: thumbFraction,
                            position: thumbPosition,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Wide items take two columns, or the whole row if only one fits. That's Run, and every chip in button mode
                final available = constraints.maxWidth - padLeft - padRight;
                final columns = max(
                  1,
                  ((available + CounterArea.spacing) / (CounterArea.minTileWidth + CounterArea.spacing)).floor(),
                );
                // Shave a bit off so rounding never wraps the last column
                final tileWidth = ((available - (columns - 1) * CounterArea.spacing) / columns).floorToDouble() - 0.5;
                final wideWidth = columns >= 2 ? tileWidth * 2 + CounterArea.spacing : tileWidth;
                final items = counterItems(context, game, widget.side, tileWidth: tileWidth, wideWidth: wideWidth);
                if (items.isEmpty && widget.emptyText != null) {
                  items.add(Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(widget.emptyText!, style: const TextStyle(color: Colors.white38, fontSize: 14)),
                  ));
                }
                return SingleChildScrollView(
                  controller: _scroll,
                  physics: _RowSnapPhysics(stops: _rowTops, parent: const ClampingScrollPhysics()),
                  padding: EdgeInsets.only(left: padLeft, right: padRight),
                  child: Wrap(
                    key: _wrapKey,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: CounterArea.spacing,
                    runSpacing: CounterArea.spacing,
                    children: [
                      for (final item in items) item is DraggableCounter ? item : _dimWhileDragging(item),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual-only scroll bar in the side's colour
class _ScrollBarPainter extends CustomPainter {
  _ScrollBarPainter({required this.fraction, required this.position, required this.color});

  /// Visible fraction and position, both 0..1
  final double fraction;
  final double position;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const width = 3.0;
    final x = size.width / 2;
    final track = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, width / 2), Offset(x, size.height - width / 2), track);
    final length = max(12.0, size.height * fraction.clamp(0.0, 1.0));
    final top = (size.height - length) * position;
    final thumb = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, top + width / 2), Offset(x, top + length - width / 2), thumb);
  }

  @override
  bool shouldRepaint(_ScrollBarPainter old) =>
      old.fraction != fraction || old.position != position || old.color != color;
}

/// Snaps to the top of a row
class _RowSnapPhysics extends ScrollPhysics {
  const _RowSnapPhysics({required this.stops, super.parent});

  final List<double> stops;

  @override
  _RowSnapPhysics applyTo(ScrollPhysics? ancestor) => _RowSnapPhysics(stops: stops, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (stops.isEmpty || position.outOfRange || !position.hasContentDimensions) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final pixels = position.pixels;
    final targets = <double>{
      for (final s in stops) s.clamp(position.minScrollExtent, position.maxScrollExtent).toDouble(),
      position.maxScrollExtent,
    }.toList()
      ..sort();
    final double target;
    if (velocity.abs() > tolerance.velocity) {
      // Flings move one row
      target = velocity > 0
          ? targets.firstWhere((t) => t > pixels + tolerance.distance, orElse: () => targets.last)
          : targets.lastWhere((t) => t < pixels - tolerance.distance, orElse: () => targets.first);
    } else {
      target = targets.reduce((a, b) => (a - pixels).abs() <= (b - pixels).abs() ? a : b);
    }
    if ((target - pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(spring, pixels, target, velocity, tolerance: tolerance);
  }

  @override
  bool get allowImplicitScrolling => false;
}

/// Long-press and drag a counter onto another of the same side to move it, or onto the bin to delete it
/// [onHoldRelease]: long-press and let go without moving. Changes the max on swipe-mode X/Y counters
class DraggableCounter extends StatefulWidget {
  const DraggableCounter({super.key, required this.counter, required this.child, this.onHoldRelease});

  final ExtraCounter counter;
  final Widget child;
  final ValueChanged<int>? onHoldRelease;

  @override
  State<DraggableCounter> createState() => _DraggableCounterState();
}

class _DraggableCounterState extends State<DraggableCounter> {
  Offset? _down;
  double _moved = 0;
  double _downX = 0;
  bool? _insertAfter; // set while something hovers over us

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameNotifier>();
    final c = widget.counter;
    // Corp half is upside down, so flip the drag copy too
    final rotated = !game.onePlayer && c.side == Side.corp;

    final draggable = Listener(
      onPointerDown: (e) {
        _down = e.position;
        _moved = 0;
        _downX = e.localPosition.dx;
      },
      onPointerMove: (e) {
        if (_down != null) _moved = max(_moved, (e.position - _down!).distance);
      },
      child: LongPressDraggable<int>(
        data: c.id,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        // Drawn in the overlay, outside the half, so it needs the font set again
        feedback: withSideFont(
          game,
          c.side,
          Material(
          type: MaterialType.transparency,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: RotatedBox(
              quarterTurns: rotated ? 2 : 0,
              child: Opacity(opacity: 0.9, child: widget.child),
            ),
          ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: widget.child),
        onDragStarted: () => draggingCounter.value = c,
        onDragEnd: (details) {
          draggingCounter.value = null;
          if (!details.wasAccepted && _moved < 12 && widget.onHoldRelease != null) {
            HapticFeedback.mediumImpact();
            final width = context.size?.width ?? 0;
            widget.onHoldRelease!(_downX < width / 2 ? -1 : 1);
          }
        },
        child: widget.child,
      ),
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != c.id && game.extras.any((x) => x.id == d.data && x.side == c.side),
      onMove: (d) {
        final box = context.findRenderObject();
        if (box is! RenderBox) return;
        // Local coords follow the half's rotation
        final after = box.globalToLocal(d.offset).dx > box.size.width / 2;
        if (after != _insertAfter) setState(() => _insertAfter = after);
      },
      onLeave: (_) => setState(() => _insertAfter = null),
      onAcceptWithDetails: (d) {
        HapticFeedback.mediumImpact();
        game.moveExtra(d.data, c.id, after: _insertAfter ?? false);
        setState(() => _insertAfter = null);
      },
      builder: (context, candidates, rejected) => Stack(
        clipBehavior: Clip.none,
        children: [
          draggable,
          if (candidates.isNotEmpty && _insertAfter != null)
            Positioned(
              top: 4,
              bottom: 4,
              left: _insertAfter! ? null : -5,
              right: _insertAfter! ? -5 : null,
              child: Container(
                width: 3,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bin over the clicks while dragging. Fills red when something's over it
class TrashTarget extends StatelessWidget {
  const TrashTarget({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: DragTarget<int>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (d) {
            HapticFeedback.heavyImpact();
            draggingCounter.value = null;
            context.read<GameNotifier>().removeExtra(d.data);
          },
          builder: (context, candidates, rejected) {
            final hover = candidates.isNotEmpty;
            return Semantics(
              label: AppLocalizations.of(context).dropToRemove,
              child: AnimatedScale(
                scale: hover ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 120),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hover ? NrColors.coreDamage : Colors.black.withValues(alpha: 0.6),
                    border: Border.all(color: NrColors.coreDamage, width: 3),
                  ),
                  child: Icon(hover ? Icons.delete : Icons.delete_outline, size: 34, color: Colors.white),
                ),
              ),
            );
          },
        ),
      );
}

bool _always(ExtraCounter _) => true;

/// Dark overlay while dragging, when [when] matches the dragged counter. Ignores touches
class DragScrim extends StatelessWidget {
  const DragScrim({super.key, this.when = _always});

  final bool Function(ExtraCounter dragged) when;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ExtraCounter?>(
        valueListenable: draggingCounter,
        builder: (context, dragged, _) => IgnorePointer(
          child: AnimatedOpacity(
            opacity: dragged != null && when(dragged) ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: const ColoredBox(color: Color(0xA6000000)), // 65% black
          ),
        ),
      );
}

class DragDim extends StatelessWidget {
  const DragDim({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          const Positioned.fill(child: DragScrim()),
        ],
      );
}

/// One-player: a strip of the opponent's counters above ours, e.g. to keep an eye on their agenda
class OpponentStrip extends StatelessWidget {
  const OpponentStrip({super.key, required this.side});

  final Side side;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameNotifier>();
    final l = AppLocalizations.of(context);
    final accent = Color(game.colorValue(side));
    final isActive = game.active == side;
    final band = CounterArea.bandHeight(1, buttons: game.counterButtons);
    final tint = isActive ? 0.20 : 0.08;
    const borderLeft = 6 + SideTab.overhang;
    return withSideFont(
      game,
      side,
      Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(borderLeft, 6, 6, 0),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: tint),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: isActive ? 0.9 : 0.3), width: 2),
          ),
          child: Stack(
            children: [
              CounterArea(side: side, maxHeight: band, emptyText: l.noCounters),
              // Can't drop our counters here
              Positioned.fill(child: DragScrim(when: (d) => d.side != side)),
            ],
          ),
        ),
        SideTab.positioned(
          borderLeft: borderLeft,
          top: 6 + 8, // short strip, the tab scales down if needed
          bottom: 8,
          tab: SideTab(text: sideNameUpper(l, side), color: accent, fill: SideTab.fillOf(accent, tint)),
        ),
      ],
      ),
    );
  }
}

/// Run / End Run. See GameNotifier.startRun and endRun
class RunButton extends StatelessWidget {
  const RunButton({super.key, this.width, this.height = CounterChip.buttonChipHeight, this.fontFamily});

  /// Buttons ignore DefaultTextStyle, so the side font is passed in
  final String? fontFamily;

  /// Two columns wide in the band
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameNotifier>();
    final active = game.runActive;
    final l = AppLocalizations.of(context);
    final preview = max(0, min(game.badPublicity, game.credits(Side.corp)));
    return SizedBox(
      width: width,
      height: height,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: active ? Colors.black.withValues(alpha: 0.3) : NrColors.run,
          foregroundColor: active ? NrColors.run : Colors.white,
          side: active ? const BorderSide(color: NrColors.run, width: 2) : null,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: Size(0, height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          if (active) {
            game.endRun();
          } else {
            game.startRun();
          }
        },
        icon: Icon(active ? Icons.stop_circle_outlined : Icons.directions_run, size: 22),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            active ? l.endRun : (preview > 0 ? l.runButtonWithCredits(preview) : l.runButton),
            style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: boldWeight(context), letterSpacing: 1),
          ),
        ),
      ),
    );
  }
}

/// Main credit display. Tap left/right for -/+1, hold for repeated 5s. Swipe: one finger = 1, two = 5,
/// applied when the last finger lifts. Shows a running total badge and optional floating +/- numbers
class CreditsHero extends StatefulWidget {
  const CreditsHero({super.key, required this.side, this.bottomInset = 0});

  final Side side;

  /// Space kept free at the bottom; the number centres in what's left
  final double bottomInset;

  static const hintSize = 28.0;
  static const hintAlign = 0.85;

  /// Gap between the side of the area and the inner edge of a -/+ hint
  static double hintClearance(double width) => (width / 2 - hintSize) / 2 * (1 - hintAlign) + hintSize;

  @override
  State<CreditsHero> createState() => _CreditsHeroState();
}

class _Floater {
  _Floater(this.id, this.amount);
  final int id;
  final int amount;
}

class _CreditsHeroState extends State<CreditsHero> {
  int _delta = 0;
  Timer? _deltaTimer;
  Timer? _repeat;
  final List<_Floater> _floaters = [];
  int _nextFloater = 0;

  // Swipe totals live here because the scale recognizer restarts every time a finger goes down or up
  int _pointers = 0;
  int _swipeFingers = 0;
  double _swipeDx = 0, _swipeDy = 0;
  Offset? _swipeLast;
  int _swipeLastCount = 0;

  void _pointerDown(PointerDownEvent _) {
    if (_pointers == 0) {
      _swipeDx = 0;
      _swipeDy = 0;
      _swipeFingers = 0;
    }
    _pointers++;
    _swipeFingers = max(_swipeFingers, _pointers);
  }

  void _pointerGone(PointerEvent _) {
    _pointers = max(0, _pointers - 1);
    if (_pointers > 0) return;
    // Mostly horizontal, at least 24dp
    if (_swipeDx.abs() >= 24 && _swipeDx.abs() > _swipeDy.abs() * 1.2) {
      _change((_swipeDx > 0 ? 1 : -1) * (_swipeFingers >= 2 ? 5 : 1));
    }
    _swipeDx = 0;
    _swipeDy = 0;
  }

  void _scaleStart(ScaleStartDetails d) {
    _swipeLast = d.localFocalPoint;
    _swipeLastCount = d.pointerCount;
  }

  void _scaleUpdate(ScaleUpdateDetails d) {
    // The focal point jumps when finger count changes, so skip those updates
    if (d.pointerCount == _swipeLastCount && _swipeLast != null) {
      final delta = d.localFocalPoint - _swipeLast!;
      _swipeDx += delta.dx;
      _swipeDy += delta.dy;
    }
    _swipeLast = d.localFocalPoint;
    _swipeLastCount = d.pointerCount;
  }

  int _total(GameNotifier game) =>
      game.credits(widget.side) + (widget.side == Side.runner ? (game.runFund ?? 0) : 0);

  void _change(int amount) {
    final game = context.read<GameNotifier>();
    final before = _total(game);
    game.addCredits(widget.side, amount);
    final applied = _total(game) - before;
    if (applied == 0) return;
    tick();
    _deltaTimer?.cancel();
    _deltaTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _delta = 0);
    });
    setState(() {
      _delta += applied;
      if (game.creditAnimation) _floaters.add(_Floater(_nextFloater++, applied));
    });
  }

  void _startRepeat(int sign) {
    _change(sign * 5);
    _repeat?.cancel();
    // Same as the long-press delay
    _repeat = Timer.periodic(const Duration(milliseconds: 500), (_) => _change(sign * 5));
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  void dispose() {
    _deltaTimer?.cancel();
    _repeat?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameNotifier>();
    final credits = game.credits(widget.side);
    final fund = widget.side == Side.runner ? game.runFund : null;
    final icon = game.creditIcon && credits >= game.creditIconThreshold ? 'NSG_5_CREDITS' : 'NSG_CREDIT';
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = min(widget.bottomInset, constraints.maxHeight * 0.5);
        final size = min((constraints.maxHeight - inset) * 0.62, constraints.maxWidth * 0.36).clamp(36.0, 220.0);
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // Swipes anywhere, taps/holds on each half
            Listener(
              onPointerDown: _pointerDown,
              onPointerUp: _pointerGone,
              onPointerCancel: _pointerGone,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _scaleStart,
                onScaleUpdate: _scaleUpdate,
                child: Row(
                  children: [
                    Expanded(child: _tapZone(-1, Icons.remove, const Alignment(-CreditsHero.hintAlign, 0), inset)),
                    Expanded(child: _tapZone(1, Icons.add, const Alignment(CreditsHero.hintAlign, 0), inset)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: inset),
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  IgnorePointer(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            NsgIcon(icon, color: Colors.white70, size: size * 0.5),
                            SizedBox(width: size * 0.08),
                            MonoDigits(
                              '$credits',
                              style: TextStyle(fontSize: size, height: 1.0, fontWeight: boldWeight(context), color: Colors.white),
                            ),
                            if (fund != null) ...[
                              SizedBox(width: size * 0.08),
                              Text(
                                '+$fund',
                                style: TextStyle(
                                  fontSize: size * 0.5,
                                  height: 1.0,
                                  fontWeight: boldWeight(context),
                                  color: NrColors.runFund,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  for (final f in _floaters)
                    IgnorePointer(
                      key: ValueKey('floater-${f.id}'),
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOut,
                          onEnd: () {
                            if (mounted) setState(() => _floaters.removeWhere((x) => x.id == f.id));
                          },
                          // Gains float up green, losses drift down red
                          builder: (context, t, child) => Transform.translate(
                            offset: f.amount > 0
                                ? Offset(size * 0.35, -size * 0.3 - t * size * 0.7)
                                : Offset(size * 0.35, size * 0.3 + t * size * 0.7),
                            child: Opacity(opacity: 1 - t, child: child),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              NsgIcon(
                                f.amount.abs() >= 5 ? 'NSG_5_CREDITS' : 'NSG_CREDIT', // held = 5
                                color: f.amount > 0 ? Colors.greenAccent : Colors.redAccent,
                                size: max(14.0, size * 0.22),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                f.amount > 0 ? '+${f.amount}' : '${f.amount}',
                                style: TextStyle(
                                  fontSize: max(14.0, size * 0.26),
                                  fontWeight: boldWeight(context),
                                  color: f.amount > 0 ? Colors.greenAccent : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_delta != 0)
                    IgnorePointer(
                      child: Align(
                        alignment: const Alignment(0, 1),
                        child: Text(
                          _delta > 0 ? '+$_delta' : '$_delta',
                          style: TextStyle(
                            fontSize: max(16.0, size * 0.22),
                            fontWeight: boldWeight(context),
                            color: _delta > 0 ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Left/right tap zone with its faint -/+ hint
  Widget _tapZone(int sign, IconData icon, Alignment hintAlignment, double inset) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _change(sign),
        onLongPressStart: (_) => _startRepeat(sign),
        onLongPressEnd: (_) => _stopRepeat(),
        onLongPressCancel: _stopRepeat,
        child: Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: Align(
            alignment: hintAlignment,
            child: Icon(icon, color: Colors.white24, size: CreditsHero.hintSize),
          ),
        ),
      );
}

/// Click pips. Tap an available one to spend it, a spent one to undo. Hold the left/right half of the row to
/// remove/add a click slot
class ClicksRow extends StatelessWidget {
  const ClicksRow({super.key, required this.side});

  final Side side;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameNotifier>();
    final clicks = game.clicks(side);
    final total = max(game.maxClicks(side), clicks);
    final isActive = game.active == side;
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: (details) {
          HapticFeedback.mediumImpact();
          game.addMaxClicks(side, details.localPosition.dx < constraints.maxWidth / 2 ? -1 : 1);
        },
        child: SizedBox(
          width: constraints.maxWidth,
          child: Opacity(
            opacity: isActive ? 1.0 : 0.35,
            // Shrinks rather than overflowing with lots of clicks
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < total; i++)
                    _ClickPip(
                      available: i < clicks,
                      color: Color(game.colorValue(side)),
                      onTap: () {
                        tick();
                        if (i < clicks) {
                          game.spendClick(side);
                        } else {
                          game.gainClick(side);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClickPip extends StatelessWidget {
  const _ClickPip({required this.available, required this.color, required this.onTap});

  final bool available;

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: available ? color : Colors.transparent,
              border: Border.all(
                color: available ? color : NrColors.clickSpent.withValues(alpha: 0.6),
                width: 3,
              ),
            ),
            child: available
                // Black symbol unless the colour is dark enough that white reads better
                ? NsgIcon('NSG_CLICK_BLUE', color: color.computeLuminance() > 0.18 ? Colors.black : Colors.white, size: 38)
                : const NsgIcon('NSG_CLICK_SPENT', color: NrColors.clickSpent, size: 38),
          ),
        ),
      );
}

/// Shown on the loser's half when the other side hits the agenda target. Tap to dismiss
class LossOverlay extends StatelessWidget {
  const LossOverlay({super.key, required this.side});

  final Side side;

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameNotifier>();
    final l = AppLocalizations.of(context);
    final scored = side == Side.corp ? l.runnerScoredAgenda(game.agendaMax) : l.corpScoredAgenda(game.agendaMax);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: game.dismissLoss,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        builder: (context, t, child) => Container(
          color: Colors.black.withValues(alpha: 0.8 * t),
          child: Opacity(opacity: t, child: child),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.2, end: 1),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.elasticOut,
                    builder: (context, s, child) => Transform.scale(scale: s, child: child),
                    child: const NsgIcon('NSG_INTERRUPT', color: NrColors.coreDamage, size: 110),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.defeat,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: boldWeight(context),
                      letterSpacing: 6,
                      color: NrColors.coreDamage,
                    ),
                  ),
                  Text(
                    scored,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(l.tapToDismiss, style: const TextStyle(fontSize: 12, color: Colors.white38)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom bar: whose turn, round, End Turn and the menu. Rotates to face the active player
/// Ending a turn with clicks left needs a second tap within 3 seconds. Also ends a run
class TurnBar extends StatefulWidget {
  const TurnBar({super.key});

  @override
  State<TurnBar> createState() => _TurnBarState();
}

class _TurnBarState extends State<TurnBar> {
  bool _armed = false;
  Timer? _disarm;

  @override
  void dispose() {
    _disarm?.cancel();
    super.dispose();
  }

  void _endTurn(GameNotifier game) {
    // Only confirm when ending a turn, not when starting one in one-player mode
    final ending = !game.onePlayer || game.isTrackedTurn;
    if (ending && game.clicks(game.active) > 0 && !_armed) {
      setState(() => _armed = true);
      _disarm?.cancel();
      _disarm = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _armed = false);
      });
      return;
    }
    _disarm?.cancel();
    setState(() => _armed = false);
    HapticFeedback.mediumImpact();
    game.endTurn();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameNotifier>();
    final corpTurn = game.active == Side.corp;
    final l = AppLocalizations.of(context);
    final run = game.runActive ? l.runSuffix : '';
    final String label;
    final String buttonText;
    final Color accent;
    if (game.onePlayer) {
      // One-player: ending our turn passes to the opponent; 'Start turn' starts our next one
      final mine = game.isTrackedTurn;
      accent = Color(game.colorValue(game.trackedSide));
      label = (mine ? l.yourTurnLabel(game.round) : l.opponentTurnLabel(game.round)) + run;
      buttonText = _armed ? l.clicksLeftEndConfirm(game.clicks(game.active)) : (mine ? l.endTurn : l.startTurn);
    } else {
      accent = Color(game.colorValue(game.active));
      label = l.turnLabel(sideNameUpper(l, game.active), game.round) + run;
      buttonText = _armed ? l.clicksLeftEndConfirm(game.clicks(game.active)) : l.endTurn;
    }
    final bar = Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white70),
          onPressed: () => _showMenu(context),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: accent, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _armed ? Colors.orange : accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => _endTurn(game),
            child: Text(
              buttonText,
              style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
          ),
        ),
      ],
    );
    return SizedBox(
      height: 56,
      child: RotatedBox(quarterTurns: (!game.onePlayer && corpTurn) ? 2 : 0, child: bar),
    );
  }
}

Future<void> _showMenu(BuildContext context) {
  final game = context.read<GameNotifier>();
  final l = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1A1A1A),
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModeSettings(compact: true),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text(l.addCounter),
              onTap: () {
                Navigator.pop(sheetContext);
                showAddCounterDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: Text(l.menuNewGame),
              onTap: () async {
                Navigator.pop(sheetContext);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l.newGameTitle),
                    content: Text(l.newGameBody),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l.cancel)),
                      FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l.newGameConfirm)),
                    ],
                  ),
                );
                if (ok == true) game.newGame();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(l.menuSettings),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
              },
            ),
          ],
        ),
      ),
    ),
  );
}
