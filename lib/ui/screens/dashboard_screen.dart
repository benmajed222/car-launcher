import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../widgets/top_status_bar_widget.dart';
import '../widgets/vehicle_cluster_widget.dart';
import '../widgets/offline_map_widget.dart';
import '../widgets/gps_clock_widget.dart';
import '../widgets/prayer_countdown_widget.dart';
import '../widgets/media_widget.dart';
import '../widgets/bottom_dock_widget.dart';

/**
 * 1280x720 Fixed Landscape Automotive Cockpit Dashboard for 10.1 Inch Display.
 * Pixel-accurate match to the automotive HUD design blueprint.
 */
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Enforce full landscape lock & sticky immersive mode for 10.1 inch display
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isArabic = settings.localeCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Column(
              children: [
                // 1. Top Status Bar (Controls, Weather, Voltage, Title, OBD/GPS)
                const TopStatusBarWidget(),

                const SizedBox(height: 6),

                // 2. Main 3-Zone Automotive Split Grid
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Zone 1 (Left): Clock, Prayer with Islamic Background, Media Now Playing
                      Expanded(
                        flex: 25,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            // 1. Digital Clock & Gregorian/Hijri Date
                            Expanded(
                              flex: 28,
                              child: GpsClockWidget(),
                            ),
                            SizedBox(height: 6),
                            // 2. Islamic Prayer Countdown with Arabesque Pattern & Adhan Audio
                            Expanded(
                              flex: 42,
                              child: PrayerCountdownWidget(),
                            ),
                            SizedBox(height: 6),
                            // 3. Apple CarPlay Media Now Playing Card
                            Expanded(
                              flex: 30,
                              child: MediaWidget(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Zone 2 (Center): Animated Interactive Offline Map Engine
                      const Expanded(
                        flex: 40,
                        child: OfflineMapWidget(),
                      ),

                      const SizedBox(width: 8),

                      // Zone 3 (Right): Live Vehicle Computer (Twin Gauges, Redline, Diagnostics)
                      const Expanded(
                        flex: 35,
                        child: VehicleClusterWidget(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // 3. Bottom Dock (Apps Drawer, Shortcuts, CarPlay Hero Button)
                const BottomDockWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
