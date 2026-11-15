enum PrayerType {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
  none
}

class PrayerItem {
  final PrayerType type;
  final String nameArabic;
  final String nameEnglish;
  final DateTime time;
  final bool isNext;

  const PrayerItem({
    required this.type,
    required this.nameArabic,
    required this.nameEnglish,
    required this.time,
    this.isNext = false,
  });
}

class PrayerSchedule {
  final List<PrayerItem> prayers;
  final PrayerItem? nextPrayer;
  final Duration timeRemaining;
  final String locationName;

  const PrayerSchedule({
    required this.prayers,
    this.nextPrayer,
    this.timeRemaining = Duration.zero,
    this.locationName = 'Ajman / UAE',
  });

  String get formattedCountdown {
    final hours = timeRemaining.inHours.toString().padLeft(2, '0');
    final minutes = (timeRemaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (timeRemaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
