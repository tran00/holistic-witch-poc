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
    return SizedBox(
      width: 450,
      height: 450,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Base natal chart (exactly the same as NatalWheel)
            NatalWheel(chartData: natalChartData),
            // Overlay transit planets
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
    final radius = min(size.width, size.height) / 2 - 20;

    // Get ascendant from natal chart for orientation
    final ascDegree = (natalChartData['ascendant'] as num?)?.toDouble() ?? 0.0;

    // Draw outer circle for transits
    _drawTransitCircle(canvas, center, radius);
    
    // Draw transit planets outside the natal chart's outer circle
    _drawTransitPlanets(canvas, center, radius + 10, ascDegree);
  }

  void _drawTransitCircle(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Outer circle for transits (beyond the natal chart)
    canvas.drawCircle(center, radius + 10, paint);
  }

  void _drawTransitPlanets(Canvas canvas, Offset center, double radius, double ascDegree) {
    if (transitChartData['planets'] is List) {
      final planets = transitChartData['planets'] as List;
      final transitRadius = radius + 25; // Position outside the natal chart's outer circle
      final outerCircleRadius = radius; // The outer circle radius
      
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      for (final planet in planets) {
        final planetName = planet['name'] as String?;
        final longitude = (planet['longitude'] ?? planet['full_degree']) as num?;
        
        if (planetName != null && longitude != null) {
          final planetDegree = longitude.toDouble();
          final angle = (-pi/2) - ((planetDegree - ascDegree) * pi / 180);
          
          // Planet position
          final planetX = center.dx + transitRadius * cos(angle);
          final planetY = center.dy + transitRadius * sin(angle);
          
          // Outer circle intersection point
          final outerX = center.dx + outerCircleRadius * cos(angle);
          final outerY = center.dy + outerCircleRadius * sin(angle);

          // Draw line from planet to outer circle
          final linePaint = Paint()
            ..color = Colors.blue.withOpacity(0.6)
            ..strokeWidth = 1.5;
          
          canvas.drawLine(
            Offset(planetX, planetY),
            Offset(outerX, outerY),
            linePaint,
          );

          // Get planet glyph
          final glyph = planetGlyphs[planetName] ?? planetName.substring(0, 2);
          
          // Draw background circle for better visibility
          canvas.drawCircle(
            Offset(planetX, planetY), 
            14, 
            Paint()..color = Colors.white.withOpacity(0.9)
          );
          
          // Draw border around background
          canvas.drawCircle(
            Offset(planetX, planetY), 
            14, 
            Paint()
              ..color = Colors.blue
              ..strokeWidth = 1.5
              ..style = PaintingStyle.stroke
          );
          
          textPainter.text = TextSpan(
            text: glyph,
            style: const TextStyle(
              fontSize: 18, 
              color: Colors.blue,
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