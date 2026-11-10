import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// App name (task switcher, About dialog).
  ///
  /// In en, this message translates to:
  /// **'NR Tracker'**
  String get appTitle;

  /// The name of THIS file's language, written in that language (shown in Settings > Language).
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @sideCorp.
  ///
  /// In en, this message translates to:
  /// **'Corp'**
  String get sideCorp;

  /// No description provided for @sideRunner.
  ///
  /// In en, this message translates to:
  /// **'Runner'**
  String get sideRunner;

  /// Side label at the top of each half and in the turn bar.
  ///
  /// In en, this message translates to:
  /// **'CORP'**
  String get sideCorpUpper;

  /// No description provided for @sideRunnerUpper.
  ///
  /// In en, this message translates to:
  /// **'RUNNER'**
  String get sideRunnerUpper;

  /// Appended to the side label / turn bar while a run is in progress. Keep the leading space.
  ///
  /// In en, this message translates to:
  /// **' · RUN'**
  String get runSuffix;

  /// No description provided for @runButton.
  ///
  /// In en, this message translates to:
  /// **'RUN'**
  String get runButton;

  /// Run button when the run will move credits from the Corp.
  ///
  /// In en, this message translates to:
  /// **'RUN  +{credits}'**
  String runButtonWithCredits(int credits);

  /// No description provided for @endRun.
  ///
  /// In en, this message translates to:
  /// **'END RUN'**
  String get endRun;

  /// Corp-only mode: green chip showing the Runner's run credits.
  ///
  /// In en, this message translates to:
  /// **'Runner run credits'**
  String get runnerRunCredits;

  /// Accessibility (screen reader) label of the bin shown over the clicks while dragging a counter. Not shown on screen.
  ///
  /// In en, this message translates to:
  /// **'Drop here to remove'**
  String get dropToRemove;

  /// Opponent strip (one-player mode) when the opponent has no counters.
  ///
  /// In en, this message translates to:
  /// **'No counters'**
  String get noCounters;

  /// No description provided for @defeat.
  ///
  /// In en, this message translates to:
  /// **'DEFEAT'**
  String get defeat;

  /// No description provided for @corpScoredAgenda.
  ///
  /// In en, this message translates to:
  /// **'The Corp scored {points} agenda points'**
  String corpScoredAgenda(int points);

  /// No description provided for @runnerScoredAgenda.
  ///
  /// In en, this message translates to:
  /// **'The Runner scored {points} agenda points'**
  String runnerScoredAgenda(int points);

  /// No description provided for @tapToDismiss.
  ///
  /// In en, this message translates to:
  /// **'Tap to dismiss'**
  String get tapToDismiss;

  /// Two-player turn bar. side = CORP or RUNNER (sideCorpUpper / sideRunnerUpper); round = round number.
  ///
  /// In en, this message translates to:
  /// **'{side} TURN · R{round}'**
  String turnLabel(String side, int round);

  /// No description provided for @yourTurnLabel.
  ///
  /// In en, this message translates to:
  /// **'YOUR TURN · R{round}'**
  String yourTurnLabel(int round);

  /// No description provided for @opponentTurnLabel.
  ///
  /// In en, this message translates to:
  /// **'OPPONENT\'S TURN · R{round}'**
  String opponentTurnLabel(int round);

  /// No description provided for @endTurn.
  ///
  /// In en, this message translates to:
  /// **'END TURN'**
  String get endTurn;

  /// One-player mode, during the opponent's turn.
  ///
  /// In en, this message translates to:
  /// **'START TURN'**
  String get startTurn;

  /// End Turn button asking for a second tap when clicks are left.
  ///
  /// In en, this message translates to:
  /// **'{count} LEFT - END?'**
  String clicksLeftEndConfirm(int count);

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @addCounter.
  ///
  /// In en, this message translates to:
  /// **'Add counters'**
  String get addCounter;

  /// No description provided for @menuNewGame.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get menuNewGame;

  /// No description provided for @newGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new game?'**
  String get newGameTitle;

  /// No description provided for @newGameBody.
  ///
  /// In en, this message translates to:
  /// **'Resets credits, clicks and all counter values. The counters themselves and the settings are kept.'**
  String get newGameBody;

  /// No description provided for @newGameConfirm.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get newGameConfirm;

  /// No description provided for @menuAbout.
  ///
  /// In en, this message translates to:
  /// **'About & credits'**
  String get menuAbout;

  /// About dialog. \n\n = blank line. [text](https://...) makes a tappable link (shown underlined; opens in the browser). Keep the licence details accurate.
  ///
  /// In en, this message translates to:
  /// **'A fan-made credit and click tracker for [Null Signal Games](https://nullsignal.games/)\' Netrunner.\n\nGame symbols and faction glyphs by Null Signal Games, licensed under [CC BY-ND 4.0](https://creativecommons.org/licenses/by-nd/4.0). Not affiliated with or endorsed by Null Signal Games.\n\nFont: [Urbanist](https://fonts.google.com/specimen/Urbanist).\n\nBased on [MTG Tracker](https://play.google.com/store/apps/datasafety?id=com.birkoss.mtgtracker) by [birkoss](https://github.com/birkoss).\n\n[Privacy Policy](https://purpl.pur.pl/NRPrivacyPolicy)'**
  String get aboutBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @changelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get changelog;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Add counters dialog button when several are selected.
  ///
  /// In en, this message translates to:
  /// **'Add {count}'**
  String addCount(int count);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @load.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get load;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @headerLayouts.
  ///
  /// In en, this message translates to:
  /// **'Layouts'**
  String get headerLayouts;

  /// No description provided for @headerMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get headerMode;

  /// No description provided for @headerGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get headerGame;

  /// No description provided for @headerAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get headerAppearance;

  /// No description provided for @headerAddedCounters.
  ///
  /// In en, this message translates to:
  /// **'Added counters'**
  String get headerAddedCounters;

  /// Display name of the built-in layout.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get layoutDefault;

  /// No description provided for @layoutDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Two-players, agenda points for both sides, tags and MU for the Runner'**
  String get layoutDefaultSubtitle;

  /// Settings: shown under Layouts when the current setup doesn't match the loaded layout.
  ///
  /// In en, this message translates to:
  /// **'Custom Layout'**
  String get layoutCustom;

  /// No description provided for @layoutCorpSolo.
  ///
  /// In en, this message translates to:
  /// **'Corp Solo'**
  String get layoutCorpSolo;

  /// No description provided for @layoutCorpSoloSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-player as the Corp, with core damage instead of MU'**
  String get layoutCorpSoloSubtitle;

  /// No description provided for @layoutRunnerSolo.
  ///
  /// In en, this message translates to:
  /// **'Runner Solo'**
  String get layoutRunnerSolo;

  /// No description provided for @layoutRunnerSoloSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-player as the Runner, with bad publicity on the Corp'**
  String get layoutRunnerSoloSubtitle;

  /// No description provided for @deleteLayout.
  ///
  /// In en, this message translates to:
  /// **'Delete layout'**
  String get deleteLayout;

  /// No description provided for @deleteLayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteLayoutTitle(String name);

  /// No description provided for @deleteLayoutBody.
  ///
  /// In en, this message translates to:
  /// **'The saved layout is removed. The current game, settings and counters aren\'t affected.'**
  String get deleteLayoutBody;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @saveAsNewLayout.
  ///
  /// In en, this message translates to:
  /// **'Save as new layout'**
  String get saveAsNewLayout;

  /// No description provided for @updateLayoutButton.
  ///
  /// In en, this message translates to:
  /// **'Update \"{name}\"'**
  String updateLayoutButton(String name);

  /// No description provided for @updateLayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Update \"{name}\"?'**
  String updateLayoutTitle(String name);

  /// No description provided for @updateLayoutBody.
  ///
  /// In en, this message translates to:
  /// **'Replaces this layout\'s saved settings and counters with the current ones.'**
  String get updateLayoutBody;

  /// No description provided for @loadLayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Load \"{name}\"?'**
  String loadLayoutTitle(String name);

  /// Followed by a list of what will change (settings and counters).
  ///
  /// In en, this message translates to:
  /// **'Loading this layout changes:'**
  String get loadLayoutBody;

  /// Layout change list: the layout has different counters than now.
  ///
  /// In en, this message translates to:
  /// **'Counters (added or removed)'**
  String get changeCounters;

  /// Layout change list: same counters, different order.
  ///
  /// In en, this message translates to:
  /// **'Counter positions'**
  String get changeCounterOrder;

  /// Layout change list: a counter's saved maximum differs.
  ///
  /// In en, this message translates to:
  /// **'Counter maximums (MU, recurring credits)'**
  String get changeCounterMax;

  /// No description provided for @saveLayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Save layout'**
  String get saveLayoutTitle;

  /// No description provided for @saveLayoutBody.
  ///
  /// In en, this message translates to:
  /// **'Saves the current settings and counters (not their values).'**
  String get saveLayoutBody;

  /// No description provided for @layoutName.
  ///
  /// In en, this message translates to:
  /// **'Layout name'**
  String get layoutName;

  /// No description provided for @layoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get layoutDescription;

  /// No description provided for @editLayoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit description'**
  String get editLayoutDescription;

  /// No description provided for @editDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Description of \"{name}\"'**
  String editDescriptionTitle(String name);

  /// No description provided for @layoutNameIsBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'That\'s a built-in layout'**
  String get layoutNameIsBuiltIn;

  /// No description provided for @layoutReplacesExisting.
  ///
  /// In en, this message translates to:
  /// **'Replaces the existing layout'**
  String get layoutReplacesExisting;

  /// No description provided for @onePlayerMode.
  ///
  /// In en, this message translates to:
  /// **'One-player mode'**
  String get onePlayerMode;

  /// No description provided for @onePlayerModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track only one side (End turn / Start turn)'**
  String get onePlayerModeSubtitle;

  /// One-player mode: which side is tracked (only shown in the layout change list).
  ///
  /// In en, this message translates to:
  /// **'Tracked side'**
  String get trackedSide;

  /// No description provided for @showOpponentCounters.
  ///
  /// In en, this message translates to:
  /// **'Show opponent\'s counters'**
  String get showOpponentCounters;

  /// No description provided for @showOpponentCountersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A strip of the opponent\'s counters above yours'**
  String get showOpponentCountersSubtitle;

  /// No description provided for @autoEndTurn.
  ///
  /// In en, this message translates to:
  /// **'Automatically end turn when clicks are exhausted'**
  String get autoEndTurn;

  /// No description provided for @agendaToWin.
  ///
  /// In en, this message translates to:
  /// **'Agenda points to win'**
  String get agendaToWin;

  /// No description provided for @creditIconFrom.
  ///
  /// In en, this message translates to:
  /// **'5-credits icon'**
  String get creditIconFrom;

  /// No description provided for @creditIconFromSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Credits at which the credit icon switches'**
  String get creditIconFromSubtitle;

  /// No description provided for @creditIconSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the 5-credits icon instead of the credit icon from a set amount'**
  String get creditIconSubtitle;

  /// 5-credits icon: the number of credits it switches at (0 = always). Also shown as "5-credits icon: Switch at" in the layout change list.
  ///
  /// In en, this message translates to:
  /// **'Switch at'**
  String get creditIconAt;

  /// No description provided for @creditAnimation.
  ///
  /// In en, this message translates to:
  /// **'Credit animation'**
  String get creditAnimation;

  /// No description provided for @creditAnimationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Modifying credits plays a floating animation'**
  String get creditAnimationSubtitle;

  /// No description provided for @counterButtons.
  ///
  /// In en, this message translates to:
  /// **'Show counter +/- buttons'**
  String get counterButtons;

  /// No description provided for @counterButtonsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adds +/- buttons to every counter. Counters get wider, so with many counters they may need more rows and scrolling.'**
  String get counterButtonsSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @corpColour.
  ///
  /// In en, this message translates to:
  /// **'Corp colour'**
  String get corpColour;

  /// No description provided for @runnerColour.
  ///
  /// In en, this message translates to:
  /// **'Runner colour'**
  String get runnerColour;

  /// The (+) button after the colour swatches, and the colour picker's title.
  ///
  /// In en, this message translates to:
  /// **'Custom colour'**
  String get customColour;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @colourHex.
  ///
  /// In en, this message translates to:
  /// **'Hex'**
  String get colourHex;

  /// Colour picker channel labels (one or two letters): red, green, blue, hue, saturation, lightness.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get colourRed;

  /// No description provided for @colourGreen.
  ///
  /// In en, this message translates to:
  /// **'G'**
  String get colourGreen;

  /// No description provided for @colourBlue.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get colourBlue;

  /// No description provided for @colourHue.
  ///
  /// In en, this message translates to:
  /// **'H'**
  String get colourHue;

  /// No description provided for @colourSaturation.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get colourSaturation;

  /// No description provided for @colourLightness.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get colourLightness;

  /// Custom colour dialog, bottom-left button: switch back to the 2D picker.
  ///
  /// In en, this message translates to:
  /// **'Colour picker'**
  String get colourModePicker;

  /// Custom colour dialog, bottom-left button: switch to the hex, RGB and HSL inputs.
  ///
  /// In en, this message translates to:
  /// **'Hex / RGB / HSL'**
  String get colourModeValues;

  /// No description provided for @corpFactionGlyph.
  ///
  /// In en, this message translates to:
  /// **'Corp faction glyph (background)'**
  String get corpFactionGlyph;

  /// No description provided for @runnerFactionGlyph.
  ///
  /// In en, this message translates to:
  /// **'Runner faction glyph (background)'**
  String get runnerFactionGlyph;

  /// No description provided for @factionNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get factionNone;

  /// No description provided for @corpFont.
  ///
  /// In en, this message translates to:
  /// **'Corp font'**
  String get corpFont;

  /// No description provided for @runnerFont.
  ///
  /// In en, this message translates to:
  /// **'Runner font'**
  String get runnerFont;

  /// Font setting: the default font (the app's own). Other fonts are listed in lib/netrunner/fonts.dart by their own names.
  ///
  /// In en, this message translates to:
  /// **'Default (Urbanist)'**
  String get fontDefault;

  /// No description provided for @dragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag: Long-press a counter and drag it to reorder or remove'**
  String get dragHint;

  /// No description provided for @noCountersYet.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get noCountersYet;

  /// No description provided for @noCountersYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Agenda points, bad publicity, tags, core damage, MU, max hand size, recurring credits, virus, advancement and generic counters'**
  String get noCountersYetSubtitle;

  /// Settings list of added counters: side and counter type.
  ///
  /// In en, this message translates to:
  /// **'{side} · {type}'**
  String addedCounterSubtitle(String side, String type);

  /// No description provided for @removeAllCounters.
  ///
  /// In en, this message translates to:
  /// **'Remove all counters'**
  String get removeAllCounters;

  /// No description provided for @addCountersTitle.
  ///
  /// In en, this message translates to:
  /// **'Add counters'**
  String get addCountersTitle;

  /// No description provided for @runnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Runner only'**
  String get runnerOnly;

  /// No description provided for @corpOnly.
  ///
  /// In en, this message translates to:
  /// **'Corp only'**
  String get corpOnly;

  /// No description provided for @alreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Already added'**
  String get alreadyAdded;

  /// No description provided for @nameOptional.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get nameOptional;

  /// No description provided for @nameNeedsSingle.
  ///
  /// In en, this message translates to:
  /// **'Select a single counter to name it'**
  String get nameNeedsSingle;

  /// No description provided for @counterAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda points'**
  String get counterAgenda;

  /// Add counters list: one line on what a counter does. Same for the other *Hint strings.
  ///
  /// In en, this message translates to:
  /// **'Reaching the target wins the game'**
  String get counterAgendaHint;

  /// No description provided for @counterBadPublicityHint.
  ///
  /// In en, this message translates to:
  /// **'Shows the Run button. Runs move this many credits from the Corp to the Runner'**
  String get counterBadPublicityHint;

  /// No description provided for @counterCoreDamageHint.
  ///
  /// In en, this message translates to:
  /// **'Each point lowers max hand size by 1'**
  String get counterCoreDamageHint;

  /// No description provided for @counterHandSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Starts at 5, minus core damage'**
  String get counterHandSizeHint;

  /// No description provided for @counterRecurringCreditHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to spend. Refills at the start of your turn'**
  String get counterRecurringCreditHint;

  /// No description provided for @counterBadPublicity.
  ///
  /// In en, this message translates to:
  /// **'Bad publicity'**
  String get counterBadPublicity;

  /// No description provided for @counterTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get counterTags;

  /// No description provided for @counterCoreDamage.
  ///
  /// In en, this message translates to:
  /// **'Core damage'**
  String get counterCoreDamage;

  /// No description provided for @counterMu.
  ///
  /// In en, this message translates to:
  /// **'Memory units (MU)'**
  String get counterMu;

  /// No description provided for @counterHandSize.
  ///
  /// In en, this message translates to:
  /// **'Max hand size'**
  String get counterHandSize;

  /// No description provided for @counterRecurringCredit.
  ///
  /// In en, this message translates to:
  /// **'Recurring credits'**
  String get counterRecurringCredit;

  /// No description provided for @counterGenericBlue.
  ///
  /// In en, this message translates to:
  /// **'Generic counter (blue)'**
  String get counterGenericBlue;

  /// No description provided for @counterGenericGreen.
  ///
  /// In en, this message translates to:
  /// **'Generic counter (green)'**
  String get counterGenericGreen;

  /// No description provided for @counterVirus.
  ///
  /// In en, this message translates to:
  /// **'Virus counter'**
  String get counterVirus;

  /// No description provided for @counterAdvancement.
  ///
  /// In en, this message translates to:
  /// **'Advancement counter'**
  String get counterAdvancement;

  /// No description provided for @counterAdvancementReverse.
  ///
  /// In en, this message translates to:
  /// **'Advancement counter (reverse)'**
  String get counterAdvancementReverse;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
