import '../models/timesheet_models.dart';

String monthName(DateTime date) {
  return [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ][date.month - 1];
}

String trimDouble(double value) {
  if (value == value.toInt()) return value.toInt().toString();
  return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
}

DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

Map<ActivityType, double> totalsByActivity(List<TimeEntryLine> lines) {
  final totals = {for (final type in ActivityType.values) type: 0.0};
  for (final line in lines) {
    totals[line.activity] = (totals[line.activity] ?? 0) + line.hours;
  }
  return totals;
}

double totalKilometers(List<TimeEntryLine> lines) {
  return lines
      .fold<double>(0, (sum, line) => sum + line.kilometers);
}

String toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

String formatHours(double hours) {
  if (hours == 0) return '';
  int h = hours.toInt();
  int m = ((hours - h) * 100).round();
  if (m == 0) return h.toString();
  return '$h.$m';
}
