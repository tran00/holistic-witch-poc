import 'dart:math';
import 'package:flutter/material.dart';

const zodiacGlyphs = [
  '♈', // Aries
  '♉', // Taurus
  '♊', // Gemini
  '♋', // Cancer
  '♌', // Leo
  '♍', // Virgo
  '♎', // Libra
  '♏', // Scorpio
  '♐', // Sagittarius
  '♑', // Capricorn
  '♒', // Aquarius
  '♓', // Pisces
];

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
};

class NatalWheel extends StatelessWidget {
  final Map<String, dynamic> chartData;
  const NatalWheel({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        // You can add interactivity here (e.g., show a dialog with planet info)
      },
      child: CustomPaint(
        size: const Size(680, 680),
        painter: NatalWheelPainter(chartData),
      ),
    );
  }
}

class NatalWheelPainter extends CustomPainter {
  final Map<String, dynamic> chartData;
  NatalWheelPainter(this.chartData);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 16;

    // Draw zodiac circle
    final circlePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, circlePaint);

    final houses = chartData['houses'] as List;
    final ascDegree = (houses.first['start_degree'] as num).toDouble();
    final zodiacRadiusOuter = radius + 24;
    final zodiacRadiusInner = radius + 4;

    // Draw zodiac segments (arcs)
    for (int i = 0; i < 12; i++) {
      // Fixed zodiac: Aries at 9 o'clock, Taurus at 8 o'clock, etc.
      final startAngle = (-pi / 2) + ((i * 30 - ascDegree) * pi / 180);
      final sweepAngle = 30 * pi / 180;
      final arcPaint = Paint()
        ..color = Colors.primaries[i % Colors.primaries.length].withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = zodiacRadiusOuter - zodiacRadiusInner;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (zodiacRadiusOuter + zodiacRadiusInner) / 2),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );

      // Draw glyph at the center of the arc
      final midAngle = startAngle + sweepAngle / 2;
      final zx = center.dx + (zodiacRadiusOuter + zodiacRadiusInner) / 2 * cos(midAngle);
      final zy = center.dy + (zodiacRadiusOuter + zodiacRadiusInner) / 2 * sin(midAngle);
      final textPainter = TextPainter(
        text: TextSpan(
          text: zodiacGlyphs[i],
          style: const TextStyle(fontSize: 22, color: Colors.deepPurple),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(zx - 12, zy - 12));
    }

    // Draw 12 houses (thicker lines)
    // for (int i = 0; i < 12; i++) {
    //   final angle = -pi / 2 + i * 2 * pi / 12;
    //   final x = center.dx + radius * cos(angle);
    //   final y = center.dy + radius * sin(angle);
    //   canvas.drawLine(center, Offset(x, y), circlePaint..strokeWidth = 2.5);
    // }

    // Draw house numbers
    if (chartData['houses'] is List) {
      final houses = chartData['houses'] as List;
      for (int i = 0; i < houses.length; i++) {
        final deg = (houses[i]['degree'] ?? 0).toDouble();
        final angle = (-pi / 2) + deg * pi / 180;
        final hx = center.dx + (radius + 10) * cos(angle);
        final hy = center.dy + (radius + 10) * sin(angle);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: const TextStyle(fontSize: 12, color: Colors.blue),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(hx - 8, hy - 8));
      }
    }

    // Draw aspects (lines between planets) with more precise orbs/colors
    if (chartData['planets'] is List) {
      final planets = chartData['planets'] as List;
      for (int i = 0; i < planets.length; i++) {
        final p1 = planets[i];
        final deg1 = (p1['norm_degree'] ?? p1['degree'])?.toDouble() ?? 0.0;
        final angle1 = (-pi / 2) + deg1 * pi / 180;
        final aspectRadius = radius - 60; // or adjust as needed
        final p1x = center.dx + aspectRadius * cos(angle1);
        final p1y = center.dy + aspectRadius * sin(angle1);

        for (int j = i + 1; j < planets.length; j++) {
          final p2 = planets[j];
          final deg2 = (p2['norm_degree'] ?? p2['degree'])?.toDouble() ?? 0.0;
          final angle2 = (-pi / 2) + deg2 * pi / 180;
          final p2x = center.dx + aspectRadius * cos(angle2);
          final p2y = center.dy + aspectRadius * sin(angle2);

          double diff = (deg1 - deg2).abs();
          if (diff > 180) diff = 360 - diff;

          Color? aspectColor;
          double orb = 0;
          if ((diff - 0).abs() < 8) { aspectColor = Colors.red; orb = (diff - 0).abs(); } // Conjunction
          else if ((diff - 180).abs() < 6) { aspectColor = Colors.blue; orb = (diff - 180).abs(); } // Opposition
          else if ((diff - 120).abs() < 5) { aspectColor = Colors.green; orb = (diff - 120).abs(); } // Trine
          else if ((diff - 90).abs() < 4) { aspectColor = Colors.orange; orb = (diff - 90).abs(); } // Square
          else if ((diff - 60).abs() < 3) { aspectColor = Colors.purple; orb = (diff - 60).abs(); } // Sextile

          if (aspectColor != null) {
            canvas.drawLine(
              Offset(p1x, p1y),
              Offset(p2x, p2y),
              Paint()
                ..color = aspectColor
                ..strokeWidth = 3,
            );
          }
        }
      }
    }

    // Draw planets with glyphs and colored dots
    if (chartData['planets'] is List) {
      final planets = chartData['planets'] as List;
      for (final planet in planets) {
        final deg = (planet['norm_degree'] ?? planet['degree'])?.toDouble() ?? 0.0;
        final angle = (-pi / 2) + (deg - ascDegree) * pi / 180;
        final innerRadius = radius - 120;
        final px = center.dx + innerRadius * cos(angle);
        final py = center.dy + innerRadius * sin(angle);

        final planetName = planet['name'] ?? '';
        final glyph = planetGlyphs[planetName] ?? planet['short_name'] ?? '?';

        final textPainter = TextPainter(
          text: TextSpan(
            text: glyph,
            style: const TextStyle(fontSize: 28, color: Colors.black),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(px - 14, py - 14));
      }
    }

    // Draw Ascendant and MC labels if present
    if (chartData['ascendant'] != null) {
      final ascDegree = (chartData['ascendant']?['degree'] ?? 0).toDouble();
      final angle = (-pi / 2) + ascDegree * pi / 180;
      final ax = center.dx + (radius + 30) * cos(angle);
      final ay = center.dy + (radius + 30) * sin(angle);

      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'ASC',
          style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(ax - 12, ay - 12));
    }
    if (chartData['mc'] != null) {
      final deg = (chartData['mc']['degree'] ?? 0).toDouble();
      final angle = (-pi / 2) + deg * pi / 180;
      final mx = center.dx + (radius + 30) * cos(angle);
      final my = center.dy + (radius + 30) * sin(angle);

      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'MC',
          style: TextStyle(fontSize: 14, color: Colors.teal, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(mx - 12, my - 12));
    }

    // Draw degree ruler (every 5° a small tick, every 30° a big tick)
    for (int deg = 0; deg < 360; deg += 5) {
      final angle = (-pi / 2) + ((deg - ascDegree) * pi / 180);
      final isMajor = deg % 30 == 0;
      final tickStart = center + Offset(
        (zodiacRadiusOuter + 2) * cos(angle),
        (zodiacRadiusOuter + 2) * sin(angle),
      );
      final tickEnd = center + Offset(
        (zodiacRadiusOuter + (isMajor ? 16 : 8)) * cos(angle),
        (zodiacRadiusOuter + (isMajor ? 16 : 8)) * sin(angle),
      );
      canvas.drawLine(
        tickStart,
        tickEnd,
        Paint()
          ..color = isMajor ? Colors.deepPurple : Colors.grey
          ..strokeWidth = isMajor ? 2.5 : 1,
      );
    }

    // Draw thick border at each zodiac sign boundary
    for (int i = 0; i < 12; i++) {
      final angle = (-pi / 2) + ((i * 30 - ascDegree) * pi / 180);
      final start = center + Offset(zodiacRadiusInner * cos(angle), zodiacRadiusInner * sin(angle));
      final end = center + Offset(zodiacRadiusOuter * cos(angle), zodiacRadiusOuter * sin(angle));
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = Colors.deepPurple
          ..strokeWidth = 4,
      );
    }

    for (int i = 0; i < 12; i++) {
      final deg = i * 30;
      final angle = (-pi / 2) + ((deg - ascDegree) * pi / 180);
      final tx = center.dx + (zodiacRadiusOuter + 22) * cos(angle);
      final ty = center.dy + (zodiacRadiusOuter + 22) * sin(angle);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$deg°',
          style: const TextStyle(fontSize: 10, color: Colors.deepPurple),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(tx - 10, ty - 8));
    }

    // Draw the inner circle for house numbers
    final innerCircleRadius = radius - 80;
    canvas.drawCircle(
      center,
      innerCircleRadius,
      Paint()
        ..color = Colors.deepPurple.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final numberRadius = innerCircleRadius + 24; // offset outside the circle


    // Draw house cusps (lines) and house numbers
    if (chartData['houses'] is List) {
      final houses = chartData['houses'] as List;
      final ascDegree = (houses.first['start_degree'] as num).toDouble();
      for (int i = 0; i < houses.length; i++) {
        final house = houses[i];
        final startDeg = (house['start_degree'] as num).toDouble();
        // Angle for house cusp line
        final angle = (-pi / 2) + (startDeg - ascDegree) * pi / 180;

        // Draw house cusp line from inner circle to outer zodiac circle
        final cuspStart = center + Offset(innerCircleRadius * cos(angle), innerCircleRadius * sin(angle));
        final cuspEnd = center + Offset(zodiacRadiusInner * cos(angle), zodiacRadiusInner * sin(angle));
        canvas.drawLine(
          cuspStart,
          cuspEnd,
          Paint()
            ..color = Colors.deepPurple
            ..strokeWidth = 3,
        );

        // Draw house number at the middle of the house
        final endDeg = (house['end_degree'] as num).toDouble();
        // Handle wrap-around for houses crossing 360°/0°
        double midDeg = startDeg + (((endDeg - startDeg + 360) % 360) / 2);
        midDeg = midDeg % 360;
        final midAngle = (-pi / 2) + (midDeg - ascDegree) * pi / 180;
        final nx = center.dx + numberRadius * cos(midAngle);
        final ny = center.dy + numberRadius * sin(midAngle);
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${house['house_id']}',
            style: const TextStyle(fontSize: 24, color: Colors.deepPurple, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(nx - textPainter.width / 2, ny - textPainter.height / 2));
      }
    }

    // 1. Build planetDegrees map FIRST
    final planetDegrees = <String, double>{};
    if (chartData['houses'] is List) {
      for (final house in chartData['houses']) {
        if (house['planets'] is List) {
          for (final planet in house['planets']) {
            planetDegrees[planet['name']] = (planet['full_degree'] as num).toDouble();
          }
        }
      }
    }
    if (chartData['ascendant'] != null) {
      planetDegrees['Ascendant'] = (chartData['ascendant']['degree'] as num).toDouble();
    }
    if (chartData['mc'] != null) {
      planetDegrees['MC'] = (chartData['mc']['degree'] as num).toDouble();
    }

    // ...now you can use planetDegrees in your aspect drawing code...
    if (chartData['aspects'] is List) {
      final aspects = chartData['aspects'] as List;
      for (final aspect in aspects) {
        final name1 = aspect['aspecting_planet'];
        final name2 = aspect['aspected_planet'];
        final deg1 = planetDegrees[name1];
        final deg2 = planetDegrees[name2];

        if (deg1 != null && deg2 != null && ascDegree != null) {
          final angle1 = (-pi / 2) + (deg1 - ascDegree) * pi / 180;
          final angle2 = (-pi / 2) + (deg2 - ascDegree) * pi / 180;

          // Place aspect lines at a radius inside the wheel
          final aspectRadius = innerCircleRadius;
          final p1 = Offset(center.dx + aspectRadius * cos(angle1), center.dy - aspectRadius * sin(angle1));
          final p2 = Offset(center.dx + aspectRadius * cos(angle2), center.dy - aspectRadius * sin(angle2));

          // Choose color by aspect type
          Color aspectColor;
          switch ((aspect['type'] as String).toLowerCase()) {
            case 'conjunction': aspectColor = Colors.red; break;
            case 'opposition': aspectColor = Colors.blue; break;
            case 'trine': aspectColor = Colors.green; break;
            case 'square': aspectColor = Colors.orange; break;
            case 'sextile': aspectColor = Colors.purple; break;
            default: aspectColor = Colors.grey;
          }

          // Draw the chord
          canvas.drawLine(
            p1,
            p2,
            Paint()
              ..color = aspectColor.withOpacity(0.7)
              ..strokeWidth = 3,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

double angleForDegree(double deg, double ascDegree) {
  return (-pi / 2) + (deg - ascDegree) * pi / 180;
}