import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fonts.dart' show defaultSideFont, resolveSideFont;

enum Side { corp, runner }

Side opponentOf(Side side) => side == Side.corp ? Side.runner : Side.corp;

/// Counters that can be added to a side
enum CounterType {
  agenda,
  badPublicity,
  tags,
  coreDamage,
  mu,
  handSize,
  recurringCredit,
  genericBlue,
  genericGreen,
  virus,
  advancement,
  advancementReverse,
}

const defaultHandSize = 5;

extension CounterTypeInfo on CounterType {
  // Labels live in the ARB file, see counterTypeLabel() in widgets.dart

  /// NSG symbol in assets/nsg, without the extension
  String get icon => switch (this) {
        CounterType.agenda => 'NSG_AGENDA',
        CounterType.badPublicity => 'NSG_BAD_PUBLICITY',
        CounterType.tags => 'NSG_TAG',
        CounterType.coreDamage => 'NSG_CORE_DAMAGE',
        CounterType.mu => 'NSG_Mu',
        CounterType.handSize => '', // uses a Material icon instead
        CounterType.recurringCredit => 'NSG_RECURRING_CREDIT',
        CounterType.genericBlue => 'NSG_GENERIC_COUNTER_BLUE',
        CounterType.genericGreen => 'NSG_GENERIC_COUNTER_GREEEN',
        CounterType.virus => 'NSG_VIRUS_COUNTER',
        CounterType.advancement => 'NSG_ADVANCEMENT_COUNTER',
        CounterType.advancementReverse => 'NSG_ADVANCEMENT_COUNTER_REVERSE',
      };

  /// Shown as X/Y. Tap changes X, long-press changes Y
  bool get hasMax => this == CounterType.recurringCredit || this == CounterType.mu;

  /// Recurring credits can't exceed their max
  bool get capped => this == CounterType.recurringCredit;

  /// Refills at the start of the owner's turn (CR 1.10.5c)
  bool get refills => this == CounterType.recurringCredit;

  bool get runnerOnly => this == CounterType.tags || this == CounterType.coreDamage || this == CounterType.mu;

  bool get corpOnly => this == CounterType.badPublicity;

  /// Forces restricted types onto their side
  Side sideFor(Side preferred) => runnerOnly ? Side.runner : (corpOnly ? Side.corp : preferred);

  /// One per side max
  bool get unique =>
      this == CounterType.agenda ||
      this == CounterType.badPublicity ||
      this == CounterType.tags ||
      this == CounterType.coreDamage ||
      this == CounterType.mu ||
      this == CounterType.handSize;

  /// Highlight when above zero
  bool get litWhenPositive => this != CounterType.mu && this != CounterType.handSize;

  /// Counters the app does something with. The rest are just for keeping count
  bool get functional =>
      this == CounterType.agenda ||
      this == CounterType.badPublicity ||
      this == CounterType.coreDamage ||
      this == CounterType.handSize ||
      this == CounterType.recurringCredit;

  bool get allowsNegative => this == CounterType.agenda || this == CounterType.handSize;

  int get defaultMax => this == CounterType.mu ? 4 : 1; // CR 1.20.2

  /// Starting X. Hand size gets core damage taken off separately
  int initialValue(int max) => refills ? max : (this == CounterType.handSize ? defaultHandSize : 0);

  /// Tap in swipe mode: spend for recurring credits, +1 for everything else
  int get tapDelta => this == CounterType.recurringCredit ? -1 : 1;
}

class ExtraCounter {
  ExtraCounter({
    required this.id,
    required this.type,
    required this.side,
    this.name = '',
    this.value = 0,
    this.max = 1,
  });

