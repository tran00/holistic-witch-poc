import 'package:flutter/material.dart';
import 'package:sweph/sweph.dart';
import 'widgets/app_drawer.dart';
import 'widgets/natal_wheel_widget.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'openai_client.dart'; 
import 'services/geocoding_service.dart';
import 'services/astrology_calculation_service.dart';
import 'utils/astrology_utils.dart';

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
      final chartData = await AstrologyCalculationService.calculateChart(
        name: _nameController.text,
        date: _dateController.text,
        time: _timeController.text,
        lat: _latController.text,
        long: _lonController.text,
        location: _cityController.text.isNotEmpty 
            ? _cityController.text 
            : 'Lat: ${_latController.text}, Lon: ${_lonController.text}',
      );

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
        final house = AstrologyUtils.findPlanetHouse(planet, houses);
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

  void _resetToPamelaDefaults() {
    setState(() {
      _nameController.text = 'Pamela';
      _dateController.text = '08/05/1980';
      _timeController.text = '04:35';
      _latController.text = '48.53';
      _lonController.text = '2.16';
      _cityController.text = '';
      _chartData = null;
      _error = null;
    });
  }

  void _resetToTranDefaults() {
    setState(() {
      _nameController.text = 'Tran';
      _dateController.text = '23/05/1975';
      _timeController.text = '18:56';
      _latController.text = '35.18';
      _lonController.text = '-94.180';
      _cityController.text = '';
      _chartData = null;
      _error = null;
    });
  }

  void _clearChart() {
    setState(() {
      _nameController.clear();
      _dateController.clear();
      _timeController.clear();
      _latController.clear();
      _lonController.clear();
      _cityController.clear();
      _chartData = null;
      _error = null;
    });
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
                      '${planet['sign'] ?? ''} - ${planet['longitude'] != null ? AstrologyUtils.formatDegreeMinute(planet['longitude']) : (planet['formatted'] ?? '')}',
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
                      '${entry.value['sign'] ?? ''} - ${entry.value['longitude'] != null ? AstrologyUtils.formatDegreeMinute(entry.value['longitude']) : (entry.value['formatted'] ?? '')}',
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
}
