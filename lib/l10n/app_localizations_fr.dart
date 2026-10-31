// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get signInTitle => 'Connexion';

  @override
  String get signInPrompt =>
      'Saisissez votre adresse e-mail ci-dessous et nous vous enverrons un lien de connexion';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get emailRequired => 'Saisissez votre adresse e-mail';

  @override
  String get sendMagicLink => 'Envoyer le lien de connexion';

  @override
  String get sendingMagicLink => 'Envoi en cours…';

  @override
  String get magicLinkSent =>
      'Veuillez consulter votre e-mail pour trouver votre lien de connexion.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get userNameLabel => 'Nom d\'utilisateur';

  @override
  String get websiteLabel => 'Site web';

  @override
  String get updateProfile => 'Mettre à jour';

  @override
  String get savingProfile => 'Enregistrement…';

  @override
  String get profileUpdated => 'Profil mis à jour avec succès !';

  @override
  String get avatarUpdated => 'Votre image de profil a été mise à jour !';

  @override
  String get myTasks => 'Mes tâches';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get noAvatar => 'Aucune image';

  @override
  String get uploadAvatar => 'Téléverser';

  @override
  String get avatarWrongType => 'Utilisez une image JPEG, PNG ou WebP.';

  @override
  String get avatarTooLarge => 'Les images ne doivent pas dépasser 1 Mo.';

  @override
  String get refresh => 'Actualiser';

  @override
  String get newTask => 'Nouvelle tâche';

  @override
  String get noTasks =>
      'Aucune tâche pour le moment. Appuyez sur + pour en ajouter une, puis liez les tâches qui doivent être terminées en premier.';

  @override
  String sectionInProgress(int count) {
    return 'En cours ($count)';
  }

  @override
  String sectionReady(int count) {
    return 'Prêtes à démarrer ($count)';
  }

  @override
  String sectionBlocked(int count) {
    return 'Bloquées ($count)';
  }

  @override
  String sectionDone(int count) {
    return 'Terminées ($count)';
  }

  @override
  String taskDue(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Échéance : $dateString';
  }

  @override
  String waitingOn(String titles) {
    return 'En attente de : $titles';
  }

  @override
  String dependsOn(String titles) {
    return 'Dépend de : $titles';
  }

  @override
  String get taskActions => 'Actions de la tâche';

  @override
  String get statusTodo => 'À faire';

  @override
  String get statusInProgress => 'En cours';

  @override
  String get statusDone => 'Terminée';

  @override
  String get moveToTodo => 'Remettre dans À faire';

  @override
  String get startTask => 'Démarrer';

  @override
  String get markDone => 'Marquer comme terminée';

  @override
  String get editDependencies => 'Modifier les dépendances…';

  @override
  String get deleteTask => 'Supprimer';

  @override
  String get startedButBlocked =>
      'Démarrée, mais une dépendance n\'est plus terminée';

  @override
  String deleteTaskTitle(String title) {
    return 'Supprimer « $title » ?';
  }

  @override
  String get deleteCannotUndo => 'Cette action est irréversible.';

  @override
  String deleteAlsoUnlinks(String titles) {
    return 'Elle sera également retirée des dépendances de $titles. Cette action est irréversible.';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get taskTitleLabel => 'Titre';

  @override
  String get taskDescriptionLabel => 'Description (facultatif)';

  @override
  String get noDueDate => 'Aucune échéance';

  @override
  String get clearDueDate => 'Effacer l\'échéance';

  @override
  String get pickDueDate => 'Choisir une date';

  @override
  String get addTask => 'Ajouter';

  @override
  String dependenciesTitle(String title) {
    return '« $title » est bloquée par';
  }

  @override
  String get noDependencyCandidates =>
      'Aucune autre tâche ne peut être liée sans créer de boucle. Ajoutez d\'abord d\'autres tâches.';

  @override
  String get saveDependencies => 'Enregistrer';

  @override
  String dependenciesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tâches sélectionnées',
      many: '$count de tâches sélectionnées',
      one: '$count tâche sélectionnée',
      zero: 'Aucune tâche sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String blockedBy(String titles) {
    return 'Bloquée par $titles';
  }

  @override
  String cantReopen(String titles) {
    return 'Impossible de rouvrir : $titles a déjà démarré';
  }

  @override
  String dependenciesNotFinished(String title, String titles) {
    return '« $title » a déjà démarré ; elle ne peut donc dépendre que de tâches terminées. Non terminées : $titles';
  }

  @override
  String get offline =>
      'Impossible de joindre le serveur. Vérifiez votre connexion et réessayez.';

  @override
  String get errorUsernameTaken =>
      'Ce nom d\'utilisateur est déjà pris. Essayez-en un autre.';

  @override
  String get errorOutOfDate =>
      'Vos tâches ont été modifiées ailleurs, cette modification n\'est donc plus autorisée. Actualisez la liste et réessayez.';

  @override
  String get errorPermissionDenied =>
      'Vous n\'avez pas l\'autorisation d\'effectuer cette action.';

  @override
  String get errorSessionExpired =>
      'Votre session a expiré. Déconnectez-vous, puis reconnectez-vous.';

  @override
  String get errorLinkExpired =>
      'Ce lien de connexion a expiré ou a déjà été utilisé. Demandez-en un nouveau.';

  @override
  String get errorTooManyRequests =>
      'Trop de tentatives. Patientez une minute, puis réessayez.';

  @override
  String get errorInvalidEmail => 'Cette adresse e-mail n\'est pas valide.';
}
