import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/launcher_settings.dart';
import '../services/native_bridge_service.dart';

class SettingsNotifier extends StateNotifier<LauncherSettings> {
  SettingsNotifier() : super(const LauncherSettings()) {
    _loadSettings();
  }

  static const _keyCarPlayPkg = 'carplay_package';
  static const _keyAutoLaunch = 'carplay_auto_launch';
  static const _keyObdMode = 'obd_mode';
  static const _keyObdAddress = 'obd_address';
  static const _keyObdPort = 'obd_port';
  static const _keyMbtilesPath = 'mbtiles_path';
  static const _keyPrayerMethod = 'prayer_method';
  static const _keyPrayerOffset = 'prayer_offset';
  static const _keyLocale = 'locale_code';
  static const _keyCarImage = 'car_image_path';
  static const _keyAdhanEnabled = 'adhan_sound_enabled';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    String? pkg = prefs.getString(_keyCarPlayPkg);
    if (pkg == null || pkg.isEmpty) {
      final detected = await NativeBridgeService.detectCarPlay();
      if (detected['isInstalled'] == true && detected['packageName'] != null) {
        pkg = detected['packageName'] as String;
      } else {
        pkg = 'com.suding.speedplay';
      }
    }

    state = LauncherSettings(
      carPlayPackage: pkg,
      autoLaunchCarPlay: prefs.getBool(_keyAutoLaunch) ?? true,
      obdMode: prefs.getString(_keyObdMode) ?? 'bluetooth',
      obdAddress: prefs.getString(_keyObdAddress) ?? '',
      obdPort: prefs.getInt(_keyObdPort) ?? 35000,
      mbtilesPath: prefs.getString(_keyMbtilesPath) ?? '/sdcard/CarLauncher/maps/uae.mbtiles',
      prayerMethod: prefs.getString(_keyPrayerMethod) ?? 'dubai',
      prayerOffsetMinutes: prefs.getInt(_keyPrayerOffset) ?? 0,
      localeCode: prefs.getString(_keyLocale) ?? 'ar',
      carImagePath: prefs.getString(_keyCarImage) ?? 'assets/images/accord_2012.png',
      isAdhanSoundEnabled: prefs.getBool(_keyAdhanEnabled) ?? true,
    );

    NativeBridgeService.configureObd(
      mode: state.obdMode,
      address: state.obdAddress.isNotEmpty ? state.obdAddress : null,
      port: state.obdPort,
    );
  }

  Future<void> setCarPlayPackage(String package) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCarPlayPkg, package);
    state = state.copyWith(carPlayPackage: package);
  }

  Future<void> setAutoLaunchCarPlay(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoLaunch, enabled);
    state = state.copyWith(autoLaunchCarPlay: enabled);
  }

  Future<void> setObdConfig({required String mode, required String address, required int port}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyObdMode, mode);
    await prefs.setString(_keyObdAddress, address);
    await prefs.setInt(_keyObdPort, port);

    state = state.copyWith(
      obdMode: mode,
      obdAddress: address,
      obdPort: port,
    );

    await NativeBridgeService.configureObd(
      mode: mode,
      address: address.isNotEmpty ? address : null,
      port: port,
    );
  }

  Future<void> setMbtilesPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMbtilesPath, path);
    state = state.copyWith(mbtilesPath: path);
  }

  Future<void> setPrayerMethod(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrayerMethod, method);
    state = state.copyWith(prayerMethod: method);
  }

  Future<void> setPrayerOffsetMinutes(int offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPrayerOffset, offset);
    state = state.copyWith(prayerOffsetMinutes: offset);
  }

  Future<void> setLocaleCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, code);
    state = state.copyWith(localeCode: code);
  }

  Future<void> toggleAdhanSound(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdhanEnabled, enabled);
    state = state.copyWith(isAdhanSoundEnabled: enabled);
  }

  void addDockApp(DockAppItem item) {
    final updated = List<DockAppItem>.from(state.dockApps)..add(item);
    state = state.copyWith(dockApps: updated);
  }

  void removeDockApp(int index) {
    if (index >= 0 && index < state.dockApps.length) {
      final updated = List<DockAppItem>.from(state.dockApps)..removeAt(index);
      state = state.copyWith(dockApps: updated);
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, LauncherSettings>((ref) {
  return SettingsNotifier();
});
