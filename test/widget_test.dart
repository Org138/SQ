// Widget tests for the dependency-gated tasks page, run against a fake
// Supabase REST backend (no network) with a signed-in test session.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqproject/l10n/app_localizations.dart';
import 'package:sqproject/pages/tasks_page.dart';

/// In-memory stand-in for the `tasks` and `task_dependencies` tables.
class FakeBackend {
  final tasks = <Map<String, dynamic>>[
    {
      'id': 'a',
      'title': 'A',
      'description': null,
      'status': 'todo',
      'due_date': null
    },
    {
      'id': 'b',
      'title': 'B',
      'description': null,
      'status': 'in_progress',
      'due_date': null
    },
    {
      'id': 'c',
      'title': 'C',
      'description': null,
      'status': 'done',
      'due_date': null
    },
  ];

  /// A is blocked by B.
  final dependencies = <Map<String, dynamic>>[
    {'task_id': 'a', 'depends_on_task_id': 'b'},
  ];

  final inserts = <http.Request>[];
  final patches = <http.Request>[];

  /// Number of reads, to check writes don't trigger a reload.
  var gets = 0;

  /// When set, PATCH requests fail with this database error message.
  String? rejectPatchesWith;

  Future<http.Response> handle(http.Request request) async {
    final json = {'content-type': 'application/json'};

    // Writes return the saved rows (`.select()`), as one object when the
    // client asked for a single row (`.single()`).
    http.Response rows(List<Map<String, dynamic>> rows) {
      final single =
          request.headers['Accept']?.contains('vnd.pgrst.object') ?? false;
      return http.Response(jsonEncode(single ? rows.single : rows), 200,
          headers: json, request: request);
    }

    if (request.method == 'GET') gets++;
    switch ((request.method, request.url.path)) {
      case ('GET', '/rest/v1/tasks'):
        return http.Response(jsonEncode(tasks), 200,
            headers: json, request: request);
      case ('GET', '/rest/v1/task_dependencies'):
        return http.Response(jsonEncode(dependencies), 200,
            headers: json, request: request);
      case ('POST', '/rest/v1/tasks'):
        inserts.add(request);
        final task = {
          'id': 'new-${tasks.length}',
          'description': null,
          'status': 'todo',
          'due_date': null,
          ...jsonDecode(request.body) as Map<String, dynamic>,
        };
        tasks.add(task);
        return rows([task]);
      case ('DELETE', '/rest/v1/tasks'):
        final id = request.url.queryParameters['id']!.replaceFirst('eq.', '');
        tasks.removeWhere((t) => t['id'] == id);
        dependencies.removeWhere(
            (d) => d['task_id'] == id || d['depends_on_task_id'] == id);
        return rows([
          {'id': id}
        ]);
      case ('PATCH', '/rest/v1/tasks'):
        patches.add(request);
        if (rejectPatchesWith != null) {
          return http.Response(
            jsonEncode({'code': '23514', 'message': rejectPatchesWith}),
            400,
            headers: json,
            request: request,
          );
        }
        final id = request.url.queryParameters['id']!.replaceFirst('eq.', '');
        final task = tasks.firstWhere((t) => t['id'] == id)
          ..addAll(jsonDecode(request.body) as Map<String, dynamic>);
        return rows([task]);
    }
    return http.Response('Unexpected ${request.method} ${request.url}', 404,
        request: request);
  }
}

/// PKCE storage kept in memory so tests don't need platform plugins.
class MemoryAsyncStorage extends GotrueAsyncStorage {
  final _items = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _items[key];

  @override
  Future<void> removeItem({required String key}) async => _items.remove(key);

  @override
  Future<void> setItem({required String key, required String value}) async =>
      _items[key] = value;
}

late FakeBackend backend;

final en = lookupAppLocalizations(const Locale('en'));

Future<void> pumpTasksPage(WidgetTester tester, {Locale? locale}) async {
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const TasksPage(),
    routes: {'/login': (_) => const Scaffold(body: Text('login'))},
  ));
  await tester.pumpAndSettle();
}

