import 'package:flutter/material.dart';

class ChartDisplayWidget extends StatelessWidget {
  final Map<String, dynamic> chartData;

  const ChartDisplayWidget({
    super.key,
    required this.chartData,
  });

  String formatDegreeMinute(double decimalDegree) {
    decimalDegree = decimalDegree % 360.0;
    final degInSign = decimalDegree % 30;
    final deg = degInSign.floor();
    final min = ((degInSign - deg) * 60).floor();
    final sec = ((((degInSign - deg) * 60) - min) * 60).round();
    return "$deg°${min.toString().padLeft(2, '0')}'${sec.toString().padLeft(2, '0')}\"";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          chartData['name'] ?? 'Natal Chart',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SelectableText('Date: ${chartData['date']}'),
        SelectableText('Time: ${chartData['time']}'),
        SelectableText('Location: ${chartData['location']}'),
        const SizedBox(height: 20),

        // Planets section
        const SelectableText(
          'Planetary Positions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (chartData['planets'] != null)
          ...(chartData['planets'] as List).map(
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
        if (chartData['houses'] != null)
          ...(chartData['houses'] as List).asMap().entries.map(
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
}