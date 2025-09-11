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
    final planets = (chartData['planets'] as List);
    final houses = (chartData['houses'] as List);

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
    final radius = min(size.width, size.height) / 2 - 66;

    // Draw outer circle for houses
    final outerCirclePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius + 20, outerCirclePaint); // Outer circle for planets

    final houses = (chartData['houses'] is List) ? chartData['houses'] as List : [];
    final ascDegree = (houses.isNotEmpty && houses.first['start_degree'] is num)
        ? (houses.first['start_degree'] as num).toDouble()
        : 0.0;

    // Zodiac radii (inner)
    final zodiacRadiusOuter = radius - 5;
    final zodiacRadiusInner = radius - 20;

    // Draw zodiac segments (arcs) - inner
    for (int i = 0; i < 12; i++) {
      final startAngle = (-pi / 2) - ((i * 30 - ascDegree) * pi / 180);
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
    }


    // Draw degree ruler (every 5° a small tick, every 30° a big tick) - inner
    for (int deg = 0; deg < 360; deg += 5) {
      final angle = (-pi / 2) - ((deg - ascDegree) * pi / 180);
      final isMajor = deg % 30 == 0;
      final tickStart = center + Offset(
        (zodiacRadiusInner - 2) * cos(angle),
        (zodiacRadiusInner - 2) * sin(angle),
      );
      final tickEnd = center + Offset(
        (zodiacRadiusInner - (isMajor ? 16 : 8)) * cos(angle),
        (zodiacRadiusInner - (isMajor ? 16 : 8)) * sin(angle),
      );
      canvas.drawLine(
        tickStart,
        tickEnd,
        Paint()
          ..color = isMajor ? Colors.deepPurple : Colors.grey
          // ..strokeWidth = isMajor ? 2.5 : 1,
          ..strokeWidth = isMajor ? 1 : 1,
      );
    }

    // Draw degree labels (inner)
    for (int i = 0; i < 12; i++) {
      final deg = i * 30;
      final angle = (-pi / 2) - ((deg - ascDegree) * pi / 180);
      final tx = center.dx + (zodiacRadiusInner - 22) * cos(angle);
      final ty = center.dy + (zodiacRadiusInner - 22) * sin(angle);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$deg°',
          style: const TextStyle(fontSize: 10, color: Colors.deepPurple),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(tx - 10, ty - 8));
    }

    // Draw house cusps (lines) - constrained to smaller inner circle
    if (chartData['houses'] is List) {
      final houses = chartData['houses'] as List;
      final houseLineInner = zodiacRadiusOuter; // Start at zodiac outer
      final houseLineOuter = zodiacRadiusOuter + 25; // Shortened to +10
      final numberRadius = radius + 10; // House numbers at outer

      for (int i = 0; i < houses.length; i++) {
        final house = houses[i];
        final startDeg = (houses[i]['start_degree'] as num).toDouble();

        // Angle for house cusp line
        final angle = (-pi / 2) - (startDeg - ascDegree) * pi / 180;

        // Draw house cusp line (shortened)
        final cuspStart = center + Offset(houseLineInner * cos(angle), houseLineInner * sin(angle));
        final cuspEnd = center + Offset(houseLineOuter * cos(angle), houseLineOuter * sin(angle));
        canvas.drawLine(
          cuspStart,
          cuspEnd,
          Paint()
            ..color = Colors.deepPurple
            ..strokeWidth = 1,
        );

        // Draw house number at the middle of the house
        final endDeg = (houses[i]['end_degree'] as num).toDouble();
        double midDeg;
        if (endDeg > startDeg) {
          midDeg = startDeg + (endDeg - startDeg) / 2;
        } else {
          midDeg = startDeg + ((endDeg + 360 - startDeg) / 2);
          if (midDeg > 360) midDeg -= 360;
        }

        final midAngle = (-pi / 2) - (midDeg - ascDegree) * pi / 180;
        final nx = center.dx + numberRadius * cos(midAngle);
        final ny = center.dy + numberRadius * sin(midAngle);
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${house['house_id']}',
            style: const TextStyle(fontSize: 18, color: Colors.deepPurple, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(nx - textPainter.width / 2, ny - textPainter.height / 2));
      }
    }

    // Draw borders to separate houses (thick lines at each house boundary)
    // for (int i = 0; i < 12; i++) {
    //   final angle = (-pi / 2) - ((i * 30 - ascDegree) * pi / 180);
    //   final start = center + Offset((zodiacRadiusOuter + 10) * cos(angle), (zodiacRadiusOuter + 10) * sin(angle));
    //   final end = center + Offset((radius + 20) * cos(angle), (radius + 20) * sin(angle));
    //   canvas.drawLine(
    //     start,
    //     end,
    //     Paint()
    //       ..color = Colors.black
    //       ..strokeWidth = 5, // Thick border
    //   );
    // }

    // Draw zodiac glyphs between their circle and the inner circle containing the lines
    // for (int i = 0; i < 12; i++) {
    //   final startAngle = (-pi / 2) - ((i * 30 - ascDegree) * pi / 180);
    //   final sweepAngle = 30 * pi / 180;
    //   final midAngle = startAngle + sweepAngle / 2;
    //   // Position between zodiac circle and house lines (e.g., at zodiacRadiusInner + 5)
    //   final glyphRadius = zodiacRadiusInner + 5;
    //   final zx = center.dx + glyphRadius * cos(midAngle);
    //   final zy = center.dy + glyphRadius * sin(midAngle);
    //   final textPainter = TextPainter(
    //     text: TextSpan(
    //       text: zodiacGlyphs[i],
    //       style: const TextStyle(fontSize: 22, color: Colors.deepPurple),
    //     ),
    //     textDirection: TextDirection.ltr,
    //   )..layout();
    //   textPainter.paint(canvas, Offset(zx - 12, zy - 12));
    // }

    // Draw planets with glyphs - outermost
    if (chartData['planets'] is List) {
      final planets = chartData['planets'] as List;
      final planetRadius = radius + 40;

      for (final planet in planets) {
        final deg = (planet['longitude'] ?? planet['full_degree'] ?? 0).toDouble();
        final angle = (-pi / 2) - (deg - ascDegree) * pi / 180;
        final px = center.dx + planetRadius * cos(angle);
        final py = center.dy + planetRadius * sin(angle);

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

    // Draw Ascendant and MC labels (outer)
    if (chartData['ascendant'] != null) {
      final ascDegree = (chartData['ascendant'] as num).toDouble();
      final angle = (-pi / 2) - ascDegree * pi / 180;
      final ax = center.dx + (radius + 50) * cos(angle);
      final ay = center.dy + (radius + 50) * sin(angle);

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
      final deg = (chartData['mc'] as num).toDouble();
      final angle = (-pi / 2) - deg * pi / 180;
      final mx = center.dx + (radius + 50) * cos(angle);
      final my = center.dy + (radius + 50) * sin(angle);

      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'MC',
          style: TextStyle(fontSize: 14, color: Colors.teal, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(mx - 12, my - 12));
    }

    // Draw the aspects circle (faint circle at aspect radius)
    final aspectRadius = radius - 60;
    canvas.drawCircle(
      center,
      aspectRadius,
      Paint()
        ..color = Colors.grey.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw aspects (lines between planets) - now in a smaller circle in the middle
    if (chartData['planets'] is List) {
      final planets = chartData['planets'] as List;
      final aspectRadius = radius - 60; // Smaller radius for middle circle

      for (int i = 0; i < planets.length; i++) {
        final p1 = planets[i];
        final deg1 = (p1['longitude'] ?? p1['full_degree'] ?? 0).toDouble();
        final angle1 = (-pi / 2) - (deg1 - ascDegree) * pi / 180;
        final p1x = center.dx + aspectRadius * cos(angle1);
        final p1y = center.dy + aspectRadius * sin(angle1);

        for (int j = i + 1; j < planets.length; j++) {
          final p2 = planets[j];
          final deg2 = (p2['longitude'] ?? p2['full_degree'] ?? 0).toDouble();
          final angle2 = (-pi / 2) - (deg2 - ascDegree) * pi / 180;
          final p2x = center.dx + aspectRadius * cos(angle2);
          final p2y = center.dy + aspectRadius * sin(angle2);

          double diff = (deg1 - deg2).abs();
          if (diff > 180) diff = 360 - diff;

          Color? aspectColor;
          if ((diff - 0).abs() < 8) aspectColor = Colors.red; // Conjunction
          else if ((diff - 180).abs() < 6) aspectColor = Colors.blue; // Opposition
          else if ((diff - 120).abs() < 5) aspectColor = Colors.green; // Trine
          else if ((diff - 90).abs() < 4) aspectColor = Colors.orange; // Square
          else if ((diff - 60).abs() < 3) aspectColor = Colors.purple; // Sextile

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

    // Build planetDegrees map
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
      planetDegrees['Ascendant'] = (chartData['ascendant'] as num).toDouble();
    }

    // Draw aspects from chartData['aspects'] if present - now in the middle
    if (chartData['aspects'] is List) {
      final aspects = chartData['aspects'] as List;
      final aspectRadius = radius - 60; // Smaller radius for middle circle

      for (final aspect in aspects) {
        final name1 = aspect['aspecting_planet'];
        final name2 = aspect['aspected_planet'];
        final deg1 = planetDegrees[name1];
        final deg2 = planetDegrees[name2];

        if (deg1 != null && deg2 != null) {
          final angle1 = (-pi / 2) - (deg1 - ascDegree) * pi / 180;
          final angle2 = (-pi / 2) - (deg2 - ascDegree) * pi / 180;

          final p1 = Offset(center.dx + aspectRadius * cos(angle1), center.dy + aspectRadius * sin(angle1));
          final p2 = Offset(center.dx + aspectRadius * cos(angle2), center.dy + aspectRadius * sin(angle2));

          Color aspectColor;
          switch ((aspect['type'] as String).toLowerCase()) {
            case 'conjunction': aspectColor = Colors.red; break;
            case 'opposition': aspectColor = Colors.blue; break;
            case 'trine': aspectColor = Colors.green; break;
            case 'square': aspectColor = Colors.orange; break;
            case 'sextile': aspectColor = Colors.purple; break;
            default: aspectColor = Colors.grey;
          }

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

    // Draw zodiac glyphs between aspects circle and zodiac outer circle
    for (int i = 0; i < 12; i++) {
      final startAngle = (-pi / 2) - ((i * 30 - ascDegree) * pi / 180);
      final sweepAngle = 30 * pi / 180;
      final midAngle = startAngle + sweepAngle / 2;
      // Position between aspects circle and zodiac outer circle (e.g., at radius - 40)
      final glyphRadius = radius - 40;
      final zx = center.dx + glyphRadius * cos(midAngle);
      final zy = center.dy + glyphRadius * sin(midAngle);
      final textPainter = TextPainter(
        text: TextSpan(
          text: zodiacGlyphs[i],
          style: const TextStyle(fontSize: 22, color: Colors.deepPurple),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(zx - 12, zy - 12));
    }

    // Draw thick border at each zodiac sign boundary (inner)
    for (int i = 0; i < 12; i++) {
      final angle = (-pi / 2) - ((i * 30 - ascDegree) * pi / 180);
      // final start = center + Offset(zodiacRadiusInner * cos(angle), zodiacRadiusInner * sin(angle));
      // final end = center + Offset(zodiacRadiusOuter * cos(angle), zodiacRadiusOuter * sin(angle));
      final glyphRadius = radius - 60;
      final start = center + Offset(zodiacRadiusInner * cos(angle), zodiacRadiusInner * sin(angle));
      final end = center + Offset(glyphRadius * cos(angle), glyphRadius * sin(angle));
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = Colors.deepPurple
          ..strokeWidth = 1,
      );
    }

    // Draw quadrant indicators (lines and labels)
    // for (int i = 0; i < 4; i++) {
    //   final angle = (-pi / 2) - ((i * 90 - ascDegree) * pi / 180);
    //   final start = center;
    //   final end = center + Offset((radius + 20) * cos(angle), (radius + 20) * sin(angle));
    //   canvas.drawLine(
    //     start,
    //     end,
    //     Paint()
    //       ..color = Colors.red
    //       ..strokeWidth = 2,
    //   );

    //   // Label the quadrant
    //   final labelRadius = radius + 30;
    //   final lx = center.dx + labelRadius * cos(angle);
    //   final ly = center.dy + labelRadius * sin(angle);
    //   final textPainter = TextPainter(
    //     text: TextSpan(
    //       text: 'Q${i + 1}',
    //       style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
    //     ),
    //     textDirection: TextDirection.ltr,
    //   )..layout();
    //   textPainter.paint(canvas, Offset(lx - 10, ly - 10));
    // }

    // Draw arrows for the four angles (ASC, DSC, MC, IC) - inward pointing, no line
    // final angles = [
    //   {'name': 'ASC', 'offset': 0.0, 'color': Colors.red},
    //   {'name': 'DSC', 'offset': 180.0, 'color': Colors.blue},
    //   {'name': 'MC', 'offset': 90.0, 'color': Colors.green},
    //   {'name': 'IC', 'offset': 270.0, 'color': Colors.purple},
    // ];

    // for (final angleData in angles) {
    //   final offset = angleData['offset'] as double;
    //   final color = angleData['color'] as Color;
    //   final angle = (-pi / 2) - ((offset - ascDegree) * pi / 180);
    //   final start = center;
    //   final end = center + Offset((radius + 20) * cos(angle), (radius + 20) * sin(angle));

    //   // Remove the line - only draw the arrowhead

    //   // Draw arrowhead (triangle at the end, pointing inward)
    //   final arrowLength = 10.0;
    //   final arrowAngle = pi / 6; // 30 degrees
    //   // Reverse direction for inward pointing
    //   final direction = atan2(start.dy - end.dy, start.dx - end.dx);
    //   final arrowPoint1 = Offset(
    //     end.dx - arrowLength * cos(direction - arrowAngle),
    //     end.dy - arrowLength * sin(direction - arrowAngle),
    //   );
    //   final arrowPoint2 = Offset(
    //     end.dx - arrowLength * cos(direction + arrowAngle),
    //     end.dy - arrowLength * sin(direction + arrowAngle),
    //   );

    //   final path = Path()
    //     ..moveTo(end.dx, end.dy)
    //     ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
    //     ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
    //     ..close();
    //   canvas.drawPath(
    //     path,
    //     Paint()
    //       ..color = color
    //       ..style = PaintingStyle.fill,
    //   );

    //   // Label the angle
    //   final labelRadius = radius + 35;
    //   final lx = center.dx + labelRadius * cos(angle);
    //   final ly = center.dy + labelRadius * sin(angle);
    //   final textPainter = TextPainter(
    //     text: TextSpan(
    //       text: angleData['name'] as String,
    //       style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold),
    //     ),
    //     textDirection: TextDirection.ltr,
    //   )..layout();
    //   textPainter.paint(canvas, Offset(lx - 15, ly - 10));
    // }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

double angleForDegree(double deg, double ascDegree) {
  return (-pi / 2) - (deg - ascDegree) * pi / 180; // Changed + to -
}