  final int id;
  final CounterType type;
  Side side;
  String name;
  int value;
  int max;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'side': side.name,
        'name': name,
        'value': value,
        'max': max,
      };

  static ExtraCounter? fromJson(Map<String, dynamic> j) {
    final type = CounterType.values.where((t) => t.name == j['type']).firstOrNull;
    if (type == null) return null;
    return ExtraCounter(
      id: (j['id'] as num?)?.toInt() ?? 0,
      type: type,
      // Old saves could have restricted types on the wrong side
      side: type.sideFor(j['side'] == Side.corp.name ? Side.corp : Side.runner),
      name: (j['name'] as String?) ?? '',
      value: (j['value'] as num?)?.toInt() ?? 0,
      max: (j['max'] as num?)?.toInt() ?? type.defaultMax,
    );
  }
}

/// Game state, settings and saved layouts. Rule refs are NSG Comprehensive Rules v26.03
///
/// Everything is saved on every change so folding/unfolding the phone doesn't lose anything
class GameNotifier extends ChangeNotifier {
  static const _prefsKey = 'nr_game_v1';
  static const _profilesKey = 'nr_profiles_v1';
  static const defaultProfileName = 'Default';

  /// CR 1.6.4
  static const startingCredits = 5;

  static const defaultCorpColor = 0xFF3B82F6;
  static const defaultRunnerColor = 0xFFEF4444;

  /// CR 1.11.2
  static int allotment(Side side) => side == Side.corp ? 3 : 4;

  /// Built-in layout: two players, blue Corp, red Runner, agenda for both, tags and MU for the Runner
  static const Map<String, dynamic> defaultProfile = {
    'name': defaultProfileName,
    'settings': {
      'onePlayer': false,
      'trackedSide': 'runner',
      'showOpponent': true,
      'autoEndTurn': false,
      'corpColor': defaultCorpColor,
      'runnerColor': defaultRunnerColor,
      'corpFaction': '',
      'runnerFaction': '',
      'corpFont': defaultSideFont,
      'runnerFont': defaultSideFont,
      'agendaMax': 7,
      'creditIcon': true,
      'creditIconThreshold': 5,
      'creditAnimation': true,
      'counterButtons': false,
    },
    'counters': [
      {'type': 'agenda', 'side': 'corp', 'name': '', 'max': 1},
      {'type': 'agenda', 'side': 'runner', 'name': '', 'max': 1},
      {'type': 'tags', 'side': 'runner', 'name': '', 'max': 1},
      {'type': 'mu', 'side': 'runner', 'name': '', 'max': 4},
    ],
  };

  static const corpSoloProfileName = 'Corp Solo';
  static const runnerSoloProfileName = 'Runner Solo';

  /// Default, but one-player as the Corp: green, Cinzel/Oxanium, plain credit icon, core damage instead of MU
  static const Map<String, dynamic> corpSoloProfile = {
    'name': corpSoloProfileName,
    'settings': {
      'onePlayer': true,
      'trackedSide': 'corp',
      'showOpponent': true,
      'autoEndTurn': false,
      'corpColor': 0xFF10B981,
      'runnerColor': defaultRunnerColor,
      'corpFaction': '',
      'runnerFaction': '',
      'corpFont': 'Cinzel',
      'runnerFont': 'Oxanium',
      'agendaMax': 7,
      'creditIcon': false,
      'creditIconThreshold': 5,
      'creditAnimation': true,
      'counterButtons': false,
    },
    'counters': [
      {'type': 'agenda', 'side': 'corp', 'name': '', 'max': 1},
      {'type': 'agenda', 'side': 'runner', 'name': '', 'max': 1},
      {'type': 'tags', 'side': 'runner', 'name': '', 'max': 1},
      {'type': 'coreDamage', 'side': 'runner', 'name': '', 'max': 1},
    ],
  };

  /// Default, but one-player as the Runner: Cinzel/Oxanium, plain credit icon, bad publicity on the Corp
  static const Map<String, dynamic> runnerSoloProfile = {
    'name': runnerSoloProfileName,
    'settings': {
      'onePlayer': true,
      'trackedSide': 'runner',
      'showOpponent': true,
      'autoEndTurn': false,
      'corpColor': defaultCorpColor,
      'runnerColor': defaultRunnerColor,
      'corpFaction': '',
      'runnerFaction': '',
      'corpFont': 'Cinzel',
      'runnerFont': 'Oxanium',
      'agendaMax': 7,
      'creditIcon': false,
      'creditIconThreshold': 5,
      'creditAnimation': true,
      'counterButtons': false,
    },
    'counters': [
      {'type': 'agenda', 'side': 'corp', 'name': '', 'max': 1},
      {'type': 'badPublicity', 'side': 'corp', 'name': '', 'max': 1},
      {'type': 'agenda', 'side': 'runner', 'name': '', 'max': 1},
      {'type': 'tags', 'side': 'runner', 'name': '', 'max': 1},
      {'type': 'mu', 'side': 'runner', 'name': '', 'max': 4},
    ],
  };

