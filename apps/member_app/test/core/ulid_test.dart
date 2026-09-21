import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/core/ulid.dart';

void main() {
  test('capture ULIDs are canonical and timestamp-sortable', () {
    final first = SoulUlid.generate(now: DateTime.utc(2026, 9, 21, 3, 0));
    final second = SoulUlid.generate(now: DateTime.utc(2026, 9, 21, 3, 1));
    expect(first, matches(RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$')));
    expect(second, matches(RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$')));
    expect(first.compareTo(second), lessThan(0));
  });

  test('capture ULIDs do not repeat for the same timestamp', () {
    final now = DateTime.utc(2026, 9, 21, 3, 0);
    final values = List.generate(100, (_) => SoulUlid.generate(now: now));
    expect(values.toSet(), hasLength(values.length));
  });
}
