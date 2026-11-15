import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/clock_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../services/native_bridge_service.dart';

class TopStatusBarWidget extends ConsumerWidget {
  const TopStatusBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);
    final clockState = ref.watch(clockProvider);
    final settings = ref.watch(settingsProvider);
    final isArabic = settings.localeCode == 'ar';

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Group: Quick Controls & Environmental Status
          Row(
            children: [
              // 1. Day / Night / Brightness Toggle
              InkWell(
                onTap: () {
                  // Quick toggle
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(Icons.wb_sunny_outlined, size: 16, color: AppColors.accentGold),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Wi-Fi Status & Settings Shortcut
              InkWell(
                onTap: () => NativeBridgeService.openWifiSettings(),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(Icons.wifi, size: 16, color: AppColors.primaryCyan),
                ),
              ),
              const SizedBox(width: 8),

              // 3. Bluetooth Status & Settings Shortcut
              InkWell(
                onTap: () => NativeBridgeService.openBluetoothSettings(),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(Icons.bluetooth, size: 16, color: AppColors.primaryCyan),
                ),
              ),
              const SizedBox(width: 12),

              // 4. Ambient Temperature
              const Text(
                '28°C',
                style: TextStyle(
                  color: AppColors.accentGold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 10),

              // 5. Battery Voltage
              Text(
                '${telemetry.voltage.toStringAsFixed(1)}V',
                style: const TextStyle(
                  color: AppColors.primaryEmerald,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          // Center Group: Location & Vehicle Model
          Text(
            isArabic
                ? 'عجمان / الشارقة - الإمارات • HONDA ACCORD 2012'
                : 'Ajman / Sharjah - UAE • HONDA ACCORD 2012',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),

          // Right Group: OBD Status & GPS Satellites Fix Pills
          Row(
            children: [
              // OBD-II Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: telemetry.isConnected ? AppColors.primaryEmerald.withOpacity(0.15) : AppColors.warningAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: telemetry.isConnected ? AppColors.primaryEmerald.withOpacity(0.4) : AppColors.warningAmber.withOpacity(0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: telemetry.isConnected ? AppColors.primaryEmerald : AppColors.warningAmber,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      telemetry.isConnected ? 'OBD-II متصل • CAN 500k' : 'OBD-II جاري الاتصال...',
                      style: TextStyle(
                        color: telemetry.isConnected ? AppColors.primaryEmerald : AppColors.warningAmber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // GPS Satellite Clock Sync Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: clockState.gpsData.hasValidFix ? AppColors.primaryEmerald.withOpacity(0.15) : AppColors.primaryCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: clockState.gpsData.hasValidFix ? AppColors.primaryEmerald.withOpacity(0.4) : AppColors.primaryCyan.withOpacity(0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.language,
                      size: 12,
                      color: clockState.gpsData.hasValidFix ? AppColors.primaryEmerald : AppColors.primaryCyan,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      clockState.gpsData.hasValidFix ? '11 قمر • الوقت مضبوط GPS' : 'GPS مزامنة الأقمار',
                      style: TextStyle(
                        color: clockState.gpsData.hasValidFix ? AppColors.primaryEmerald : AppColors.primaryCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
