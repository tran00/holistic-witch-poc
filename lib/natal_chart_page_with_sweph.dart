import 'package:flutter/material.dart';
import 'package:poc/rag_service_singleton.dart';
import 'package:sweph/sweph.dart';
import 'widgets/app_drawer.dart';
import 'widgets/natal_wheel_widget.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'openai_client.dart'; 
import 'services/geocoding_service.dart';
import 'services/unified_astrology_service.dart';
import 'services/chart_interpretation_service.dart';
import 'services/rag_service.dart';
import 'utils/astrology_utils.dart';
import 'utils/chart_analysis.dart';

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
  late final ChartInterpretationService _chartInterpretationService;

  String? _chartPrompt;
  bool _showPromptEditor = false;
  final TextEditingController _promptController = TextEditingController();

  // Store RAG query and answer for each button
  List<Map<String, String?>> _ragResults = List.generate(10, (index) => {'query': null, 'answer': null});

  // Astrology tone categories (id, name, description, narration)
  final List<Map<String, String>> _astrologyToneCategories = [
    {
      'id': '0',
      'name': "Ouverture — Le Souffle de l'Âme",
      'description': "Ton thème natal est une carte vivante. Un organisme vibrant où chaque planète, chaque signe, chaque maison est un organe relié aux autres. Rien n’est figé : tout respire, tout dialogue. Ici, il ne s’agit pas de prédire, mais de révéler le chant secret de ton âme.",
      'narration': ''
    },
    {
      'id': '1',
      'name': "La Triade Vitale",
      'description': "Soleil → Ta lumière créatrice : ton chemin de rayonnement, ce que tu es appelé·e à incarner avec constance. • Lune → Tes marées intérieures : ton univers émotionnel, la mémoire intime qui te berce. • Ascendant (+ son maître) → Ta porte d’entrée dans le monde : la vibration que les autres ressentent en premier.",
      'narration': "Ton Soleil en [Signe] éclaire la voie de ton accomplissement. Ta Lune en [Signe] révèle la couleur de ton monde intérieur, ce dont ton cœur a besoin pour se sentir en sécurité. Ton Ascendant en [Signe] est le seuil par lequel tu t’offres au monde, la première note de ta mélodie incarnée."
    },
    {
      'id': '2',
      'name': "Les Axes de l’Être",
      'description': "Ascendant / Descendant → relation entre soi et l’autre. Fond du Ciel / Milieu du Ciel → racines et vocation.",
      'narration': "TTon axe Ascendant–Descendant trace la danse entre ton individualité et tes relations. Ton axe Fond du Ciel–Milieu du Ciel est la respiration entre tes racines intimes et ton horizon de réalisation. Ensemble, ces lignes forment la croix de ton être : elles relient l’intime et le monde, le je et le nous."
    },
    {
      'id': '3',
      'name': "Les Climats de l’Âme — Éléments & Modes",
      'description': "Éléments (Feu, Terre, Air, Eau) → ton atmosphère énergétique. Modes (Cardinal, Fixe, Mutable) → ta manière d’avancer dans la vie.",
      'narration': "Ton ciel est habité par une dominante de [Élément]. Cela signifie que tu avances avant tout par [fonction de l’élément]. Ton mode [Cardinal/Fixe/Mutable] révèle que tu as une manière [initier / stabiliser / transformer] ton chemin. Ce climat est le souffle général qui nourrit toutes tes planètes. "
    },
    {
      'id': '4',
      'name': "Les Planètes Personnelles — Ta voix intime",
      'description': "Mercure : ta pensée, ton langage. Vénus : ton amour, tes désirs, ta beauté. Mars : ton feu, ton action, ta force vitale.",
      'narration': "Mercure en [Signe/Maison] révèle comment ton esprit dialogue avec le monde. Vénus en [Signe/Maison] raconte ta manière d’aimer, de créer, de savourer la beauté. Mars en [Signe/Maison] montre comment ton feu intérieur se met en mouvement, là où tu poses tes actes et affirmes ta volonté."
    },
    {
      'id': '5',
      'name': "Les Planètes Sociales — Ton chemin de croissance",
      'description': "Jupiter : expansion, confiance, abondance. Saturne : structure, responsabilité, maturité.",
      'narration': "Jupiter t’ouvre les horizons de [Maison/Signe] : c’est là que tu apprends à grandir avec confiance. Saturne, lui, t’enseigne la patience et la solidité dans [Maison/Signe]. Ensemble, ils sculptent l’équilibre entre ton désir d’expansion et ta capacité à bâtir sur du solide."
    },
    {
      'id': '6',
      'name': "Les Transpersonnelles — Les vents de l’époque",
      'description': "Uranus : liberté, innovation, rébellion. Neptune : intuition, rêve, compassion. Pluton : transformation, régénération, renaissance.",
      'narration': "Uranus éveille en toi la nécessité de briser les chaînes dans [Maison/Signe]. Neptune t’invite à écouter le mystère et à t’abandonner à ton intuition en [Maison/Signe]. Pluton, lui, te conduit aux profondeurs pour renaître transformé·e à travers [Maison/Signe]."
    },
    {
      'id': '7',
      'name': "Les Messagers Karmiques",
      'description': "Nœud Nord : direction évolutive. Nœud Sud : mémoire, acquis. Chiron : blessure sacrée → guérison. Lilith : vérité sauvage, part indomptée.",
      'narration': "Ton Nœud Nord en [Signe/Maison] est l’appel de ton âme vers ton futur. Ton Nœud Sud en [Signe/Maison] porte les mémoires et les dons hérités, mais qu’il te faut dépasser. Chiron révèle ta blessure initiatique qui devient sagesse. Lilith dévoile ta vérité nue, la part sauvage de ton être qui refuse le compromis."
    },
    {
      'id': '8',
      'name': "Les Dialogues du Ciel — Aspects",
      'description': "Chaque aspect est un chant vibratoire : Conjonction → fusion. Opposition → miroir. Carré → défi initiatique. Trigone → grâce. Sextile → opportunité subtile.",
      'narration': "Entre [Planète] et [Planète], il existe une [conjonction/carré/opposition...]. C’est un dialogue qui t’invite à [intégration] : parfois tension, parfois harmonie, mais toujours porteur de croissance."
    },
    {
      'id': '9',
      'name': "Les Cycles — Lune & Éclipses",
      'description': "Phase lunaire natale : ton rythme émotionnel profond. Éclipses proches de ta naissance : portails karmiques, points de bascule.",
      'narration': "Tu es né·e sous une [phase lunaire] : ton énergie émotionnelle se vit comme [explication]. Si une éclipse a marqué ta naissance, elle t’invite à vivre des transformations intenses dans [Maison/Signe], comme une porte cosmique inscrite en toi."
    }
  ];

  Future<void> _askOpenAIInterpretationCategory(int idx) async {

      

    if (_chartData == null) return;
    setState(() {
      _isLoadingInterpretation = true;
      _chartInterpretation = null;
      // Optionally clear previous result for this button
      _ragResults[idx] = {'query': null, 'answer': null};
    });

    try {

      print("======================");
      print("_askOpenAIInterpretationCategory $idx");

      final cat = _astrologyToneCategories[idx];
      final narration = (cat['narration'] ?? '');
      // Fallback: just stringify chart data for prompt
      // final chartString = _chartData!.toString();

      print(narration);

      final placements = ChartAnalysis.getPlacements(_chartData!);
  String placementsString = '';
  String retrieverQuery = '';

      // final planet = 

      // '${planet['sign'] ?? ''} - ${planet['longitude'] != null ? AstrologyUtils.formatDegreeMinute(planet['longitude']) : (planet['formatted'] ?? '')}'

      print(placements);
      print("======================");


      if(idx == 1) {
        final sun = placements.firstWhere((p) => p.startsWith("Sun"));
        final moon = placements.firstWhere((p) => p.startsWith("Moon"));
        final asc = placements.firstWhere((p) => p.startsWith("Ascendant"), orElse: () => '');

        placementsString = '$sun\n$moon\n$asc ?';

      } else if (idx == 2) {

        final asc = placements.firstWhere((p) => p.startsWith("Ascendant"), orElse: () => '');
        final desc = placements.firstWhere((p) => p.startsWith("Descendant"), orElse: () => '');
        final mc = placements.firstWhere((p) => p.startsWith("Midheaven"), orElse: () => '');
        final ic = placements.firstWhere((p) => p.startsWith("Imum Coeli"), orElse: () => '');

        placementsString = '$asc\n$desc\n$mc\n$ic ?';

      } else if (idx == 3) {
        // Elements & Modes
        final elementCounts = <String, int>{'Fire': 0, 'Earth': 0, 'Air': 0, 'Water': 0};
        final modeCounts = <String, int>{'Cardinal': 0, 'Fixed': 0, 'Mutable': 0};

        for (final placement in placements) {
          final parts = placement.split(':');
          if (parts.length < 2) continue;
          final details = parts[1].trim().split(' ');
          if (details.isEmpty) continue;
          final sign = details[0];
          final element = AstrologyUtils.getElement(sign);
          final mode = AstrologyUtils.getMode(sign);
          if (element != 'Unknown') {
            elementCounts[element] = (elementCounts[element] ?? 0) + 1;
          }
          if (mode != 'Unknown') {
            modeCounts[mode] = (modeCounts[mode] ?? 0) + 1;
          }
        }

        final dominantElement = elementCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        final dominantMode = modeCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

        placementsString = 'Dominant Element: $dominantElement\nDominant Mode: $dominantMode';
      } else if (idx == 4) {
        // Personal planets
        final personalPlanets = ['Mercury', 'Venus', 'Mars'];
        final personalPlacements = placements.where((p) {
          for (final planet in personalPlanets) {
            if (p.startsWith(planet)) return true;
          }
          return false;
        }).toList();
        placementsString = personalPlacements.join('\n');
      } else if (idx == 5) {
        // Social planets
        final socialPlanets = ['Jupiter', 'Saturn'];
        final socialPlacements = placements.where((p) {
          for (final planet in socialPlanets) {
            if (p.startsWith(planet)) return true;
          }
          return false;
        }).toList();
        placementsString = socialPlacements.join('\n');
      } else if (idx == 6) {
        // Transpersonal planets
        final transpersonalPlanets = ['Uranus', 'Neptune', 'Pluto'];
        final transpersonalPlacements = placements.where((p) {
          for (final planet in transpersonalPlanets) {
            if (p.startsWith(planet)) return true;
          }
          return false;
        }).toList();
        placementsString = transpersonalPlacements.join('\n');
      } else if (idx == 7) {
        // Karmic messengers
        final karmicBodies = ['North Node', 'South Node', 'Chiron', 'Lilith'];
        final karmicPlacements = placements.where((p) {
          for (final body in karmicBodies) {
            if (p.startsWith(body)) return true;
          }
          return false;
        }).toList();
        placementsString = karmicPlacements.join('\n');
      } else if (idx == 8) {
        // Aspects
        final aspects = ChartAnalysis.calculateAspects(_chartData!);
        placementsString = aspects.join('\n');

      } else if (idx == 9) {
        // Phase lunaire
        final phase = ChartAnalysis.getMoonPhase(_chartData!);
        placements.add('Phase lunaire: $phase');

        // Eclipse proche
        final isEclipse = ChartAnalysis.isNearEclipse(_chartData!);
        placements.add('Éclipse proche: ${isEclipse ? 'Oui' : 'Non'}');
      } else {
        placementsString = placements.join('\n');
      }

        retrieverQuery = 'Que signifie ${ChartAnalysis.translatePlacementFR(placementsString)} en astrologie ?';


    // final prompt =
    //   'You are an astrologer who always answers in a poetic and symbolic tone. \nUse the retrieved texts if available. If nothing is retrieved, use your own astrological knowledge.\n Follow this structure: :\n Narration: ${narration}\n Thème : ${cat['name'] ?? ''} and ${cat['description'] ?? ''}\nPlacement :\n$placementsString\n Retrieved texts:';

    final prompt = """You are an astrologer who always answers in a symbolic tone. 
    Use the retrieved texts if available. If nothing is retrieved, use your own astrological knowledge.
    Do not output structured headers like Narration, Thème, Placement.
    Keep the answer concise, evocative, and readable.
    Do not include sources, citations, or any retrieved text markers in your answer.
    Tone guidance:
    - Narration: ${narration}
    - Thème : ${cat['name'] ?? ''} and ${cat['description'] ?? ''}
    """;

    // Placement: $placementsString

      setState(() {
        _chartPrompt = prompt;
        _promptController.text = prompt;
        // Show the query immediately (answer will be set after await)
        _ragResults[idx]['query'] = retrieverQuery;
      });
      final answer = await ragService.askQuestion(retrieverQuery, systemPrompt: prompt);
      final responseText = answer['answer'] ?? '';

      if (mounted) {
        setState(() {
          _chartInterpretation = responseText;
          _ragResults[idx]['answer'] = responseText;
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
  void initState() {
    super.initState();
    // Initialize OpenAI client and interpretation service with RAG
    final openAIClient = OpenAIClient(dotenv.env['OPENAI_API_KEY'] ?? '');
    final ragService = RagService(); // Initialize RAG service
    _chartInterpretationService = ChartInterpretationService(openAIClient, ragService);
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
      await Sweph.init();
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
      // final chartData = await AstrologyCalculationService.calculateChart(
      final chartData = await UnifiedAstrologyService.calculateChartFromUserInput(
        
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


  Future<void> _sendCustomPrompt() async {
    if (_promptController.text.isEmpty) return;
    
    setState(() {
      _isLoadingInterpretation = true;
      _chartInterpretation = null;
      _chartPrompt = _promptController.text;
    });

    try {
      final answer = await _chartInterpretationService.sendCustomPrompt(_promptController.text);
      
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
                // Show each button with its query/answer below
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_astrologyToneCategories.length, (idx) {
                    final cat = _astrologyToneCategories[idx];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoadingInterpretation ? null : () => _askOpenAIInterpretationCategory(idx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          child: Text(cat['name']!.isNotEmpty ? cat['name']! : 'Synthèse', textAlign: TextAlign.center),
                        ),
                        if (_ragResults[idx]['query'] != null || _ragResults[idx]['answer'] != null)
                          Container(
                            margin: const EdgeInsets.only(top: 6, bottom: 16),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_ragResults[idx]['query'] != null) ...[
                                  const Text('RAG Query:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  SelectableText(_ragResults[idx]['query'] ?? '', style: TextStyle(fontSize: 12, fontFamily: 'monospace')),
                                  const SizedBox(height: 6),
                                ],
                                if (_ragResults[idx]['answer'] != null) ...[
                                  const Text('Réponse IA:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  SelectableText(_ragResults[idx]['answer'] ?? '', style: TextStyle(fontSize: 13)),
                                ],
                              ],
                            ),
                          ),
                      ],
                    );
                  })
                ),
                const SizedBox(height: 12),
                /*
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
                */
                /*
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
                */

                /*
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
                */

                /*
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
                ], */
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
