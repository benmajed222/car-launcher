import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prayer_data.dart';
import '../services/prayer_service.dart';
import 'clock_provider.dart';
import 'settings_provider.dart';

final prayerScheduleProvider = Provider<PrayerSchedule>((ref) {
  final clockState = ref.watch(clockProvider);
  final settings = ref.watch(settingsProvider);

  final lat = clockState.gpsData.hasValidFix
      ? clockState.gpsData.latitude
      : PrayerService.defaultLatitude;
  final lng = clockState.gpsData.hasValidFix
      ? clockState.gpsData.longitude
      : PrayerService.defaultLongitude;

  final locationDesc = clockState.gpsData.hasValidFix
      ? 'GPS Fix (${lat.toStringAsFixed(2)}°, ${lng.toStringAsFixed(2)}°)'
      : 'Ajman / UAE';

  return PrayerService.calculateSchedule(
    now: clockState.currentTime,
    latitude: lat,
    longitude: lng,
    method: settings.prayerMethod,
    offsetMinutes: settings.prayerOffsetMinutes,
    locationName: locationDesc,
  );
});
