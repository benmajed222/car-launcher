import 'dart:async';
import 'package:flutter/services.dart';
import '../models/obd_telemetry.dart';

class ObdService {
  static const EventChannel _streamChannel = EventChannel('car_launcher/obd_stream');

  static Stream<ObdTelemetry> get telemetryStream {
    return _streamChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
          if (event is Map) {
            return ObdTelemetry.fromMap(event);
          }
          return const ObdTelemetry();
        })
        .handleError((error) {
          return ObdTelemetry(
            isConnected: false,
            statusMessage: 'Telemetry stream error: $error',
          );
        });
  }
}
