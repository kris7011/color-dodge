import 'package:color_dodge/game/daily_challenge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UTC dates produce identical seeds across timezone offsets', () {
    final utc = DateTime.utc(2026, 10, 18, 12);
    final local = DateTime.parse('2026-10-18T14:00:00+02:00');
    expect(DailyChallenge.seedFor(utc), 20261018);
    expect(DailyChallenge.seedFor(local), 20261018);
    expect(DailyChallenge.utcDayKey(local), '2026-10-18');
  });

  test('the next UTC date produces a new challenge', () {
    expect(
      DailyChallenge.seedFor(DateTime.utc(2026, 10, 19)),
      isNot(DailyChallenge.seedFor(DateTime.utc(2026, 10, 18))),
    );
  });

  test('the UTC day is used at local midnight boundaries', () {
    final local = DateTime.parse('2026-10-19T01:00:00+02:00');
    expect(DailyChallenge.utcDayKey(local), '2026-10-18');
    expect(DailyChallenge.seedFor(local), 20261018);
  });
}
