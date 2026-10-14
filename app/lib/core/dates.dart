/// Operacje na datach kalendarzowych (bez godzin) w lokalnej strefie czasowej.
class Dates {
  Dates._();

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime today() => dateOnly(DateTime.now());

  static bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days, d.hour, d.minute);

  static DateTime addMonths(DateTime d, int months) => DateTime(d.year, d.month + months, 1);

  static int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  /// Różnica w dniach kalendarzowych (odporna na zmianę czasu letni/zimowy).
  static int daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  /// "2026-08-14"
  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime parseKey(String key) {
    final parts = key.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  /// Początek tygodnia (poniedziałek).
  static DateTime startOfWeek(DateTime d) => dateOnly(d).subtract(Duration(days: d.weekday - 1));

  /// 42 dni (6 tygodni) siatki miesiąca, od poniedziałku.
  static List<DateTime> monthGrid(DateTime month) {
    final first = startOfWeek(DateTime(month.year, month.month, 1));
    return List.generate(42, (i) => DateTime(first.year, first.month, first.day + i));
  }

  /// Data całodniowa jest przesyłana jako północ UTC tego dnia.
  static DateTime allDayToLocal(DateTime utc) => DateTime(utc.year, utc.month, utc.day);

  static DateTime allDayToUtc(DateTime local) => DateTime.utc(local.year, local.month, local.day);
}
