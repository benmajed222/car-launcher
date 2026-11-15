import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/launcher_settings.dart';
import '../../providers/settings_provider.dart';
import '../../services/native_bridge_service.dart';
import '../screens/apps_drawer_screen.dart';
import '../screens/settings_screen.dart';

class BottomDockWidget extends ConsumerWidget {
  const BottomDockWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isArabic = settings.localeCode == 'ar';

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: const Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Left Group: Settings Gear & App Drawer
          Row(
            children: [
              // Settings Icon Button
              _buildIconButton(
                icon: Icons.settings,
                color: AppColors.textSecondary,
                tooltip: isArabic ? 'الإعدادات' : 'Settings',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              // Apps Drawer Capsule Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AppsDrawerScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCardElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryCyan.withOpacity(0.5), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.apps, size: 18, color: AppColors.primaryCyan),
                        const SizedBox(width: 6),
                        Text(
                          isArabic ? 'التطبيقات' : 'Apps',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. Center Group: Customizable App Shortcuts
          Row(
            children: [
              // Render registered dock apps
              ...settings.dockApps.map((app) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildDockAppButton(
                    title: app.name,
                    icon: _getIconForType(app.iconType),
                    color: _getColorForType(app.iconType),
                    onTap: () => NativeBridgeService.launchApp(app.packageName),
                  ),
                );
              }).toList(),

              // Add App Shortcut (+) Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => _showAddShortcutDialog(context, ref),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCardElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Icon(Icons.add, size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),

          // 3. Right Group: Apple CarPlay Hero Button (Matching Mockup Exactly)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final success = await NativeBridgeService.launchCarPlay(settings.carPlayPackage);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? 'لم يتم العثور على تطبيق كاربلاي. يرجى تحديده من الإعدادات.'
                            : 'CarPlay link app not found. Check Settings.',
                      ),
                      backgroundColor: AppColors.dangerRed,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF2563EB),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryCyan, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCyan.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Apple CarPlay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          isArabic ? 'متصل وجاهز للفتح' : 'Connected & Ready',
                          style: const TextStyle(
                            color: AppColors.primaryEmerald,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.apple,
                      size: 24,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockAppButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceCardElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 18),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'android_auto':
        return Icons.navigation_outlined;
      case 'camera':
        return Icons.videocam;
      case 'phone':
        return Icons.phone;
      case 'radio':
        return Icons.radio;
      default:
        return Icons.open_in_new;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'android_auto':
        return AppColors.primaryCyan;
      case 'camera':
        return const Color(0xFFFF5252);
      case 'phone':
        return AppColors.primaryEmerald;
      case 'radio':
        return AppColors.accentGold;
      default:
        return AppColors.primaryCyan;
    }
  }

  void _showAddShortcutDialog(BuildContext context, WidgetRef ref) async {
    final apps = await NativeBridgeService.getAllInstalledApps();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر تطبيقاً لإضافته إلى الشريط السفلي:',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (c, idx) {
                    final a = apps[idx];
                    return ListTile(
                      leading: const Icon(Icons.android, color: AppColors.primaryCyan),
                      title: Text(a['appName'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                      onTap: () {
                        ref.read(settingsProvider.notifier).addDockApp(
                          DockAppItem(
                            name: a['appName'] ?? 'App',
                            packageName: a['packageName'] ?? '',
                            iconType: 'custom',
                          ),
                        );
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
