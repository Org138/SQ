// Fails if a target locale's ARB file is missing a message from app_en.arb,
// has one app_en.arb doesn't, or has an empty one. flutter gen-l10n falls back
// to English for a missing message without failing, so an untranslated string
// would otherwise ship. The target locales come from .lingo/config.json.
// This only compares keys: it can't tell whether a translation is stale.
//
//   dart run tool/check_arb_keys.dart
import 'dart:convert';
import 'dart:io';

const _config = '.lingo/config.json';
const _dir = 'lib/l10n';
const _source = 'en';

void main() {
  final config =
      jsonDecode(File(_config).readAsStringSync()) as Map<String, dynamic>;
  final locales = (config['targetLocales'] as List).cast<String>();
  final source = _messages(_source)!;
  final problems = <String>[];

  for (final locale in locales) {
    final messages = _messages(locale);
    if (messages == null) {
      problems.add('$_dir/app_$locale.arb is missing');
      continue;
    }
    for (final key in source.keys) {
      if (!messages.containsKey(key)) {
        problems.add('app_$locale.arb: missing "$key"');
      } else if (messages[key].trim().isEmpty) {
        problems.add('app_$locale.arb: "$key" is empty');
      }
    }
    for (final key in messages.keys) {
      if (!source.containsKey(key)) {
        problems.add('app_$locale.arb: "$key" isn\'t in app_$_source.arb');
      }
    }
  }

  if (problems.isNotEmpty) {
    problems.forEach(stderr.writeln);
    stderr.writeln('Translate the new strings (lingo run) '
        'or remove the old ones, then commit the ARB files.');
    exitCode = 1;
  }
}

/// The messages in `app_<locale>.arb`, leaving out @ metadata, or null if the
/// file doesn't exist.
Map<String, dynamic>? _messages(String locale) {
  final file = File('$_dir/app_$locale.arb');
  if (!file.existsSync()) return null;
  final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final MapEntry(:key, :value) in arb.entries)
      if (!key.startsWith('@')) key: value,
  };
}
