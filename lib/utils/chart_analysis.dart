import 'dart:math';
import 'astrology_utils.dart';

class ChartAnalysis {
  /// Mapping of zodiac signs to elements
  static const Map<String, String> elements = {
    "Aries": "Fire", "Leo": "Fire", "Sagittarius": "Fire",
    "Taurus": "Earth", "Virgo": "Earth", "Capricorn": "Earth",
    "Gemini": "Air", "Libra": "Air", "Aquarius": "Air",
    "Cancer": "Water", "Scorpio": "Water", "Pisces": "Water"
  };

  static const Map<String, String> rulers = {
    "Aries": "Mars",
    "Taurus": "Venus",
    "Gemini": "Mercury",
    "Cancer": "Moon",
    "Leo": "Sun",
    "Virgo": "Mercury",
    "Libra": "Venus",
    "Scorpio": "Mars / Pluto",
    "Sagittarius": "Jupiter",
    "Capricorn": "Saturn",
    "Aquarius": "Saturn / Uranus",
    "Pisces": "Jupiter / Neptune"
  };

  /// Mapping of zodiac signs to modes
  static const Map<String, String> modes = {
    "Aries": "Cardinal", "Cancer": "Cardinal", "Libra": "Cardinal", "Capricorn": "Cardinal",
    "Taurus": "Fixed", "Leo": "Fixed", "Scorpio": "Fixed", "Aquarius": "Fixed",
    "Gemini": "Mutable", "Virgo": "Mutable", "Sagittarius": "Mutable", "Pisces": "Mutable"
  };

  /// Count elements (Fire, Earth, Air, Water)
  static Map<String, int> countElements(Map<String, dynamic> chartData) {
    final Map<String, int> elemCount = {"Fire": 0, "Earth": 0, "Air": 0, "Water": 0};
    for (var p in chartData["planets"]) {
      final sign = p["sign"];
      elemCount[elements[sign]!] = elemCount[elements[sign]!]! + 1;
    }
    return elemCount;
  }

  /// Count modes (Cardinal, Fixed, Mutable)
  static Map<String, int> countModes(Map<String, dynamic> chartData) {
    final Map<String, int> modeCount = {"Cardinal": 0, "Fixed": 0, "Mutable": 0};
    for (var p in chartData["planets"]) {
      final sign = p["sign"];
      modeCount[modes[sign]!] = modeCount[modes[sign]!]! + 1;
    }
    return modeCount;
  }

  /// Detect major aspects
  static List<String> calculateAspects(Map<String, dynamic> chartData) {
    List planets = chartData["planets"];
    List<String> aspects = [];

    for (int i = 0; i < planets.length; i++) {
      for (int j = i + 1; j < planets.length; j++) {
        double diff = (planets[i]["full_degree"] - planets[j]["full_degree"]).abs();
        diff = diff > 180 ? 360 - diff : diff; // minimal angle
        final aspect = _checkAspect(diff);
        if (aspect != null) {
          aspects.add("${planets[i]["name"]} $aspect ${planets[j]["name"]} "
              "(Δ ${diff.toStringAsFixed(1)}°)");
        }
      }
    }

    return aspects;
  }

  /// Determine Moon phase
  static String getMoonPhase(Map<String, dynamic> chartData) {
    var planets = chartData["planets"];
    var sun = planets.firstWhere((p) => p["name"] == "Sun");
    var moon = planets.firstWhere((p) => p["name"] == "Moon");

    double diffSunMoon = (sun["full_degree"] - moon["full_degree"]).abs() % 360;
    if (diffSunMoon < 45) return "New Moon phase";
    if ((diffSunMoon - 90).abs() < 20) return "First Quarter phase";
    if ((diffSunMoon - 180).abs() < 20) return "Full Moon phase";
    if ((diffSunMoon - 270).abs() < 20) return "Last Quarter phase";
    return "Intermediate phase";
  }

  /// Check if chart is near an eclipse
  static bool isNearEclipse(Map<String, dynamic> chartData) {
    var planets = chartData["planets"];
    var sun = planets.firstWhere((p) => p["name"] == "Sun");
    var moon = planets.firstWhere((p) => p["name"] == "Moon");
    var node = planets.firstWhere((p) => p["name"] == "North Node", orElse: () => null);

    if (node == null) return false;

    return ((sun["full_degree"] - node["full_degree"]).abs() < 18 ||
        (moon["full_degree"] - node["full_degree"]).abs() < 18);
  }

