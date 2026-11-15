import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../services/native_bridge_service.dart';

class AppsDrawerScreen extends ConsumerStatefulWidget {
  const AppsDrawerScreen({super.key});

  @override
  ConsumerState<AppsDrawerScreen> createState() => _AppsDrawerScreenState();
}

class _AppsDrawerScreenState extends ConsumerState<AppsDrawerScreen> {
  List<Map<String, String>> _allApps = [];
  List<Map<String, String>> _filteredApps = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await NativeBridgeService.getAllInstalledApps();
    setState(() {
      _allApps = apps;
      _filteredApps = apps;
      _isLoading = false;
    });
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredApps = _allApps;
      });
    } else {
      setState(() {
        _filteredApps = _allApps
            .where((app) =>
                (app['appName'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
                (app['packageName'] ?? '').toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isArabic = settings.localeCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(isArabic ? 'تطبيقات النظام' : 'All Applications'),
          backgroundColor: AppColors.surfaceCard,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: isArabic ? 'إعدادات النظام' : 'System Settings',
              onPressed: () {
                NativeBridgeService.openSystemSettings();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: isArabic ? 'البحث عن تطبيق...' : 'Search apps...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primaryCyan),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
                  ),
                ),
              ),
            ),

            // Apps Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
                  : _filteredApps.isEmpty
                      ? Center(
                          child: Text(
                            isArabic ? 'لم يتم العثور على تطبيقات' : 'No applications found',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6, // 6 columns for 1280px landscape display
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: _filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = _filteredApps[index];
                            final appName = app['appName'] ?? 'App';
                            final pkg = app['packageName'] ?? '';

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  NativeBridgeService.launchApp(pkg);
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCard,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.cardBorder, width: 1),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceCardElevated,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.android,
                                          size: 28,
                                          color: AppColors.primaryCyan,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        appName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