  /// Built-in layouts, in list order. They can't be renamed, overwritten or deleted
  static const builtInProfiles = [defaultProfile, corpSoloProfile, runnerSoloProfile];

  static bool isBuiltIn(String name) => builtInProfiles.any((p) => p['name'] == name);

  Map<String, dynamic>? _profile(String name) =>
      builtInProfiles.where((p) => p['name'] == name).firstOrNull ??
      _profiles.where((x) => x['name'] == name).firstOrNull;

  // Game state
  final Map<Side, int> _credits = {Side.corp: startingCredits, Side.runner: startingCredits};

  /// CR 1.6.7: Corp goes first
  final Map<Side, int> _clicks = {Side.corp: 3, Side.runner: 0};

  /// Clicks per turn. Can be changed by holding the click row
  final Map<Side, int> _maxClicks = {Side.corp: 3, Side.runner: 4};
  final List<ExtraCounter> _extras = [];
  int _nextExtraId = 1;
  Side _active = Side.corp;
  int _round = 1;

  /// Credits the Corp paid into the current run. Null when there's no run
  int? _runFund;

  bool _loaded = false;
  bool _lossDismissed = false; // not saved on purpose
  Timer? _autoEndTimer;

  // Settings
  bool _onePlayer = false;
  Side _trackedSide = Side.runner;
  bool _showOpponent = true;
  bool _autoEndTurn = false;
  int _corpColor = defaultCorpColor;
  int _runnerColor = defaultRunnerColor;
  String _corpFaction = '';
  String _runnerFaction = '';

  /// Always one of sideFonts
  String _corpFont = defaultSideFont;
  String _runnerFont = defaultSideFont;
  int _agendaMax = 7;
  bool _creditIcon = true;
  int _creditIconThreshold = 5;
  bool _creditAnimation = true;
  bool _counterButtons = true;

  /// Locale tag
  String _language = '';

  // Layouts
  final List<Map<String, dynamic>> _profiles = [];
  String _activeProfile = defaultProfileName;

  int credits(Side side) => _credits[side]!;
  int clicks(Side side) => _clicks[side]!;
  int maxClicks(Side side) => _maxClicks[side]!;
  List<ExtraCounter> get extras => List.unmodifiable(_extras);
  List<ExtraCounter> extrasFor(Side side) => _extras.where((c) => c.side == side).toList();
  Side get active => _active;
  int get round => _round;
  int? get runFund => _runFund;
  bool get runActive => _runFund != null;
  bool get loaded => _loaded;

  bool get onePlayer => _onePlayer;
  Side get trackedSide => _trackedSide;
  bool get showOpponent => _showOpponent;
  String get language => _language;
  bool get autoEndTurn => _autoEndTurn;
  int colorValue(Side side) => side == Side.corp ? _corpColor : _runnerColor;
  String faction(Side side) => side == Side.corp ? _corpFaction : _runnerFaction;
  String font(Side side) => side == Side.corp ? _corpFont : _runnerFont;
  int get agendaMax => _agendaMax;
  bool get creditIcon => _creditIcon;
  int get creditIconThreshold => _creditIconThreshold;
  bool get creditAnimation => _creditAnimation;

  /// Off = swipe mode
  bool get counterButtons => _counterButtons;

  bool get isTrackedTurn => _active == _trackedSide;

  List<String> get profileNames => [
        for (final p in builtInProfiles) p['name'] as String,
        ..._profiles.map((p) => p['name'] as String).where((n) => !isBuiltIn(n)),
      ];
  String get activeProfile => _activeProfile;

