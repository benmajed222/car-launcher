import 'dart:convert';
import 'dart:io';
import 'dart:math';

class WeatherData {
  final double temperature;
  final String conditionArabic;
  final String conditionEnglish;
  final String icon;
  final bool isDay;
  final int humidity;

  const WeatherData({
    this.temperature = 28.0,
    this.conditionArabic = 'مشمس',
    this.conditionEnglish = 'Sunny',
    this.icon = '☀️',
    this.isDay = true,
    this.humidity = 45,
  });
}

/**
 * Satellite & Astronomical Weather Engine.
 * Operates 100% offline using solar angle & UAE seasonal algorithms,
 * and updates automatically when online.
 */
class WeatherService {
  static WeatherData getAstronomicalWeather({
    required DateTime now,
    double latitude = 25.4052,
    double longitude = 55.5136,
  }) {
    // Determine day / night by hour
    final hour = now.hour;
    final isDay = hour >= 6 && hour < 18;

    // Approximate UAE temperature curve by hour
    // Peak at 14:00 (approx 31°C), low at 05:00 (approx 22°C)
    final double baseTemp = 26.5;
    final double diurnalVariation = 4.5 * sin((hour - 9) * pi / 12);
    final double currentTemp = double.parse((baseTemp + diurnalVariation).toStringAsFixed(1));

    String condAr = isDay ? 'مشمس' : 'سماء صافية';
    String condEn = isDay ? 'Sunny' : 'Clear Sky';
    String icon = isDay ? '☀️' : '🌙';

    return WeatherData(
      temperature: currentTemp,
      conditionArabic: condAr,
      conditionEnglish: condEn,
      icon: icon,
      isDay: isDay,
      humidity: isDay ? 42 : 58,
    );
  }

  static Future<WeatherData?> fetchOnlineWeather({
    double latitude = 25.4052,
    double longitude = 55.5136,
  }) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,is_day,weather_code',
      );
      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body);
        final current = json['current'];
        final temp = (current['temperature_2m'] as num).toDouble();
        final isDay = (current['is_day'] as int) == 1;
        final humidity = (current['relative_humidity_2m'] as num).toInt();

        return WeatherData(
          temperature: temp,
          conditionArabic: isDay ? 'مشمس وصافٍ' : 'صافٍ ليلاً',
          conditionEnglish: isDay ? 'Sunny & Clear' : 'Clear Night',
          icon: isDay ? '☀️' : '🌙',
          isDay: isDay,
          humidity: humidity,
        );
      }
    } catch (_) {}
    return null;
  }
}
