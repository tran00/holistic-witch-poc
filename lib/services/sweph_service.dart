import 'package:sweph/sweph.dart';
import '../utils/astrology_utils.dart';

class SwephService {
  static bool _isInitialized = false;

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

  /// Calculate a complete natal chart
  static Future<Map<String, dynamic>> calculateChart({
    required String name,
    required DateTime dateTime,
    required double latitude,
    required double longitude,
    required String location,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Calculate Julian Day (UTC)
      final julianDay = Sweph.swe_julday(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour + dateTime.minute / 60.0 + dateTime.second / 3600.0,
        CalendarType.SE_GREG_CAL,
      );

      // Create chart data structure
      final chartData = <String, dynamic>{
        'name': name,
        'date': '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}',
        'time': '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'julianDay': julianDay,
        'planets': <String, dynamic>{},
        'houses': <String, dynamic>{},
      };

      // Calculate planetary positions
      await _calculatePlanets(julianDay, chartData);

      // Calculate houses
      await _calculateHouses(julianDay, latitude, longitude, chartData);

      // Group planets into houses
      AstrologyUtils.groupPlanetsIntoHouses(chartData);

      // Convert to wheel format
      AstrologyUtils.convertChartDataToWheelFormat(chartData);

      return chartData;
    } catch (e) {
      print('❌ Error calculating chart: $e');
      throw Exception('Failed to calculate chart: $e');
    }
  }

  /// Calculate planetary positions
  static Future<void> _calculatePlanets(
    double julianDay,
    Map<String, dynamic> chartData,
  ) async {
    // Main planets with their HeavenlyBody enum values
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
        final sign = AstrologyUtils.getZodiacSign(longitude);
        final degree = longitude % 30;

        chartData['planets'][planetName] = {
          'name': planetName,
          'glyph': planetGlyph,
          'longitude': longitude,
          'latitude': result.latitude,
          'distance': result.distance,
          // Removed speed field as it is not available
          'full_degree': longitude,
          'sign': sign,
          'degree': degree,
          'formatted': '${sign} ${degree.toStringAsFixed(2)}°',
        };
      } catch (e) {
        print('❌ Error calculating ${planet[1]}: $e');
      }
    }

    // Calculate additional points
    await _calculateAdditionalPoints(julianDay, chartData);
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
        // Removed speed field as it is not available
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
        // Removed speed field as it is not available
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
        'latitude': -nodeResult.latitude, // Opposite latitude
        'distance': nodeResult.distance,
        // Removed speed field as it is not available
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
      final result = Sweph.swe_houses(
        julianDay,
        latitude,
        longitude,
        Hsys.P, // Placidus house system
      );

      final houseCusps = result.cusps;

      // Store the Ascendant for reference
      if (houseCusps.isNotEmpty) {
        final ascendant = houseCusps[1]; // First house cusp = Ascendant
        chartData['ascendant'] = ascendant;

        // Store other angles
        chartData['descendant'] = houseCusps.length > 7 ? houseCusps[7] : null; // House 7 cusp
        chartData['mc'] = houseCusps.length > 10 ? houseCusps[10] : null; // House 10 cusp
        chartData['imum_coeli'] = houseCusps.length > 4 ? houseCusps[4] : null; // House 4 cusp

        // Create house data
        for (int i = 1; i <= 12 && i < houseCusps.length; i++) {
          final houseLon = houseCusps[i];
          final nextHouseLon = i < 12 ? houseCusps[i + 1] : houseCusps[1];
          final sign = AstrologyUtils.getZodiacSign(houseLon);

          chartData['houses']['House $i'] = {
            'house_id': i,
            'longitude': houseLon,
            'sign': sign,
            'degree': houseLon % 30,
            'formatted': '${sign} ${(houseLon % 30).toStringAsFixed(2)}°',
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