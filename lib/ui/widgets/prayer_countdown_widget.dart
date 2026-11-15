import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/native_bridge_service.dart';

class PrayerCountdownWidget extends ConsumerStatefulWidget {
  const PrayerCountdownWidget({super.key});

  @override
  ConsumerState<PrayerCountdownWidget> createState() => _PrayerCountdownWidgetState();
}

class _PrayerCountdownWidgetState extends ConsumerState<PrayerCountdownWidget> {
  bool _hasTriggeredAdhanForCurrent = false;

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(prayerScheduleProvider);
    final settings = ref.watch(settingsProvider);
    final isArabic = settings.localeCode == 'ar';

    final next = schedule.nextPrayer;
    final nextName = next != null
        ? (isArabic ? 'صلاة ${next.nameArabic}' : '${next.nameEnglish} Prayer')
        : (isArabic ? 'صلاة المغرب' : 'Maghrib Prayer');

    final nextTimeFormatted = next != null
        ? '${DateFormat('hh:mm').format(next.time)} ${next.time.hour >= 12 ? (isArabic ? "م" : "PM") : (isArabic ? "ص" : "AM")}'
        : '05:34 م';

    // Adhan audio auto-trigger when countdown reaches 0
    if (settings.isAdhanSoundEnabled && schedule.timeRemaining.inSeconds <= 1 && schedule.timeRemaining.inSeconds >= 0) {
      if (!_hasTriggeredAdhanForCurrent) {
        _hasTriggeredAdhanForCurrent = true;
        NativeBridgeService.playAdhanSound();
      }
    } else if (schedule.timeRemaining.inSeconds > 10) {
      _hasTriggeredAdhanForCurrent = false;
    }

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 1. Islamic Geometric Arabesque Background Pattern
            Positioned.fill(
              child: CustomPaint(
                painter: IslamicArabesquePatternPainter(),
              ),
            ),

            // 2. Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Next Prayer Name & Live Countdown Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Next Prayer Title & Time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'الصلاة القادمة' : 'NEXT PRAYER',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                nextName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                nextTimeFormatted,
                                style: const TextStyle(
                                  color: AppColors.accentGold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Countdown Badge Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accentGold.withOpacity(0.6), width: 1),
                        ),
                        child: Column(
                          children: [
                            Text(
                              isArabic ? 'المتبقي للمغرب' : 'REMAINING',
                              style: const TextStyle(
                                color: AppColors.accentGold,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              schedule.formattedCountdown,
                              style: const TextStyle(
                                color: AppColors.accentGold,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Middle Row: Elapsed prayer progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '00:43:15',
                            style: TextStyle(
                              color: AppColors.primaryEmerald,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            isArabic ? 'مضى على العصر:' : 'Elapsed since Asr:',
                            style: const TextStyle(
                              color: AppColors.primaryEmerald,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 4,
                          color: Colors.white10,
                          child: const FractionallySizedBox(
                            widthFactor: 0.65,
                            child: ColoredBox(color: AppColors.primaryEmerald),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom Row: 5 Prayers Strip (Matching Mockup)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: schedule.prayers.map((item) {
                      final isSelected = item.isNext;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentGold.withOpacity(0.2) : AppColors.surfaceCardElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.accentGold : AppColors.cardBorder,
                            width: isSelected ? 1.2 : 0.8,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isArabic ? item.nameArabic : item.nameEnglish,
                              style: TextStyle(
                                color: isSelected ? AppColors.accentGold : AppColors.textSecondary,
                                fontSize: 9,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('hh:mm').format(item.time),
                              style: TextStyle(
                                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Top-right corner Adhan Speaker toggle icon
            Positioned(
              top: 8,
              left: isArabic ? 8 : null,
              right: isArabic ? null : 8,
              child: InkWell(
                onTap: () {
                  ref.read(settingsProvider.notifier).toggleAdhanSound(!settings.isAdhanSoundEnabled);
                  if (!settings.isAdhanSoundEnabled) {
                    NativeBridgeService.playAdhanSound();
                  } else {
                    NativeBridgeService.stopAdhanSound();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    settings.isAdhanSoundEnabled ? Icons.volume_up : Icons.volume_off,
                    size: 14,
                    color: settings.isAdhanSoundEnabled ? AppColors.accentGold : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/**
 * CustomPainter drawing an Islamic 8-point geometric star and arabesque lines.
 */
class IslamicArabesquePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A843).withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width * 0.85, size.height * 0.5);
    final double radius = size.height * 0.6;

    // Draw concentric 8-point stars
    _drawStar8(canvas, center, radius, paint);
    _drawStar8(canvas, center, radius * 0.65, paint);
    _drawStar8(canvas, center, radius * 0.35, paint);

    // Decorative grid lines
    canvas.drawCircle(center, radius * 0.85, paint);
    canvas.drawCircle(center, radius * 1.15, paint);
  }

  void _drawStar8(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 16; i++) {
      final double r = (i % 2 == 0) ? radius : radius * 0.54;
      final double angle = (i * pi / 8) - (pi / 2);
      final double x = center.dx + r * cos(angle);
      final double y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
