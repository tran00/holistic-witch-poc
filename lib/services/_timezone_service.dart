// lib/services/timezone_service.dart
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:http/http.dart' as http;
import 'dart:convert';

class TimezoneService {
  static bool _isInitialized = false;

  /// Initialize timezone database
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      tz_data.initializeTimeZones();
      _isInitialized = true;
      print('✅ Timezone database initialized');
    } catch (e) {
      print('❌ Error initializing timezone database: $e');
      throw Exception('Error initializing timezone: $e');
    }
  }

  /// Get timezone from coordinates using basic geographic mapping
  static String getTimezoneFromCoordinates(double latitude, double longitude) {
    // Common timezone mappings for major regions with valid timezone names
    
    // Europe
    if (latitude >= 35 && latitude <= 70 && longitude >= -10 && longitude <= 40) {
      if (longitude >= -5 && longitude <= 25) {
        return 'Europe/Paris'; // Western/Central Europe
      } else if (longitude >= 25 && longitude <= 40) {
        return 'Europe/Bucharest'; // Eastern Europe
      }
    }
    
    // North America
    if (latitude >= 25 && latitude <= 70 && longitude >= -170 && longitude <= -50) {
      if (longitude >= -85) return 'America/New_York'; // Eastern US
      else if (longitude >= -105) return 'America/Chicago'; // Central US
      else if (longitude >= -125) return 'America/Denver'; // Mountain US
      else return 'America/Los_Angeles'; // Pacific US
    }
    
    // Asia
    if (latitude >= 0 && latitude <= 70 && longitude >= 40 && longitude <= 180) {
      if (longitude >= 40 && longitude <= 80) return 'Europe/Moscow'; // Western Asia
      else if (longitude >= 80 && longitude <= 120) return 'Asia/Shanghai'; // Central/Eastern Asia
      else return 'Asia/Tokyo'; // Far East Asia
    }
    
    // Default fallback to UTC for unknown regions
    return 'UTC';
  }

  /// Get timezone from external API (exact copy from your working code)
  static Future<String> getTimezoneFromAPI(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'http://api.geonames.org/timezoneJSON?lat=$latitude&lng=$longitude&username=YOUR_USERNAME'
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['timezoneId'] ?? 'UTC';
      }
    } catch (e) {
      print('Error getting timezone: $e');
    }
    return 'UTC';
  }

  /// Convert local time to UTC using timezone (exact copy from your working code)
  static Map<String, int> convertToUTC(
    int localYear,
    int localMonth,
    int localDay,
    int localHour,
    int localMinute,
    double latitude,
    double longitude,
  ) {
    // Declare UTC variables
    int utcYear = localYear;
    int utcMonth = localMonth;
    int utcDay = localDay;
    int utcHour = localHour;
    int utcMinute = localMinute;

    // Get timezone for birth location
    String timezoneName;
    try {
      timezoneName = getTimezoneFromCoordinates(latitude, longitude);
      final location = tz.getLocation(timezoneName);
      
      // Create local date/time at birth location
      final localDateTime = tz.TZDateTime(
        location,
        localYear,
        localMonth,
        localDay,
        localHour,
        localMinute,
      );

      // Convert to UTC
      final utcDateTime = localDateTime.toUtc();
      
      print('📍 Birth location timezone: $timezoneName');
      print('🕐 Local time: $localDateTime');
      print('🌍 UTC time: $utcDateTime');
      
      // Update UTC values
      utcYear = utcDateTime.year;
      utcMonth = utcDateTime.month;
      utcDay = utcDateTime.day;
      utcHour = utcDateTime.hour;
      utcMinute = utcDateTime.minute;
      
    } catch (e) {
      print('⚠️ Timezone error: $e, using local time as UTC');
      timezoneName = 'UTC';
      
      // Fallback: treat input time as UTC (already set above)
    }

    return {
      'year': utcYear,
      'month': utcMonth,
      'day': utcDay,
      'hour': utcHour,
      'minute': utcMinute,
    };
  }

  /// Check if timezone service is initialized
  static bool get isInitialized => _isInitialized;
}