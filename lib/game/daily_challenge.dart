/// Stable daily challenge identity shared across all UTC time zones.
abstract final class DailyChallenge {
  static String utcDayKey(DateTime moment) {
    final utc = moment.toUtc();
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '${utc.year}-$month-$day';
  }

  static int seedFor(DateTime moment) {
    final utc = moment.toUtc();
    return utc.year * 10000 + utc.month * 100 + utc.day;
  }
}
