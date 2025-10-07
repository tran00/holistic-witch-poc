// lib/daily_chart_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets/app_drawer.dart';
import 'widgets/natal_wheel_widget.dart';
import 'widgets/composite_natal_wheel_widget.dart';
import 'services/sweph_service.dart';
import 'services/astrology_calculation_service.dart';
import 'rag_service_singleton.dart';

class DailyChartPage extends StatefulWidget {
  const DailyChartPage({super.key});

  @override
  State<DailyChartPage> createState() => _DailyChartPageState();
}

class _DailyChartPageState extends State<DailyChartPage> {
  final _formKey = GlobalKey<FormState>();

  // Natal chart form controllers
  final _natalNameController = TextEditingController();
  final _natalDateController = TextEditingController();
  final _natalTimeController = TextEditingController();
  final _natalLocationController = TextEditingController();
  final _natalLatitudeController = TextEditingController();
  final _natalLongitudeController = TextEditingController();

  // Daily chart form controllers
  final _dailyDateController = TextEditingController();
  final _dailyTimeController = TextEditingController();
  final _dailyLocationController = TextEditingController();
  final _dailyLatitudeController = TextEditingController();
  final _dailyLongitudeController = TextEditingController();

  Map<String, dynamic>? _natalChartData;
  Map<String, dynamic>? _dailyChartData;
  bool _isLoading = false;
  bool _isInitialized = false; // Add this
  String? _errorMessage;

