import 'dart:math';

abstract final class SoulUlid {
  static const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static final Random _random = Random.secure();

  static String generate({DateTime? now}) {
    final milliseconds =
        (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
    final timestamp =
        BigInt.from(milliseconds) & ((BigInt.one << 48) - BigInt.one);

    var randomness = BigInt.zero;
    for (var i = 0; i < 10; i++) {
      randomness = (randomness << 8) | BigInt.from(_random.nextInt(256));
    }

    var value = (timestamp << 80) | randomness;
    final output = List<String>.filled(26, '0');
    for (var index = output.length - 1; index >= 0; index--) {
      output[index] = _alphabet[(value & BigInt.from(31)).toInt()];
      value >>= 5;
    }
    return output.join();
  }
}