  int get badPublicity =>
      _extras.where((c) => c.type == CounterType.badPublicity).fold(0, (sum, c) => sum + c.value);

  bool hasCounter(CounterType type, [Side? side]) =>
      _extras.any((c) => c.type == type && (side == null || c.side == side));

  bool canAdd(CounterType type, Side side) =>
      type.sideFor(side) == side && !(type.unique && hasCounter(type, side));

  int _agendaOf(Side side) =>
      _extras.where((c) => c.type == CounterType.agenda && c.side == side).fold(0, (m, c) => max(m, c.value));

  /// CR 1.7.2a
  Side? get winner {
    if (_agendaOf(Side.corp) >= _agendaMax) return Side.corp;
    if (_agendaOf(Side.runner) >= _agendaMax) return Side.runner;
    return null;
  }

  /// Two-player only
  Side? get loserToShow {
    final w = winner;
    if (w == null || _onePlayer || _lossDismissed) return null;
    return opponentOf(w);
  }

  // Actions

  /// During a run the Runner spends run credits first
  void addCredits(Side side, int delta) {
    var d = delta;
    if (side == Side.runner && d < 0 && _runFund != null && _runFund! > 0) {
      final take = min(_runFund!, -d);
      _runFund = _runFund! - take;
      d += take;
    }
    _credits[side] = (_credits[side]! + d).clamp(-999, 999);
    _changed();
  }

  void dismissLoss() {
    _lossDismissed = true;
    notifyListeners();
  }

  /// Hand size starts lowered by any core damage already taken
  int _startValue(CounterType type, Side side, int max) =>
      type.initialValue(max) - (type == CounterType.handSize ? _coreDamageOf(side) : 0);

  int _coreDamageOf(Side side) =>
      _extras.where((c) => c.type == CounterType.coreDamage && c.side == side).fold(0, (sum, c) => sum + c.value);

  int addExtra(CounterType type, Side side, String name) {
    if (!canAdd(type, side)) return -1;
    final m = type.defaultMax;
    final c = ExtraCounter(
      id: _nextExtraId++,
      type: type,
      side: side,
      name: name.trim(),
      value: _startValue(type, side, m),
      max: m,
    );
    _extras.add(c);
    _changed();
    return c.id;
  }

  ExtraCounter? removeExtra(int id) {
    final c = _extras.where((x) => x.id == id).firstOrNull;
    if (c == null) return null;
    _extras.remove(c);
    if (winner == null) _lossDismissed = false;
    _changed();
    return c;
  }

  List<ExtraCounter> removeAllExtras() {
    final removed = List<ExtraCounter>.of(_extras);
    _extras.clear();
    _lossDismissed = false;
    _changed();
    return removed;
  }

  /// Same side only. Order is saved and goes into layouts
  void moveExtra(int id, int targetId, {bool after = false}) {
    if (id == targetId) return;
    final c = _extras.where((x) => x.id == id).firstOrNull;
    final t = _extras.where((x) => x.id == targetId).firstOrNull;
    if (c == null || t == null || c.side != t.side) return;
    _extras.remove(c);
    final i = _extras.indexOf(t);
    _extras.insert(after ? i + 1 : i, c);
    _changed();
  }

  void addExtraValue(int id, int delta) {
    final c = _extras.where((x) => x.id == id).firstOrNull;
    if (c == null) return;
    final upper = c.type.capped ? c.max : (c.type == CounterType.agenda ? _agendaMax : 99);
    final before = c.value;
    c.value = (c.value + delta).clamp(c.type.allowsNegative ? -99 : 0, upper);
    // Core damage also changes max hand size
    final applied = c.value - before;
    if (c.type == CounterType.coreDamage && applied != 0) {
      for (final h in _extras.where((x) => x.type == CounterType.handSize && x.side == c.side)) {
        h.value = (h.value - applied).clamp(-99, 99);
      }
    }
    if (c.type == CounterType.agenda && winner == null) _lossDismissed = false;
    _changed();
  }

