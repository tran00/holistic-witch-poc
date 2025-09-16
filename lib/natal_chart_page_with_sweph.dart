import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:sweph/sweph.dart';
import 'widgets/app_drawer.dart';
import 'widgets/natal_wheel_widget.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'openai_client.dart'; 
import 'services/geocoding_service.dart';

class NatalChartPageWithSweph extends StatefulWidget {
  const NatalChartPageWithSweph({super.key});

  @override
  State<NatalChartPageWithSweph> createState() =>
      _NatalChartPageWithSwephState();
}

class _NatalChartPageWithSwephState extends State<NatalChartPageWithSweph> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  Map<String, dynamic>? _chartData;
  bool _isLoading = false;
  String? _error;

  bool _isInitialized = false;

  String? _chartInterpretation;
  bool _isLoadingInterpretation = false;
  late final OpenAIClient _openAI;

  String? _chartPrompt;
  bool _showPromptEditor = false;
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _openAI = OpenAIClient(dotenv.env['OPENAI_API_KEY'] ?? '');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize timezone data first
      tz_data.initializeTimeZones();
      print('✅ Timezone database initialized');
      
      // Then initialize SwEph
      await _initializeSweph();
      
      // Set default values for birth data
      _dateController.text = '08/05/1980';
      _timeController.text = '04:35';
      _latController.text = '48.8848';
      _lonController.text = '2.2674';
      _nameController.text = 'Sample Chart';
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('❌ Error initializing app: $e');
      setState(() {
        _error = 'Error initializing app: $e';
      });
    }
  }

  Future<void> _initializeSweph() async {
    try {
      await Sweph.init(); // <-- This is required!
      Sweph.swe_set_ephe_path('assets/sweph/');
      print('✅ Swiss Ephemeris initialized successfully');
    } catch (e) {
      print('❌ Error initializing Swiss Ephemeris: $e');
      setState(() {
        _error = 'Error initializing ephemeris: $e';
      });
    }
  }

  Future<void> _calculateChart() async {
    if (!_isInitialized) {
      setState(() {
        _error = 'App is still initializing. Please wait...';
      });
      return;
    }

    if (_dateController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _latController.text.isEmpty ||
        _lonController.text.isEmpty) {
      setState(() {
        _error = 'Please fill all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Parse date and time
      final dateParts = _dateController.text.split('/');
      final timeParts = _timeController.text.split(':');

      if (dateParts.length != 3 || timeParts.length != 2) {
        throw Exception('Invalid date or time format');
      }

      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final latitude = double.parse(_latController.text);
      final longitude = double.parse(_lonController.text);

      // Parse local date and time
      final localDay = int.parse(dateParts[0]);
      final localMonth = int.parse(dateParts[1]);
      final localYear = int.parse(dateParts[2]);
      final localHour = int.parse(timeParts[0]);
      final localMinute = int.parse(timeParts[1]);

      // Declare UTC variables outside try block
      int utcYear = localYear;
      int utcMonth = localMonth;
      int utcDay = localDay;
      int utcHour = localHour;
      int utcMinute = localMinute;

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
        'name': _nameController.text.isNotEmpty
            ? _nameController.text
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

      // Calculate planetary positions
      await _calculatePlanets(julianDay, chartData);

      // Calculate houses (using Placidus system)
      await _calculateHouses(julianDay, latitude, longitude, chartData);

      // First: Group planets into houses (while houses is still a Map)
      groupPlanetsIntoHouses(chartData);

      // Second: Convert to wheel format (converts Map to List)
      _convertChartDataToWheelFormat(chartData);

      print('🔍 Planets data: ${chartData['planets']}');
      print('🔍 Houses data: ${chartData['houses']}');

      setState(() {
        _chartData = chartData;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error calculating chart: $e');
      setState(() {
        _error = 'Error calculating chart: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _calculatePlanets(
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
        final sign = _getZodiacSign(longitude);
        final degree = longitude % 30;
        chartData['planets'][entry.key] = {
          'name': entry.key, // <-- This is correct!
          'longitude': longitude,
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
  }

  Future<void> _calculateHouses(
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
          final sign = _getZodiacSign(houseLon);

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

  String _getZodiacSign(double longitude) {
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

  void _clearChart() {
    setState(() {
      _chartData = null;
      _error = null;
      _nameController.clear();
      _dateController.clear();
      _timeController.clear();
      _latController.clear();
      _lonController.clear();
    });
  }

  void _resetToPamelaDefaults() {
    setState(() {
      _dateController.text = '08/05/1980';
      _timeController.text = '04:35';
      _latController.text = '48.8848';
      _lonController.text = '2.2674';
      _nameController.text = 'Pamela';
      _cityController.text = 'Neuilly-sur-Seine'; // Set city for Pamela
      _chartData = null;
      _error = null;
    });
  }

  void _resetToTranDefaults() {
    setState(() {
      _dateController.text = '23/05/1975';
      _timeController.text = '18:56';
      _latController.text = '35.18';
      _lonController.text = '94.18';
      _nameController.text = 'Trân';
      _cityController.text = ''; // Clear city field
      _chartData = null;
      _error = null;
    });
  }

  void _convertChartDataToWheelFormat(Map<String, dynamic> chartData) {
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

  void groupPlanetsIntoHouses(Map<String, dynamic> chartData) {
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
        print(
          '⚠️ Planet ${planet['name']} at ${degree}° not assigned to any house',
        );
      }
    }
  }

  // String formatDegreeMinute(double decimalDegree) {
  //   final deg = decimalDegree.floor();
  //   final min = ((decimalDegree - deg) * 60).round();
  //   return "$deg°${min.toString().padLeft(2, '0')}'";
  // }

  String formatDegreeMinute(double decimalDegree) {
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

    // return "$sign $deg°${min.toString().padLeft(2, '0')}'${sec.toString().padLeft(2, '0')}\"";
    return "$deg°${min.toString().padLeft(2, '0')}'${sec.toString().padLeft(2, '0')}\"";
  }

  Future<void> _askOpenAIInterpretation() async {
    if (_chartData == null) return;
    
    setState(() {
      _isLoadingInterpretation = true;
      _chartInterpretation = null;
    });

    try {
      // Build comprehensive chart data for OpenAI
      final planets = _chartData!['planets'] as List;
      final houses = _chartData!['houses'] as List;
      
      String prompt = """En tant qu'astrologue expert, analyse cette carte natale complète et donne une interprétation détaillée:

INFORMATIONS DE NAISSANCE:
- Nom: ${_chartData!['name'] ?? 'Personne'}
- Date: ${_chartData!['date']}
- Heure: ${_chartData!['time']}
- Lieu: ${_chartData!['location']}

POSITIONS PLANÉTAIRES:""";

      // Add planetary positions
      for (final planet in planets) {
        final name = planet['name'];
        final sign = planet['sign'];
        final degree = planet['longitude'] ?? planet['full_degree'];
        final house = _findPlanetHouse(planet, houses);
        prompt += "\n- $name en $sign ${degree?.toStringAsFixed(1)}° (Maison $house)";
      }

      prompt += "\n\nMAISONS ASTROLOGIQUES:";
      
      // Add house cusps
      for (int i = 0; i < houses.length; i++) {
        final house = houses[i];
        final sign = house['sign'];
        final degree = house['longitude'];
        prompt += "\n- Maison ${i + 1}: $sign ${degree?.toStringAsFixed(1)}°";
      }

      prompt += """

DEMANDE D'ANALYSE:
1. Analyse la personnalité générale basée sur le Soleil, la Lune et l'Ascendant
2. Décris les traits dominants de caractère
3. Explique les aspects majeurs entre planètes et leur influence
4. Analyse les secteurs de vie importants (maisons occupées)
5. Donne des conseils pour l'évolution personnelle
6. Mentionne les défis et opportunités principaux

Sois précis, bienveillant et constructif dans ton analyse.

Tu t'adresses à l'utilisateur de manière directe et personnelle.""";

      // Store the prompt
      setState(() {
        _chartPrompt = prompt;
        _promptController.text = prompt;
      });

      final answer = await _openAI.sendMessage(prompt);
      
      if (mounted) {
        setState(() {
          _chartInterpretation = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chartInterpretation = 'Erreur lors de l\'analyse: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInterpretation = false;
        });
      }
    }
  }

  // Helper function to find which house a planet is in
  int _findPlanetHouse(Map<String, dynamic> planet, List houses) {
    final planetDegree = (planet['longitude'] ?? planet['full_degree'] ?? 0).toDouble();
    
    for (int i = 0; i < houses.length; i++) {
      final houseStart = (houses[i]['start_degree'] as num).toDouble();
      final houseEnd = (houses[i]['end_degree'] as num).toDouble();
      
      if (houseEnd > houseStart) {
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

  Future<void> _sendCustomPrompt() async {
    if (_promptController.text.isEmpty) return;
    
    setState(() {
      _isLoadingInterpretation = true;
      _chartInterpretation = null;
      _chartPrompt = _promptController.text;
    });

    try {
      final answer = await _openAI.sendMessage(_promptController.text);
      
      if (mounted) {
        setState(() {
          _chartInterpretation = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chartInterpretation = 'Erreur lors de l\'analyse: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInterpretation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Natal Chart with SwEph'),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Birth Information',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Input fields
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Sample Chart',
                ),
              ), // ← Make sure this closing parenthesis and comma are here

              const SizedBox(height: 16),

              TextField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Birth Date (DD/MM/YYYY)',
                  border: OutlineInputBorder(),
                  hintText: '08/05/1980',
                ),
              ), // ← And here

              const SizedBox(height: 16),

              TextField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Birth Time (HH:MM)',
                  border: OutlineInputBorder(),
                  hintText: '04:35',
                ),
              ), // ← And here

              const SizedBox(height: 16),

              // Autocomplete<String>(
              //   optionsBuilder: (TextEditingValue textEditingValue) async {
              //     if (textEditingValue.text == '') {
              //       return const Iterable<String>.empty();
              //     }
              //     final suggestions = await fetchCitySuggestions(textEditingValue.text);
              //     return suggestions;
              //   },
              //   fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              //     return TextField(
              //       controller: controller,
              //       focusNode: focusNode,
              //       decoration: const InputDecoration(
              //         labelText: 'City of Birth',
              //         border: OutlineInputBorder(),
              //         hintText: 'Type your city...',
              //       ),
              //     );
              //   },
              //   onSelected: (String selection) {
              //     _cityController.text = selection;
              //   },
              // ),
              TypeAheadField<Map<String, dynamic>>(
                controller: _cityController,
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'City of Birth (optional)', // Add (optional)
                      border: OutlineInputBorder(),
                      hintText: 'Type your city... (coordinates are sufficient)',
                    ),
                  );
                },
                suggestionsCallback: (pattern) async {
                  return await GeocodingService().fetchCitySuggestions(pattern);
                },
                itemBuilder: (context, Map<String, dynamic> suggestion) {
                  return ListTile(title: Text(suggestion['display_name']));
                },
                onSelected: (Map<String, dynamic> suggestion) {
                  _cityController.text = suggestion['display_name'];
                  _latController.text = suggestion['lat'];
                  _lonController.text = suggestion['lon'];
                },
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _latController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                  hintText: '48.8848 (Neuilly-sur-Seine)',
                ),
                keyboardType: TextInputType.number,
              ), // ← And here

              const SizedBox(height: 16),

              TextField(
                controller: _lonController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                  hintText: '2.2674 (Neuilly-sur-Seine)',
                ),
                keyboardType: TextInputType.number,
              ), // ← And here

              const SizedBox(height: 16),

              // Add this button next to your coordinate fields:
              ElevatedButton.icon(
                onPressed: () async {
                  if (_latController.text.isNotEmpty && _lonController.text.isNotEmpty) {
                    final lat = double.tryParse(_latController.text);
                    final lon = double.tryParse(_lonController.text);
                    
                    if (lat != null && lon != null) {
                      final result = await GeocodingService().reverseGeocode(lat, lon);
                      if (result != null) {
                        setState(() {
                          _cityController.text = result['display_name'] ?? '';
                        });
                      }
                    }
                  }
                },
                icon: const Icon(Icons.location_searching),
                label: const Text('Find City'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  ElevatedButton(
                    onPressed: (_isLoading || !_isInitialized) ? null : _calculateChart,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : !_isInitialized
                            ? const Text('Initializing...')
                            : const Text('Calculate Natal Chart'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _resetToPamelaDefaults,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Pamela'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _resetToTranDefaults,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Tran'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _clearChart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('Clear'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Error display
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red[800]),
                  ),
                ),

              // Chart display
              if (_chartData != null) ...[
                const Divider(height: 40),
                _buildChartDisplay(),
                NatalWheel(chartData: _chartData!),
                
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoadingInterpretation ? null : _askOpenAIInterpretation,
                      icon: _isLoadingInterpretation 
                          ? const SizedBox(
                              width: 16, 
                              height: 16, 
                              child: CircularProgressIndicator(strokeWidth: 2)
                            )
                          : const Icon(Icons.psychology),
                      label: const Text('Analyse OpenAI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showPromptEditor = !_showPromptEditor;
                        });
                      },
                      icon: Icon(_showPromptEditor ? Icons.keyboard_arrow_up : Icons.edit),
                      label: Text(_showPromptEditor ? 'Masquer' : 'Modifier prompt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                // Prompt editor section
                if (_showPromptEditor) ...[
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Éditeur de Prompt OpenAI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _promptController,
                          maxLines: 15,
                          decoration: const InputDecoration(
                            hintText: 'Écrivez votre question ou modifiez le prompt...',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isLoadingInterpretation ? null : _sendCustomPrompt,
                              icon: _isLoadingInterpretation 
                                  ? const SizedBox(
                                      width: 16, 
                                      height: 16, 
                                      child: CircularProgressIndicator(strokeWidth: 2)
                                    )
                                  : const Icon(Icons.send),
                              label: const Text('Envoyer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                _promptController.clear();
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Effacer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Display prompt used
                if (_chartPrompt != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.code, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              '📤 Prompt envoyé à OpenAI',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SelectableText(
                            _chartPrompt!,
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Display interpretation
                if (_chartInterpretation != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.psychology, color: Colors.deepPurple),
                            SizedBox(width: 8),
                            Text(
                              '📥 Réponse d\'OpenAI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          _chartInterpretation!,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          _chartData!['name'] ?? 'Natal Chart',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SelectableText('Date: ${_chartData!['date']}'),
        SelectableText('Time: ${_chartData!['time']}'),
        SelectableText('Location: ${_chartData!['location']}'),
        const SizedBox(height: 20),

        // Planets section
        const SelectableText(
          'Planetary Positions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (_chartData!['planets'] != null)
          ...(_chartData!['planets'] as List).map(
            (planet) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: SelectableText(
                      planet['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      '${planet['sign'] ?? ''} - ${planet['longitude'] != null ? formatDegreeMinute(planet['longitude']) : (planet['formatted'] ?? '')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Houses section
        const SelectableText(
          'House Cusps (Placidus)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (_chartData!['houses'] != null)
          ...(_chartData!['houses'] as List).asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: SelectableText(
                      'House ${entry.key + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      '${entry.value['sign'] ?? ''} - ${entry.value['longitude'] != null ? formatDegreeMinute(entry.value['longitude']) : (entry.value['formatted'] ?? '')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _cityController.dispose();
    _promptController.dispose(); // Add this
    super.dispose();
  }

  Map<String, dynamic> deepConvertToMapStringDynamic(Map input) {
    return input.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), deepConvertToMapStringDynamic(value));
      } else {
        return MapEntry(key.toString(), value);
      }
    });
  }
}

Future<List<Map<String, dynamic>>> fetchCitySuggestions(String query) async {
  if (query.isEmpty) return [];
  final url = Uri.parse(
    'https://nominatim.openstreetmap.org/search?city=$query&format=json&addressdetails=1&limit=10',
  );
  final response = await http.get(url, headers: {'User-Agent': 'YourApp/1.0'});
  if (response.statusCode == 200) {
    final List data = json.decode(response.body);
    return data.map<Map<String, dynamic>>((item) {
      return {
        'display_name': item['display_name'] ?? '',
        'lat': item['lat'] ?? '',
        'lon': item['lon'] ?? '',
      };
    }).toList();
  }
  return [];
}

String _getTimezoneFromCoordinates(double latitude, double longitude) {
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

// Example function to get timezone from an external API
Future<String> _getTimezoneFromAPI(double latitude, double longitude) async {
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
