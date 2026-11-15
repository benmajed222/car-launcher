import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gps_clock_service.dart';

class ClockState {
  final DateTime currentTime;
  final GpsFixData gpsData;

  const ClockState({
    required this.currentTime,
    this.gpsData = const GpsFixData(),
  });
}

class ClockNotifier extends StateNotifier<ClockState> {
  StreamSubscription<GpsFixData>? _gpsSub;
  Timer? _timer;
  GpsFixData _latestGps = const GpsFixData();

  ClockNotifier()
      : super(ClockState(
          currentTime: DateTime.now().toUtc().add(const Duration(hours: 4)),
        )) {
    _init();
  }

  void _init() {
    _gpsSub = GpsClockService.gpsStream.listen((data) {
      _latestGps = data;
      _updateTime();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTime();
    });
  }

  void _updateTime() {
    final calibrated = GpsClockService.getCalibratedTime(_latestGps);
    state = ClockState(
      currentTime: calibrated,
      gpsData: _latestGps,
    );
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}

final clockProvider = StateNotifierProvider<ClockNotifier, ClockState>((ref) {
  return ClockNotifier();
});
