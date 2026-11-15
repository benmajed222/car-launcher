import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/telemetry_provider.dart';
import '../../providers/settings_provider.dart';
import 'honda_logo_widget.dart';

class VehicleClusterWidget extends ConsumerWidget {
  const VehicleClusterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);
    final settings = ref.watch(settingsProvider);
    final isArabic = settings.localeCode == 'ar';

    // Calculate gear estimation based on speed and RPM for 2012 Accord 5-speed automatic
    String gear = 'P';
    if (telemetry.speed == 0 && telemetry.rpm < 900) {
      gear = 'P';
    } else if (telemetry.speed < 20) {
      gear = 'D1';
    } else if (telemetry.speed < 45) {
      gear = 'D2';
    } else if (telemetry.speed < 70) {
      gear = 'D3';
    } else if (telemetry.speed < 100) {
      gear = 'D4';
    } else {
      gear = 'D5';
    }

    final double rpmValue = telemetry.rpm / 1000.0;
    final int speedValue = telemetry.speed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header: Official Chrome Honda Emblem & Accord Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dedicated Chrome Honda Logo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCardElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const HondaLogoWidget(
                  width: 38,
                  height: 28,
                  brand: 'honda',
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isArabic ? 'بيانات كمبيوتر السيارة الحية' : 'LIVE VEHICLE TELEMETRY',
                    style: const TextStyle(
                      color: AppColors.primaryCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    isArabic ? 'هوندا أكورد - 2012' : 'HONDA ACCORD - 2012',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 2. Twin Circular Gauges: RPM (Left) & Speed (Right)
          Expanded(
            flex: 6,
            child: Row(
              children: [
                // Gauge 1: Engine RPM & Gear Indicator
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: CustomPaint(
                        painter: CircularArcGaugePainter(
                          value: (telemetry.rpm / 7000.0).clamp(0.0, 1.0),
                          activeColor: telemetry.isRpmRedline ? AppColors.dangerRed : AppColors.primaryEmerald,
                          trackColor: Colors.white10,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                rpmValue.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const Text(
                                'RPM x1000',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCardElevated,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Text(
                                  gear,
                                  style: const TextStyle(
                                    color: AppColors.primaryCyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Gauge 2: Vehicle Speed
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: CustomPaint(
                        painter: CircularArcGaugePainter(
                          value: (telemetry.speed / 200.0).clamp(0.0, 1.0),
                          activeColor: AppColors.primaryCyan,
                          trackColor: Colors.white10,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$speedValue',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                isArabic ? 'كم / ساعة' : 'KM / H',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'OBD SPEED',
                                style: TextStyle(
                                  color: AppColors.primaryCyan,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Linear Tachometer Redline Bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('REDLINE 7', style: TextStyle(color: AppColors.dangerRed, fontSize: 8, fontWeight: FontWeight.bold)),
                  Text('6', style: TextStyle(color: AppColors.textMuted, fontSize: 8)),
                  Text('4', style: TextStyle(color: AppColors.textMuted, fontSize: 8)),
                  Text('2', style: TextStyle(color: AppColors.textMuted, fontSize: 8)),
                  Text('0', style: TextStyle(color: AppColors.textMuted, fontSize: 8)),
                ],
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 6,
                  color: Colors.black45,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final ratio = (telemetry.rpm / 7000.0).clamp(0.0, 1.0);
                      return Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: ratio,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryEmerald,
                                    AppColors.primaryCyan,
                                    AppColors.accentGold,
                                    AppColors.dangerRed,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 4. Bottom 3 Diagnostic Cards
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Card 1: Engine Load & Intake Temp
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.bar_chart,
                    iconColor: AppColors.accentGold,
                    title: isArabic ? 'حمل المحرك' : 'ENGINE LOAD',
                    value: '%${telemetry.throttle}',
                    subtitle: 'هواء ${telemetry.intakeTemp}°C',
                  ),
                ),
                const SizedBox(width: 8),

                // Card 2: Battery & Charging Status
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.bolt,
                    iconColor: AppColors.primaryCyan,
                    title: isArabic ? 'البطارية' : 'BATTERY',
                    value: '${telemetry.voltage.toStringAsFixed(1)}V',
                    subtitle: telemetry.voltage >= 13.5 ? 'شحن ممتاز' : 'جهد طبيعي',
                  ),
                ),
                const SizedBox(width: 8),

                // Card 3: Coolant Temp
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.thermostat,
                    iconColor: telemetry.isCoolantCriticalAlert ? AppColors.dangerRed : (telemetry.isCoolantAmberAlert ? AppColors.warningAmber : AppColors.primaryEmerald),
                    title: isArabic ? 'حرارة المحرك' : 'COOLANT',
                    value: '${telemetry.coolantTemp}°C',
                    subtitle: telemetry.isCoolantCriticalAlert ? 'تحذير حرارة!' : 'طبيعية',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 14, color: iconColor),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              value,
              style: TextStyle(
                color: iconColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Center(
            child: Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/**
 * CustomPainter for the circular arc speedometer / tachometer gauges.
 */
class CircularArcGaugePainter extends CustomPainter {
  final double value; // 0.0 to 1.0
  final Color activeColor;
  final Color trackColor;

  CircularArcGaugePainter({
    required this.value,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 8.0;

    const startAngle = 135.0 * (pi / 180.0);
    const sweepTotal = 270.0 * (pi / 180.0);

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    // Active Arc
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * value,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CircularArcGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.activeColor != activeColor;
  }
}