  void addExtraMax(int id, int delta) {
    final c = _extras.where((x) => x.id == id).firstOrNull;
    if (c == null || !c.type.hasMax) return;
    c.max = (c.max + delta).clamp(0, 99);
    if (c.type.capped && c.value > c.max) c.value = c.max;
    _changed();
  }

  /// Run moves credits equal to bad publicity from the Corp to the Runner. Deliberately not CR 10.6, where they
  /// come from the bank
  void startRun() {
    if (_runFund != null) return;
    final x = max(0, min(badPublicity, _credits[Side.corp]!));
    _credits[Side.corp] = _credits[Side.corp]! - x;
    _runFund = x;
    _changed();
  }

  /// Unspent run credits go back to the Corp
  void endRun() {
    if (_runFund == null) return;
    _endRunSilently();
    _changed();
  }

  void _endRunSilently() {
    _credits[Side.corp] = (_credits[Side.corp]! + (_runFund ?? 0)).clamp(-999, 999);
    _runFund = null;
  }

  /// Corp-only screen
  void spendRunFund() {
    if (_runFund != null && _runFund! > 0) {
      _runFund = _runFund! - 1;
      _changed();
    }
  }

  /// CR 1.11.3
  void spendClick(Side side) {
    if (_clicks[side]! <= 0) return;
    _clicks[side] = _clicks[side]! - 1;
    _changed();
    if (_autoEndTurn && side == _active && _clicks[side] == 0) {
      _autoEndTimer?.cancel();
      _autoEndTimer = Timer(const Duration(milliseconds: 700), () {
        if (_active == side && _clicks[side] == 0) endTurn();
      });
    }
  }

  void gainClick(Side side) {
    if (_clicks[side]! >= _maxClicks[side]!) return;
    _autoEndTimer?.cancel();
    _clicks[side] = _clicks[side]! + 1;
    _changed();
  }

  /// 1-9. Raising it mid-turn gives the click straight away; lowering it takes extra clicks away
  void addMaxClicks(Side side, int delta) {
    final m = (_maxClicks[side]! + delta).clamp(1, 9);
    final applied = m - _maxClicks[side]!;
    if (applied == 0) return;
    _maxClicks[side] = m;
    if (applied > 0 && side == _active) {
      _autoEndTimer?.cancel();
      _clicks[side] = min(m, _clicks[side]! + applied);
    } else {
      _clicks[side] = min(_clicks[side]!, m);
    }
    _changed();
  }

  /// CR 5.6.3c / 5.7.2c: unspent clicks are lost. CR 5.6.1a / 5.7.1a: next player gains clicks
  /// CR 1.10.5c: recurring credits refill. Also ends any run in progress
  void endTurn() {
    _autoEndTimer?.cancel();
    if (_runFund != null) _endRunSilently();
    _clicks[_active] = 0;
    _active = opponentOf(_active);
    if (_active == Side.corp) _round++;
    _clicks[_active] = _maxClicks[_active]!;
    for (final c in _extras) {
      if (c.type.refills && c.side == _active) c.value = c.max;
    }
    _changed();
  }

  /// Resets values only. Counters and settings stay
  void newGame() {
    _autoEndTimer?.cancel();
    _credits[Side.corp] = startingCredits;
    _credits[Side.runner] = startingCredits;
    _maxClicks[Side.corp] = allotment(Side.corp);
    _maxClicks[Side.runner] = allotment(Side.runner);
    _clicks[Side.corp] = allotment(Side.corp);
    _clicks[Side.runner] = 0;
    for (final c in _extras) {
      c.value = c.type.initialValue(c.max);
    }
    _runFund = null;
    _active = Side.corp;
    _round = 1;
    _lossDismissed = false;
    _changed();
  }

  // Settings

  void setOnePlayer(bool value) {
    _onePlayer = value;
    _changed();
  }

  void setTrackedSide(Side side) {
    _trackedSide = side;
    _changed();
  }

  void setLanguage(String tag) {
    _language = tag;
    _changed();
  }

