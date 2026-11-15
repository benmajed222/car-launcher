import 'package:adhan/adhan.dart';
import '../models/prayer_data.dart';

class PrayerService {
  // Default coordinates: Ajman / Sharjah (UAE)
  static const double defaultLatitude = 25.4052;
  static const double defaultLongitude = 55.5136;

  static CalculationParameters _getCalculationParameters(String methodCode) {
    switch (methodCode.toLowerCase()) {
      case 'ummalqura':
      case 'umm_al_qura':
        return CalculationMethod.umm_al_qura.getParameters();
      case 'muslimworldleague':
      case 'muslim_world_league':
      case 'mwl':
        return CalculationMethod.muslim_world_league.getParameters();
      case 'dubai':
      default:
        return CalculationMethod.dubai.getParameters();
    }
  }

  static PrayerSchedule calculateSchedule({
    required DateTime now,
    double latitude = defaultLatitude,
    double longitude = defaultLongitude,
    String method = 'dubai',
    int offsetMinutes = 0,
    String locationName = 'Ajman / UAE',
  }) {
    final coordinates = Coordinates(latitude, longitude);
    final date = DateComponents.from(now);
    final params = _getCalculationParameters(method);

    final prayerTimes = PrayerTimes(coordinates, date, params);

    final offset = Duration(minutes: offsetMinutes);

    final fajrTime = prayerTimes.fajr.add(offset);
    final sunriseTime = prayerTimes.sunrise.add(offset);
    final dhuhrTime = prayerTimes.dhuhr.add(offset);
    final asrTime = prayerTimes.asr.add(offset);
    final maghribTime = prayerTimes.maghrib.add(offset);
    final ishaTime = prayerTimes.isha.add(offset);

    // Build today's prayer list
    final List<PrayerItem> items = [
      PrayerItem(type: PrayerType.fajr, nameArabic: 'الفجر', nameEnglish: 'Fajr', time: fajrTime),
      PrayerItem(type: PrayerType.sunrise, nameArabic: 'الشروق', nameEnglish: 'Sunrise', time: sunriseTime),
      PrayerItem(type: PrayerType.dhuhr, nameArabic: 'الظهر', nameEnglish: 'Dhuhr', time: dhuhrTime),
      PrayerItem(type: PrayerType.asr, nameArabic: 'العصر', nameEnglish: 'Asr', time: asrTime),
      PrayerItem(type: PrayerType.maghrib, nameArabic: 'المغرب', nameEnglish: 'Maghrib', time: maghribTime),
      PrayerItem(type: PrayerType.isha, nameArabic: 'العشاء', nameEnglish: 'Isha', time: ishaTime),
    ];

    // Determine next prayer
    PrayerItem? next;
    Duration remaining = Duration.zero;

    for (final item in items) {
      if (item.time.isAfter(now)) {
        next = item;
        remaining = item.time.difference(now);
        break;
      }
    }

    // If past Isha, next prayer is tomorrow's Fajr
    if (next == null) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowDate = DateComponents.from(tomorrow);
      final tomorrowPrayers = PrayerTimes(coordinates, tomorrowDate, params);
      final tomorrowFajr = tomorrowPrayers.fajr.add(offset);

      next = PrayerItem(
        type: PrayerType.fajr,
        nameArabic: 'الفجر',
        nameEnglish: 'Fajr',
        time: tomorrowFajr,
        isNext: true,
      );
      remaining = tomorrowFajr.difference(now);
    }

    // Update isNext flag on today's items if matched
    final updatedList = items.map((p) {
      return PrayerItem(
        type: p.type,
        nameArabic: p.nameArabic,
        nameEnglish: p.nameEnglish,
        time: p.time,
        isNext: p.type == next?.type && p.time.day == now.day,
      );
    }).toList();

    return PrayerSchedule(
      prayers: updatedList,
      nextPrayer: next,
      timeRemaining: remaining.isNegative ? Duration.zero : remaining,
      locationName: locationName,
    );
  }
}
