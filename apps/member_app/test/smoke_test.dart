import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/core/environment.dart';
import 'package:soul_member_app/src/core/soul_theme.dart';

void main() {
  test('member API stays under the documented V1 base path', () {
    expect(SoulEnvironment.apiBaseUri.path, '/api/v1/');
  });

  test('member visual system keeps the approved SOUL lime and forest palette', () {
    expect(SoulColors.lime.toARGB32(), 0xffb4d63c);
    expect(SoulColors.forestDeep.toARGB32(), 0xff0a1b02);
  });
}
