import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInTitle;

  /// No description provided for @signInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in via the magic link with your email below'**
  String get signInPrompt;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get emailRequired;

  /// No description provided for @sendMagicLink.
  ///
  /// In en, this message translates to:
  /// **'Send Magic Link'**
  String get sendMagicLink;

  /// Sign-in button label while the magic link is being sent
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get sendingMagicLink;

  /// No description provided for @magicLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email for login link!'**
  String get magicLinkSent;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @userNameLabel.
  ///
  /// In en, this message translates to:
  /// **'User Name'**
  String get userNameLabel;

  /// No description provided for @websiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get websiteLabel;

  /// Button that saves the profile
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateProfile;

  /// No description provided for @savingProfile.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingProfile;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Successfully updated profile!'**
  String get profileUpdated;

  /// No description provided for @avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated your profile image!'**
  String get avatarUpdated;

  /// Tasks page title and the profile button that opens it
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get myTasks;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Placeholder shown when the user has no profile image
  ///
  /// In en, this message translates to:
  /// **'No Image'**
  String get noAvatar;

  /// No description provided for @uploadAvatar.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get uploadAvatar;

  /// No description provided for @avatarWrongType.
  ///
  /// In en, this message translates to:
  /// **'Use a JPEG, PNG or WebP image.'**
  String get avatarWrongType;

  /// No description provided for @avatarTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Images must be 1 MB or smaller.'**
  String get avatarTooLarge;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Add-task button tooltip and the add-task dialog title
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet. Tap + to add one, then link tasks that must be finished first.'**
  String get noTasks;

  /// No description provided for @sectionInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress ({count})'**
  String sectionInProgress(int count);

  /// No description provided for @sectionReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to start ({count})'**
  String sectionReady(int count);

  /// No description provided for @sectionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked ({count})'**
  String sectionBlocked(int count);

  /// No description provided for @sectionDone.
  ///
  /// In en, this message translates to:
  /// **'Done ({count})'**
  String sectionDone(int count);

  /// No description provided for @taskDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String taskDue(DateTime date);

  /// Unfinished tasks this task depends on
  ///
  /// In en, this message translates to:
  /// **'Waiting on: {titles}'**
  String waitingOn(String titles);

  /// No description provided for @dependsOn.
  ///
  /// In en, this message translates to:
  /// **'Depends on: {titles}'**
  String dependsOn(String titles);

  /// No description provided for @taskActions.
  ///
  /// In en, this message translates to:
  /// **'Task actions'**
  String get taskActions;

  /// No description provided for @statusTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get statusTodo;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @moveToTodo.
  ///
  /// In en, this message translates to:
  /// **'Move back to To do'**
  String get moveToTodo;

  /// Menu action that moves a task to In progress
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startTask;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get markDone;

  /// No description provided for @editDependencies.
  ///
  /// In en, this message translates to:
  /// **'Edit dependencies…'**
  String get editDependencies;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTask;

  /// No description provided for @startedButBlocked.
  ///
  /// In en, this message translates to:
  /// **'Started, but a dependency is no longer done'**
  String get startedButBlocked;

  /// No description provided for @deleteTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deleteTaskTitle(String title);

  /// No description provided for @deleteCannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get deleteCannotUndo;

  /// No description provided for @deleteAlsoUnlinks.
  ///
  /// In en, this message translates to:
  /// **'It will also be removed as a dependency from {titles}. This can\'t be undone.'**
  String deleteAlsoUnlinks(String titles);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @taskTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get taskTitleLabel;

  /// No description provided for @taskDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get taskDescriptionLabel;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @clearDueDate.
  ///
  /// In en, this message translates to:
  /// **'Clear due date'**
  String get clearDueDate;

  /// No description provided for @pickDueDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDueDate;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addTask;

  /// Title of the dialog that picks the tasks this task depends on
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is blocked by'**
  String dependenciesTitle(String title);

  /// No description provided for @noDependencyCandidates.
  ///
  /// In en, this message translates to:
  /// **'No other tasks can be linked without creating a loop. Add more tasks first.'**
  String get noDependencyCandidates;

  /// No description provided for @saveDependencies.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveDependencies;

  /// Why a task can't start or finish. Matches the database trigger's message.
  ///
  /// In en, this message translates to:
  /// **'Blocked by {titles}'**
  String blockedBy(String titles);

  /// Why a done task can't go back to To do. Matches the database trigger's message.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reopen: {titles} already started'**
  String cantReopen(String titles);

  /// No description provided for @dependenciesNotFinished.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" has already started, so it can only depend on finished tasks. Not finished: {titles}'**
  String dependenciesNotFinished(String title, String titles);

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your connection and try again.'**
  String get offline;
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
      <String>['de', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
