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
    
    // Use the actual Ascendant degree from natal chart data for proper orientation
    final ascDegree = natalChartData['ascendant'] as double? ?? 0.0;
    
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
        
        // Skip North and South Node for transit display
        if (planetName != null && (
            planetName.toLowerCase().contains('node') ||
            planetName.toLowerCase().contains('noeud') ||
            planetName == 'North Node' ||
            planetName == 'South Node'
        )) {
          continue;
        }
        
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
          
          // Draw retrograde indicator "R" if planet is retrograde
          final isRetrograde = planet['is_retrograde'] == true || 
                              planet['retrograde'] == true ||
                              (planet['speed'] != null && (planet['speed'] as num) < 0);
          if (isRetrograde) {
            final retroPainter = TextPainter(
              text: const TextSpan(
                text: 'R',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            retroPainter.paint(
              canvas,
              Offset(
                planetX - textPainter.width / 2 + 15,
                planetY + textPainter.height / 2 - 15,
              ),
            );
          }

          // Calculate zodiac degrees and minutes
          final rawDegrees = planetDegree;
          final zodiacSign = (rawDegrees / 30).floor().clamp(0, 11);
          const zodiacNamesFull = [
            'Bélier', 'Taureau', 'Gémeaux', 'Cancer', 'Lion', 'Vierge',
            'Balance', 'Scorpion', 'Sagittaire', 'Capricorne', 'Verseau', 'Poissons'
          ];
          final degreesInSign = rawDegrees % 30;
          final degrees = degreesInSign.floor();
          final minutes = ((degreesInSign - degrees) * 60).round();
          final signName = zodiacNamesFull[zodiacSign];
          final degreeText = '$degrees°${minutes.toString().padLeft(2, '0')}\'\n$signName';
          
          final degreePainter = TextPainter(
            text: TextSpan(
              text: degreeText,
              style: const TextStyle(
                fontSize: 10, 
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          
          // Determine position for degree text (left or right side of planet)
          final normalizedAngle = (angle + 2 * pi) % (2 * pi);
          final isOnLeftSide = normalizedAngle > pi / 2 && normalizedAngle < 3 * pi / 2;
          final textOffsetX = isOnLeftSide 
              ? planetX - textPainter.width / 2 - degreePainter.width - 4
              : planetX + textPainter.width / 2 + 4;
          final textOffsetY = planetY - degreePainter.height / 2;
          degreePainter.paint(
            canvas,
            Offset(textOffsetX, textOffsetY),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
