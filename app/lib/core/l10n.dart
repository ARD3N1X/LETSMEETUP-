import 'package:intl/intl.dart';

/// Lekka lokalizacja PL/EN. Język ustawia [SettingsController]; zmiana przebudowuje całą aplikację.
class L10n {
  L10n._();

  static String lang = 'pl';

  static bool get isEnglish => lang == 'en';
  static String get locale => isEnglish ? 'en' : 'pl';
}

/// Zwraca tekst w bieżącym języku.
String tr(String pl, String en) => L10n.isEnglish ? en : pl;

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class Fmt {
  Fmt._();

  /// "Sierpień 2026"
  static String monthYear(DateTime d) => capitalize(DateFormat.yMMMM(L10n.locale).format(d).replaceAll(' r.', ''));

  /// "Sierpień"
  static String month(DateTime d) => capitalize(DateFormat.LLLL(L10n.locale).format(d));

  /// "Wtorek, 26 sierpnia 2026"
  static String fullDate(DateTime d) => capitalize(DateFormat.yMMMMEEEEd(L10n.locale).format(d));

  /// "Wtorek, 26 sierpnia"
  static String dayTitle(DateTime d) => capitalize(DateFormat.MMMMEEEEd(L10n.locale).format(d));

  /// "26 sie 2026"
  static String shortDate(DateTime d) => DateFormat.yMMMd(L10n.locale).format(d);

  /// "14:00"
  static String time(DateTime d) => DateFormat.Hm(L10n.locale).format(d);

  static List<String> get weekdayShort =>
      L10n.isEnglish ? const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'] : const ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'];

  static List<String> get weekdayNames => L10n.isEnglish
      ? const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
      : const ['poniedziałek', 'wtorek', 'środa', 'czwartek', 'piątek', 'sobota', 'niedziela'];

  static String minutes(int minutes) {
    if (minutes == 0) return tr('W chwili rozpoczęcia', 'At start time');
    if (minutes % 1440 == 0) {
      final days = minutes ~/ 1440;
      return tr(days == 1 ? '1 dzień przed' : '$days dni przed', days == 1 ? '1 day before' : '$days days before');
    }
    if (minutes % 60 == 0) {
      final h = minutes ~/ 60;
      return tr('$h godz. przed', '$h h before');
    }
    return tr('$minutes min przed', '$minutes min before');
  }

  /// "5M", "1H", "1D" — etykiety chipów przypomnień.
  static String minutesShort(int minutes) {
    if (minutes % 1440 == 0) return '${minutes ~/ 1440}${tr('D', 'D')}';
    if (minutes % 60 == 0) return '${minutes ~/ 60}${tr('G', 'H')}';
    return '${minutes}M';
  }
}
