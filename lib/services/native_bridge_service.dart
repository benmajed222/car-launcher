import 'package:flutter/services.dart';

class NativeBridgeService {
  static const MethodChannel _carPlayChannel = MethodChannel('car_launcher/carplay');
  static const MethodChannel _obdControlChannel = MethodChannel('car_launcher/obd_control');
  static const MethodChannel _systemChannel = MethodChannel('car_launcher/system');

  // ================= CARPLAY & NAVIGATION ================= //

  static Future<Map<String, dynamic>> detectCarPlay() async {
    try {
      final res = await _carPlayChannel.invokeMethod<Map<dynamic, dynamic>>('detectCarPlay');
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } catch (_) {}
    return {'isInstalled': false, 'packageName': null};
  }

  static Future<List<Map<String, String>>> getAllLinkApps() async {
    try {
      final res = await _carPlayChannel.invokeListMethod<Map<dynamic, dynamic>>('getAllLinkApps');
      if (res != null) {
        return res.map((item) => Map<String, String>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> launchCarPlay([String? targetPackage]) async {
    try {
      final res = await _carPlayChannel.invokeMethod<bool>('launchCarPlay', {
        'targetPackage': targetPackage,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> navigateCarPlayMaps({
    required double lat,
    required double lng,
    required String label,
  }) async {
    try {
      final res = await _carPlayChannel.invokeMethod<bool>('navigateCarPlayMaps', {
        'lat': lat,
        'lng': lng,
        'label': label,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  // ================= OBD-II CONTROL ================= //

  static Future<bool> configureObd({
    required String mode,
    String? address,
    int port = 35000,
  }) async {
    try {
      final res = await _obdControlChannel.invokeMethod<bool>('configureObd', {
        'mode': mode,
        'address': address,
        'port': port,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, String>>> getPairedBluetoothDevices() async {
    try {
      final res = await _obdControlChannel.invokeListMethod<Map<dynamic, dynamic>>('getPairedDevices');
      if (res != null) {
        return res.map((item) => Map<String, String>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<String> sendRawObdCommand(String command) async {
    try {
      final res = await _obdControlChannel.invokeMethod<String>('sendRawCommand', {
        'command': command,
      });
      return res ?? 'No response';
    } catch (e) {
      return 'Error: $e';
    }
  }

  static Future<bool> reconnectObd() async {
    try {
      final res = await _obdControlChannel.invokeMethod<bool>('reconnectObd');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  // ================= SYSTEM & HARDWARE UTILITIES ================= //

  static Future<List<Map<String, String>>> getAllInstalledApps() async {
    try {
      final res = await _systemChannel.invokeListMethod<Map<dynamic, dynamic>>('getAllInstalledApps');
      if (res != null) {
        return res.map((item) => Map<String, String>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> launchApp(String packageName) async {
    try {
      final res = await _systemChannel.invokeMethod<bool>('launchApp', {
        'packageName': packageName,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<double> getVolume() async {
    try {
      final res = await _systemChannel.invokeMethod<double>('getVolume');
      return res ?? 0.5;
    } catch (_) {
      return 0.5;
    }
  }

  static Future<bool> setVolume(double level) async {
    try {
      final res = await _systemChannel.invokeMethod<bool>('setVolume', {
        'level': level,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setScreenBrightness(double brightness) async {
    try {
      final res = await _systemChannel.invokeMethod<bool>('setScreenBrightness', {
        'brightness': brightness,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openSystemSettings() async {
    try {
      await _systemChannel.invokeMethod('openSystemSettings');
    } catch (_) {}
  }

  static Future<void> openWifiSettings() async {
    try {
      await _systemChannel.invokeMethod('openWifiSettings');
    } catch (_) {}
  }

  static Future<void> openBluetoothSettings() async {
    try {
      await _systemChannel.invokeMethod('openBluetoothSettings');
    } catch (_) {}
  }

  static Future<void> playAdhanSound() async {
    try {
      await _systemChannel.invokeMethod('playAdhanSound');
    } catch (_) {}
  }

  static Future<void> stopAdhanSound() async {
    try {
      await _systemChannel.invokeMethod('stopAdhanSound');
    } catch (_) {}
  }
}
