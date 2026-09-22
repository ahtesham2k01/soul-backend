import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('member UI has no hardcoded English copy outside localization calls', () {
    final files = <File>[
      File('lib/src/app.dart'),
      ...Directory('lib/src/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('_screen.dart') ||
                file.path.endsWith('welcome_flow.dart'),
          ),
    ];

    final violations = <String>[];

    for (final file in files) {
      final source = file.readAsStringSync();
      final localizedSpans = _localizedCallSpans(source);

      for (final literal in _stringLiterals(source)) {
        if (_insideAny(literal.start, localizedSpans)) continue;
        if (!_looksLikeMemberCopy(literal.text)) continue;

        final line =
            '\n'.allMatches(source.substring(0, literal.start)).length + 1;
        violations.add(
          '${file.path}:$line: ${literal.text.trim()}',
        );
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Member-facing copy must come from BootstrapState translation keys.\n'
          '${violations.join('\n')}',
    );
  });
}

final class _Span {
  const _Span(this.start, this.end);

  final int start;
  final int end;
}

final class _Literal {
  const _Literal(this.start, this.text);

  final int start;
  final String text;
}

bool _insideAny(int offset, List<_Span> spans) =>
    spans.any((span) => offset >= span.start && offset < span.end);

List<_Span> _localizedCallSpans(String source) {
  final spans = <_Span>[];
  final calls = RegExp(
    r'(?:(?:widget|state)\.)?labels\??\.(?:text|format)\s*\(',
  );

  for (final match in calls.allMatches(source)) {
    var index = match.end;
    var depth = 1;

    while (index < source.length && depth > 0) {
      if (_startsLineComment(source, index)) {
        index = _skipLineComment(source, index);
        continue;
      }
      if (_startsBlockComment(source, index)) {
        index = _skipBlockComment(source, index);
        continue;
      }

      final char = source[index];
      if (char == "'" || char == '"') {
        index = _skipString(source, index);
        continue;
      }
      if (char == '(') depth++;
      if (char == ')') depth--;
      index++;
    }

    spans.add(_Span(match.start, index));
  }

  return spans;
}

List<_Literal> _stringLiterals(String source) {
  final literals = <_Literal>[];
  var index = 0;

  while (index < source.length) {
    if (_startsLineComment(source, index)) {
      index = _skipLineComment(source, index);
      continue;
    }
    if (_startsBlockComment(source, index)) {
      index = _skipBlockComment(source, index);
      continue;
    }

    final char = source[index];
    if (char != "'" && char != '"') {
      index++;
      continue;
    }

    final start = index;
    final quote = char;
    final buffer = StringBuffer();
    index++;

    while (index < source.length) {
      final current = source[index];

      if (current == '\\') {
        if (index + 1 < source.length) {
          buffer.write(source[index + 1]);
          index += 2;
          continue;
        }
      }

      if (current == quote) {
        index++;
        break;
      }

      if (current == r'$') {
        if (index + 1 < source.length && source[index + 1] == '{') {
          index = _skipInterpolation(source, index + 1);
          continue;
        }
        var cursor = index + 1;
        while (cursor < source.length &&
            RegExp(r'[A-Za-z0-9_]').hasMatch(source[cursor])) {
          cursor++;
        }
        if (cursor > index + 1) {
          index = cursor;
          continue;
        }
      }

      buffer.write(current);
      index++;
    }

    literals.add(_Literal(start, buffer.toString()));
  }

  return literals;
}

int _skipString(String source, int start) {
  final quote = source[start];
  var index = start + 1;

  while (index < source.length) {
    final current = source[index];
    if (current == '\\') {
      index += 2;
      continue;
    }
    if (current == quote) return index + 1;
    if (current == r'$' &&
        index + 1 < source.length &&
        source[index + 1] == '{') {
      index = _skipInterpolation(source, index + 1);
      continue;
    }
    index++;
  }

  return source.length;
}

int _skipInterpolation(String source, int braceStart) {
  var depth = 1;
  var index = braceStart + 1;

  while (index < source.length && depth > 0) {
    if (_startsLineComment(source, index)) {
      index = _skipLineComment(source, index);
      continue;
    }
    if (_startsBlockComment(source, index)) {
      index = _skipBlockComment(source, index);
      continue;
    }

    final char = source[index];
    if (char == "'" || char == '"') {
      index = _skipString(source, index);
      continue;
    }
    if (char == '{') depth++;
    if (char == '}') depth--;
    index++;
  }

  return index;
}

bool _startsLineComment(String source, int index) =>
    index + 1 < source.length &&
    source[index] == '/' &&
    source[index + 1] == '/';

bool _startsBlockComment(String source, int index) =>
    index + 1 < source.length &&
    source[index] == '/' &&
    source[index + 1] == '*';

int _skipLineComment(String source, int start) {
  final newline = source.indexOf('\n', start + 2);
  return newline == -1 ? source.length : newline + 1;
}

int _skipBlockComment(String source, int start) {
  final end = source.indexOf('*/', start + 2);
  return end == -1 ? source.length : end + 2;
}

bool _looksLikeMemberCopy(String raw) {
  final value = raw.trim();
  if (value.isEmpty || !RegExp(r'[A-Za-z]').hasMatch(value)) return false;

  const exactAllowlist = {
    'SOUL',
    'SOUL mobile app',
    'Unable to load SOUL right now.',
    'Retry',
  };
  if (exactAllowlist.contains(value)) return false;

  if (value.startsWith('SOUL ·')) return false;
  if (value.startsWith('^') &&
      value.isNotEmpty &&
      value.codeUnitAt(value.length - 1) == 36) {
    return false;
  }
  if (value.startsWith('package:') ||
      value.startsWith('assets/') ||
      value.startsWith('http://') ||
      value.startsWith('https://')) {
    return false;
  }

  if (RegExp(r'^[a-z0-9_./:?=&{}-]+$').hasMatch(value)) return false;
  if (RegExp(r'^[A-Z0-9_./:-]{2,}$').hasMatch(value)) return false;
  if (RegExp(r'^[-–—·,:%+()\d\s]+$').hasMatch(value)) return false;
  if (RegExp(r'^[a-z]{1,3}$').hasMatch(value)) return false;

  final words = RegExp(r'[A-Za-z]+').allMatches(value).length;
  if (words >= 2) return true;

  return RegExp(r'^[A-Z][a-z]{2,}$').hasMatch(value);
}
