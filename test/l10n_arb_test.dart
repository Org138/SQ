// Translated ARB files must keep app_en.arb's keys and placeholders.
// flutter gen-l10n only rejects text it can't parse; a translation that drops
// {titles} or skips a key still builds, so these catch that before a run.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _dir = 'lib/l10n';
const _template = 'app_en.arb';

Map<String, dynamic> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// How a message uses one placeholder: [kind] is `plural`, `select` or
/// `selectordinal`, or empty for a plain `{name}`; [cases] are the case
/// labels (`=1`, `one`, `other`, ...) of the first plural or select on it.
typedef _Argument = ({String kind, Set<String> cases});

/// Reads the placeholders out of an ICU message, including the ones inside
/// plural and select cases. Case labels and case text aren't placeholders,
/// and a placeholder used several times is listed once, since plural cases
/// repeat it a different number of times in each language.
class _Arguments {
  _Arguments(this._message) {
    _text();
    if (_i < _message.length) _fail('unmatched }');
  }

  final String _message;
  final found = <String, _Argument>{};
  var _i = 0;

  /// Text up to the `}` that closes the enclosing case, or the end.
  void _text() {
    while (_i < _message.length && _message[_i] != '}') {
      if (_message[_i++] == '{') _argument();
    }
  }

  /// `name}`, or `name, kind, label{text} label{text}...}`.
  void _argument() {
    final name = _word();
    if (_eat('}')) {
      found.putIfAbsent(name, () => (kind: '', cases: {}));
      return;
    }
    _expect(',');
    final kind = _word();
    _expect(',');
    final cases = <String>{};
    while (!_eat('}')) {
      cases.add(_word());
      _expect('{');
      _text();
      _expect('}');
    }
    final previous = found[name];
    if (previous == null || previous.kind.isEmpty) {
      found[name] = (kind: kind, cases: cases);
    }
  }

  String _word() {
    _skipSpace();
    final start = _i;
    while (_i < _message.length && !' \t\n,{}'.contains(_message[_i])) {
      _i++;
    }
    if (_i == start) _fail('expected a name');
    final word = _message.substring(start, _i);
    _skipSpace();
    return word;
  }

  bool _eat(String char) {
    _skipSpace();
    if (_i < _message.length && _message[_i] == char) {
      _i++;
      return true;
    }
    if (_i >= _message.length) _fail('unmatched {');
    return false;
  }

  void _expect(String char) {
    if (!_eat(char)) _fail('expected $char');
  }

  void _skipSpace() {
    while (_i < _message.length && ' \t\n'.contains(_message[_i])) {
      _i++;
    }
  }

  Never _fail(String reason) => throw FormatException(reason, _message, _i);
}

/// Every way [message], the translation of [key], uses placeholders
/// differently from [original].
List<String> _placeholderProblems(String key, String original, String message) {
  final Map<String, _Argument> expected, actual;
  try {
    expected = _Arguments(original).found;
  } on FormatException catch (e) {
    return ['$key: $_template can\'t be read (${e.message})'];
  }
  try {
    actual = _Arguments(message).found;
  } on FormatException catch (e) {
    return ['$key: can\'t be read (${e.message} at ${e.offset})'];
  }

  final expectedNames = expected.keys.toList()..sort();
  final actualNames = actual.keys.toList()..sort();
  if (!listEquals(expectedNames, actualNames)) {
    return [
      '$key: expected ${_braced(expectedNames)}, got ${_braced(actualNames)}'
    ];
  }
  final problems = <String>[];
  for (final name in expectedNames) {
    final want = expected[name]!, got = actual[name]!;
    if (want.kind != got.kind) {
      problems.add('$key: expected ${_shape(name, want.kind)}, '
          'got ${_shape(name, got.kind)}');
    } else if (want.kind == 'select' && !setEquals(want.cases, got.cases)) {
      // Select cases are values the code passes in, so they can't be
      // translated or dropped. Plural cases differ by language.
      problems.add('$key: {$name} cases expected '
          '${_sorted(want.cases)}, got ${_sorted(got.cases)}');
    } else if (want.kind.isNotEmpty && !got.cases.contains('other')) {
      problems.add('$key: {$name, ${got.kind}} has no other case');
    }
  }
  return problems;
}