/// Opens the actions menu on the task titled [title].
Future<void> openMenu(WidgetTester tester, String title,
    {AppLocalizations? l10n}) async {
  final tile =
      find.ancestor(of: find.text(title), matching: find.byType(ListTile));
  await tester.tap(find.descendant(
      of: tile, matching: find.byTooltip((l10n ?? en).taskActions)));
  await tester.pumpAndSettle();
}

/// Picks the 15th of the current month in the new-task dialog's date
/// picker, and returns that date.
Future<DateTime> pickDueDate(WidgetTester tester,
    [AppLocalizations? l10n]) async {
  await tester.tap(find.text((l10n ?? en).pickDueDate));
  await tester.pumpAndSettle();
  await tester.tap(find.text('15'));
  final ok = MaterialLocalizations.of(
          tester.element(find.byType(DatePickerDialog)))
      .okButtonLabel;
  await tester.tap(find.text(ok));
  await tester.pumpAndSettle();
  final now = DateTime.now();
  return DateTime(now.year, now.month, 15);
}

/// Makes the screen a small phone's, 320 × 640, for the rest of the test.
void useSmallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The menu item labeled [label] (menu items are typed by a private enum).
PopupMenuItem<dynamic> menuItem(String label) => find
    .ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
    )
    .evaluate()
    .single
    .widget as PopupMenuItem<dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-key',
      httpClient: MockClient((request) => backend.handle(request)),
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: MemoryAsyncStorage(),
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
    );
    // A non-JWT access token has no expiry, so the session is accepted
    // without contacting the auth server.
    await Supabase.instance.client.auth.recoverSession(jsonEncode({
      'access_token': 'test-access-token',
      'token_type': 'bearer',
      'refresh_token': 'test-refresh-token',
      'user': {
        'id': 'user-1',
        'aud': 'authenticated',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'created_at': '2026-01-01T00:00:00Z',
      },
    }));
  });

  setUp(() => backend = FakeBackend());

  testWidgets('groups tasks and shows what a blocked task waits on',
      (tester) async {
    await pumpTasksPage(tester);

    expect(find.text('In progress (1)'), findsOneWidget);
    expect(find.text('Blocked (1)'), findsOneWidget);
    expect(find.text('Done (1)'), findsOneWidget);
    expect(find.textContaining('Ready to start'), findsNothing);
    expect(find.text('Waiting on: B'), findsOneWidget);
  });

  testWidgets('a blocked task cannot be started or finished', (tester) async {
    await pumpTasksPage(tester);
    await openMenu(tester, 'A');

    expect(menuItem('Start').enabled, isFalse);
    expect(menuItem('Mark done').enabled, isFalse);
    expect(find.text('Blocked by "B"'), findsNWidgets(2));

    await tester.tap(find.text('Start'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(backend.patches, isEmpty);
  });

  testWidgets('finishing a dependency unblocks the tasks waiting on it',
      (tester) async {
    await pumpTasksPage(tester);
    expect(backend.gets, 2);
    await openMenu(tester, 'B');
    await tester.tap(find.text('Mark done'));
    await tester.pumpAndSettle();

    final patch = backend.patches.single;
    expect(patch.url.queryParameters['id'], 'eq.b');
    expect(jsonDecode(patch.body), {'status': 'done'});

    // Updated from the returned row, without reloading: A is unblocked.
    expect(backend.gets, 2);
    expect(find.text('Ready to start (1)'), findsOneWidget);
    expect(find.textContaining('Blocked'), findsNothing);
    expect(find.text('Depends on: B'), findsOneWidget);
  });

  testWidgets('deleting a task removes its links without reloading',
      (tester) async {
    await pumpTasksPage(tester);
    await openMenu(tester, 'B');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(backend.gets, 2);
    expect(find.text('B'), findsNothing);
    expect(find.text('Ready to start (1)'), findsOneWidget);
    expect(find.textContaining('Depends on'), findsNothing);
  });

  testWidgets('a new task appears without reloading', (tester) async {
    await pumpTasksPage(tester);
    await tester.tap(find.byTooltip('New task'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'D');
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // No description or due date was given, so none is sent.
    expect(jsonDecode(backend.inserts.single.body), {'title': 'D'});
    expect(backend.gets, 2);
    expect(find.text('Ready to start (1)'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
  });

  testWidgets('a task shows its due date with its other details',
      (tester) async {
    backend.tasks[0]['due_date'] = '2026-10-20';
    await pumpTasksPage(tester);

    expect(find.text('Due Oct 20, 2026\nWaiting on: B'), findsOneWidget);
  });

  testWidgets('a new task can be given a due date, or have it cleared',
      (tester) async {
    await pumpTasksPage(tester);
    await tester.tap(find.byTooltip('New task'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'D');
    await tester.pump();
    expect(find.text('No due date'), findsOneWidget);
    expect(find.byTooltip('Clear due date'), findsNothing);

    await pickDueDate(tester);
    await tester.tap(find.byTooltip('Clear due date'));
    await tester.pump();
    expect(find.text('No due date'), findsOneWidget);
    expect(find.byTooltip('Clear due date'), findsNothing);

    final due = await pickDueDate(tester);
    expect(find.text(en.taskDue(due)), findsOneWidget);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Sent as the date column's YYYY-MM-DD, whatever the locale.
    final month = due.month.toString().padLeft(2, '0');
    expect(jsonDecode(backend.inserts.single.body),
        {'title': 'D', 'due_date': '${due.year}-$month-15'});
    expect(find.text(en.taskDue(due)), findsOneWidget);
  });

  testWidgets('the dependencies dialog counts the checked tasks',
      (tester) async {
    await pumpTasksPage(tester);
    await openMenu(tester, 'A');
    await tester.tap(find.text('Edit dependencies…'));
    await tester.pumpAndSettle();
    expect(find.text('1 task selected'), findsOneWidget);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'B'));
    await tester.pump();
    expect(find.text('No tasks selected'), findsOneWidget);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'B'));
    await tester.tap(find.widgetWithText(CheckboxListTile, 'C'));
    await tester.pump();
    expect(find.text('2 tasks selected'), findsOneWidget);
  });

  // The app's own checks passed, so the board on screen was out of date.
  testWidgets('says the tasks changed when a gating trigger rejects',
      (tester) async {
    backend.rejectPatchesWith = 'Can\'t reopen: "X" already started';
    await pumpTasksPage(tester);
    await openMenu(tester, 'C');
    await tester.tap(find.text('Move back to To do'));
    await tester.pumpAndSettle();

    expect(backend.patches, hasLength(1));
    expect(
        find.text('Your tasks changed somewhere else, so that change isn\'t '
            'allowed anymore. Refresh the list and try again.'),
        findsOneWidget);
    expect(find.text('Done (1)'), findsOneWidget);
  });

  // Text that doesn't fit (e.g. a long German label in a Row) fails the
  // test with an overflow error.
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('the board and its dialogs fit a small phone in $locale',
        (tester) async {
      useSmallPhone(tester);
      final l10n = lookupAppLocalizations(locale);
      backend.tasks[0]['due_date'] = '2026-10-20';
      await pumpTasksPage(tester, locale: locale);

      expect(find.text(l10n.myTasks), findsOneWidget);
      expect(find.text(l10n.sectionInProgress(1)), findsOneWidget);
      expect(find.text(l10n.sectionBlocked(1)), findsOneWidget);
      expect(find.text(l10n.sectionDone(1)), findsOneWidget);
      expect(
          find.text('${l10n.taskDue(DateTime(2026, 10, 20))}\n'
              '${l10n.waitingOn('B')}'),
          findsOneWidget);

      // The blocked task's menu, with the reason under each disabled item.
      await openMenu(tester, 'A', l10n: l10n);
      expect(find.text(l10n.blockedBy('"B"')), findsNWidgets(2));
      await tester.tap(find.text(l10n.editDependencies));
      await tester.pumpAndSettle();
      expect(find.text(l10n.dependenciesTitle('A')), findsOneWidget);
      expect(find.text(l10n.dependenciesSelected(1)), findsOneWidget);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      // The new-task dialog at its widest, with a due date set.
      await tester.tap(find.byTooltip(l10n.newTask));
      await tester.pumpAndSettle();
      expect(find.text(l10n.noDueDate), findsOneWidget);
      final due = await pickDueDate(tester, l10n);
      expect(find.text(l10n.taskDue(due)), findsOneWidget);
      expect(find.byTooltip(l10n.clearDueDate), findsOneWidget);
    });
  }
}
