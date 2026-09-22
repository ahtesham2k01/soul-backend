import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/features/auth/auth_input_validation.dart';

void main() {
  test('normalizes valid regional and ISO dates', () {
    final today = DateTime(2026, 9, 22);
    expect(
      normalizeAdultDateOfBirth('22/09/2000', today: today),
      '2000-09-22',
    );
    expect(
      normalizeAdultDateOfBirth('2000-09-22', today: today),
      '2000-09-22',
    );
  });

  test('rejects impossible calendar dates in every accepted format', () {
    final today = DateTime(2026, 9, 22);
    expect(normalizeAdultDateOfBirth('31/02/2000', today: today), isNull);
    expect(normalizeAdultDateOfBirth('2000-02-31', today: today), isNull);
    expect(normalizeAdultDateOfBirth('29/02/2001', today: today), isNull);
  });

  test('enforces exact eighteenth birthday boundary', () {
    final today = DateTime(2026, 9, 22);
    expect(
      normalizeAdultDateOfBirth('22/09/2008', today: today),
      '2008-09-22',
    );
    expect(normalizeAdultDateOfBirth('23/09/2008', today: today), isNull);
  });

  test('rejects implausible ages above 120', () {
    expect(
      normalizeAdultDateOfBirth(
        '21/09/1906',
        today: DateTime(2026, 9, 22),
      ),
      isNull,
    );
  });
}
