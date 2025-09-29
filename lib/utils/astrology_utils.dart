// lib/utils/astrology_utils.dart

/// Utility class for astrological calculations and formatting
class AstrologyUtils {
  
  /// Get zodiac sign name from longitude
  static String getZodiacSign(double longitude) {
    final signs = [
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn',
      'Aquarius',
      'Pisces',
    ];

    final signIndex = (longitude / 30).floor() % 12;
    return signs[signIndex];
  }

  /// Format decimal degrees to degrees, minutes, seconds
  static String formatDegreeMinute(double decimalDegree) {
    // normalize
    decimalDegree = decimalDegree % 360.0;

    // degree in sign
    final degInSign = decimalDegree % 30;
    final deg = degInSign.floor();
    final min = ((degInSign - deg) * 60).floor();
    final sec = ((((degInSign - deg) * 60) - min) * 60).round();

    return "$deg°${min.toString().padLeft(2, '0')}'${sec.toString().padLeft(2, '0')}\"";
  }

  /// Format decimal degrees with zodiac sign
  static String formatDegreesWithSign(double decimalDegree) {
    // normalize
    decimalDegree = decimalDegree % 360.0;

    // zodiac sign
    final signs = [
      "Aries",
      "Taurus",
      "Gemini",
      "Cancer",
      "Leo",
      "Virgo",
      "Libra",
      "Scorpio",
      "Sagittarius",
      "Capricorn",
      "Aquarius",
      "Pisces",
    ];
    final signIndex = (decimalDegree ~/ 30); // integer division
    final sign = signs[signIndex];

    // degree in sign
    final degInSign = decimalDegree % 30;
    final deg = degInSign.floor();
    final min = ((degInSign - deg) * 60).floor();
    final sec = ((((degInSign - deg) * 60) - min) * 60).round();

    return "$sign $deg°${min.toString().padLeft(2, '0')}'${sec.toString().padLeft(2, '0')}\"";
  }

  /// Get planetary body mappings for SwEph
  static Map<String, int> getPlanetaryBodies() {
    return {
      'Sun': 0,    // HeavenlyBody.SE_SUN
      'Moon': 1,   // HeavenlyBody.SE_MOON
      'Mercury': 2, // HeavenlyBody.SE_MERCURY
      'Venus': 3,   // HeavenlyBody.SE_VENUS
      'Mars': 4,    // HeavenlyBody.SE_MARS
      'Jupiter': 5, // HeavenlyBody.SE_JUPITER
      'Saturn': 6,  // HeavenlyBody.SE_SATURN
      'Uranus': 7,  // HeavenlyBody.SE_URANUS
      'Neptune': 8, // HeavenlyBody.SE_NEPTUNE
      'Pluto': 9,   // HeavenlyBody.SE_PLUTO
    };
  }

  /// Find which house a planet is in based on degree
  static int findPlanetHouse(Map<String, dynamic> planet, List houses) {
    final planetDegree = (planet['longitude'] ?? planet['full_degree'] ?? 0).toDouble();
    
    for (int i = 0; i < houses.length; i++) {
      final houseStart = (houses[i]['start_degree'] as num).toDouble();
      final houseEnd = (houses[i]['end_degree'] as num).toDouble();
      
      if (houseEnd > houseStart) {
        // Normal case: house doesn't cross 0°
        if (planetDegree >= houseStart && planetDegree < houseEnd) {
          return i + 1;
        }
      } else {
        // Handle houses that cross 0°
        if (planetDegree >= houseStart || planetDegree < houseEnd) {
          return i + 1;
        }
      }
    }
    return 1; // Default to house 1 if not found
  }

  /// Group planets into their respective houses
  static void groupPlanetsIntoHouses(Map<String, dynamic> chartData) {
    final houses = chartData['houses'] as Map;
    final planets = chartData['planets'] as Map;

    // Ensure each house has a planets list
    for (final house in houses.values) {
      house['planets'] = [];
    }

    for (final planet in planets.values) {
      final degree = (planet['longitude'] ?? 0.0).toDouble();
      planet['full_degree'] = degree;

      // Find the house this planet belongs to
      bool assigned = false;
      for (int i = 1; i <= 12; i++) {
        final house = houses['House $i'];
        if (house == null) continue;

        final start = (house['start_degree'] as num).toDouble();
        final end = (house['end_degree'] as num).toDouble();

        bool inHouse = false;
        if (start < end) {
          // Normal case: house doesn't cross 0°
          inHouse = degree >= start && degree < end;
        } else {
          // Wrap-around case: house crosses 0° (e.g., House 12 to House 1)
          inHouse = degree >= start || degree < end;
        }

        if (inHouse) {
          house['planets'].add(planet);
          assigned = true;
          break;
        }
      }

      if (!assigned) {
        print('⚠️ Planet ${planet['name']} at $degree° not assigned to any house');
      }
    }
  }

