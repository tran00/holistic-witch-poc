// lib/daily_chart_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets/app_drawer.dart';
import 'widgets/natal_wheel_widget.dart';
import 'widgets/composite_natal_wheel_widget.dart';
import 'services/sweph_service.dart';
import 'services/astrology_calculation_service.dart';

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
    });
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
                      const SizedBox(height: 60),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}