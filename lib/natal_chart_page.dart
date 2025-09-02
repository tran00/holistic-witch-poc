import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/app_drawer.dart';
// import 'package:flutter_typeahead/flutter_typeahead.dart';

class NatalChartPage extends StatefulWidget {
  const NatalChartPage({super.key});

  @override
  State<NatalChartPage> createState() => _NatalChartPageState();
}

class _NatalChartPageState extends State<NatalChartPage> {
  final _formKey = GlobalKey<FormState>();
  final _birthDateController = TextEditingController();
  final _birthTimeController = TextEditingController();
  final _birthPlaceController = TextEditingController();

  String? result;

  double? _selectedLat;
  double? _selectedLon;

  Map<String, dynamic>? _lastSentParams;

  @override
  void dispose() {
    _birthDateController.dispose();
    _birthTimeController.dispose();
    _birthPlaceController.dispose();
    super.dispose();
  }

  Future<void> _fetchNatalChart() async {
    final userId = dotenv.env['ASTROLOGY_API_USER_ID'];
    final apiKey = dotenv.env['ASTROLOGY_API_KEY'];
    final date = _birthDateController.text; // format: JJMMAAAA
    final time = _birthTimeController.text; // format: HH:MM
    final place = _birthPlaceController.text;

    if (userId == null || apiKey == null) {
      setState(() {
        result = "Clés API manquantes.";
      });
      return;
    }

    // Convert JJMMAAAA to DD-MM-YYYY for the API
    if (date.length != 8) {
      setState(() {
        result = "Format de date invalide.";
      });
      return;
    }
    final day = date.substring(0, 2);
    final month = date.substring(2, 4);
    final year = date.substring(4, 8);

    // Split time
    final timeParts = time.split(':');
    if (timeParts.length != 2) {
      setState(() {
        result = "Format d'heure invalide.";
      });
      return;
    }
    final hour = timeParts[0];
    final min = timeParts[1];

    // For demo: use Paris coordinates if you don't have geocoding
    double lat = _selectedLat ?? 48.8566;
    double lon = _selectedLon ?? 2.3522;

    // Optionally, you can use a geocoding API to get lat/lon from place

    final url = Uri.parse('https://json.astrologyapi.com/v1/natal_wheel_chart');
    // final url = Uri.parse('https://json.astrologyapi.com/v1/western_horoscope');
    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode('$userId:$apiKey'))}',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      "day": int.parse(day),
      "month": int.parse(month),
      "year": int.parse(year),
      "hour": int.parse(hour),
      "min": int.parse(min),
      "lat": lat,
      "lon": lon,
      "tzone": 1.0, // Paris timezone
    });

    print('URL: $url');
    print('Headers: $headers');
    print('Body: $body');

    setState(() {
      _lastSentParams = {
        "day": int.parse(day),
        "month": int.parse(month),
        "year": int.parse(year),
        "hour": int.parse(hour),
        "min": int.parse(min),
        "lat": lat,
        "lon": lon,
        "tzone": 1.0,
      };
      result = "Calcul en cours...";
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // You can display the whole response or just a part, e.g. sun sign
          result = response.body;
          // Or for a cleaner display, for example:
          // result = "Signe solaire : ${data['sun']['sign']}\nAscendant : ${data['ascendant']['sign']}\n...";
        });
      } else {
        setState(() {
          result = "Erreur API : ${response.statusCode}\n${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        result = "Erreur de connexion : $e";
      });
    }
  }

  void _calculateChart() {
    // For now, just display the input. Replace with API call later.
    setState(() {
      result =
          "Date de naissance : ${_birthDateController.text}\n"
          "Heure de naissance : ${_birthTimeController.text}\n"
          "Lieu de naissance : ${_birthPlaceController.text}\n"
          "\n(Votre thème astral sera affiché ici après connexion à l'API)";
    });
  }

  Future<List<Map<String, dynamic>>> fetchSuggestions(String pattern) async {
    if (pattern.length < 2) return [];
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$pattern&format=json&addressdetails=1&limit=5',
    );
    final response = await http.get(url, headers: {
      'User-Agent': 'FlutterApp',
    });
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calcul du thème astral')),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _birthDateController,
                decoration: const InputDecoration(
                  labelText: 'Date de naissance (JJMMAAAA)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 8,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthTimeController,
                decoration: const InputDecoration(
                  labelText: 'Heure de naissance (HH:MM)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 12),
              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.length < 2) return const [];
                  return await fetchSuggestions(textEditingValue.text);
                },
                displayStringForOption: (option) => option['display_name'] ?? '',
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _birthPlaceController.text = controller.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Lieu de naissance',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
                onSelected: (option) {
                  _birthPlaceController.text = option['display_name'] ?? '';
                  _selectedLat = double.tryParse(option['lat'] ?? '');
                  _selectedLon = double.tryParse(option['lon'] ?? '');
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      child: SizedBox(
                        width: 300,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              title: Text(option['display_name'] ?? ''),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchNatalChart,
                child: const Text('Calculer le thème astral'),
              ),
              const SizedBox(height: 16),

              // Display the JSON parameters just after the button
              if (_lastSentParams != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(_lastSentParams),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),

              const SizedBox(height: 32),

              // Then display the result (SVG link, etc.)
              if (result != null)
                Builder(
                  builder: (context) {
                    try {
                      final data = jsonDecode(result!);
                      if (data is Map && data['chart_url'] != null) {
                        final chartUrl = data['chart_url'];
                        return Column(
                          children: [
                            const Text('Votre carte du ciel :', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            InkWell(
                              child: Text(
                                chartUrl,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              onTap: () async {
                                final uri = Uri.parse(chartUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            if (data['msg'] != null)
                              Text(data['msg'], style: const TextStyle(color: Colors.green)),
                          ],
                        );
                      }
                    } catch (e) {
                      print('JSON decode error: $e');
                    }
                    // Fallback: display as text
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(result!),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}