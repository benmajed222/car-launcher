import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../services/native_bridge_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // CarPlay state
  List<Map<String, String>> _detectedLinkApps = [];
  final TextEditingController _customCarPlayController = TextEditingController();

  // OBD state
  List<Map<String, String>> _pairedBtDevices = [];
  final TextEditingController _wifiIpController = TextEditingController();
  final TextEditingController _wifiPortController = TextEditingController();
  final TextEditingController _rawCmdController = TextEditingController();
  String _rawConsoleOutput = 'OBD-II console ready. Send ATZ or ATRV to test.';

  // Map state
  final TextEditingController _mapPathController = TextEditingController();

  // Hardware controls
  double _currentVolume = 0.7;
  double _currentBrightness = 1.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final settings = ref.read(settingsProvider);
    _customCarPlayController.text = settings.carPlayPackage;
    _wifiIpController.text = settings.obdAddress.isNotEmpty ? settings.obdAddress : '192.168.0.10';
    _wifiPortController.text = settings.obdPort.toString();
    _mapPathController.text = settings.mbtilesPath;

    final linkApps = await NativeBridgeService.getAllLinkApps();
    final btDevices = await NativeBridgeService.getPairedBluetoothDevices();
    final vol = await NativeBridgeService.getVolume();

    setState(() {
      _detectedLinkApps = linkApps;
      _pairedBtDevices = btDevices;
      _currentVolume = vol;
    });
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
          title: Text(isArabic ? 'إعدادات المنظومة (BenMajed Cockpit)' : 'BenMajed Cockpit Settings'),
          backgroundColor: AppColors.surfaceCard,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppColors.primaryCyan,
            labelColor: AppColors.primaryCyan,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(icon: const Icon(Icons.apple), text: isArabic ? 'آبل كاربلاي' : 'Apple CarPlay'),
              Tab(icon: const Icon(Icons.speed), text: isArabic ? 'حساسات OBD-II' : 'OBD-II Telemetry'),
              Tab(icon: const Icon(Icons.map), text: isArabic ? 'الخرائط أوفلاين' : 'Offline Maps'),
              Tab(icon: const Icon(Icons.mosque), text: isArabic ? 'أوقات الصلاة' : 'Prayer Times'),
              Tab(icon: const Icon(Icons.tune), text: isArabic ? 'المركبة والشاشة' : 'Display & Vehicle'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCarPlayTab(settings, isArabic),
            _buildObdTab(settings, isArabic),
            _buildMapsTab(settings, isArabic),
            _buildPrayerTab(settings, isArabic),
            _buildDisplayVehicleTab(settings, isArabic),
          ],
        ),
      ),
    );
  }

  // ================= TAB 1: APPLE CARPLAY ================= //
  Widget _buildCarPlayTab(dynamic settings, bool isArabic) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(isArabic ? 'تكامل آبل كاربلاي (Apple CarPlay)' : 'Apple CarPlay Integration'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? 'حدد تطبيق كاربلاي المثبت في نظام الشاشة (XY Auto T100):'
                      : 'Select the factory CarPlay link app installed on XY Auto T100:',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (_detectedLinkApps.isEmpty)
                  Text(
                    isArabic ? 'لم يتم العثور على حزم تلقائية، اكتب اسم الحزمة يدوياً:' : 'No link packages auto-detected. Enter manually below:',
                    style: const TextStyle(color: AppColors.warningAmber, fontSize: 12),
                  )
                else
                  ..._detectedLinkApps.map((app) {
                    final pkg = app['packageName'] ?? '';
                    final name = app['appName'] ?? pkg;

                    return RadioListTile<String>(
                      value: pkg,
                      groupValue: settings.carPlayPackage,
                      activeColor: AppColors.carPlayGreen,
                      title: Text('$name ($pkg)', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsProvider.notifier).setCarPlayPackage(val);
                          _customCarPlayController.text = val;
                        }
                      },
                    );
                  }).toList(),

                const SizedBox(height: 12),
                TextField(
                  controller: _customCarPlayController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: isArabic ? 'اسم حزمة التطبيق المخصص' : 'Custom CarPlay Package Name',
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (val) {
                    ref.read(settingsProvider.notifier).setCarPlayPackage(val.trim());
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(
                    isArabic ? 'تشغيل كاربلاي تلقائياً عند توصيل الآيفون' : 'Auto-launch Apple CarPlay when iPhone connects',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  ),
                  value: settings.autoLaunchCarPlay,
                  activeColor: AppColors.carPlayGreen,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setAutoLaunchCarPlay(val);
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.launch, color: Colors.black),
                  label: Text(isArabic ? 'اختبار تشغيل آبل كاربلاي الآن' : 'Test Launch Apple CarPlay Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.carPlayGreen,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    NativeBridgeService.launchCarPlay(settings.carPlayPackage);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= TAB 2: OBD-II TELEMETRY & CONSOLE ================= //
  Widget _buildObdTab(dynamic settings, bool isArabic) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(isArabic ? 'اتصال محول OBD-II (ELM327)' : 'OBD-II (ELM327) Connection'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'bluetooth',
                        groupValue: settings.obdMode,
                        title: const Text('Bluetooth SPP', style: TextStyle(color: AppColors.textPrimary)),
                        activeColor: AppColors.primaryCyan,
                        onChanged: (val) {
                          ref.read(settingsProvider.notifier).setObdConfig(
                            mode: 'bluetooth',
                            address: settings.obdAddress,
                            port: settings.obdPort,
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'wifi',
                        groupValue: settings.obdMode,
                        title: const Text('Wi-Fi Socket', style: TextStyle(color: AppColors.textPrimary)),
                        activeColor: AppColors.primaryCyan,
                        onChanged: (val) {
                          ref.read(settingsProvider.notifier).setObdConfig(
                            mode: 'wifi',
                            address: _wifiIpController.text.trim(),
                            port: int.tryParse(_wifiPortController.text.trim()) ?? 35000,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(),
                if (settings.obdMode == 'bluetooth') ...[
                  Text(
                    isArabic ? 'الأجهزة المقترنة بالبلوتوث:' : 'Paired Bluetooth Devices:',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  if (_pairedBtDevices.isEmpty)
                    Text(
                      isArabic ? 'لا توجد أجهزة بلوتوث مقترنة.' : 'No paired Bluetooth devices found.',
                      style: const TextStyle(color: AppColors.warningAmber, fontSize: 12),
                    )
                  else
                    ..._pairedBtDevices.map((d) {
                      final name = d['name'] ?? 'Device';
                      final addr = d['address'] ?? '';
                      final isSelected = settings.obdAddress == addr;
                      return ListTile(
                        leading: Icon(Icons.bluetooth, color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary),
                        title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        subtitle: Text(addr, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryCyan) : null,
                        onTap: () {
                          ref.read(settingsProvider.notifier).setObdConfig(
                            mode: 'bluetooth',
                            address: addr,
                            port: settings.obdPort,
                          );
                        },
                      );
                    }).toList(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.bluetooth_searching),
                    label: Text(isArabic ? 'فتح إعدادات البلوتوث للاقتران' : 'Open Bluetooth Settings'),
                    onPressed: () => NativeBridgeService.openBluetoothSettings(),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _wifiIpController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(labelText: 'Wi-Fi IP (192.168.0.10)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _wifiPortController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(labelText: 'Port (35000)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= TAB 3: OFFLINE MAPS ================= //
  Widget _buildMapsTab(dynamic settings, bool isArabic) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(isArabic ? 'الخرائط أوفلاين (Offline Maps)' : 'Offline Maps Configuration'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _mapPathController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Maps Directory / MBTiles Path',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (val) {
                    ref.read(settingsProvider.notifier).setMbtilesPath(val.trim());
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= TAB 4: PRAYER TIMES ================= //
  Widget _buildPrayerTab(dynamic settings, bool isArabic) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(isArabic ? 'حساب مواقيت الصلاة والأذان' : 'Prayer Times & Adhan Audio'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(
                    isArabic ? 'تشغيل صوت الأذان التلقائي وقت دخول الصلاة' : 'Play Adhan audio when prayer time arrives',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  ),
                  value: settings.isAdhanSoundEnabled,
                  activeColor: AppColors.accentGold,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).toggleAdhanSound(val);
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.volume_up),
                  label: Text(isArabic ? 'اختبار صوت الأذان الآن' : 'Test Adhan Audio Now'),
                  onPressed: () => NativeBridgeService.playAdhanSound(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= TAB 5: DISPLAY, VOLUME & VEHICLE ================= //
  Widget _buildDisplayVehicleTab(dynamic settings, bool isArabic) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(isArabic ? 'إضاءة الشاشة والتحكم بالصوت' : 'Screen Brightness & Volume Control'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Brightness Slider
                Row(
                  children: [
                    const Icon(Icons.brightness_medium, color: AppColors.accentGold),
                    const SizedBox(width: 12),
                    Text(isArabic ? 'إضاءة الشاشة:' : 'Brightness:', style: const TextStyle(color: AppColors.textPrimary)),
                    Expanded(
                      child: Slider(
                        value: _currentBrightness,
                        min: 0.1,
                        max: 1.0,
                        activeColor: AppColors.accentGold,
                        onChanged: (val) {
                          setState(() => _currentBrightness = val);
                          NativeBridgeService.setScreenBrightness(val);
                        },
                      ),
                    ),
                    Text('${(_currentBrightness * 100).toInt()}%', style: const TextStyle(color: AppColors.accentGold)),
                  ],
                ),
                const Divider(),
                // Volume Slider
                Row(
                  children: [
                    const Icon(Icons.volume_up, color: AppColors.primaryCyan),
                    const SizedBox(width: 12),
                    Text(isArabic ? 'مستوى الصوت:' : 'Volume:', style: const TextStyle(color: AppColors.textPrimary)),
                    Expanded(
                      child: Slider(
                        value: _currentVolume,
                        min: 0.0,
                        max: 1.0,
                        activeColor: AppColors.primaryCyan,
                        onChanged: (val) {
                          setState(() => _currentVolume = val);
                          NativeBridgeService.setVolume(val);
                        },
                      ),
                    ),
                    Text('${(_currentVolume * 100).toInt()}%', style: const TextStyle(color: AppColors.primaryCyan)),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        _buildSectionHeader(isArabic ? 'نوع وشعار السيارة' : 'Vehicle Brand & Profile'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.directions_car, color: AppColors.primaryCyan),
                  title: const Text('Honda Accord 2012 / Hyundai', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('ISO 15765-4 CAN 500k', style: TextStyle(color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primaryCyan,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
