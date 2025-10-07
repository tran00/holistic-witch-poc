import 'dart:math';
import 'package:flutter/material.dart';
import 'natal_wheel_widget.dart';

const planetGlyphs = {
  'Sun': '☉',
  'Moon': '☽', 
  'Mercury': '☿',
  'Venus': '♀',
  'Mars': '♂',
  'Jupiter': '♃',
  'Saturn': '♄',
  'Uranus': '♅',
  'Neptune': '♆',
  'Pluto': '♇',
  'Chiron': '⚷',
  'North Node': '☊',
  'South Node': '☋',
};

class CompositeNatalWheel extends StatelessWidget {
  final Map<String, dynamic> natalChartData;
  final Map<String, dynamic> transitChartData;

  const CompositeNatalWheel({
    super.key, 
    required this.natalChartData, 
    required this.transitChartData
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 450,
        height: 450,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 450,
              height: 450,
              child: NatalWheel(chartData: natalChartData),
            ),
            CustomPaint(
              painter: TransitOverlayPainter(natalChartData, transitChartData),
              size: const Size(450, 450),
            ),
          ],
        ),
      ),
    );
  }
}

class TransitOverlayPainter extends CustomPainter {
  final Map<String, dynamic> natalChartData;
  final Map<String, dynamic> transitChartData;

  TransitOverlayPainter(this.natalChartData, this.transitChartData);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 0;
    final ascDegree = (natalChartData['ascendant'] as num?)?.toDouble() ?? 0.0;
    _drawTransitCircle(canvas, center, radius);
    _drawTransitPlanets(canvas, center, radius + 20, ascDegree);
  }

  void _drawTransitCircle(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paint);
  }

  void _drawTransitPlanets(Canvas canvas, Offset center, double radius, double ascDegree) {
    if (transitChartData['planets'] is List) {
      final planets = transitChartData['planets'] as List;
      final transitRadius = radius + 25;
      final outerCircleRadius = radius - 20;
      
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      for (final planet in planets) {
        final planetName = planet['name'] as String?;
        final longitude = (planet['longitude'] ?? planet['full_degree']) as num?;
        
        if (planetName != null && longitude != null) {
          final planetDegree = longitude.toDouble();
          final angle = (-pi) - (planetDegree - ascDegree) * pi / 180;
          
          final planetX = center.dx + transitRadius * cos(angle);
          final planetY = center.dy + transitRadius * sin(angle);
          final outerX = center.dx + outerCircleRadius * cos(angle);
          final outerY = center.dy + outerCircleRadius * sin(angle);

          // Calculate line start point at a distance from the planet glyph
          final glyphRadius = -18; // Distance from planet center to start the line
          final lineStartX = center.dx + (transitRadius + glyphRadius) * cos(angle);
          final lineStartY = center.dy + (transitRadius + glyphRadius) * sin(angle);

          final linePaint = Paint()
            ..color = Colors.blue.withOpacity(0.6)
            ..strokeWidth = 1.5;
          
          canvas.drawLine(Offset(lineStartX, lineStartY), Offset(outerX, outerY), linePaint);

          final glyph = planetGlyphs[planetName] ?? planetName.substring(0, 2);
          
          // canvas.drawCircle(
          //   Offset(planetX, planetY), 
          //   14, 
          //   Paint()..color = Colors.white.withOpacity(0.9)
          // );
          
          // canvas.drawCircle(
          //   Offset(planetX, planetY), 
          //   14, 
          //   Paint()
          //     ..color = Colors.blue
          //     ..strokeWidth = 1.5
          //     ..style = PaintingStyle.stroke
          // );
          
          textPainter.text = TextSpan(
            text: glyph,
            style: const TextStyle(
              fontSize: 20, 
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(planetX - textPainter.width / 2, planetY - textPainter.height / 2));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