  static List<String> getPlacements(Map<String, dynamic> chartData) {
    List<String> placements = [];

    // --- Planets ---
    final planets = chartData["planets"];
    if (planets is Map) {
      planets.forEach((key, planet) {
        if (planet is Map && planet["longitude"] != null) {
          final sign = planet["sign"];
          final degree = AstrologyUtils.formatDegreeMinute(planet["longitude"]);
          placements.add("${planet['name']}: $sign $degree");
        }
      });
    } else if (planets is List) {
      for (final planet in planets) {
        if (planet is Map && planet["longitude"] != null) {
          final sign = planet["sign"];
          final degree = AstrologyUtils.formatDegreeMinute(planet["longitude"]);
          placements.add("${planet['name']}: $sign $degree");
        }
      }
    }

    // --- Angles (Asc, Dsc, MC, IC) ---
    final angles = {
      "Ascendant": chartData["ascendant"],
      "Descendant": chartData["descendant"],
      "Midheaven": chartData["mc"],
      "Imum Coeli": chartData["imum_coeli"],
    };

    angles.forEach((name, lon) {
      if (lon != null) {
        final sign = AstrologyUtils.getZodiacSign(lon);
        final degree = AstrologyUtils.formatDegreeMinute(lon);
        final ruler = rulers[sign];
        placements.add("$name: $sign $degree (ruler: $ruler)");
      }
    });


  // ...existing code...
    return placements;
  }

  static String buildRetrieverQuery(List<String> placements) {
    String? sun, moon, ascendant;
    for (final p in placements) {
      if (p.startsWith('Sun:')) sun = p.substring(4).trim();
      if (p.startsWith('Moon:')) moon = p.substring(5).trim();
      if (p.startsWith('Ascendant:')) ascendant = p.substring(10).trim();
    }
    List<String> parts = [];
    if (sun != null) parts.add('Sun in $sun');
    if (moon != null) parts.add('Moon in $moon');
    if (ascendant != null) parts.add('Ascendant in $ascendant');
    return parts.join('; ');
  }


  static String buildRetrieverQueryFR(List<String> placements) {
    String? soleil, lune, ascendant;
    for (final p in placements) {
      if (p.startsWith('Sun:')) soleil = p.substring(4).trim();
      if (p.startsWith('Moon:')) lune = p.substring(5).trim();
      if (p.startsWith('Ascendant:')) ascendant = p.substring(10).trim();
    }

    // Helper: translate zodiac sign from English to French
    String translateSign(String sign) {
      switch (sign) {
        case 'Aries': return 'Bélier';
        case 'Taurus': return 'Taureau';
        case 'Gemini': return 'Gémeaux';
        case 'Cancer': return 'Cancer';
        case 'Leo': return 'Lion';
        case 'Virgo': return 'Vierge';
        case 'Libra': return 'Balance';
        case 'Scorpio': return 'Scorpion';
        case 'Sagittarius': return 'Sagittaire';
        case 'Capricorn': return 'Capricorne';
        case 'Aquarius': return 'Verseau';
        case 'Pisces': return 'Poissons';
        default: return sign;
      }
    }

    List<String> parts = [];

    if (soleil != null) {
      final sign = soleil.split(' ').first; // remove degrees
      parts.add('Soleil en ${translateSign(sign)}');
    }
    if (lune != null) {
      final sign = lune.split(' ').first;
      parts.add('Lune en ${translateSign(sign)}');
    }
    if (ascendant != null) {
      final sign = ascendant.split(' ').first;
      // Optional: include ruler
      String ascRuler = '';
      final match = RegExp(r'\(ruler: (.+)\)').firstMatch(ascendant);
      if (match != null) {
        ascRuler = match.group(1)!;
        ascRuler = ascRuler.replaceAllMapped(RegExp(r'\b(\w+)\b'), (m) {
          switch (m[1]) {
            case 'Sun': return 'Soleil';
            case 'Moon': return 'Lune';
            case 'Mercury': return 'Mercure';
            case 'Venus': return 'Vénus';
            case 'Mars': return 'Mars';
            case 'Jupiter': return 'Jupiter';
            case 'Saturn': return 'Saturne';
            case 'Uranus': return 'Uranus';
            case 'Neptune': return 'Neptune';
            case 'Pluto': return 'Pluton';
          }
          return m[1]!;
        });
      }
      if (ascRuler.isNotEmpty) {
        parts.add('Ascendant en ${translateSign(sign)} (maître: $ascRuler)');
      } else {
        parts.add('Ascendant en ${translateSign(sign)}');
      }
    }

    return parts.join('; ');
  }


  /// Helper: format degree
  static String formatDegree(double degree) {
    int deg = degree.floor();
    int min = ((degree - deg) * 60).round();
    return "$deg°$min′";
  }

  /// Helper: detect aspect
  static String? _checkAspect(double d) {
    if ((d - 0).abs() <= 8 || (d - 360).abs() <= 8) return "Conjunction";
    if ((d - 60).abs() <= 6) return "Sextile";
    if ((d - 90).abs() <= 6) return "Square";
    if ((d - 120).abs() <= 8) return "Trine";
    if ((d - 180).abs() <= 8) return "Opposition";
    return null;
  }
}
