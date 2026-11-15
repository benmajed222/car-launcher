import 'dart:async';
import 'package:flutter/services.dart';

class GpsFixData {
  final int utcMillis;
  final int timeOffsetMs;
  final bool hasValidFix;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double bearing;

  const GpsFixData({
    this.utcMillis = 0,
    this.timeOffsetMs = 0,
    this.hasValidFix = false,
    this.latitude = 25.4052,
    this.longitude = 55.5136,
    this.speedKmh = 0.0,
    this.bearing = 0.0,
  });

  factory GpsFixData.fromMap(Map<dynamic, dynamic> map) {
    return GpsFixData(
      utcMillis: (map['utcMillis'] as num?)?.toInt() ?? 0,
      timeOffsetMs: (map['timeOffsetMs'] as num?)?.toInt() ?? 0,
      hasValidFix: map['hasValidFix'] as bool? ?? false,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 25.4052,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 55.5136,
      speedKmh: (map['speedKmh'] as num?)?.toDouble() ?? 0.0,
      bearing: (map['bearing'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GpsClockService {
  static const EventChannel _gpsTimeChannel = EventChannel('car_launcher/gps_time');

  static Stream<GpsFixData> get gpsStream {
    return _gpsTimeChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
          if (event is Map) {
            return GpsFixData.fromMap(event);
          }
          return const GpsFixData();
        })
        .handleError((error) {
          return const GpsFixData();
        });
  }

  // Returns calibrated DateTime in Asia/Dubai (UTC+4)
  static DateTime getCalibratedTime(GpsFixData fixData) {
    DateTime utcDate;
    if (fixData.hasValidFix && fixData.utcMillis > 1600000000000) {
      utcDate = DateTime.fromMillisecondsSinceEpoch(fixData.utcMillis, isUtc: true);
    } else {
      utcDate = DateTime.now().toUtc();
    }
    // Gulf Standard Time (GST) is always UTC+4 with no Daylight Saving Time
    return utcDate.add(const Duration(hours: 4));
  }
}
