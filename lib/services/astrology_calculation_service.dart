import 'package:sweph/sweph.dart';
import '../utils/astrology_utils.dart';
import '../services/geocoding_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class AstrologyCalculationService {
  /// Calculate a complete natal chart
  static Future<Map<String, dynamic>> calculateChart({
    required String name,
    required String date, // format DD/MM/YYYY
    required String time,
    required String lat,
    required String long,
    required String location,
  }) async {

    // print(name);
    // print(date);
    // print(time);
    // print(lat);
    // print(long);
    // print(location);

    try {
      // Parse date and time
      // final dateParts = date.split('-');
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

      // Parse local date and time
      final localDay = int.parse(dateParts[0]);
      final localMonth = int.parse(dateParts[1]);
      final localYear = int.parse(dateParts[2]);
      final localHour = int.parse(timeParts[0]);
      final localMinute = int.parse(timeParts[1]);

      print(  '---------------------------------');
      print('📍 Birth date and time');
      print('Date: $localDay/$localMonth/$localYear');
      print('Time: $localHour:$localMinute');

      // Declare UTC variables outside try block
      int utcYear = localYear;
      int utcMonth = localMonth;
      int utcDay = localDay;
      int utcHour = localHour;
      int utcMinute = localMinute;

      print(  '---------------------------------');
      print('📍 UTC variables');
      print('Date: $utcDay/$utcMonth/$utcYear');
      print('Time: $utcHour:$utcMinute');
      print('---------------------------------');

      // Get timezone for birth location
      String timezoneName;
      try {
        timezoneName = GeocodingService().getTimezoneFromCoordinates(latitude, longitude);
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

      print('---------------------------------');
      print('📅 julianDay');
      print(utcYear);
      print(utcMonth);
      print(utcDay);
      print(utcHour);
      print(utcMinute);
      print(utcHour + utcMinute / 60.0);
      print('---------------------------------');

      // Calculate Julian Day using UTC
      final julianDay = Sweph.swe_julday(
        utcYear,
        utcMonth,
        utcDay,
        utcHour + utcMinute / 60.0,
        CalendarType.SE_GREG_CAL,
      );

      // Calculate planetary positions
      Map<String, dynamic> chartData = {
        'name': name.isNotEmpty
            ? name
            : 'Natal Chart',
        'date':
            '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year',
        'time':
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        'location': 'Lat: $latitude, Lon: $longitude',
        'julianDay': julianDay,
        'planets': {},
        'houses': {},
      };

      print('🔍 chartData data: ${chartData}');

      // Calculate planetary positions
      await _calculatePlanets(julianDay, chartData);

      // Calculate houses
      await _calculateHouses(julianDay, latitude, longitude, chartData);

      // Group planets into houses
      AstrologyUtils.groupPlanetsIntoHouses(chartData);

      // Convert to wheel format
      AstrologyUtils.convertChartDataToWheelFormat(chartData);

      print('🔍 Planets data: ${chartData['planets']}');
      print('🔍 Houses data: ${chartData['houses']}');

      // print('🔍 Planets data: ${chartData['planets']}');
      // for (final planet in chartData['planets'].values) {
      //   print('  - ${planet['name']} at ${planet['longitude']}°');
      // }
      // print('🔍 Houses data: ${chartData['houses']}');
      // for (final house in chartData['houses'].values) {
      //   print('  - House ${house['number']} starts at ${house['start_degree']}°');
      // }

      return chartData;
    } catch (e) {
      print('❌ Error calculating chart: $e');
      throw Exception('Failed to calculate chart: $e');
    }
  }

  /// Calculate planetary positions - EXACTLY the same as natal_chart_page_with_sweph
  static Future<void> _calculatePlanets(
    double julianDay,
    Map<String, dynamic> chartData,
  ) async {
    // Use proper HeavenlyBody enum values
    final planets = {
      'Sun': HeavenlyBody.SE_SUN,
      'Moon': HeavenlyBody.SE_MOON,
      'Mercury': HeavenlyBody.SE_MERCURY,
      'Venus': HeavenlyBody.SE_VENUS,
      'Mars': HeavenlyBody.SE_MARS,
      'Jupiter': HeavenlyBody.SE_JUPITER,
      'Saturn': HeavenlyBody.SE_SATURN,
      'Uranus': HeavenlyBody.SE_URANUS,
      'Neptune': HeavenlyBody.SE_NEPTUNE,
      'Pluto': HeavenlyBody.SE_PLUTO,
    };

    for (final entry in planets.entries) {
      try {
        final result = Sweph.swe_calc_ut(
          julianDay,
          entry.value,
          SwephFlag.SEFLG_SPEED,
        );
        
        final longitude = result.longitude;
        final speed = result.speedInLongitude; // This is the correct field!
        final sign = AstrologyUtils.getZodiacSign(longitude);
        final degree = longitude % 30;
        final isRetrograde = speed < 0; // Negative speed = retrograde motion
        
        // Only print retrograde planets for clarity
        if (isRetrograde) {
          print('⭐ RETROGRADE: ${entry.key} at ${longitude.toStringAsFixed(2)}°, speed=${speed.toStringAsFixed(4)}°/day');
        }
        
        chartData['planets'][entry.key] = {
          'name': entry.key,
          'longitude': longitude,
          'speed': speed,
          'is_retrograde': isRetrograde,
          'sign': sign,
          'degree': degree,
          'formatted': '${sign} ${degree.toStringAsFixed(2)}°',
        };

      } catch (e) {
        print('❌ Error calculating ${entry.key}: $e');
        chartData['planets'][entry.key] = {
          'name': entry.key, // <-- This is correct!
          'formatted': 'Error: $e',
        };
      }
    }
    // Calculate additional points
    // await _calculateAdditionalPoints(julianDay, chartData);
  }

  /// Calculate additional astrological points
  static Future<void> _calculateAdditionalPoints(
    double julianDay,
    Map<String, dynamic> chartData,
  ) async {
    // Add Chiron
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
        'formatted': '${sign} ${(longitude % 30).toStringAsFixed(2)}°',
      };
    } catch (e) {
      print('❌ Error calculating Chiron: $e');
    }

    // Add North Node
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
        'formatted': '${northNodeSign} ${(northNodeLongitude % 30).toStringAsFixed(2)}°',
      };

      // Calculate South Node (opposite of North Node)
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
        'formatted': '${southNodeSign} ${(southNodeLongitude % 30).toStringAsFixed(2)}°',
      };
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
      HouseCuspData? result;

      try {
        result = Sweph.swe_houses(
          julianDay,
          latitude,
          longitude,
          Hsys.P,
        ); // Placidus
      } catch (e1) {
        try {
          result = Sweph.swe_houses(
            julianDay,
            latitude,
            longitude,
            Hsys.K,
          ); // Koch
        } catch (e2) {
          try {
            result = Sweph.swe_houses(
              julianDay,
              latitude,
              longitude,
              Hsys.E,
            ); // Equal
          } catch (e3) {
            print('❌ All house systems failed: $e1, $e2, $e3');
            return;
          }
        }
      }

      if (result != null) {
        final houseCusps = result.cusps;

        // Debug: Print raw house cusps
        print('🏠 Raw house cusps from SwEph:');
        for (int i = 0; i < houseCusps.length && i < 12; i++) {
          print('House ${i + 1}: ${houseCusps[i].toStringAsFixed(2)}°');
        }

        // Only take the first 12 house cusps starting from index 1 (ignore any extra)
        final validCusps = houseCusps.skip(1).take(12).toList();

        // Debug: Print raw house cusps (adjusted for new indexing)
        print('🏠 Raw house cusps from SwEph (shifted):');
        for (int i = 0; i < validCusps.length; i++) {
          print('House ${i + 1}: ${validCusps[i].toStringAsFixed(2)}°');
        }

        // Store the Ascendant for reference
        final ascendant = validCusps[0]; // First house cusp = Ascendant
        chartData['ascendant'] = ascendant;

        print('🏠 Ascendant: ${ascendant.toStringAsFixed(2)}°');

        // Store other angles
        chartData['descendant'] = validCusps[6]; // House 7 cusp
        chartData['mc'] = validCusps[9]; // House 10 cusp
        chartData['imum_coeli'] = validCusps[3]; // House 4 cusp

        for (int i = 0; i < validCusps.length; i++) {
          final houseLon = validCusps[i];
          final nextHouseLon = validCusps[(i + 1) % validCusps.length];
          final sign = AstrologyUtils.getZodiacSign(houseLon);

          chartData['houses']['House ${i + 1}'] = {
            'longitude': houseLon,
            'sign': sign,
            'degree': houseLon % 30,
            'formatted': '${sign} ${(houseLon % 30).toStringAsFixed(2)}°',
            'start_degree': houseLon,
            'end_degree': nextHouseLon,
            'house_id': i + 1,
            'planets': [],
          };

          print(
            'House ${i + 1}: start=${houseLon.toStringAsFixed(2)}°, end=${nextHouseLon.toStringAsFixed(2)}°, sign=${sign}',
          );
        }
      } else {
        print('❌ No house data returned from SwEph');
      }
    } catch (e) {
      print('❌ Error calculating houses: $e');
      // No dummy houses - leave houses empty
    }
  }
}