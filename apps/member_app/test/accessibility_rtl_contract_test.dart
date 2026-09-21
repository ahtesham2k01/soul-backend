import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('member app applies server-provided RTL direction', () {
    final source = File('lib/src/app.dart').readAsStringSync();

    expect(source, contains("state.direction == 'rtl'"));
    expect(source, contains('TextDirection.rtl'));
    expect(source, contains('TextDirection.ltr'));
  });

  test('shared selectable cards expose explicit accessibility semantics', () {
    final source = File('lib/src/core/soul_design.dart').readAsStringSync();

    expect(source, contains('class SoulChoiceTile'));
    expect(source, contains('Semantics('));
    expect(source, contains('button: true'));
    expect(source, contains('selected: selected'));
    expect(source, contains('label: label'));
    expect(source, contains('onTap: onTap'));
    expect(source, contains('ExcludeSemantics('));
  });

  test('primary navigation exposes selected state to assistive technology', () {
    final source = File('lib/src/app.dart').readAsStringSync();

    expect(source, contains('class _BottomBarItem'));
    expect(source, contains('button: true'));
    expect(source, contains('selected: selected'));
    expect(source, contains('label: label'));
  });
}