  void setShowOpponent(bool value) {
    _showOpponent = value;
    _changed();
  }

  void setAutoEndTurn(bool value) {
    _autoEndTurn = value;
    _changed();
  }

  void setColor(Side side, int argb) {
    if (side == Side.corp) {
      _corpColor = argb;
    } else {
      _runnerColor = argb;
    }
    _changed();
  }

  void setFont(Side side, String family) {
    if (side == Side.corp) {
      _corpFont = resolveSideFont(family);
    } else {
      _runnerFont = resolveSideFont(family);
    }
    _changed();
  }

  void setFaction(Side side, String key) {
    if (side == Side.corp) {
      _corpFaction = key;
    } else {
      _runnerFaction = key;
    }
    _changed();
  }

  void setAgendaMax(int value) {
    _agendaMax = value.clamp(1, 15);
    for (final c in _extras) {
      if (c.type == CounterType.agenda) c.value = min(c.value, _agendaMax);
    }
    _changed();
  }

  void setCreditIcon(bool value) {
    _creditIcon = value;
    _changed();
  }

  void setCreditIconThreshold(int value) {
    _creditIconThreshold = value.clamp(0, 99);
    _changed();
  }

  void setCreditAnimation(bool value) {
    _creditAnimation = value;
    _changed();
  }

  void setCounterButtons(bool value) {
    _counterButtons = value;
    _changed();
  }

  // Layouts

  Map<String, dynamic> _settingsToJson() => {
        'onePlayer': _onePlayer,
        'trackedSide': _trackedSide.name,
        'showOpponent': _showOpponent,
        'autoEndTurn': _autoEndTurn,
        'corpColor': _corpColor,
        'runnerColor': _runnerColor,
        'corpFaction': _corpFaction,
        'runnerFaction': _runnerFaction,
        'corpFont': _corpFont,
        'runnerFont': _runnerFont,
        'agendaMax': _agendaMax,
        'creditIcon': _creditIcon,
        'creditIconThreshold': _creditIconThreshold,
        'creditAnimation': _creditAnimation,
        'counterButtons': _counterButtons,
      };

  void _settingsFromJson(Map<String, dynamic> j) {
    int read(String key, int fallback) => (j[key] as num?)?.toInt() ?? fallback;
    bool flag(String key, bool fallback) => j[key] is bool ? j[key] as bool : fallback;
    _onePlayer = flag('onePlayer', false);
    _trackedSide = j['trackedSide'] == Side.corp.name ? Side.corp : Side.runner;
    _showOpponent = flag('showOpponent', true);
    _autoEndTurn = flag('autoEndTurn', false);
    _corpColor = read('corpColor', defaultCorpColor);
    _runnerColor = read('runnerColor', defaultRunnerColor);
    _corpFaction = (j['corpFaction'] as String?) ?? '';
    _runnerFaction = (j['runnerFaction'] as String?) ?? '';
    // '' in old saves, or a font that's been removed
    _corpFont = resolveSideFont(j['corpFont'] as String?);
    _runnerFont = resolveSideFont(j['runnerFont'] as String?);
    _agendaMax = read('agendaMax', 7).clamp(1, 15);
    _creditIcon = flag('creditIcon', true);
    _creditIconThreshold = read('creditIconThreshold', 5).clamp(0, 99);
    _creditAnimation = flag('creditAnimation', true);
    _counterButtons = flag('counterButtons', true);
  }

  /// Built-in layouts can't be overwritten. A null description keeps the existing one
  void saveProfile(String name, {String? description}) {
    final n = name.trim();
    if (n.isEmpty || isBuiltIn(n)) return;
    final i = _profiles.indexWhere((p) => p['name'] == n);
    final layout = {
      'name': n,
      'description': description?.trim() ?? (i >= 0 ? profileDescription(n) : ''),
      'settings': _settingsToJson(),
      'counters': [
        for (final c in _extras) {'type': c.type.name, 'side': c.side.name, 'name': c.name, 'max': c.max},
      ],
    };
    if (i >= 0) {
      _profiles[i] = layout;
    } else {
      _profiles.add(layout);
    }
    _activeProfile = n;
    _saveProfiles();
    _changed();
  }