/// Every way [arb], the translation for [locale], differs from [template].
List<String> _problems(
    Map<String, dynamic> template, Map<String, dynamic> arb, String locale) {
  final problems = <String>[];
  if (arb['@@locale'] != locale) {
    problems.add('@@locale: expected "$locale", got "${arb['@@locale']}"');
  }
  bool isMessage(String key) => !key.startsWith('@');
  for (final key in template.keys.where(isMessage)) {
    final message = arb[key];
    if (message is! String) {
      problems.add('$key: missing');
      continue;
    }
    problems
        .addAll(_placeholderProblems(key, template[key] as String, message));
    // Metadata is optional in a translation, but if it's copied it must match.
    final metadata = arb['@$key'];
    if (metadata != null &&
        jsonEncode(metadata) != jsonEncode(template['@$key'])) {
      problems.add('@$key: differs from $_template');
    }
  }
  for (final key in arb.keys.where(isMessage)) {
    if (!template.containsKey(key)) problems.add('$key: not in $_template');
  }
  return problems;
}

String _braced(List<String> names) =>
    names.isEmpty ? 'none' : names.map((n) => '{$n}').join(' ');

String _shape(String name, String kind) =>
    kind.isEmpty ? '{$name}' : '{$name, $kind}';

String _sorted(Set<String> cases) => (cases.toList()..sort()).join(' ');

void main() {
  final template = _read('$_dir/$_template');
  final translations = Directory(_dir)
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .where((name) => name.endsWith('.arb') && name != _template)
      .toList()
    ..sort();

  group('translated ARB files', () {
    for (final name in translations) {
      test(name, () {
        final locale =
            RegExp(r'^app_(.+)\.arb$').firstMatch(name)?[1] ?? '(unknown)';
        final problems = _problems(template, _read('$_dir/$name'), locale);
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  });

  // The checks themselves, so they're exercised before any translation exists.
  group('checker', () {
    Map<String, dynamic> copy() =>
        jsonDecode(jsonEncode(template)) as Map<String, dynamic>
          ..['@@locale'] = 'xx';

    test('accepts a copy of the template', () {
      expect(_problems(template, copy(), 'xx'), isEmpty);
    });

    test('reports dropped and renamed placeholders', () {
      final arb = copy()
        ..['blockedBy'] = 'Bloqueado'
        ..['sectionDone'] = 'Hecho ({cuenta})'
        ..['deleteTaskTitle'] = '¿Eliminar "{title}"? {title}';
      expect(_problems(template, arb, 'xx'), [
        'sectionDone: expected {count}, got {cuenta}',
        'blockedBy: expected {titles}, got none',
      ]);
    });

    test('reports missing and extra keys, locale and metadata', () {
      final arb = copy()
        ..remove('cantReopen')
        ..['extra'] = 'x'
        ..['@taskDue'] = {'description': 'changed'};
      expect(_problems(template, arb, 'es'), [
        '@@locale: expected "es", got "xx"',
        '@taskDue: differs from $_template',
        'cantReopen: missing',
        'extra: not in $_template',
      ]);
    });

    group('plural and select', () {
      const tasks = '{count, plural, =1{1 task} other{{count} tasks}}';
      const owner = '{who, select, me{Mine} other{{name}\'s}}';
      List<String> check(String original, String translation) =>
          _placeholderProblems('k', original, translation);

      test('accepts translated case text and extra plural cases', () {
        expect(
            check(tasks,
                '{count, plural, one{1 tarea} many{{count} de tareas} other{{count} tareas}}'),
            isEmpty);
        expect(
            check(owner, '{who, select, me{Mío} other{De {name}}}'), isEmpty);
      });

      test('reports a placeholder dropped from inside a case', () {
        expect(check(owner, '{who, select, me{Mío} other{De otro}}'),
            ['k: expected {name} {who}, got {who}']);
      });

      test('reports a plural that became plain text or lost other', () {
        expect(check(tasks, '{count} tareas'),
            ['k: expected {count, plural}, got {count}']);
        expect(check(tasks, '{count, plural, one{1 tarea}}'),
            ['k: {count, plural} has no other case']);
      });

      test('reports translated or dropped select cases', () {
        expect(check(owner, '{who, select, yo{Mío} other{De {name}}}'),
            ['k: {who} cases expected me other, got other yo']);
      });

      test('reports unbalanced braces', () {
        expect(
            check(tasks, '{count, plural, one{1 tarea} other{{count} tareas}'),
            [startsWith('k: can\'t be read (unmatched {')]);
        expect(check('{count}', '{count}}'),
            [startsWith('k: can\'t be read (unmatched }')]);
      });
    });
  });
}
