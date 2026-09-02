import 'package:intl/intl.dart';

class AppDateUtils {
  static final _iso = DateFormat('yyyy-MM-dd');
  static final _monthYearEs = DateFormat('MMMM yyyy', 'es');
  static final _fullEs = DateFormat('EEEE, d MMMM yyyy', 'es');
  static final _weekdayShort = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  static String toIso(DateTime d) => _iso.format(DateTime(d.year, d.month, d.day));

  static DateTime fromIso(String s) => DateTime.parse(s);

  static String formatMonthYear(DateTime d) {
    final raw = _monthYearEs.format(d);
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  static String formatFull(DateTime d) {
    final raw = _fullEs.format(d);
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  static List<String> get weekdaysShort => _weekdayShort;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isFuture(DateTime d) {
    final today = DateTime.now();
    final a = DateTime(d.year, d.month, d.day);
    final b = DateTime(today.year, today.month, today.day);
    return a.isAfter(b);
  }

  static DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  static List<DateTime> calendarDays(DateTime focusedMonth) {
    final firstOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final weekday = firstOfMonth.weekday;
    final start = firstOfMonth.subtract(Duration(days: weekday - 1));
    return List.generate(42, (i) => start.add(Duration(days: i)));
  }

  static int daysInMonth(int year, int month) {
    final next = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return next.subtract(const Duration(days: 1)).day;
  }
}
