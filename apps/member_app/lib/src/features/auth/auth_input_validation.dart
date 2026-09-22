DateTime? _strictDate(int year, int month, int day) {
  final value = DateTime(year, month, day);
  if (value.year != year || value.month != month || value.day != day) {
    return null;
  }
  return value;
}

String? normalizeAdultDateOfBirth(
  String input, {
  DateTime? today,
}) {
  final trimmed = input.trim();
  DateTime? value;

  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmed);
  if (iso != null) {
    final year = int.tryParse(iso.group(1)!);
    final month = int.tryParse(iso.group(2)!);
    final day = int.tryParse(iso.group(3)!);
    if (year != null && month != null && day != null) {
      value = _strictDate(year, month, day);
    }
  } else {
    final regional =
        RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(trimmed);
    if (regional != null) {
      final day = int.tryParse(regional.group(1)!);
      final month = int.tryParse(regional.group(2)!);
      final year = int.tryParse(regional.group(3)!);
      if (year != null && month != null && day != null) {
        value = _strictDate(year, month, day);
      }
    }
  }

  if (value == null) return null;

  final reference = today ?? DateTime.now();
  var age = reference.year - value.year;
  if (reference.month < value.month ||
      (reference.month == value.month && reference.day < value.day)) {
    age--;
  }

  if (age < 18 || age > 120) return null;

  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
