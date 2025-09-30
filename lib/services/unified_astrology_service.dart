import 'package:sweph/sweph.dart';
import '../utils/astrology_utils.dart';
import '../services/geocoding_service.dart';
import 'package:timezone/timezone.dart' as tz;

class UnifiedAstrologyService {
  static bool _isInitialized = false;
  static const bool _enableSouthNode = false;

  /// Initialize Swiss Ephemeris
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Sweph.init();
      Sweph.swe_set_ephe_path('assets/sweph/');
      _isInitialized = true;
      print('✅ Swiss Ephemeris initialized successfully');
    } catch (e) {
      print('❌ Error initializing Swiss Ephemeris: $e');
      throw Exception('Failed to initialize Swiss Ephemeris: $e');
    }
  }

  /// High-level API: Calculate chart from user-friendly input
  static Future<Map<String, dynamic>> calculateChartFromUserInput({
    required String name,
    required String date, // format DD/MM/YYYY
    required String time, // format HH:MM
    required String lat,
    required String long,
    required String location,
  }) async {
    await initialize();
    try {
      final dateParts = date.split('/');
      if (dateParts.length != 3) {
        throw Exception('Invalid date format. Expected DD/MM/YYYY');
      }
      final timeParts = time.split(':');
      if (timeParts.length != 2) {
        throw Exception('Invalid time format. Expected HH:MM');
      }
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final latitude = double.parse(lat);
      final longitude = double.parse(long);
      // Timezone handling
      int utcYear = year, utcMonth = month, utcDay = day, utcHour = hour, utcMinute = minute;
      String timezoneName;
      try {
        timezoneName = GeocodingService().getTimezoneFromCoordinates(latitude, longitude);
        final tzLocation = tz.getLocation(timezoneName);
        final localDateTime = tz.TZDateTime(tzLocation, year, month, day, hour, minute);
        final utcDateTime = localDateTime.toUtc();
        utcYear = utcDateTime.year;
        utcMonth = utcDateTime.month;
        utcDay = utcDateTime.day;
        utcHour = utcDateTime.hour;
        utcMinute = utcDateTime.minute;
      } catch (e) {
        timezoneName = 'UTC';
      }
      final julianDay = Sweph.swe_julday(
        utcYear, utcMonth, utcDay, utcHour + utcMinute / 60.0, CalendarType.SE_GREG_CAL,
      );
      return await _calculateFullChart(
        name: name,
        date: '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year',
        time: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        latitude: latitude,
        longitude: longitude,
        location: location,
        julianDay: julianDay,
      );
    } catch (e) {
      print('❌ Error calculating chart: $e');
      throw Exception('Failed to calculate chart: $e');
    }
  }

  /// Low-level API: Calculate chart from DateTime and coordinates
  static Future<Map<String, dynamic>> calculateChart({
    required String name,
    required DateTime dateTime,
    required double latitude,
    required double longitude,
    required String location,
  }) async {
    await initialize();
    try {
      final julianDay = Sweph.swe_julday(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour + dateTime.minute / 60.0 + dateTime.second / 3600.0,
        CalendarType.SE_GREG_CAL,
      );
      return await _calculateFullChart(
        name: name,
        date: '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}',
        time: '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
        latitude: latitude,
        longitude: longitude,
        location: location,
        julianDay: julianDay,
      );
    } catch (e) {
      print('❌ Error calculating chart: $e');
      throw Exception('Failed to calculate chart: $e');
    }
  }

  /// Shared chart calculation logic
  static Future<Map<String, dynamic>> _calculateFullChart({
    required String name,
    required String date,
    required String time,
    required double latitude,
    required double longitude,
    required String location,
    required double julianDay,
  }) async {
    final chartData = <String, dynamic>{
      'name': name.isNotEmpty ? name : 'Natal Chart',
      'date': date,
      'time': time,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'julianDay': julianDay,
      'planets': <String, dynamic>{},
      'houses': <String, dynamic>{},
    };
    await _calculatePlanets(julianDay, chartData);
    await _calculateHouses(julianDay, latitude, longitude, chartData);
    AstrologyUtils.groupPlanetsIntoHouses(chartData);
    AstrologyUtils.convertChartDataToWheelFormat(chartData);
    return chartData;
  }

  /// Calculate planetary positions and additional points
  static Future<void> _calculatePlanets(
    double julianDay,
    Map<String, dynamic> chartData,
  ) async {
    final planets = [
      [HeavenlyBody.SE_SUN, 'Sun', '☉'],
      [HeavenlyBody.SE_MOON, 'Moon', '☽'],
      [HeavenlyBody.SE_MERCURY, 'Mercury', '☿'],
      [HeavenlyBody.SE_VENUS, 'Venus', '♀'],
      [HeavenlyBody.SE_MARS, 'Mars', '♂'],
      [HeavenlyBody.SE_JUPITER, 'Jupiter', '♃'],
      [HeavenlyBody.SE_SATURN, 'Saturn', '♄'],
      [HeavenlyBody.SE_URANUS, 'Uranus', '♅'],
      [HeavenlyBody.SE_NEPTUNE, 'Neptune', '♆'],
      [HeavenlyBody.SE_PLUTO, 'Pluto', '♇'],
    ];
    for (final planet in planets) {
      try {
        final planetId = planet[0] as HeavenlyBody;
        final planetName = planet[1] as String;
        final planetGlyph = planet[2] as String;
        final result = Sweph.swe_calc_ut(
          julianDay,
          planetId,
          SwephFlag.SEFLG_SPEED,
        );
        final longitude = result.longitude;
        final speed = result.speedInLongitude;
        final sign = AstrologyUtils.getZodiacSign(longitude);
        final degree = longitude % 30;
        final isRetrograde = speed < 0;
        chartData['planets'][planetName] = {
          'name': planetName,
          'glyph': planetGlyph,
          'longitude': longitude,
          'latitude': result.latitude,
          'distance': result.distance,
          'speed': speed,
          'is_retrograde': isRetrograde,
          'full_degree': longitude,
          'sign': sign,
          'degree': degree,
          'formatted': '$sign ${degree.toStringAsFixed(2)}°',
        };
      } catch (e) {
        print('❌ Error calculating $planet: $e');
      }
    }
    await _calculateAdditionalPoints(julianDay, chartData);
  }

  /// Calculate additional astrological points (Chiron, Nodes)
  static Future<void> _calculateAdditionalPoints(
    double julianDay,
    Map<String, dynamic> chartData,
  ) async {
    // Chiron
    try {
      final chironResult = Sweph.swe_calc_ut(
        julianDay,
        HeavenlyBody.SE_CHIRON,
        SwephFlag.SEFLG_SPEED,
      );
      final longitude = chironResult.longitude;
      final sign = AstrologyUtils.getZodiacSign(longitude);
      chartData['planets']['Chiron'] = {
        'name': 'Chiron',
        'glyph': '⚷',
        'longitude': longitude,
        'latitude': chironResult.latitude,
        'distance': chironResult.distance,
        'full_degree': longitude,
        'sign': sign,
        'degree': longitude % 30,
        'formatted': '$sign ${(longitude % 30).toStringAsFixed(2)}°',
      };
    } catch (e) {
      print('❌ Error calculating Chiron: $e');
    }
    // Lunar Nodes
    try {
      final nodeResult = Sweph.swe_calc_ut(
        julianDay,
        HeavenlyBody.SE_TRUE_NODE,
        SwephFlag.SEFLG_SPEED,
      );
      final northNodeLongitude = nodeResult.longitude;
      final northNodeSign = AstrologyUtils.getZodiacSign(northNodeLongitude);
      chartData['planets']['North Node'] = {
        'name': 'North Node',
        'glyph': '☊',
        'longitude': northNodeLongitude,
        'latitude': nodeResult.latitude,
        'distance': nodeResult.distance,
        'full_degree': northNodeLongitude,
        'sign': northNodeSign,
        'degree': northNodeLongitude % 30,
        'formatted': '$northNodeSign ${(northNodeLongitude % 30).toStringAsFixed(2)}°',
      };

      if(_enableSouthNode)  {
        final southNodeLongitude = (northNodeLongitude + 180) % 360;
        final southNodeSign = AstrologyUtils.getZodiacSign(southNodeLongitude);
        chartData['planets']['South Node'] = {
          'name': 'South Node',
          'glyph': '☋',
          'longitude': southNodeLongitude,
          'latitude': -nodeResult.latitude,
          'distance': nodeResult.distance,
          'full_degree': southNodeLongitude,
          'sign': southNodeSign,
          'degree': southNodeLongitude % 30,
          'formatted': '$southNodeSign ${(southNodeLongitude % 30).toStringAsFixed(2)}°',
        };
      }
    } catch (e) {
      print('❌ Error calculating Lunar Nodes: $e');
    }
  }

  /// Calculate house cusps
  static Future<void> _calculateHouses(
    double julianDay,
    double latitude,
    double longitude,
    Map<String, dynamic> chartData,
  ) async {
    try {
      final result = Sweph.swe_houses(
        julianDay,
        latitude,
        longitude,
        Hsys.P, // Placidus
      );
      final houseCusps = result.cusps;
      if (houseCusps.isNotEmpty) {
        final ascendant = houseCusps[1];
        chartData['ascendant'] = ascendant;
        chartData['descendant'] = houseCusps.length > 7 ? houseCusps[7] : null;
        chartData['mc'] = houseCusps.length > 10 ? houseCusps[10] : null;
        chartData['imum_coeli'] = houseCusps.length > 4 ? houseCusps[4] : null;
        for (int i = 1; i <= 12 && i < houseCusps.length; i++) {
          final houseLon = houseCusps[i];
          final nextHouseLon = i < 12 ? houseCusps[i + 1] : houseCusps[1];
          final sign = AstrologyUtils.getZodiacSign(houseLon);
          chartData['houses']['House $i'] = {
            'house_id': i,
            'longitude': houseLon,
            'sign': sign,
            'degree': houseLon % 30,
            'formatted': '$sign ${(houseLon % 30).toStringAsFixed(2)}°',
            'start_degree': houseLon,
            'end_degree': nextHouseLon,
            'planets': [],
          };
        }
      }
    } catch (e) {
      print('❌ Error calculating houses: $e');
      throw Exception('Failed to calculate houses: $e');
    }
  }

  /// Dispose resources
  static void dispose() {
    if (_isInitialized) {
      Sweph.swe_close();
      _isInitialized = false;
    }
  }
}
