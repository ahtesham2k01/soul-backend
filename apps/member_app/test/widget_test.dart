import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/app.dart';

void main() {
  test('member application exposes the SOUL root widget', () {
    expect(const SoulApp(), isA<SoulApp>());
  });
}