  /// Convert chart data from Map format to List format for wheel display
  static void convertChartDataToWheelFormat(Map<String, dynamic> chartData) {
    // Convert houses map to list
    if (chartData['houses'] is Map) {
      chartData['houses'] = (chartData['houses'] as Map).values.toList();
    }
    // Convert planets map to list
    if (chartData['planets'] is Map) {
      chartData['planets'] = (chartData['planets'] as Map).values.toList();
    }
    // For each house, ensure 'planets' is a list (even if empty)
    if (chartData['houses'] is List) {
      for (var house in chartData['houses']) {
        if (house is Map && house['planets'] is! List) {
          house['planets'] = [];
        }
      }
    }
  }

  /// Get house system names
  static Map<String, String> getHouseSystems() {
    return {
      'P': 'Placidus',
      'K': 'Koch',
      'E': 'Equal',
      'W': 'Whole Sign',
      'C': 'Campanus',
      'R': 'Regiomontanus',
    };
  }

  /// Get aspect angles and their names
  static Map<String, double> getAspects() {
    return {
      'Conjunction': 0,
      'Sextile': 60,
      'Square': 90,
      'Trine': 120,
      'Opposition': 180,
    };
  }

  /// Calculate aspects between two planets
  static List<Map<String, dynamic>> calculateAspects(
    List planets, {
    double orb = 8.0,
  }) {
    final aspects = <Map<String, dynamic>>[];
    final aspectAngles = getAspects();

    for (int i = 0; i < planets.length; i++) {
      for (int j = i + 1; j < planets.length; j++) {
        final planet1 = planets[i];
        final planet2 = planets[j];
        
        final lon1 = (planet1['longitude'] ?? 0).toDouble();
        final lon2 = (planet2['longitude'] ?? 0).toDouble();
        
        double angle = (lon2 - lon1).abs();
        if (angle > 180) angle = 360 - angle;

        for (final aspectEntry in aspectAngles.entries) {
          final aspectAngle = aspectEntry.value;
          final difference = (angle - aspectAngle).abs();
          
          if (difference <= orb) {
            aspects.add({
              'planet1': planet1['name'],
              'planet2': planet2['name'],
              'aspect': aspectEntry.key,
              'angle': angle,
              'orb': difference,
              'exact': difference < 1.0,
            });
            break; // Only add the closest aspect
          }
        }
      }
    }

    return aspects;
  }

  /// Get element for a zodiac sign
  static String getElement(String sign) {
    const fireSignss = ['Aries', 'Leo', 'Sagittarius'];
    const earthSigns = ['Taurus', 'Virgo', 'Capricorn'];
    const airSigns = ['Gemini', 'Libra', 'Aquarius'];
    const waterSigns = ['Cancer', 'Scorpio', 'Pisces'];

    if (fireSignss.contains(sign)) return 'Fire';
    if (earthSigns.contains(sign)) return 'Earth';
    if (airSigns.contains(sign)) return 'Air';
    if (waterSigns.contains(sign)) return 'Water';
    
    return 'Unknown';
  }

  /// Get modality for a zodiac sign
  static String getModality(String sign) {
    const cardinalSigns = ['Aries', 'Cancer', 'Libra', 'Capricorn'];
    const fixedSigns = ['Taurus', 'Leo', 'Scorpio', 'Aquarius'];
    const mutableSigns = ['Gemini', 'Virgo', 'Sagittarius', 'Pisces'];

    if (cardinalSigns.contains(sign)) return 'Cardinal';
    if (fixedSigns.contains(sign)) return 'Fixed';
    if (mutableSigns.contains(sign)) return 'Mutable';
    
    return 'Unknown';
  }

  /// Deep convert Map to Map<String, dynamic>
  static Map<String, dynamic> deepConvertToMapStringDynamic(Map input) {
    return input.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), deepConvertToMapStringDynamic(value));
      } else {
        return MapEntry(key.toString(), value);
      }
    });
  }
}