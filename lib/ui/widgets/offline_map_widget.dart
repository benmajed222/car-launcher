import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/clock_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../services/native_bridge_service.dart';
import '../../services/road_speed_limit_service.dart';

class OfflineMapWidget extends ConsumerStatefulWidget {
  const OfflineMapWidget({super.key});

  @override
  ConsumerState<OfflineMapWidget> createState() => _OfflineMapWidgetState();
}

class _OfflineMapWidgetState extends ConsumerState<OfflineMapWidget> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  double _currentZoom = 15.0;
  bool _isAutoFollow = true;

  late AnimationController _overspeedPulseController;

  @override
  void initState() {
    super.initState();
    _overspeedPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _overspeedPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clockState = ref.watch(clockProvider);
    final telemetry = ref.watch(telemetryProvider);
    final settings = ref.watch(settingsProvider);
    final isArabic = settings.localeCode == 'ar';

    final lat = clockState.gpsData.hasValidFix ? clockState.gpsData.latitude : 25.4052;
    final lng = clockState.gpsData.hasValidFix ? clockState.gpsData.longitude : 55.5136;
    final currentPoint = LatLng(lat, lng);
    final bearing = clockState.gpsData.bearing != 0.0 ? clockState.gpsData.bearing : 315.0;

    // Dynamically resolve real-time road, speed limit and compass heading
    final roadInfo = RoadSpeedLimitService.resolveCurrentRoad(
      latitude: lat,
      longitude: lng,
      bearing: bearing,
      currentSpeed: telemetry.speed,
    );

    // Check if offline map files exist
    final offlineDir = Directory(settings.mbtilesPath.replaceAll(RegExp(r'/[^/]+\.mbtiles$'), ''));
    final hasLocalOfflineFiles = offlineDir.existsSync();

    // Smoothly update camera when auto-follow is active
    if (_isAutoFollow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(currentPoint, _currentZoom);
          _mapController.rotate(bearing);
        } catch (_) {}
      });
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
            // 1. FlutterMap Interactive Engine
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentPoint,
                initialZoom: _currentZoom,
                initialRotation: bearing,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onPositionChanged: (pos, hasGesture) {
                  if (hasGesture) {
                    setState(() {
                      _isAutoFollow = false;
                    });
                  }
                },
              ),
              children: [
                // Offline Tile Layer (Local File System or Online Tile Sync)
                TileLayer(
                  urlTemplate: hasLocalOfflineFiles
                      ? 'file:///sdcard/CarLauncher/maps/{z}/{x}/{y}.png'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.aam.carlauncher',
                  tileBuilder: (context, tileWidget, tile) {
                    // Dark Luxury Matrix Filter matching mockup exactly
                    return ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        -0.85, 0, 0, 0, 210,
                        0, -0.85, 0, 0, 220,
                        0, 0, -0.85, 0, 240,
                        0, 0, 0, 1, 0,
                      ]),
                      child: tileWidget,
                    );
                  },
                ),

                // Simulated Road Navigation Guidance Line (Cyan Route)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [
                        LatLng(lat - 0.02, lng - 0.005),
                        LatLng(lat, lng),
                        LatLng(lat + 0.025, lng + 0.008),
                        LatLng(lat + 0.05, lng + 0.015),
                      ],
                      strokeWidth: 5.0,
                      color: AppColors.primaryCyan,
                    ),
                  ],
                ),

                // Vehicle Position & Direction Arrow Marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPoint,
                      width: 52,
                      height: 52,
                      child: Transform.rotate(
                        angle: (bearing * 3.141592653589793) / 180.0,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryCyan.withOpacity(0.25),
                                border: Border.all(color: AppColors.primaryCyan, width: 2),
                              ),
                            ),
                            const Icon(
                              Icons.navigation,
                              size: 26,
                              color: AppColors.primaryCyan,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 2. Top Header: Road Name Banner & Speed Limit Sign (Dynamic & Matching Mockup)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic Circular Speed Limit Sign: changes by road (e.g. 120 MAX, 100 MAX, 80 MAX, 60 MAX)
                  AnimatedBuilder(
                    animation: _overspeedPulseController,
                    builder: (context, child) {
                      final double glow = roadInfo.isOverspeed ? _overspeedPulseController.value * 10 : 0.0;
                      return Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: roadInfo.isOverspeed ? AppColors.dangerRed : const Color(0xFFE53935),
                            width: 3.5,
                          ),
                          boxShadow: [
                            if (roadInfo.isOverspeed)
                              BoxShadow(
                                color: AppColors.dangerRed.withOpacity(0.8),
                                blurRadius: glow + 4,
                                spreadRadius: glow / 2,
                              ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${roadInfo.speedLimit}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                            const Text(
                              'MAX',
                              style: TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 8),

                  // Dynamic Highway Banner (e.g. E311 شارع الشيخ محمد بن زايد)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.overlayDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder, width: 1),
                      ),
                      child: Row(
                        children: [
                          // Road Code Badge (E311, E11, E611, S116)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryCyan,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              roadInfo.code,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isArabic ? roadInfo.nameArabic : roadInfo.nameEnglish,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  roadInfo.directionSubtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.primaryEmerald,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Google Maps CarPlay 1-Tap Navigation Shortcuts (Home & Work)
            Positioned(
              top: 65,
              left: 10,
              child: Row(
                children: [
                  _buildCarPlayNavPill(
                    icon: Icons.home,
                    label: isArabic ? 'المنزل' : 'Home',
                    color: AppColors.primaryCyan,
                    onTap: () {
                      NativeBridgeService.navigateCarPlayMaps(
                        lat: settings.homeLat,
                        lng: settings.homeLng,
                        label: settings.homeLabel,
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildCarPlayNavPill(
                    icon: Icons.work,
                    label: isArabic ? 'العمل' : 'Work',
                    color: AppColors.accentGold,
                    onTap: () {
                      NativeBridgeService.navigateCarPlayMaps(
                        lat: settings.workLat,
                        lng: settings.workLng,
                        label: settings.workLabel,
                      );
                    },
                  ),
                ],
              ),
            ),

            // 4. Dynamic Bottom Compass & Offline Status (e.g. NW 315° | بدون إنترنت)
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.overlayDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                ),
                child: Text(
                  '${roadInfo.headingText} | ${isArabic ? "بدون إنترنت" : "Offline"}',
                  style: const TextStyle(
                    color: AppColors.primaryCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),

            // 5. Map Controls (Zoom +, Zoom -, Recenter)
            Positioned(
              bottom: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Recenter
                  _buildMapActionButton(
                    icon: _isAutoFollow ? Icons.gps_fixed : Icons.gps_not_fixed,
                    color: _isAutoFollow ? AppColors.primaryCyan : AppColors.textSecondary,
                    onTap: () {
                      setState(() {
                        _isAutoFollow = true;
                        _mapController.move(currentPoint, _currentZoom);
                      });
                    },
                  ),
                  const SizedBox(height: 6),
                  // Zoom In
                  _buildMapActionButton(
                    icon: Icons.add,
                    color: AppColors.textPrimary,
                    onTap: () {
                      setState(() {
                        _currentZoom = (_currentZoom + 1.0).clamp(3.0, 18.0);
                        _mapController.move(_mapController.camera.center, _currentZoom);
                      });
                    },
                  ),
                  const SizedBox(height: 6),
                  // Zoom Out
                  _buildMapActionButton(
                    icon: Icons.remove,
                    color: AppColors.textPrimary,
                    onTap: () {
                      setState(() {
                        _currentZoom = (_currentZoom - 1.0).clamp(3.0, 18.0);
                        _mapController.move(_mapController.camera.center, _currentZoom);
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarPlayNavPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.overlayDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.6), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.overlayDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
