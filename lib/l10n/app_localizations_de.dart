// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get signInTitle => 'Anmelden';

  @override
  String get signInPrompt =>
      'Melde dich unten mit deiner E-Mail-Adresse über den Magic Link an';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get emailRequired => 'Gib deine E-Mail-Adresse ein';

  @override
  String get sendMagicLink => 'Magic Link senden';

  @override
  String get sendingMagicLink => 'Wird geladen';

  @override
  String get magicLinkSent => 'Prüfe dein E-Mail-Postfach auf den Anmeldelink!';

  @override
  String get profileTitle => 'Profil';

  @override
  String get userNameLabel => 'Benutzername';

  @override
  String get websiteLabel => 'Website';

  @override
  String get updateProfile => 'Aktualisieren';

  @override
  String get savingProfile => 'Wird gespeichert …';

  @override
  String get profileUpdated => 'Profil erfolgreich aktualisiert!';

  @override
  String get avatarUpdated => 'Dein Profilbild wurde aktualisiert!';

  @override
  String get myTasks => 'Meine Aufgaben';

  @override
  String get signOut => 'Abmelden';

  @override
  String get noAvatar => 'Kein Bild';

  @override
  String get uploadAvatar => 'Hochladen';

  @override
  String get avatarWrongType => 'Verwende ein JPEG-, PNG- oder WebP-Bild.';

  @override
  String get avatarTooLarge => 'Bilder dürfen höchstens 1 MB groß sein.';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get newTask => 'Neue Aufgabe';

  @override
  String get noTasks =>
      'Noch keine Aufgaben. Tippe auf +, um eine hinzuzufügen, und verknüpfe dann Aufgaben, die zuerst erledigt werden müssen.';

  @override
  String sectionInProgress(int count) {
    return 'In Bearbeitung ($count)';
  }

  @override
  String sectionReady(int count) {
    return 'Bereit zum Start ($count)';
  }

  @override
  String sectionBlocked(int count) {
    return 'Blockiert ($count)';
  }

  @override
  String sectionDone(int count) {
    return 'Erledigt ($count)';
  }

  @override
  String taskDue(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Fällig am $dateString';
  }

  @override
  String waitingOn(String titles) {
    return 'Wartet auf: $titles';
  }

  @override
  String dependsOn(String titles) {
    return 'Abhängig von: $titles';
  }

  @override
  String get taskActions => 'Aufgabenaktionen';

  @override
  String get statusTodo => 'Zu erledigen';

  @override
  String get statusInProgress => 'In Bearbeitung';

  @override
  String get statusDone => 'Erledigt';

  @override
  String get moveToTodo => 'Zurück zu „Zu erledigen“ verschieben';

  @override
  String get startTask => 'Starten';

  @override
  String get markDone => 'Als erledigt markieren';

  @override
  String get editDependencies => 'Abhängigkeiten bearbeiten …';

  @override
  String get deleteTask => 'Löschen';

  @override
  String get startedButBlocked =>
      'Gestartet, aber eine Abhängigkeit ist nicht mehr erledigt';

  @override
  String deleteTaskTitle(String title) {
    return '„$title“ löschen?';
  }

  @override
  String get deleteCannotUndo => 'Dies kann nicht rückgängig gemacht werden.';

  @override
  String deleteAlsoUnlinks(String titles) {
    return 'Die Aufgabe wird außerdem als Abhängigkeit aus $titles entfernt. Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get taskTitleLabel => 'Titel';

  @override
  String get taskDescriptionLabel => 'Beschreibung (optional)';

  @override
  String get noDueDate => 'Kein Fälligkeitsdatum';

  @override
  String get clearDueDate => 'Fälligkeitsdatum entfernen';

  @override
  String get pickDueDate => 'Datum auswählen';

  @override
  String get addTask => 'Hinzufügen';

  @override
  String dependenciesTitle(String title) {
    return '„$title“ wird blockiert von';
  }

  @override
  String get noDependencyCandidates =>
      'Es können keine weiteren Aufgaben verknüpft werden, ohne eine Schleife zu erzeugen. Füge zuerst weitere Aufgaben hinzu.';

  @override
  String get saveDependencies => 'Speichern';

  @override
  String blockedBy(String titles) {
    return 'Blockiert von $titles';
  }

  @override
  String cantReopen(String titles) {
    return 'Kann nicht erneut geöffnet werden: $titles bereits gestartet';
  }

  @override
  String dependenciesNotFinished(String title, String titles) {
    return '„$title“ wurde bereits gestartet und kann daher nur von erledigten Aufgaben abhängen. Nicht erledigt: $titles';
  }

  @override
  String get offline =>
      'Der Server ist nicht erreichbar. Prüfe deine Verbindung und versuche es erneut.';

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