  // Transit interpretation state
  Map<String, String> _planetInterpretations = {};
  Map<String, String> _planetPrompts = {};
  Map<String, String> _planetDebugInfo = {};
  Map<String, bool> _planetLoadingStates = {
    // Slow planets
    'Saturn': false,
    'Uranus': false,
    'Neptune': false,
    'Pluto': false,
    // Fast planets  
    'La lune': false,
    'Mercure': false,
    'Vénus': false,
    'Mars': false,
    'Jupiter': false,
  };

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  // Add this method
  Future<void> _initializeServices() async {
    try {
      await SwephService.initialize();
      setState(() {
        _isInitialized = true;
      });
      _initializeWithDefaults();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize services: $e';
      });
    }
  }

  void _initializeWithDefaults() {
    // Default natal data
    _natalNameController.text = 'John Doe';
    _natalDateController.text = '15/05/1990';  // Changed to DD/MM/YYYY
    _natalTimeController.text = '14:30';
    _natalLocationController.text = 'Paris, France';
    _natalLatitudeController.text = '48.8848';
    _natalLongitudeController.text = '2.2674';

    // Default daily data - today
    final now = DateTime.now();
    _dailyDateController.text = DateFormat('dd/MM/yyyy').format(now);  // Changed to DD/MM/YYYY
    _dailyTimeController.text = DateFormat('HH:mm').format(now);
    _dailyLocationController.text = 'Paris, France';
    _dailyLatitudeController.text = '48.8566';
    _dailyLongitudeController.text = '2.3522';
  }

  @override
  void dispose() {
    _natalNameController.dispose();
    _natalDateController.dispose();
    _natalTimeController.dispose();
    _natalLocationController.dispose();
    _natalLatitudeController.dispose();
    _natalLongitudeController.dispose();
    _dailyDateController.dispose();
    _dailyTimeController.dispose();
    _dailyLocationController.dispose();
    _dailyLatitudeController.dispose();
    _dailyLongitudeController.dispose();
    super.dispose();
  }

  DateTime? _parseDateTime(String date, String time) {
    try {
      // Parse DD/MM/YYYY format
      final dateParts = date.split('/');
      if (dateParts.length != 3) return null;
      
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);
      
      final timeParts = time.split(':');
      if (timeParts.length != 2) return null;
      
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  Future<void> _generateCharts() async {
    print('Generate Charts button clicked.');

    // Check if services are initialized
    if (!_isInitialized) {
      setState(() {
        _errorMessage = 'Services are still initializing. Please wait...';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed.');
      setState(() {
        _errorMessage = 'Please fill all required fields correctly.';
      });
      return;
    }

    setState(() {
      print('Starting chart generation...');
      _isLoading = true;
      _errorMessage = null;
      _natalChartData = null;
      _dailyChartData = null;
    });

    try {
      // Parse natal date/time
      print('Parsing natal date/time...');
      final natalDateTime = _parseDateTime(_natalDateController.text, _natalTimeController.text);
      if (natalDateTime == null) {
        throw Exception('Invalid natal date/time format');
      }

      // Parse daily date/time
      print('Parsing daily date/time...');
      final dailyDateTime = _parseDateTime(_dailyDateController.text, _dailyTimeController.text);
      if (dailyDateTime == null) {
        throw Exception('Invalid daily date/time format');
      }

      // Generate natal chart
      print('Generating natal chart...');
      final natalData = await AstrologyCalculationService.calculateChart(
        name: _natalNameController.text,
        date: _natalDateController.text,
        time: _natalTimeController.text,
        lat: _natalLatitudeController.text,
        long: _natalLongitudeController.text,
        location: _natalLocationController.text,
      );

      // Generate daily chart
      print('Generating daily chart...');
      final dailyData = await AstrologyCalculationService.calculateChart(
        name: 'Daily Chart - ${_dailyDateController.text}',
        date: _dailyDateController.text,
        time: _dailyTimeController.text,
        lat: _dailyLatitudeController.text,
        long: _dailyLongitudeController.text,
        location: _dailyLocationController.text,
      );

      print('Charts generated successfully.');
      setState(() {
        _natalChartData = natalData;
        _dailyChartData = dailyData;
      });
    } catch (e) {
      print('Error generating charts: $e');
      setState(() {
        _errorMessage = 'Error generating charts: $e';
      });
    } finally {
      setState(() {
        print('Chart generation complete.');
        _isLoading = false;
      });
    }
  }

  void _clearCharts() {
    setState(() {
      _natalChartData = null;
      _dailyChartData = null;
      _errorMessage = null;
      _planetInterpretations.clear();
      _planetPrompts.clear();
      _planetDebugInfo.clear();
      _planetLoadingStates = {
        'Saturn': false,
        'Uranus': false,
        'Neptune': false,
        'Pluto': false,
      };
    });
  }

  Future<void> _requestPlanetTransitInterpretation(String planetName) async {
    print('🌟 Starting interpretation request for $planetName');
    
    if (_natalChartData == null || _dailyChartData == null) {
      print('❌ Chart data missing: natal=${_natalChartData != null}, daily=${_dailyChartData != null}');
      setState(() {
        _planetDebugInfo[planetName] = '❌ Données manquantes: Veuillez d\'abord générer les cartes natale et quotidienne.';
      });
      return;
    }

    setState(() {
      _planetLoadingStates[planetName] = true;
      _planetDebugInfo[planetName] = '🔄 Début de l\'analyse pour $planetName...';
    });

    try {
      // Build prompt with specific planet transit information
      final String prompt = _buildPlanetTransitPrompt(planetName);
      
      print('📝 Prompt generated for $planetName: ${prompt.length} characters');
      
      setState(() {
        _planetPrompts[planetName] = prompt;
        _planetDebugInfo[planetName] = '''📤 Requête envoyée au système RAG...

🔮 Service RAG configuré et prêt
📊 Longueur de la requête: ${prompt.length} caractères
🌍 Endpoint: RAG Service (Pinecone + Supabase + OpenAI)
⏱️ Début de l\'analyse...''';
      });

      print('🚀 Sending query for $planetName to RAG service...');
      
      // Use RAG service with astrology context filter
      final ragResponse = await ragService.askQuestion(
        prompt,
        systemPrompt: "Tu es un astrologue professionnel expert en transits planétaires. Réponds en français de manière détaillée et bienveillante en t'appuyant sur le contexte astrologique fourni.",
        contextFilter: 'astrologie', // Filter for astrology-related content
        topK: 8, // Get more relevant sources
        scoreThreshold: 0.4, // Lower threshold for more context
      );
      
      final interpretation = ragResponse['answer'] as String;
      final sources = ragResponse['sources'] as List;
      
      print('✅ Received RAG interpretation for $planetName: ${interpretation.length} characters from ${sources.length} sources');
      
      setState(() {
        _planetInterpretations[planetName] = interpretation;
        _planetLoadingStates[planetName] = false;
        _planetDebugInfo[planetName] = '''✅ Analyse RAG terminée avec succès !
        
📊 Statistiques:
• Requête envoyée: ${prompt.length} caractères
• Réponse reçue: ${interpretation.length} caractères
• Sources consultées: ${sources.length}
• Statut: Succès ✅
• Système: RAG (Pinecone + Supabase + OpenAI)
• Context Filter: Astrologie
• Temps de traitement: ~quelques secondes''';
      });
      
    } catch (e) {
      print('❌ Error getting RAG interpretation for $planetName: $e');
      
      setState(() {
        _planetLoadingStates[planetName] = false;
        _planetDebugInfo[planetName] = '''❌ Erreur lors de l\'analyse RAG:
        
🚨 Type d\'erreur: ${e.runtimeType}
📝 Message: ${e.toString()}
🔧 Suggestions:
• Vérifiez votre connexion internet
• Vérifiez les configurations RAG dans .env
• Vérifiez Pinecone et Supabase
• Consultez les logs de debug

💡 Détails techniques:
${e.toString()}''';
        _errorMessage = 'Failed to get $planetName RAG interpretation: $e';
      });
    }
  }

  String _getEnglishPlanetName(String frenchName) {
    switch (frenchName) {
      case 'La lune': return 'Moon';
      case 'Mercure': return 'Mercury';
      case 'Vénus': return 'Venus';
      case 'Mars': return 'Mars';
      case 'Jupiter': return 'Jupiter';
      case 'Saturn': return 'Saturn';
      case 'Uranus': return 'Uranus';
      case 'Neptune': return 'Neptune';
      case 'Pluto': return 'Pluto';
      default: return frenchName; // Return as-is if no mapping found
    }
  }

  String _buildPlanetTransitPrompt(String planetName) {
    if (_natalChartData == null || _dailyChartData == null) return '';

    try {
      final natalPlanets = (_natalChartData!['planets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final transitPlanets = (_dailyChartData!['planets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final natalHouses = (_natalChartData!['houses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final dailyHouses = (_dailyChartData!['houses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      
      print('🔍 Debug - Natal planets: ${natalPlanets.length}, Transit planets: ${transitPlanets.length}');
      print('🏠 Debug - Natal houses: ${natalHouses.length}, Daily houses: ${dailyHouses.length}');
      
      // Debug: Print the actual house data structure
      print('📋 Daily houses structure:');
      for (int i = 0; i < dailyHouses.length && i < 3; i++) {
        print('   House ${i + 1}: ${dailyHouses[i]}');
      }
    
      // Convert French planet name to English for chart data lookup
      final englishPlanetName = _getEnglishPlanetName(planetName);
      print('🔄 Planet name mapping: $planetName -> $englishPlanetName');
    
      // Find the transit planet using English name
      final transitPlanet = transitPlanets.firstWhere(
        (planet) => planet['name'].toString().toLowerCase() == englishPlanetName.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );
      
      if (transitPlanet.isEmpty) {
        print('❌ Transit planet $englishPlanetName (from $planetName) not found');
        print('📋 Available planets: ${transitPlanets.map((p) => p['name']).join(', ')}');
        return '';
      }
      
      final transitLongitude = (transitPlanet['longitude'] as num?)?.toDouble();
      if (transitLongitude == null) {
        print('❌ Transit longitude is null for $planetName');
        return 'Erreur: longitude de transit manquante pour $planetName';
      }
      
      final transitSign = _getZodiacSign(transitLongitude);
      final transitDegrees = _getDegreesInSign(transitLongitude);
      
      // Find which house this transit is in using DAILY chart houses (where the transit actually is)
      final transitHouse = _findHouseForLongitude(transitLongitude, dailyHouses);
      
      final natalDate = _natalDateController.text;
      final transitDate = _dailyDateController.text;
      
      String prompt = '''En tant qu'astrologue professionnel, veuillez fournir une interprétation détaillée du transit de $planetName pour une personne née le $natalDate, en analysant la position de $planetName le $transitDate.

POSITION ACTUELLE DE $planetName EN TRANSIT:
- $planetName: ${transitDegrees.toStringAsFixed(1)}° en $transitSign (Maison $transitHouse)

THÈME NATAL (Naissance):
''';

      // Add natal planets with aspects to the transiting planet
      for (var planet in natalPlanets) {
        final name = planet['name'];
        final longitude = (planet['longitude'] as num?)?.toDouble();
        if (longitude == null) continue; // Skip planets with null longitude
        
        final sign = _getZodiacSign(longitude);
        final degrees = _getDegreesInSign(longitude);
        
        // Calculate aspect between transit planet and natal planet
        final aspect = _calculateAspect(transitLongitude, longitude);
        if (aspect.isNotEmpty) {
          prompt += '- $name natal: ${degrees.toStringAsFixed(1)}° $sign [$aspect avec $planetName en transit]\n';
        } else {
          prompt += '- $name natal: ${degrees.toStringAsFixed(1)}° $sign\n';
        }
      }

      prompt += '''

Veuillez fournir une interprétation qui inclut:

1. **Signification générale**: Que représente ce transit de $planetName en $transitSign dans la Maison $transitHouse
2. **Aspects importants**: Analysez les aspects formés avec les planètes natales
3. **Domaines de vie activés**: Quels secteurs de vie sont influencés par cette position
4. **Opportunités et défis**: Que peut-on attendre de positif et de difficile
5. **Conseils pratiques**: Comment bien vivre et utiliser cette énergie
6. **Timing**: Durée approximative et intensité de ce transit

Gardez l'interprétation accessible, pratique et bienveillante, en français.''';

      return prompt;
      
    } catch (e) {
      print('❌ Error building prompt for $planetName: $e');
      return 'Erreur lors de la génération du prompt: $e';
    }
  }

  String _calculateAspect(double longitude1, double longitude2) {
    double diff = (longitude1 - longitude2).abs();
    if (diff > 180) diff = 360 - diff;
    
    if (diff <= 9) return 'Conjonction';
    if ((diff - 60).abs() <= 8) return 'Sextile';
    if ((diff - 90).abs() <= 9) return 'Carré';
    if ((diff - 120).abs() <= 9) return 'Trigone';
    if ((diff - 180).abs() <= 9) return 'Opposition';
    
    return '';
  }

  int _findHouseForLongitude(double longitude, List<Map<String, dynamic>> houses) {
    if (houses.isEmpty) return 1;
    
    // Normalize longitude to 0-360 range
    longitude = longitude % 360;
    if (longitude < 0) longitude += 360;
    
    print('🏠 Finding house for longitude ${longitude.toStringAsFixed(2)}°');
    
    // Print all house cusps for debugging with multiple possible field names
    for (int i = 0; i < houses.length; i++) {
      final house = houses[i];
      print('   House ${i + 1} data: $house');
      
      // Try different possible field names for house cusp
      final cusp = (house['cusp'] as num?)?.toDouble() ??
                  (house['start_degree'] as num?)?.toDouble() ??
                  (house['longitude'] as num?)?.toDouble() ??
                  (house['degree'] as num?)?.toDouble();
      print('   House ${i + 1}: ${cusp?.toStringAsFixed(2)}°');
    }
    
    for (int i = 0; i < houses.length; i++) {
      final house = houses[i];
      
      // Try different possible field names for house cusp
      final cusp = (house['cusp'] as num?)?.toDouble() ??
                  (house['start_degree'] as num?)?.toDouble() ??
                  (house['longitude'] as num?)?.toDouble() ??
                  (house['degree'] as num?)?.toDouble();
      
      if (cusp == null) {
        print('⚠️ House ${i + 1}: No valid cusp found in $house');
        continue;
      }
      
      // Normalize cusp to 0-360 range
      final normalizedCusp = cusp % 360;
      final currentCusp = normalizedCusp < 0 ? normalizedCusp + 360 : normalizedCusp;
      
      // Get next house cusp
      final nextIndex = (i + 1) % houses.length;
      final nextHouse = houses[nextIndex];
      final nextCusp = (nextHouse['cusp'] as num?)?.toDouble() ??
                      (nextHouse['start_degree'] as num?)?.toDouble() ??
                      (nextHouse['longitude'] as num?)?.toDouble() ??
                      (nextHouse['degree'] as num?)?.toDouble();
      
      if (nextCusp == null) continue;
      
      final normalizedNextCusp = nextCusp % 360;
      final nextHouseCusp = normalizedNextCusp < 0 ? normalizedNextCusp + 360 : normalizedNextCusp;
      
      // Check if longitude falls within this house
      bool isInHouse = false;
      
      if (currentCusp <= nextHouseCusp) {
        // Normal case: house doesn't cross 0°
        isInHouse = longitude >= currentCusp && longitude < nextHouseCusp;
      } else {
        // House crosses 0° (e.g., from 350° to 20°)
        isInHouse = longitude >= currentCusp || longitude < nextHouseCusp;
      }
      
      if (isInHouse) {
        print('🎯 Planet at ${longitude.toStringAsFixed(2)}° is in House ${i + 1} (${currentCusp.toStringAsFixed(2)}° - ${nextHouseCusp.toStringAsFixed(2)}°)');
        return i + 1;
      }
    }
    
    print('⚠️ Could not determine house, defaulting to House 1');
    return 1; // Default to first house
  }

  String _getZodiacSign(double longitude) {
    const signs = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 
                   'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'];
    int signIndex = (longitude / 30).floor();
    return signs[signIndex % 12];
  }

  double _getDegreesInSign(double longitude) {
    return longitude % 30;
  }

  Widget _buildNatalForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Natal Chart Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _natalNameController.text = 'Tran';
                    _natalDateController.text = '23/05/1975';  // Changed to DD/MM/YYYY
                    _natalTimeController.text = '18:56';
                    _natalLatitudeController.text = '35.18';
                    _natalLongitudeController.text = '-94.180';
                    _natalLocationController.text = 'Default Location for Tran';
                  },
                  child: const Text('Use Tran'),
                ),
                TextButton(
                  onPressed: () {
                    _natalNameController.text = 'Pamela';
                    _natalDateController.text = '08/05/1980';  // Changed to DD/MM/YYYY
                    _natalTimeController.text = '04:35';
                    _natalLatitudeController.text = '48.53';
                    _natalLongitudeController.text = '2.16';
                    _natalLocationController.text = 'Default Location for Pamela';
                  },
                  child: const Text('Use Pamela'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _natalNameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) => value?.isEmpty == true ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _natalDateController,
                    decoration: const InputDecoration(
                      labelText: 'Birth Date (DD/MM/YYYY)',  // Updated label
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Please enter birth date' : null,
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        _natalDateController.text = DateFormat('dd/MM/yyyy').format(date);  // Changed format
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _natalTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Birth Time (HH:MM)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Please enter birth time' : null,
                    readOnly: true,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 12, minute: 0),
                      );
                      if (time != null) {
                        _natalTimeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _natalLocationController,
              decoration: const InputDecoration(
                labelText: 'Birth Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) => value?.isEmpty == true ? 'Please enter birth location' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _natalLatitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Please enter latitude';
                      final lat = double.tryParse(value!);
                      if (lat == null || lat < -90 || lat > 90) {
                        return 'Invalid latitude (-90 to 90)';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _natalLongitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Please enter longitude';
                      final lng = double.tryParse(value!);
                      if (lng == null || lng < -180 || lng > 180) {
                        return 'Invalid longitude (-180 to 180)';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Chart Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dailyDateController,
                    decoration: const InputDecoration(
                      labelText: 'Date (DD/MM/YYYY)',  // Updated label
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Please enter date' : null,
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        _dailyDateController.text = DateFormat('dd/MM/yyyy').format(date);  // Changed format
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _dailyTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Time (HH:MM)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Please enter time' : null,
                    readOnly: true,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        _dailyTimeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dailyLocationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) => value?.isEmpty == true ? 'Please enter location' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dailyLatitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Please enter latitude';
                      final lat = double.tryParse(value!);
                      if (lat == null || lat < -90 || lat > 90) {
                        return 'Invalid latitude (-90 to 90)';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _dailyLongitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Please enter longitude';
                      final lng = double.tryParse(value!);
                      if (lng == null || lng < -180 || lng > 180) {
                        return 'Invalid longitude (-180 to 180)';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Chart Comparison'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: !_isInitialized
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing Swiss Ephemeris...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compare any day\'s planetary positions with your natal chart',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    _buildNatalForm(),
                    const SizedBox(height: 16),
                    _buildDailyForm(),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _generateCharts,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(_isLoading ? 'Generating Charts...' : 'Generate Chart Comparison'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _clearCharts,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Charts'),
                        ),
                      ],
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (_natalChartData != null) ...[
                      const Text(
                        'Natal Chart',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      NatalWheel(chartData: _natalChartData!),
                    ],
                    if (_dailyChartData != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Daily Chart',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      NatalWheel(chartData: _dailyChartData!),
                    ],
                    if (_natalChartData != null && _dailyChartData != null) ...[
                      const SizedBox(height: 40),
                      const Text(
                        'Composite Chart (Natal + Daily Transits)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Natal Planets', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 16),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Transit Planets', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 60),
                      CompositeNatalWheel(
                        natalChartData: _natalChartData!,
                        transitChartData: _dailyChartData!,
                      ),
                      const SizedBox(height: 32),
                      // Transit des planètes lentes Section
                      const Text(
                        'Transit des planètes lentes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B2CBF),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Display planets with their buttons and interpretations inline
                      ...['Saturn', 'Uranus', 'Neptune', 'Pluto'].map((planetName) {
                        return Column(
                          children: [
                            // Planet button
                            Center(
                              child: _buildPlanetButton(
                                planetName, 
                                _getPlanetIcon(planetName), 
                                _getPlanetColor(planetName)
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Show interpretation immediately below the button if available
                            Builder(
                              builder: (context) {
                                final hasInterpretation = _planetInterpretations.containsKey(planetName);
                                final hasDebugInfo = _planetDebugInfo.containsKey(planetName);
                                final isLoading = _planetLoadingStates[planetName] ?? false;
                                
                                if (hasInterpretation || hasDebugInfo || isLoading) {
                                  return _buildInterpretationCard(
                                    planetName, 
                                    _planetInterpretations[planetName] ?? ''
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            const SizedBox(height: 24), // Space between planet sections
                          ],
                        );
                      }).toList(),
                      const SizedBox(height: 40),
                      
                      // Transit des planètes rapides Section
                      const Text(
                        'Transit des planètes rapides',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B2CBF),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Display fast planets with their buttons and interpretations inline
                      ...['La lune', 'Mercure', 'Vénus', 'Mars', 'Jupiter'].map((planetName) {
                        return Column(
                          children: [
                            // Planet button
                            Center(
                              child: _buildPlanetButton(
                                planetName, 
                                _getPlanetIcon(planetName), 
                                _getPlanetColor(planetName)
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Show interpretation immediately below the button if available
                            Builder(
                              builder: (context) {
                                final hasInterpretation = _planetInterpretations.containsKey(planetName);
                                final hasDebugInfo = _planetDebugInfo.containsKey(planetName);
                                final isLoading = _planetLoadingStates[planetName] ?? false;
                                
                                if (hasInterpretation || hasDebugInfo || isLoading) {
                                  return _buildInterpretationCard(
                                    planetName, 
                                    _planetInterpretations[planetName] ?? ''
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            const SizedBox(height: 24), // Space between planet sections
                          ],
                        );
                      }).toList(),
                      const SizedBox(height: 60),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPlanetButton(String planetName, IconData icon, Color color) {
    final isLoading = _planetLoadingStates[planetName] ?? false;
    
    return SizedBox(
      width: 200, // Increased width for better visual balance when centered
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : () {
          print('🔘 Button clicked for $planetName');
          _requestPlanetTransitInterpretation(planetName);
        },
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(
          isLoading ? 'Analyse...' : '$planetName en transit',
          style: const TextStyle(fontSize: 14), // Slightly larger text
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: 14, // Slightly more padding
            horizontal: 20,
          ),
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildInterpretationCard(String planetName, String interpretation) {
    final prompt = _planetPrompts[planetName] ?? '';
    final debugInfo = _planetDebugInfo[planetName] ?? '';
    
    return Column(
      children: [
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getPlanetIcon(planetName), color: _getPlanetColor(planetName)),
                    const SizedBox(width: 8),
                    Text(
                      'Transit de $planetName',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getPlanetColor(planetName),
                      ),
                    ),
                  ],
                ),
                // Prompt Section
                if (prompt.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text(
                      '📝 Requête envoyée au système RAG',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          prompt,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Interpretation Section
                if (interpretation.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '� Interprétation RAG (IA + Base de Connaissances)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      interpretation,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getPlanetIcon(String planetName) {
    switch (planetName) {
      // Slow planets
      case 'Saturn': return Icons.schedule;
      case 'Uranus': return Icons.electric_bolt;
      case 'Neptune': return Icons.water_drop;
      case 'Pluto': return Icons.transform;
      // Fast planets
      case 'La lune': return Icons.nightlight_round;
      case 'Mercure': return Icons.speed;
      case 'Vénus': return Icons.favorite;
      case 'Mars': return Icons.whatshot;
      case 'Jupiter': return Icons.star;
      default: return Icons.circle;
    }
  }

  Color _getPlanetColor(String planetName) {
    switch (planetName) {
      // Slow planets
      case 'Saturn': return const Color(0xFF8B4513);
      case 'Uranus': return const Color(0xFF1E90FF);
      case 'Neptune': return const Color(0xFF4169E1);
      case 'Pluto': return const Color(0xFF8B008B);
      // Fast planets
      case 'La lune': return const Color(0xFFC0C0C0); // Silver
      case 'Mercure': return const Color(0xFFFF8C00); // Dark orange
      case 'Vénus': return const Color(0xFFFF69B4); // Hot pink
      case 'Mars': return const Color(0xFFDC143C); // Crimson
      case 'Jupiter': return const Color(0xFFFFD700); // Gold
      default: return const Color(0xFF7B2CBF);
    }
  }
}