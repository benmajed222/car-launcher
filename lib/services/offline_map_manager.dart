import 'dart:io';
import 'dart:math';

class MapStatus {
  final bool hasOfflineTiles;
  final int tileCount;
  final double sizeMB;
  final String path;

  const MapStatus({
    required this.hasOfflineTiles,
    required this.tileCount,
    required this.sizeMB,
    required this.path,
  });
}

/**
 * Manages downloading, updating and caching high-detail offline map tiles for the UAE.
 * Tiles are saved to /sdcard/CarLauncher/maps/{z}/{x}/{y}.png for 100% offline rendering.
 */
class OfflineMapManager {
  static const String defaultMapDir = '/sdcard/CarLauncher/maps';

  // Tile coordinate conversion math (Web Mercator)
  static int lon2tile(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  static int lat2tile(double lat, int zoom) {
    return ((1.0 - log(tan(lat * pi / 180.0) + 1.0 / cos(lat * pi / 180.0)) / pi) / 2.0 * (1 << zoom)).floor();
  }

  static Future<MapStatus> getMapStatus([String dirPath = defaultMapDir]) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      return MapStatus(
        hasOfflineTiles: false,
        tileCount: 0,
        sizeMB: 0.0,
        path: dirPath,
      );
    }

    int count = 0;
    int totalBytes = 0;

    try {
      await for (final file in dir.list(recursive: true, followLinks: false)) {
        if (file is File && file.path.endsWith('.png')) {
          count++;
          totalBytes += await file.length();
        }
      }
    } catch (_) {}

    return MapStatus(
      hasOfflineTiles: count > 10,
      tileCount: count,
      sizeMB: double.parse((totalBytes / (1024 * 1024)).toStringAsFixed(2)),
      path: dirPath,
    );
  }

  /**
   * Downloads and caches UAE offline map tiles covering Ajman, Sharjah, Dubai, and main corridors.
   * Runs when the car connects to Wi-Fi / Hotspot.
   */
  static Future<void> downloadUaeOfflineTiles({
    String targetDir = defaultMapDir,
    required Function(int current, int total, String status) onProgress,
  }) async {
    // UAE Primary Driving Zone Coordinates (Ajman, Sharjah, Dubai Corridors)
    const double minLat = 24.85;
    const double maxLat = 25.50;
    const double minLon = 55.05;
    const double maxLon = 55.65;

    // Zoom levels: 10 (macro), 11, 12, 13, 14 (detailed road level)
    final zoomLevels = [10, 11, 12, 13, 14];

    // Calculate total tiles to download
    final List<Map<String, int>> tilesToDownload = [];
    for (final z in zoomLevels) {
      final xMin = lon2tile(minLon, z);
      final xMax = lon2tile(maxLon, z);
      final yMin = lat2tile(maxLat, z);
      final yMax = lat2tile(minLat, z);

      for (int x = xMin; x <= xMax; x++) {
        for (int y = yMin; y <= yMax; y++) {
          tilesToDownload.add({'z': z, 'x': x, 'y': y});
        }
      }
    }

    final total = tilesToDownload.length;
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);

    int downloaded = 0;

    for (final t in tilesToDownload) {
      final z = t['z']!;
      final x = t['x']!;
      final y = t['y']!;

      final localFile = File('$targetDir/$z/$x/$y.png');
      if (await localFile.exists()) {
        downloaded++;
        onProgress(downloaded, total, 'فحص البلاطات الحالية ($downloaded/$total)...');
        continue;
      }

      try {
        await localFile.parent.create(recursive: true);

        // Fetch high-contrast OSM tile
        final uri = Uri.parse('https://tile.openstreetmap.org/$z/$x/$y.png');
        final request = await client.getUrl(uri);
        request.headers.set('User-Agent', 'BenMajedCockpit/1.0 (Automotive Android HeadUnit)');
        final response = await request.close();

        if (response.statusCode == 200) {
          final bytes = await response.fold<List<int>>([], (prev, element) => prev..addAll(element));
          await localFile.writeAsBytes(bytes);
        }
      } catch (_) {
        // Continue downloading remaining tiles even if a network timeout occurs
      }

      downloaded++;
      if (downloaded % 5 == 0 || downloaded == total) {
        onProgress(downloaded, total, 'جاري تنزيل خرائط الإمارات الحديثة ($downloaded/$total)...');
      }
    }

    client.close();
    onProgress(total, total, 'تم اكتمال تنزيل وتحديث خريطة الإمارات بنجاح!');
  }
}
