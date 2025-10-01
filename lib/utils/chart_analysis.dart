import 'dart:math';
import 'astrology_utils.dart';

class ChartAnalysis {

  /// Translate a single placement string (e.g., 'Sun: Aries 12°34\'56"') to French
  static String translatePlacementFR(String placement) {
    String translatePlanet(String name) {
      switch (name) {
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
        case 'North Node': return 'Nœud Nord';
        case 'South Node': return 'Nœud Sud';
        case 'Chiron': return 'Chiron';
        case 'Lilith': return 'Lilith';
        case 'Ascendant': return 'Ascendant';
        case 'Descendant': return 'Descendant';
        case 'Midheaven': return 'Milieu du Ciel';
        case 'Imum Coeli': return 'Fond du Ciel';
        default: return name;
      }
    }
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
    final colonIdx = placement.indexOf(':');
    if (colonIdx == -1) return placement;
    final name = placement.substring(0, colonIdx).trim();
    var rest = placement.substring(colonIdx + 1).trim();
    final signMatch = RegExp(r'([A-Za-z]+)').firstMatch(rest);
    final sign = signMatch != null ? signMatch.group(1)! : '';
    final restAfterSign = signMatch != null ? rest.substring(signMatch.end).trim() : rest;
    // Special handling for angles with extra info (ruler, mode)
    if (name == 'Ascendant' || name == 'Descendant' || name == 'Midheaven' || name == 'Imum Coeli') {
      String extra = '';
      final match = RegExp(r'\(([^)]+)\)').firstMatch(restAfterSign);
      if (match != null) {
        extra = match.group(1)!;
        extra = extra.replaceAllMapped(RegExp(r'\b([A-Za-z]+)\b'), (m) => translatePlanet(m[1]!));
      }
      if (extra.isNotEmpty) {
        return '${translatePlanet(name)} en ${translateSign(sign)} ($extra)';
      } else {
        return '${translatePlanet(name)} en ${translateSign(sign)}';
      }
    } else {
      return '${translatePlanet(name)} en ${translateSign(sign)}';
    }
  }
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
        final mode = modes[sign];
        placements.add("$name: $sign $degree (ruler: $ruler, mode: $mode)");
      }
    });

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
    // Helper: translate planet/angle names and zodiac signs from English to French
    String translatePlanet(String name) {
      switch (name) {
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
        case 'North Node': return 'Nœud Nord';
        case 'South Node': return 'Nœud Sud';
        case 'Chiron': return 'Chiron';
        case 'Lilith': return 'Lilith';
        case 'Ascendant': return 'Ascendant';
        case 'Descendant': return 'Descendant';
        case 'Midheaven': return 'Milieu du Ciel';
        case 'Imum Coeli': return 'Fond du Ciel';
        default: return name;
      }
    }
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
    for (final p in placements) {
      // Example: "Sun: Aries 12°34'56""
      final colonIdx = p.indexOf(':');
      if (colonIdx == -1) {
        parts.add(p); // fallback, not a standard placement
        continue;
      }
      final name = p.substring(0, colonIdx).trim();
      var rest = p.substring(colonIdx + 1).trim();

      // Try to extract sign and degree
      final signMatch = RegExp(r'([A-Za-z]+)').firstMatch(rest);
      final sign = signMatch != null ? signMatch.group(1)! : '';
      final restAfterSign = signMatch != null ? rest.substring(signMatch.end).trim() : rest;

      // Special handling for angles with extra info (ruler, mode)
      if (name == 'Ascendant' || name == 'Descendant' || name == 'Midheaven' || name == 'Imum Coeli') {
        // Look for (ruler: ...)
        String extra = '';
        final match = RegExp(r'\(([^)]+)\)').firstMatch(restAfterSign);
        if (match != null) {
          extra = match.group(1)!;
          // Translate planet names in extra
          extra = extra.replaceAllMapped(RegExp(r'\b([A-Za-z]+)\b'), (m) => translatePlanet(m[1]!));
        }
        if (extra.isNotEmpty) {
          parts.add('${translatePlanet(name)} en ${translateSign(sign)} ($extra)');
        } else {
          parts.add('${translatePlanet(name)} en ${translateSign(sign)}');
        }
      } else {
        parts.add('${translatePlanet(name)} en ${translateSign(sign)}');
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
