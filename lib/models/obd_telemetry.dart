/**
 * Real-time vehicle telemetry model for 2012 Honda Accord (ISO 15765-4 CAN).
 */
class ObdTelemetry {
  final int speed;              // km/h (PID 010D)
  final int rpm;                // Engine RPM (PID 010C)
  final int coolantTemp;        // °C (PID 0105)
  final double voltage;         // Alternator/Battery V (ATRV)
  final int intakeTemp;         // °C (PID 010F)
  final int throttle;           // % (PID 0111)
  final bool isConnected;       // Connection status
  final String statusMessage;   // Diagnostics state

  const ObdTelemetry({
    this.speed = 0,
    this.rpm = 0,
    this.coolantTemp = 85,
    this.voltage = 13.8,
    this.intakeTemp = 35,
    this.throttle = 0,
    this.isConnected = false,
    this.statusMessage = 'Awaiting OBD-II connection...',
  });

  // Warning thresholds
  bool get isCoolantAmberAlert => coolantTemp > 98 && coolantTemp <= 103;
  bool get isCoolantCriticalAlert => coolantTemp > 103;
  bool get isVoltageLowAlert => (rpm > 500 && voltage < 13.2) || (rpm <= 500 && voltage < 12.2);
  bool get isRpmRedline => rpm >= 6500;

  factory ObdTelemetry.fromMap(Map<dynamic, dynamic> map) {
    return ObdTelemetry(
      speed: (map['speed'] as num?)?.toInt() ?? 0,
      rpm: (map['rpm'] as num?)?.toInt() ?? 0,
      coolantTemp: (map['coolantTemp'] as num?)?.toInt() ?? 85,
      voltage: (map['voltage'] as num?)?.toDouble() ?? 13.8,
      intakeTemp: (map['intakeTemp'] as num?)?.toInt() ?? 35,
      throttle: (map['throttle'] as num?)?.toInt() ?? 0,
      isConnected: map['isConnected'] as bool? ?? false,
      statusMessage: map['statusMessage'] as String? ?? 'Active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'speed': speed,
      'rpm': rpm,
      'coolantTemp': coolantTemp,
      'voltage': voltage,
      'intakeTemp': intakeTemp,
      'throttle': throttle,
      'isConnected': isConnected,
      'statusMessage': statusMessage,
    };
  }
}
