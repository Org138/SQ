// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get signInTitle => 'Sign In';

  @override
  String get signInPrompt => 'Sign in with a link sent to your email below';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailRequired => 'Enter your email address';

  @override
  String get sendMagicLink => 'Send sign-in link';

  @override
  String get sendingMagicLink => 'Sending…';

  @override
  String get magicLinkSent => 'Check your email for a sign-in link.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get userNameLabel => 'User Name';

  @override
  String get websiteLabel => 'Website';

  @override
  String get updateProfile => 'Update';

  @override
  String get savingProfile => 'Saving…';

  @override
  String get profileUpdated => 'Successfully updated profile!';

  @override
  String get avatarUpdated => 'Updated your profile image!';

  @override
  String get myTasks => 'My Tasks';

  @override
  String get signOut => 'Sign Out';

  @override
  String get noAvatar => 'No Image';

  @override
  String get uploadAvatar => 'Upload';

  @override
  String get avatarWrongType => 'Use a JPEG, PNG or WebP image.';

  @override
  String get avatarTooLarge => 'Images must be 1 MB or smaller.';

  @override
  String get refresh => 'Refresh';

  @override
  String get newTask => 'New task';

  @override
  String get noTasks =>
      'No tasks yet. Tap + to add one, then link tasks that must be finished first.';

  @override
  String sectionInProgress(int count) {
    return 'In progress ($count)';
  }

  @override
  String sectionReady(int count) {
    return 'Ready to start ($count)';
  }

  @override
  String sectionBlocked(int count) {
    return 'Blocked ($count)';
  }

  @override
  String sectionDone(int count) {
    return 'Done ($count)';
  }

  @override
  String taskDue(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Due $dateString';
  }

  @override
  String waitingOn(String titles) {
    return 'Waiting on: $titles';
  }

  @override
  String dependsOn(String titles) {
    return 'Depends on: $titles';
  }

  @override
  String get taskActions => 'Task actions';

  @override
  String get statusTodo => 'To do';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusDone => 'Done';

  @override
  String get moveToTodo => 'Move back to To do';

  @override
  String get startTask => 'Start';

  @override
  String get markDone => 'Mark done';

  @override
  String get editDependencies => 'Edit dependencies…';

  @override
  String get deleteTask => 'Delete';

  @override
  String get startedButBlocked => 'Started, but a dependency is no longer done';

  @override
  String deleteTaskTitle(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get deleteCannotUndo => 'This can\'t be undone.';

  @override
  String deleteAlsoUnlinks(String titles) {
    return 'It will also be removed as a dependency from $titles. This can\'t be undone.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get taskTitleLabel => 'Title';

  @override
  String get taskDescriptionLabel => 'Description (optional)';

  @override
  String get noDueDate => 'No due date';

  @override
  String get clearDueDate => 'Clear due date';

  @override
  String get pickDueDate => 'Pick date';

  @override
  String get addTask => 'Add';

  @override
  String dependenciesTitle(String title) {
    return '\"$title\" is blocked by';
  }

  @override
  String get noDependencyCandidates =>
      'No other tasks can be linked without creating a loop. Add more tasks first.';

  @override
  String get saveDependencies => 'Save';

  @override
  String blockedBy(String titles) {
    return 'Blocked by $titles';
  }

  @override
  String cantReopen(String titles) {
    return 'Can\'t reopen: $titles already started';
  }

  @override
  String dependenciesNotFinished(String title, String titles) {
    return '\"$title\" has already started, so it can only depend on finished tasks. Not finished: $titles';
  }

  @override
  String get offline =>
      'Couldn\'t reach the server. Check your connection and try again.';

  @override
  String get errorUsernameTaken => 'That user name is taken. Try another one.';

  @override
  String get errorOutOfDate =>
      'Your tasks changed somewhere else, so that change isn\'t allowed anymore. Refresh and try again.';

  @override
  String get errorPermissionDenied => 'You don\'t have permission to do that.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Sign out and sign in again.';

  @override
  String get errorLinkExpired =>
      'That sign-in link has expired or was already used. Request a new one.';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Wait a minute and try again.';

  @override
  String get errorInvalidEmail => 'That email address isn\'t valid.';
}
