// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get signInTitle => 'Iniciar sesión';

  @override
  String get signInPrompt =>
      'Inicia sesión con un enlace enviado a tu correo electrónico a continuación';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get emailRequired => 'Introduce tu dirección de correo electrónico';

  @override
  String get sendMagicLink => 'Enviar enlace de inicio de sesión';

  @override
  String get sendingMagicLink => 'Enviando…';

  @override
  String get magicLinkSent =>
      'Revisa tu correo para ver el enlace de inicio de sesión.';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get userNameLabel => 'Nombre de usuario';

  @override
  String get websiteLabel => 'Sitio web';

  @override
  String get updateProfile => 'Actualizar';

  @override
  String get savingProfile => 'Guardando…';

  @override
  String get profileUpdated => '¡Perfil actualizado correctamente!';

  @override
  String get avatarUpdated => '¡Se ha actualizado tu imagen de perfil!';

  @override
  String get myTasks => 'Mis tareas';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get noAvatar => 'Sin imagen';

  @override
  String get uploadAvatar => 'Subir';

  @override
  String get avatarWrongType => 'Usa una imagen JPEG, PNG o WebP.';

  @override
  String get avatarTooLarge => 'Las imágenes deben pesar 1 MB o menos.';

  @override
  String get refresh => 'Actualizar';

  @override
  String get newTask => 'Nueva tarea';

  @override
  String get noTasks =>
      'Aún no hay tareas. Toca + para añadir una y luego vincula las tareas que deben terminarse antes.';

  @override
  String sectionInProgress(int count) {
    return 'En curso ($count)';
  }

  @override
  String sectionReady(int count) {
    return 'Listas para empezar ($count)';
  }

  @override
  String sectionBlocked(int count) {
    return 'Bloqueadas ($count)';
  }

  @override
  String sectionDone(int count) {
    return 'Hechas ($count)';
  }

  @override
  String taskDue(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Vence el $dateString';
  }

  @override
  String waitingOn(String titles) {
    return 'A la espera de: $titles';
  }

  @override
  String dependsOn(String titles) {
    return 'Depende de: $titles';
  }

  @override
  String get taskActions => 'Acciones de la tarea';

  @override
  String get statusTodo => 'Por hacer';

  @override
  String get statusInProgress => 'En curso';

  @override
  String get statusDone => 'Hecha';

  @override
  String get moveToTodo => 'Volver a Por hacer';

  @override
  String get startTask => 'Iniciar';

  @override
  String get markDone => 'Marcar como hecha';

  @override
  String get editDependencies => 'Editar dependencias…';

  @override
  String get deleteTask => 'Eliminar';

  @override
  String get startedButBlocked =>
      'Iniciada, pero una dependencia ya no está terminada';

  @override
  String deleteTaskTitle(String title) {
    return '¿Eliminar \"$title\"?';
  }

  @override
  String get deleteCannotUndo => 'Esta acción no se puede deshacer.';

  @override
  String deleteAlsoUnlinks(String titles) {
    return 'También se quitará como dependencia de $titles. Esta acción no se puede deshacer.';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get taskTitleLabel => 'Título';

  @override
  String get taskDescriptionLabel => 'Descripción (opcional)';

  @override
  String get noDueDate => 'Sin fecha de vencimiento';

  @override
  String get clearDueDate => 'Borrar fecha de vencimiento';

  @override
  String get pickDueDate => 'Elegir fecha';

  @override
  String get addTask => 'Añadir';

  @override
  String dependenciesTitle(String title) {
    return '\"$title\" está bloqueada por';
  }

  @override
  String get noDependencyCandidates =>
      'No se puede vincular ninguna otra tarea sin crear un bucle. Añade más tareas primero.';

  @override
  String get saveDependencies => 'Guardar';

  @override
  String blockedBy(String titles) {
    return 'Bloqueada por $titles';
  }

  @override
  String cantReopen(String titles) {
    return 'No se puede reabrir: $titles ya ha empezado';
  }

  @override
  String dependenciesNotFinished(String title, String titles) {
    return '\"$title\" ya ha empezado, por lo que solo puede depender de tareas terminadas. Sin terminar: $titles';
  }

  @override
  String get offline =>
      'No se pudo conectar con el servidor. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get errorUsernameTaken =>
      'Ese nombre de usuario ya está en uso. Prueba con otro.';

  @override
  String get errorOutOfDate =>
      'Tus tareas cambiaron en otro lugar, así que ese cambio ya no se permite. Actualiza e inténtalo de nuevo.';

  @override
  String get errorPermissionDenied => 'No tienes permiso para hacer eso.';

  @override
  String get errorSessionExpired =>
      'Tu sesión ha caducado. Cierra sesión e inicia sesión de nuevo.';

  @override
  String get errorLinkExpired =>
      'Ese enlace de inicio de sesión ha caducado o ya se usó. Solicita uno nuevo.';

  @override
  String get errorTooManyRequests =>
      'Demasiados intentos. Espera un minuto e inténtalo de nuevo.';

  @override
  String get errorInvalidEmail => 'Ese correo electrónico no es válido.';
}
