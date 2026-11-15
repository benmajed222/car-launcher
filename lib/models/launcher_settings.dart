class DockAppItem {
  final String name;
  final String packageName;
  final String iconType; // 'android_auto', 'camera', 'phone', 'radio', 'custom'

  const DockAppItem({
    required this.name,
    required this.packageName,
    required this.iconType,
  });

  Map<String, String> toMap() => {
    'name': name,
    'packageName': packageName,
    'iconType': iconType,
  };

  factory DockAppItem.fromMap(Map<dynamic, dynamic> map) => DockAppItem(
    name: map['name'] as String? ?? 'App',
    packageName: map['packageName'] as String? ?? '',
    iconType: map['iconType'] as String? ?? 'custom',
  );
}

class LauncherSettings {
  final String carPlayPackage;
  final bool autoLaunchCarPlay;
  final String obdMode; // 'bluetooth' or 'wifi'
  final String obdAddress;
  final int obdPort;
  final String mbtilesPath;
  final String prayerMethod; // 'dubai', 'ummalqura', 'mwl'
  final int prayerOffsetMinutes;
  final String localeCode; // 'ar' or 'en'
  final String carImagePath;

  // New features
  final bool isAdhanSoundEnabled;
  final double homeLat;
  final double homeLng;
  final String homeLabel;
  final double workLat;
  final double workLng;
  final String workLabel;
  final List<DockAppItem> dockApps;

  const LauncherSettings({
    this.carPlayPackage = 'com.suding.speedplay',
    this.autoLaunchCarPlay = true,
    this.obdMode = 'bluetooth',
    this.obdAddress = '',
    this.obdPort = 35000,
    this.mbtilesPath = '/sdcard/CarLauncher/maps/uae.mbtiles',
    this.prayerMethod = 'dubai',
    this.prayerOffsetMinutes = 0,
    this.localeCode = 'ar',
    this.carImagePath = 'assets/images/accord_2012.png',
    this.isAdhanSoundEnabled = true,
    this.homeLat = 25.4052,
    this.homeLng = 55.4500,
    this.homeLabel = 'المنزل',
    this.workLat = 25.2048,
    this.workLng = 55.2708,
    this.workLabel = 'العمل',
    this.dockApps = const [
      DockAppItem(name: 'Android Auto', packageName: 'com.google.android.projection.gearhead', iconType: 'android_auto'),
      DockAppItem(name: 'الكاميرا', packageName: 'com.xyauto.camera', iconType: 'camera'),
      DockAppItem(name: 'الهاتف', packageName: 'com.android.dialer', iconType: 'phone'),
      DockAppItem(name: 'الراديو FM', packageName: 'com.android.fmradio', iconType: 'radio'),
    ],
  });

  LauncherSettings copyWith({
    String? carPlayPackage,
    bool? autoLaunchCarPlay,
    String? obdMode,
    String? obdAddress,
    int? obdPort,
    String? mbtilesPath,
    String? prayerMethod,
    int? prayerOffsetMinutes,
    String? localeCode,
    String? carImagePath,
    bool? isAdhanSoundEnabled,
    double? homeLat,
    double? homeLng,
    String? homeLabel,
    double? workLat,
    double? workLng,
    String? workLabel,
    List<DockAppItem>? dockApps,
  }) {
    return LauncherSettings(
      carPlayPackage: carPlayPackage ?? this.carPlayPackage,
      autoLaunchCarPlay: autoLaunchCarPlay ?? this.autoLaunchCarPlay,
      obdMode: obdMode ?? this.obdMode,
      obdAddress: obdAddress ?? this.obdAddress,
      obdPort: obdPort ?? this.obdPort,
      mbtilesPath: mbtilesPath ?? this.mbtilesPath,
      prayerMethod: prayerMethod ?? this.prayerMethod,
      prayerOffsetMinutes: prayerOffsetMinutes ?? this.prayerOffsetMinutes,
      localeCode: localeCode ?? this.localeCode,
      carImagePath: carImagePath ?? this.carImagePath,
      isAdhanSoundEnabled: isAdhanSoundEnabled ?? this.isAdhanSoundEnabled,
      homeLat: homeLat ?? this.homeLat,
      homeLng: homeLng ?? this.homeLng,
      homeLabel: homeLabel ?? this.homeLabel,
      workLat: workLat ?? this.workLat,
      workLng: workLng ?? this.workLng,
      workLabel: workLabel ?? this.workLabel,
      dockApps: dockApps ?? this.dockApps,
    );
  }
}
