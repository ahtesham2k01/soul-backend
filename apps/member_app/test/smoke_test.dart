import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/core/environment.dart';

void main() {
  test('member API stays under the documented V1 base path', () {
    expect(SoulEnvironment.apiBaseUri.path, '/api/v1/');
  });
}