  String profileDescription(String name) =>
      (_profiles.where((p) => p['name'] == name).firstOrNull?['description'] as String?) ?? '';

  void setProfileDescription(String name, String description) {
    final p = _profiles.where((x) => x['name'] == name).firstOrNull;
    if (p == null) return;
    p['description'] = description.trim();
    _saveProfiles();
    notifyListeners();
  }

  /// Counters matching an existing one by type, side and name keep their value
  void loadProfile(String name) {
    final p = _profile(name);
    if (p == null) return;
    _applyProfile(p);
    _activeProfile = name;
    _changed();
  }

  void _applyProfile(Map<String, dynamic> p) {
    _settingsFromJson(Map<String, dynamic>.from(p['settings'] as Map));
    final old = List<ExtraCounter>.of(_extras);
    _extras.clear();
    for (final raw in (p['counters'] as List)) {
      final j = Map<String, dynamic>.from(raw as Map);
      final type = CounterType.values.where((t) => t.name == j['type']).firstOrNull;
      if (type == null) continue;
      final side = type.sideFor(j['side'] == Side.corp.name ? Side.corp : Side.runner);
      final name = (j['name'] as String?) ?? '';
      final m = (j['max'] as num?)?.toInt() ?? type.defaultMax;
      if (!canAdd(type, side)) continue;
      final match = old.where((c) => c.type == type && c.side == side && c.name == name).firstOrNull;
      if (match != null) {
        old.remove(match);
        match.max = m;
        if (type.capped) match.value = min(match.value, m);
        _extras.add(match);
      } else {
        _extras.add(ExtraCounter(id: _nextExtraId++, type: type, side: side, name: name, value: _startValue(type, side, m), max: m));
      }
    }
    if (_runFund != null && !hasCounter(CounterType.badPublicity)) _endRunSilently();
    _lossDismissed = false;
  }

  /// Keys that loading [name] would change: setting keys from _settingsToJson, plus 'counters', 'counterOrder'
  /// and 'counterMax'. Empty if nothing would change
  List<String> layoutChanges(String name) {
    final p = _profile(name);
    if (p == null) return const [];
    final probe = GameNotifier().._settingsFromJson(Map<String, dynamic>.from(p['settings'] as Map));
    final after = probe._settingsToJson();
    probe.dispose();
    final now = _settingsToJson();
    final changes = [for (final k in now.keys) if (now[k] != after[k]) k];

    final wanted = <(CounterType, Side, String, int)>[];
    for (final raw in (p['counters'] as List? ?? const [])) {
      final j = Map<String, dynamic>.from(raw as Map);
      final type = CounterType.values.where((t) => t.name == j['type']).firstOrNull;
      if (type == null) continue;
      final side = type.sideFor(j['side'] == Side.corp.name ? Side.corp : Side.runner);
      if (type.unique && wanted.any((w) => w.$1 == type && w.$2 == side)) continue;
      wanted.add((type, side, (j['name'] as String?) ?? '', (j['max'] as num?)?.toInt() ?? type.defaultMax));
    }
    final current = [for (final c in _extras) (c.type, c.side, c.name, c.max)];
    String id((CounterType, Side, String, int) c) => '${c.$1.name}/${c.$2.name}/${c.$3}';
    final wantedIds = wanted.map(id).toList();
    final currentIds = current.map(id).toList();
    if (!listEquals([...wantedIds]..sort(), [...currentIds]..sort())) {
      changes.add('counters');
    } else {
      if (!listEquals(wantedIds, currentIds)) changes.add('counterOrder');
      List<String> withMax(List<(CounterType, Side, String, int)> list) =>
          [for (final c in list) '${id(c)}=${c.$4}']..sort();
      if (!listEquals(withMax(wanted), withMax(current))) changes.add('counterMax');
    }
    return changes;
  }

