// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NR Tracker';

  @override
  String get languageName => 'English';

  @override
  String get sideCorp => 'Corp';

  @override
  String get sideRunner => 'Runner';

  @override
  String get sideCorpUpper => 'CORP';

  @override
  String get sideRunnerUpper => 'RUNNER';

  @override
  String get runSuffix => ' · RUN';

  @override
  String get runButton => 'RUN';

  @override
  String runButtonWithCredits(int credits) {
    return 'RUN  +$credits';
  }

  @override
  String get endRun => 'END RUN';

  @override
  String get runnerRunCredits => 'Runner run credits';

  @override
  String get dropToRemove => 'Drop here to remove';

  @override
  String get noCounters => 'No counters';

  @override
  String get defeat => 'DEFEAT';

  @override
  String corpScoredAgenda(int points) {
    return 'The Corp scored $points agenda points';
  }

  @override
  String runnerScoredAgenda(int points) {
    return 'The Runner scored $points agenda points';
  }

  @override
  String get tapToDismiss => 'Tap to dismiss';

  @override
  String turnLabel(String side, int round) {
    return '$side TURN · R$round';
  }

  @override
  String yourTurnLabel(int round) {
    return 'YOUR TURN · R$round';
  }

  @override
  String opponentTurnLabel(int round) {
    return 'OPPONENT\'S TURN · R$round';
  }

  @override
  String get endTurn => 'END TURN';

  @override
  String get startTurn => 'START TURN';

  @override
  String clicksLeftEndConfirm(int count) {
    return '$count LEFT - END?';
  }

  @override
  String get menuSettings => 'Settings';

  @override
  String get addCounter => 'Add counters';

  @override
  String get menuNewGame => 'New game';

  @override
  String get newGameTitle => 'Start a new game?';

  @override
  String get newGameBody =>
      'Resets credits, clicks and all counter values. The counters themselves and the settings are kept.';

  @override
  String get newGameConfirm => 'New game';

  @override
  String get menuAbout => 'About & credits';

  @override
  String get aboutBody =>
      'A fan-made credit and click tracker for [Null Signal Games](https://nullsignal.games/)\' Netrunner.\n\nGame symbols and faction glyphs by Null Signal Games, licensed under [CC BY-ND 4.0](https://creativecommons.org/licenses/by-nd/4.0). Not affiliated with or endorsed by Null Signal Games.\n\nFont: [Urbanist](https://fonts.google.com/specimen/Urbanist).\n\nBased on [MTG Tracker](https://play.google.com/store/apps/datasafety?id=com.birkoss.mtgtracker) by [birkoss](https://github.com/birkoss).\n\n[Privacy Policy](https://purpl.pur.pl/NRPrivacyPolicy)';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get changelog => 'Changelog';

  @override
  String get add => 'Add';

  @override
  String addCount(int count) {
    return 'Add $count';
  }

  @override
  String get remove => 'Remove';

  @override
  String get save => 'Save';

  @override
  String get replace => 'Replace';

  @override
  String get update => 'Update';

  @override
  String get load => 'Load';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get headerLayouts => 'Layouts';

  @override
  String get headerMode => 'Mode';

  @override
  String get headerGame => 'Game';

  @override
  String get headerAppearance => 'Appearance';

  @override
  String get headerAddedCounters => 'Added counters';

  @override
  String get layoutDefault => 'Default';

  @override
  String get layoutDefaultSubtitle =>
      'Two-players, agenda points for both sides, tags and MU for the Runner';

  @override
  String get layoutCustom => 'Custom Layout';

  @override
  String get layoutCorpSolo => 'Corp Solo';

  @override
  String get layoutCorpSoloSubtitle =>
      'One-player as the Corp, with core damage instead of MU';

  @override
  String get layoutRunnerSolo => 'Runner Solo';

  @override
  String get layoutRunnerSoloSubtitle =>
      'One-player as the Runner, with bad publicity on the Corp';

  @override
  String get deleteLayout => 'Delete layout';

  @override
  String deleteLayoutTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteLayoutBody =>
      'The saved layout is removed. The current game, settings and counters aren\'t affected.';

  @override
  String get delete => 'Delete';

  @override
  String get saveAsNewLayout => 'Save as new layout';

  @override
  String updateLayoutButton(String name) {
    return 'Update \"$name\"';
  }

  @override
  String updateLayoutTitle(String name) {
    return 'Update \"$name\"?';
  }

  @override
  String get updateLayoutBody =>
      'Replaces this layout\'s saved settings and counters with the current ones.';

  @override
  String loadLayoutTitle(String name) {
    return 'Load \"$name\"?';
  }

  @override
  String get loadLayoutBody => 'Loading this layout changes:';

  @override
  String get changeCounters => 'Counters (added or removed)';

  @override
  String get changeCounterOrder => 'Counter positions';

  @override
  String get changeCounterMax => 'Counter maximums (MU, recurring credits)';

  @override
  String get saveLayoutTitle => 'Save layout';

  @override
  String get saveLayoutBody =>
      'Saves the current settings and counters (not their values).';

  @override
  String get layoutName => 'Layout name';

  @override
  String get layoutDescription => 'Description (optional)';

  @override
  String get editLayoutDescription => 'Edit description';

  @override
  String editDescriptionTitle(String name) {
    return 'Description of \"$name\"';
  }

  @override
  String get layoutNameIsBuiltIn => 'That\'s a built-in layout';

  @override
  String get layoutReplacesExisting => 'Replaces the existing layout';

  @override
  String get onePlayerMode => 'One-player mode';

  @override
  String get onePlayerModeSubtitle =>
      'Track only one side (End turn / Start turn)';

  @override
  String get trackedSide => 'Tracked side';

  @override
  String get showOpponentCounters => 'Show opponent\'s counters';

  @override
  String get showOpponentCountersSubtitle =>
      'A strip of the opponent\'s counters above yours';

  @override
  String get autoEndTurn => 'Automatically end turn when clicks are exhausted';

  @override
  String get agendaToWin => 'Agenda points to win';

  @override
  String get creditIconFrom => '5-credits icon';

  @override
  String get creditIconFromSubtitle =>
      'Credits at which the credit icon switches';

  @override
  String get creditIconSubtitle =>
      'Show the 5-credits icon instead of the credit icon from a set amount';

  @override
  String get creditIconAt => 'Switch at';

  @override
  String get creditAnimation => 'Credit animation';

  @override
  String get creditAnimationSubtitle =>
      'Modifying credits plays a floating animation';

  @override
  String get counterButtons => 'Show counter +/- buttons';

  @override
  String get counterButtonsSubtitle =>
      'Adds +/- buttons to every counter. Counters get wider, so with many counters they may need more rows and scrolling.';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get corpColour => 'Corp colour';

  @override
  String get runnerColour => 'Runner colour';

  @override
  String get customColour => 'Custom colour';

  @override
  String get select => 'Select';

  @override
  String get colourHex => 'Hex';

  @override
  String get colourRed => 'R';

  @override
  String get colourGreen => 'G';

  @override
  String get colourBlue => 'B';

  @override
  String get colourHue => 'H';

  @override
  String get colourSaturation => 'S';

  @override
  String get colourLightness => 'L';

  @override
  String get colourModePicker => 'Colour picker';

  @override
  String get colourModeValues => 'Hex / RGB / HSL';

  @override
  String get corpFactionGlyph => 'Corp faction glyph (background)';

  @override
  String get runnerFactionGlyph => 'Runner faction glyph (background)';

  @override
  String get factionNone => 'None';

  @override
  String get corpFont => 'Corp font';

  @override
  String get runnerFont => 'Runner font';

  @override
  String get fontDefault => 'Default (Urbanist)';

  @override
  String get dragHint =>
      'Drag: Long-press a counter and drag it to reorder or remove';

  @override
  String get noCountersYet => 'None yet';

  @override
  String get noCountersYetSubtitle =>
      'Agenda points, bad publicity, tags, core damage, MU, max hand size, recurring credits, virus, advancement and generic counters';

  @override
  String addedCounterSubtitle(String side, String type) {
    return '$side · $type';
  }

  @override
  String get removeAllCounters => 'Remove all counters';

  @override
  String get addCountersTitle => 'Add counters';

  @override
  String get runnerOnly => 'Runner only';

  @override
  String get corpOnly => 'Corp only';

  @override
  String get alreadyAdded => 'Already added';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String get nameNeedsSingle => 'Select a single counter to name it';

  @override
  String get counterAgenda => 'Agenda points';

  @override
  String get counterAgendaHint => 'Reaching the target wins the game';

  @override
  String get counterBadPublicityHint =>
      'Shows the Run button. Runs move this many credits from the Corp to the Runner';

  @override
  String get counterCoreDamageHint => 'Each point lowers max hand size by 1';

  @override
  String get counterHandSizeHint => 'Starts at 5, minus core damage';

  @override
  String get counterRecurringCreditHint =>
      'Tap to spend. Refills at the start of your turn';

  @override
  String get counterBadPublicity => 'Bad publicity';

  @override
  String get counterTags => 'Tags';

  @override
  String get counterCoreDamage => 'Core damage';

  @override
  String get counterMu => 'Memory units (MU)';

  @override
  String get counterHandSize => 'Max hand size';

  @override
  String get counterRecurringCredit => 'Recurring credits';

  @override
  String get counterGenericBlue => 'Generic counter (blue)';

  @override
  String get counterGenericGreen => 'Generic counter (green)';

  @override
  String get counterVirus => 'Virus counter';

  @override
  String get counterAdvancement => 'Advancement counter';

  @override
  String get counterAdvancementReverse => 'Advancement counter (reverse)';
}
