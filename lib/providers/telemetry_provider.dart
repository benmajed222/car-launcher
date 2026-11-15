import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/obd_telemetry.dart';
import '../services/obd_service.dart';

class TelemetryNotifier extends StateNotifier<ObdTelemetry> {
  StreamSubscription<ObdTelemetry>? _subscription;
  Timer? _simulationTimer;
  bool _isSimulation = false;

  TelemetryNotifier() : super(const ObdTelemetry()) {
    _startListening();
  }

  void _startListening() {
    _subscription = ObdService.telemetryStream.listen(
      (telemetry) {
        if (!_isSimulation) {
          state = telemetry;
        }
      },
      onError: (err) {
        if (!_isSimulation) {
          state = state = ObdTelemetry(
            isConnected: false,
            statusMessage: 'Error: $err',
          );
        }
      },
    );
  }

  void toggleSimulation(bool enable) {
    _isSimulation = enable;
    _simulationTimer?.cancel();

    if (_isSimulation) {
      int tick = 0;
      _simulationTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
        tick++;
        final mockSpeed = (tick * 3) % 140;
        final mockRpm = 800 + ((tick * 120) % 5500);
        final mockCoolant = 88 + (tick % 6);
        final mockVoltage = 14.1;

        state = ObdTelemetry(
          speed: mockSpeed,
          rpm: mockRpm,
          coolantTemp: mockCoolant,
          voltage: mockVoltage,
          intakeTemp: 38,
          throttle: (mockSpeed * 100 ~/ 160),
          isConnected: true,
          statusMessage: 'Bench Simulation Active',
        );
      });
    } else {
      state = const ObdTelemetry(
        isConnected: false,
        statusMessage: 'Awaiting real OBD-II adapter...',
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }
}

final telemetryProvider = StateNotifierProvider<TelemetryNotifier, ObdTelemetry>((ref) {
  return TelemetryNotifier();
});