  void deleteProfile(String name) {
    _profiles.removeWhere((p) => p['name'] == name);
    if (_activeProfile == name) _activeProfile = defaultProfileName;
    _saveProfiles();
    _changed();
  }

  Future<void> _saveProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profilesKey, jsonEncode({'profiles': _profiles}));
    } catch (e) {
      debugPrint('NR Tracker: could not save layouts ($e)');
    }
  }

  // Persistence

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawProfiles = prefs.getString(_profilesKey);
      if (rawProfiles != null) {
        final list = (jsonDecode(rawProfiles) as Map<String, dynamic>)['profiles'] as List? ?? const [];
        _profiles
          ..clear()
          ..addAll(list.whereType<Map<String, dynamic>>());
      }
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } else {
        _applyProfile(defaultProfile);
      }
    } catch (e) {
      debugPrint('NR Tracker: could not load saved game ($e); starting fresh');
      _applyProfile(defaultProfile);
    }
    _loaded = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoEndTimer?.cancel();
    super.dispose();
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_toJson()));
    } catch (e) {
      debugPrint('NR Tracker: could not save game ($e)');
    }
  }

  Map<String, dynamic> _toJson() => {
        'v': 3,
        'corpCredits': _credits[Side.corp],
        'runnerCredits': _credits[Side.runner],
        'corpClicks': _clicks[Side.corp],
        'runnerClicks': _clicks[Side.runner],
        'corpMaxClicks': _maxClicks[Side.corp],
        'runnerMaxClicks': _maxClicks[Side.runner],
        'extras': _extras.map((c) => c.toJson()).toList(),
        'nextExtraId': _nextExtraId,
        'runFund': _runFund,
        'active': _active.name,
        'round': _round,
        'activeProfile': _activeProfile,
        'language': _language,
        ..._settingsToJson(),
      };

  void _fromJson(Map<String, dynamic> j) {
    int read(String key, int fallback) => (j[key] as num?)?.toInt() ?? fallback;
    final version = read('v', 1);

    _credits[Side.corp] = read('corpCredits', startingCredits);
    _credits[Side.runner] = read('runnerCredits', startingCredits);
    _clicks[Side.corp] = read('corpClicks', allotment(Side.corp));
    _clicks[Side.runner] = read('runnerClicks', 0);
    _maxClicks[Side.corp] = read('corpMaxClicks', allotment(Side.corp)).clamp(1, 9);
    _maxClicks[Side.runner] = read('runnerMaxClicks', allotment(Side.runner)).clamp(1, 9);
    _extras
      ..clear()
      ..addAll(((j['extras'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ExtraCounter.fromJson)
          .whereType<ExtraCounter>());
    _nextExtraId = max(read('nextExtraId', 1), _extras.fold<int>(0, (m, c) => max(m, c.id)) + 1);
    _runFund = (j['runFund'] as num?)?.toInt();
    _active = j['active'] == Side.runner.name ? Side.runner : Side.corp;
    _round = read('round', 1);
    _activeProfile = (j['activeProfile'] as String?) ?? defaultProfileName;
    _language = (j['language'] as String?) ?? '';
    _settingsFromJson(j);

    // Migrating old saves where these were built in
    void migrate(CounterType type, Side side, int value, {int max = 1, bool always = false}) {
      if ((always || value > 0) && canAdd(type, side)) {
        _extras.add(ExtraCounter(id: _nextExtraId++, type: type, side: side, value: value, max: max));
      }
    }

    if (version < 3) {
      // v2
      migrate(CounterType.agenda, Side.corp, read('corpAgenda', 0), always: true);
      migrate(CounterType.agenda, Side.runner, read('runnerAgenda', 0), always: true);
      migrate(CounterType.tags, Side.runner, read('tags', 0));
      migrate(CounterType.coreDamage, Side.runner, read('coreDamage', 0));
      migrate(CounterType.mu, Side.runner, read('muUsed', 0), max: read('muLimit', 4), always: true);
    }
    if (version < 2) {
      // v1
      migrate(CounterType.badPublicity, Side.corp, read('badPublicity', 0));
    }
  }
}
