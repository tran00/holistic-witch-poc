import 'package:flutter/material.dart';
import 'package:sweph/sweph.dart';
import 'widgets/app_drawer.dart';
import 'widgets/natal_wheel_widget.dart';

class NatalChartPageWithSweph extends StatefulWidget {
  const NatalChartPageWithSweph({super.key});

  @override
  State<NatalChartPageWithSweph> createState() => _NatalChartPageWithSwephState();
}

class _NatalChartPageWithSwephState extends State<NatalChartPageWithSweph> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  Map<String, dynamic>? _chartData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    // Set default values for birth data
    _dateController.text = '08/05/1980';  // May 8, 1980
    _timeController.text = '04:35';       // 4:35 AM
    _latController.text = '48.8848';      // Neuilly-sur-Seine latitude
    _lonController.text = '2.2674';       // Neuilly-sur-Seine longitude
    _nameController.text = 'Sample Chart'; // Default name
    
    _initializeSweph();
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

      // Create a local DateTime object (assumes input is local time)
      final localDateTime = DateTime(localYear, localMonth, localDay, localHour, localMinute);

      // Convert to UTC
      final utcDateTime = localDateTime.toUtc();

      // Use UTC values for sweph
      final utcYear = utcDateTime.year;
      final utcMonth = utcDateTime.month;
      final utcDay = utcDateTime.day;
      final utcHour = utcDateTime.hour;
      final utcMinute = utcDateTime.minute;

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
        'name': _nameController.text.isNotEmpty ? _nameController.text : 'Natal Chart',
        'date': '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year',
        'time': '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
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

  Future<void> _calculatePlanets(double julianDay, Map<String, dynamic> chartData) async {
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
        final result = Sweph.swe_calc_ut(julianDay, entry.value, SwephFlag.SEFLG_SPEED);
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

  Future<void> _calculateHouses(double julianDay, double latitude, double longitude, Map<String, dynamic> chartData) async {
    try {
      HouseCuspData? result;
      
      try {
        result = Sweph.swe_houses(julianDay, latitude, longitude, Hsys.P); // Placidus
      } catch (e1) {
        try {
          result = Sweph.swe_houses(julianDay, latitude, longitude, Hsys.K); // Koch
        } catch (e2) {
          try {
            result = Sweph.swe_houses(julianDay, latitude, longitude, Hsys.E); // Equal
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
        
        // Only take the first 12 house cusps (ignore any extra)
        final validCusps = houseCusps.take(12).toList();
        
        // Store the Ascendant for reference
        final ascendant = validCusps[0]; // First house cusp = Ascendant
        chartData['ascendant'] = ascendant;
        
        print('🏠 Ascendant: ${ascendant.toStringAsFixed(2)}°');
        
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
          
          print('House ${i + 1}: start=${houseLon.toStringAsFixed(2)}°, end=${nextHouseLon.toStringAsFixed(2)}°, sign=${sign}');
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
      'Aries', 'Taurus', 'Gemini', 'Cancer',
      'Leo', 'Virgo', 'Libra', 'Scorpio',
      'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
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

  void _resetToDefaults() {
    setState(() {
      _dateController.text = '08/05/1980';
      _timeController.text = '04:35';
      _latController.text = '48.8848';
      _lonController.text = '2.2674';
      _nameController.text = 'Sample Chart';
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
        print('⚠️ Planet ${planet['name']} at ${degree}° not assigned to any house');
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
      "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
      "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
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

              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _calculateChart,
                    child: _isLoading 
                        ? const CircularProgressIndicator()
                        : const Text('Calculate Natal Chart'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _resetToDefaults,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Defaults'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _clearChart,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
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
        Text(
          _chartData!['name'] ?? 'Natal Chart',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Date: ${_chartData!['date']}'),
        Text('Time: ${_chartData!['time']}'),
        Text('Location: ${_chartData!['location']}'),
        const SizedBox(height: 20),

        // Planets section
        const Text(
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
                    child: Text(
                      planet['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${planet['sign'] ?? ''} - ${planet['longitude'] != null ? formatDegreeMinute(planet['longitude']) : (planet['formatted'] ?? '')}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Houses section
        const Text(
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
                    child: Text(
                      'House ${entry.key + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${entry.value['sign'] ?? ''} - ${entry.value['longitude'] != null ? formatDegreeMinute(entry.value['longitude']) : (entry.value['formatted'] ?? '')}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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