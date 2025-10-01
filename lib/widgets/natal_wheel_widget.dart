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
  
  // All possible node variations
  'North Node': '☊',
  'South Node': '☋',
  'Noeud Nord': '☊',
  'Noeud Sud': '☋',
  'True Node': '☊',
  'Mean Node': '☊',
  'Node': '☊',
  'NN': '☊',  // Short name
  'SN': '☋',  // Short name
  'Ch': '⚷',  // Chiron short name
  
  // Backup for common variations
  'NORTH_NODE': '☊',
  'SOUTH_NODE': '☋',
  'TRUE_NODE': '☊',
  'MEAN_NODE': '☊',
};


const debugDrawLineToPlanet = false;

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

  // Add this method to automatically add missing nodes
  void _addMissingNodes() {
    if (chartData['planets'] is! List) return;
    
    final planets = chartData['planets'] as List;

    // print(planets);
    
    // Check if we have any nodes
    final hasNorthNode = planets.any((p) => 
      (p['name'] as String).toLowerCase().contains('north') ||
      (p['name'] as String).toLowerCase().contains('noeud nord') ||
      (p['name'] as String).toLowerCase().contains('true node') ||
      (p['name'] as String).toLowerCase().contains('mean node')
    );

    final hasSouthNode = planets.any((p) => 
      (p['name'] as String).toLowerCase().contains('south') ||
      (p['name'] as String).toLowerCase().contains('noeud sud')
    );

    // print('north and south node status: $hasNorthNode, $hasSouthNode');
    
    // If no nodes at all, add them at example positions
    if (!hasNorthNode && !hasSouthNode) {
      print('🔮 Adding missing North and South Nodes');
      
      // Add North Node at 120° (example position)
      planets.add({
        'name': 'North Node',
        'short_name': 'NN',
        'longitude': 120.0,
      });
      
      // Add South Node at opposite position (300°)
      planets.add({
        'name': 'South Node', 
        'short_name': 'SN',
        'longitude': 300.0,
      });
    }
    // If we have North Node but no South Node, calculate South Node
    else if (hasNorthNode && !hasSouthNode) {

      final northNode = planets.firstWhere((p) => 
        (p['name'] as String).toLowerCase().contains('north') ||
        (p['name'] as String).toLowerCase().contains('North Node') ||
        (p['name'] as String).toLowerCase().contains('noeud nord') ||
        (p['name'] as String).toLowerCase().contains('true node') ||
        (p['name'] as String).toLowerCase().contains('mean node')
      );
      
      final northDegree = (northNode['longitude'] ?? 0).toDouble();
      final southDegree = (northDegree + 180) % 360;
      
      print('🔮 Adding South Node at ${southDegree}° (opposite of North Node at ${northDegree}°)');
      
      planets.add({
        'name': 'South Node',
        'short_name': 'SN', 
        'longitude': southDegree,
      });
    } else {

      final northNode = planets.firstWhere((p) => 
        (p['name'] as String).toLowerCase().contains('north') ||
        (p['name'] as String).toLowerCase().contains('North Node') ||
        (p['name'] as String).toLowerCase().contains('noeud nord') ||
        (p['name'] as String).toLowerCase().contains('true node') ||
        (p['name'] as String).toLowerCase().contains('mean node')
      );
      final southhNode = planets.firstWhere((p) => 
        (p['name'] as String).toLowerCase().contains('south') ||
        (p['name'] as String).toLowerCase().contains('South Node') ||
        (p['name'] as String).toLowerCase().contains('noeud sud')
      );
      
      final northDegree = (northNode['longitude'] ?? 0).toDouble();
      final southDegree = (southhNode['longitude'] ?? 0).toDouble();

      planets.add({
        'name': 'North Node',
        'short_name': 'NN', 
        'longitude': northDegree,
      });

      planets.add({
        'name': 'South Node',
        'short_name': 'SN', 
        'longitude': southDegree,
      });
    }
    
    // Add Chiron if missing
    final hasChiron = planets.any((p) => 
      (p['name'] as String).toLowerCase() == 'chiron'
    );

    if(hasChiron) {
      final chironNode = planets.firstWhere((p) => 
        (p['name'] as String).toLowerCase().contains('chiron')
      );
      
      final chironDegree = (chironNode['longitude'] ?? 0).toDouble();

      planets.add({
        'name': 'Chiron',
        'short_name': 'Ch', 
        'longitude': chironDegree,
      }); 

      // print('Chiron degree: $chironDegree');
    } else {
      // print('Chiron not found');
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Add missing nodes before drawing
    // _addMissingNodes();
    
    // Debug: Print all planets after adding nodes
    if (chartData['planets'] is List) {
      // final planets = chartData['planets'] as List;
      // print('🌟 Final planets list:');
      // for (final planet in planets) {
      //   print('  - ${planet['name']} at ${planet['longitude']}°');
      // }
    }
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 100; // Reduced from -66 to -100 (smaller chart)

    // Draw outer circle for houses
    final outerCirclePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius + 20, outerCirclePaint); // Adjusted outer circle for new spacing

    final houses = (chartData['houses'] is List) ? chartData['houses'] as List : [];
    final ascDegree = (houses.isNotEmpty && houses.first['start_degree'] is num)
        ? (houses.first['start_degree'] as num).toDouble()
        : 0.0;

    // Zodiac radii (inner)
    final zodiacRadiusOuter = radius - 5;
    final zodiacRadiusInner = radius - 20;

    // Draw zodiac segments (arcs) - inner
    for (int i = 0; i < 12; i++) {
      final startAngle = (-pi) - ((i * 30 - ascDegree) * pi / 180); // Rotated base
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

    // Draw degree ruler (every 1° a tiny tick, every 5° a small tick, every 30° a big tick) - inner
    for (int deg = 0; deg < 360; deg += 1) {
      final angle = (-pi) - ((deg - ascDegree) * pi / 180); // Rotated base
      final isMajor = deg % 30 == 0;   // Every 30° (zodiac sign boundaries)
      final isMinor = deg % 5 == 0;    // Every 5°
      final isTiny = deg % 1 == 0;     // Every 1°
      
      double tickLength;
      Color tickColor;
      double strokeWidth;
      
      if (isMajor) {
        tickLength = 16;
        tickColor = Colors.deepPurple;
        strokeWidth = .5;
      } else if (isMinor) {
        tickLength = 10;
        tickColor = Colors.deepPurple.withOpacity(0.7);
        strokeWidth = 1;
      } else if (isTiny) {
        tickLength = 4;
        tickColor = Colors.grey.withOpacity(0.6);
        strokeWidth = 0.5;
      } else {
        continue; // Skip if none of the conditions match
      }
      
      final tickStart = center + Offset(
        (zodiacRadiusInner - 2) * cos(angle),
        (zodiacRadiusInner - 2) * sin(angle),
      );
      final tickEnd = center + Offset(
        (zodiacRadiusInner - 2 - tickLength) * cos(angle),
        (zodiacRadiusInner - 2 - tickLength) * sin(angle),
      );
      canvas.drawLine(
        tickStart,
        tickEnd,
        Paint()
          ..color = tickColor
          ..strokeWidth = strokeWidth,
      );
    }

    // Draw degree labels (every 10° for better readability)
    // for (int deg = 0; deg < 360; deg += 10) {
    //   final angle = (-pi) - ((deg - ascDegree) * pi / 180); // Rotated base
    //   final tx = center.dx + (zodiacRadiusInner - 26) * cos(angle);
    //   final ty = center.dy + (zodiacRadiusInner - 26) * sin(angle);
      
    //   // Use different styling for major (30°) vs minor (10°) labels
    //   final isMajor = deg % 30 == 0;
    //   final fontSize = isMajor ? 11.0 : 8.0;
    //   final fontWeight = isMajor ? FontWeight.bold : FontWeight.normal;
    //   final color = isMajor ? Colors.deepPurple : Colors.deepPurple.withOpacity(0.7);
      
      // final textPainter = TextPainter(
      //   text: TextSpan(
      //     text: '$deg°',
      //     style: TextStyle(
      //       fontSize: fontSize, 
      //       color: color,
      //       fontWeight: fontWeight,
      //     ),
      //   ),
      //   textDirection: TextDirection.ltr,
      // )..layout();
      // textPainter.paint(canvas, Offset(tx - textPainter.width / 2, ty - textPainter.height / 2));
    // }

    // Draw house cusps (lines) - constrained to smaller inner circle
    if (chartData['houses'] is List) {
      final houses = chartData['houses'] as List;
      final houseLineInner = zodiacRadiusOuter; // Start at zodiac outer
      final houseLineOuter = zodiacRadiusOuter + 25; // Shortened to +10
      final numberRadius = radius + 5; // House numbers at outer

      for (int i = 0; i < houses.length; i++) {
        final house = houses[i];
        final startDeg = (houses[i]['start_degree'] as num).toDouble();

        // Angle for house cusp line
        final angle = (-pi) - (startDeg - ascDegree) * pi / 180; // Rotated base

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

        // Draw triangle at house cusp (bigger for angular houses)
        final houseNumber = house['house_id'] ?? (i + 1);
        final isAngularHouse = [1, 4, 7, 10].contains(houseNumber); // AC, IC, DC, MC
        
        final triangleRadius = isAngularHouse ? houseLineOuter : houseLineOuter - 25; // Position angular triangles at house line
        final triangleSize = isAngularHouse ? 12.0 : 4.0; // Reasonable size for angular houses
        final triangleCenter = center + Offset(triangleRadius * cos(angle), triangleRadius * sin(angle));
        
        // Create triangle (outward for angular houses, outward for regular houses)
        final trianglePath = Path();
        
        if (isAngularHouse) {
          // Angular houses: Triangle tip points INWARD from center (more visible)
          final tipOffset = triangleCenter - Offset(triangleSize * cos(angle), triangleSize * sin(angle));
          // Triangle base points (perpendicular to radius)
          final baseLeft = triangleCenter + Offset(
            triangleSize * 0.6 * cos(angle + pi / 2), 
            triangleSize * 0.6 * sin(angle + pi / 2)
          );
          final baseRight = triangleCenter + Offset(
            triangleSize * 0.6 * cos(angle - pi / 2), 
            triangleSize * 0.6 * sin(angle - pi / 2)
          );
          
          trianglePath.moveTo(tipOffset.dx, tipOffset.dy);
          trianglePath.lineTo(baseLeft.dx, baseLeft.dy);
          trianglePath.lineTo(baseRight.dx, baseRight.dy);
        } else {
          // Regular houses: Triangle tip points OUTWARD from center
          final tipOffset = triangleCenter + Offset(triangleSize * cos(angle), triangleSize * sin(angle));
          // Triangle base points (perpendicular to radius)
          final baseLeft = triangleCenter + Offset(
            triangleSize * 0.6 * cos(angle + pi / 2), 
            triangleSize * 0.6 * sin(angle + pi / 2)
          );
          final baseRight = triangleCenter + Offset(
            triangleSize * 0.6 * cos(angle - pi / 2), 
            triangleSize * 0.6 * sin(angle - pi / 2)
          );
          
          trianglePath.moveTo(tipOffset.dx, tipOffset.dy);
          trianglePath.lineTo(baseLeft.dx, baseLeft.dy);
          trianglePath.lineTo(baseRight.dx, baseRight.dy);
        }
        trianglePath.close();
        
        // Use different colors for angular houses
        final triangleColor = isAngularHouse ? Colors.red : Colors.deepPurple;
        final strokeWidth = isAngularHouse ? 2.0 : 0.5;
        
        canvas.drawPath(
          trianglePath,
          Paint()
            ..color = triangleColor
            ..style = PaintingStyle.fill,
        );

        // Draw triangle border
        canvas.drawPath(
          trianglePath,
          Paint()
            ..color = triangleColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth,
        );

        // Add text labels for angular houses
        if (isAngularHouse) {
          String angleLabel;
          switch (houseNumber) {
            case 1:
              angleLabel = 'ASC';
              break;
            case 4:
              angleLabel = 'IC';
              break;
            case 7:
              angleLabel = 'DSC';
              break;
            case 10:
              angleLabel = 'MC';
              break;
            default:
              angleLabel = '';
          }
          
          final labelRadius = triangleRadius + 25; // Position label further out
          final labelCenter = center + Offset(labelRadius * cos(angle), labelRadius * sin(angle));
          
          final textPainter = TextPainter(
            text: TextSpan(
              text: angleLabel,
              style: const TextStyle(
                fontSize: 12, 
                color: Colors.red, 
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          
          textPainter.paint(
            canvas, 
            Offset(
              labelCenter.dx - textPainter.width / 2,
              labelCenter.dy - textPainter.height / 2,
            ),
          );
        }

        // Draw house number at the middle of the house
        final endDeg = (houses[i]['end_degree'] as num).toDouble();
        double midDeg;
        if (endDeg > startDeg) {
          midDeg = startDeg + (endDeg - startDeg) / 2;
        } else {
          midDeg = startDeg + ((endDeg + 360 - startDeg) / 2);
          if (midDeg > 360) midDeg -= 360;
        }

        final midAngle = (-pi) - (midDeg - ascDegree) * pi / 180; // Rotated base
        final nx = center.dx + numberRadius * cos(midAngle);
        final ny = center.dy + numberRadius * sin(midAngle);
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${house['house_id']}',
            style: const TextStyle(fontSize: 14, color: Colors.deepPurple, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(nx - textPainter.width / 2, ny - textPainter.height / 2));
      }
    }

    // Draw planets with glyphs - outermost
    if (chartData['planets'] is List) {
      final planets = chartData['planets'] as List;
      final planetRadius = radius + 60; // Increased from +40 to +60 (more space from house lines)

      for (final planet in planets) {
        final deg = (planet['longitude'] ?? planet['full_degree'] ?? 0).toDouble();
        final angle = (-pi) - (deg - ascDegree) * pi / 180; // Rotated base
        final px = center.dx + planetRadius * cos(angle);
        final py = center.dy + planetRadius * sin(angle);

        final planetName = planet['name'] ?? '';
        final shortName = planet['short_name'] ?? '';

        // Try multiple ways to find the glyph
        String glyph = planetGlyphs[planetName] ?? 
                       planetGlyphs[shortName] ?? 
                       planetGlyphs[planetName.toUpperCase()] ??
                       planetGlyphs[shortName.toUpperCase()] ??
                       '?'; // Debug fallback

        // Special styling for nodes
        Color glyphColor = Colors.black;
        double fontSize = 28;

        if (planetName.toLowerCase().contains('node') || 
            planetName.toLowerCase().contains('noeud') ||
            shortName.toLowerCase().contains('n')) {
          glyphColor = Colors.indigo;
          fontSize = 30;
        } else if (planetName.toLowerCase() == 'chiron' || shortName.toLowerCase() == 'ch') {
          glyphColor = Colors.teal;
        }

        // Draw planet glyph
        final glyphPainter = TextPainter(
          text: TextSpan(
            text: glyph,
            style: TextStyle(
              fontSize: fontSize, 
              color: glyphColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        glyphPainter.paint(
          canvas, 
          Offset(
            px - glyphPainter.width / 2,   // Center horizontally
            py - glyphPainter.height / 2,  // Center vertically
          ),
        );

        // Draw zodiac sign name under the planet glyph
        final rawDegrees = deg;
        final zodiacSign = (rawDegrees / 30).floor().clamp(0, 11);
        const zodiacNamesFull = [
          'Bélier', 'Taureau', 'Gémeaux', 'Cancer', 'Lion', 'Vierge',
          'Balance', 'Scorpion', 'Sagittaire', 'Capricorne', 'Verseau', 'Poissons'
        ];
        final signNameFull = zodiacNamesFull[zodiacSign];
        // final signPainter = TextPainter(
        //   text: TextSpan(
        //     text: signNameFull,
        //     style: const TextStyle(
        //       fontSize: 10, 
        //       color: Colors.black,
        //       fontWeight: FontWeight.w600,
        //     ),
        //   ),
        //   textDirection: TextDirection.ltr,
        // )..layout();
        // signPainter.paint(
        //   canvas,
        //   Offset(
        //     px - signPainter.width / 2 + 15,
        //     py + glyphPainter.height / 2 + 1, // Just below the glyph
        //   ),
        // );

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
              px - glyphPainter.width / 2 + 15,
              py + glyphPainter.height / 2 - 15,
            ),
          );
        }

        // Calculate zodiac degrees and minutes (for degree label)
        final degreesInSign = rawDegrees % 30;
        final degrees = degreesInSign.floor();
        final minutes = ((degreesInSign - degrees) * 60).round();
        const zodiacNames = [
          'Ari', 'Tau', 'Gem', 'Can', 'Leo', 'Vir',
          'Lib', 'Sco', 'Sag', 'Cap', 'Aqu', 'Pis'
        ];
        // final signName = zodiacNames[zodiacSign];
        final signName = zodiacNamesFull[zodiacSign];
        final degreeText = '$degrees°${minutes.toString().padLeft(2, '0')}\'\n$signName';
        final degreePainter = TextPainter(
          text: TextSpan(
            text: degreeText,
            style: const TextStyle(
              fontSize: 10, 
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        // Determine if planet is on left side of wheel (6 o'clock to 12 o'clock)
        final normalizedAngle = (angle + 2 * pi) % (2 * pi);
        final isOnLeftSide = normalizedAngle > pi / 2 && normalizedAngle < 3 * pi / 2;
        final textOffsetX = isOnLeftSide 
            ? px - glyphPainter.width / 2 - degreePainter.width - 4
            : px + glyphPainter.width / 2 + 4;
        final textOffsetY = py - degreePainter.height / 2;
        degreePainter.paint(
          canvas,
          Offset(textOffsetX, textOffsetY),
        );
      }
    }
    
    // Draw radial degree lines (normals) from planets to degree ruler
    if (chartData['planets'] is List) {
      final planets = chartData['planets'] as List;
      final planetRadius = radius + 60; // Updated to match planet positions
      final degreeRulerRadius = zodiacRadiusInner - 2; // Connect to the degree ruler

      for (final planet in planets) {
        final deg = (planet['longitude'] ?? planet['full_degree'] ?? 0).toDouble();
        final angle = (-pi) - (deg - ascDegree) * pi / 180; // Rotated base
        
        // Planet position (start of line)
        final planetStart = center + Offset(
          planetRadius * cos(angle),
          planetRadius * sin(angle),
        );
        
        // Degree ruler position (end of line)
        final rulerEnd = center + Offset(
          degreeRulerRadius * cos(angle),
          degreeRulerRadius * sin(angle),
        );

        // Draw the radial line from planet to degree ruler
        canvas.drawLine(
          planetStart,
          rulerEnd,
          Paint()
            ..color = Colors.grey.withOpacity(0.4)
            ..strokeWidth = 1,
        );
      }
    }
    
    // Draw lines from center to planets
    if(debugDrawLineToPlanet) {
      if (chartData['planets'] is List) {
        final planets = chartData['planets'] as List;
        final planetRadius = radius + 60; // Updated to match planet positions

        for (final planet in planets) {
          final deg = (planet['longitude'] ?? planet['full_degree'] ?? 0).toDouble();
          final angle = (-pi) - (deg - ascDegree) * pi / 180; // Rotated base
          final px = center.dx + planetRadius * cos(angle);
          final py = center.dy + planetRadius * sin(angle);

          // Draw line from center to planet
          canvas.drawLine(
            center,
            Offset(px, py),
            Paint()
              ..color = Colors.grey.withOpacity(0.5)
              ..strokeWidth = 1,
          );
        }
      }
    }

    // Draw Ascendant and MC labels (fixed positions)
    // if (chartData['ascendant'] != null) {
    //   final angle = -pi; // Left (9 o'clock)
    //   final ax = center.dx + (radius + 50) * cos(angle);
    //   final ay = center.dy + (radius + 50) * sin(angle);

    //   final textPainter = TextPainter(
    //     text: const TextSpan(
    //       text: 'ASC',
    //       style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
    //     ),
    //     textDirection: TextDirection.ltr,
    //   )..layout();
    //   textPainter.paint(canvas, Offset(ax - 12, ay - 12));
    // }
    // if (chartData['mc'] != null) {
    //   final angle = -pi / 2; // Top (12 o'clock)
    //   final mx = center.dx + (radius + 50) * cos(angle);
    //   final my = center.dy + (radius + 50) * sin(angle);

    //   final textPainter = TextPainter(
    //     text: const TextSpan(
    //       text: 'MC',
    //       style: TextStyle(fontSize: 14, color: Colors.teal, fontWeight: FontWeight.bold),
    //     ),
    //     textDirection: TextDirection.ltr,
    //   )..layout();
    //   textPainter.paint(canvas, Offset(mx - 12, my - 12));
    // }

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
        final angle1 = (-pi) - (deg1 - ascDegree) * pi / 180; // Rotated base
        final p1x = center.dx + aspectRadius * cos(angle1);
        final p1y = center.dy + aspectRadius * sin(angle1);

        for (int j = i + 1; j < planets.length; j++) {
          final p2 = planets[j];
          final deg2 = (p2['longitude'] ?? p2['full_degree'] ?? 0).toDouble();
          final angle2 = (-pi) - (deg2 - ascDegree) * pi / 180; // Rotated base
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
          final angle1 = (-pi) - (deg1 - ascDegree) * pi / 180; // Rotated base
          final angle2 = (-pi) - (deg2 - ascDegree) * pi / 180; // Rotated base

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
      // Calculate the middle of each zodiac sign (15° from the start of each sign)
      final signMiddleDegree = i * 30 + 15; // Middle of each 30° zodiac sign
      final midAngle = (-pi) - ((signMiddleDegree - ascDegree) * pi / 180); // Rotated base
      
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
      textPainter.paint(
        canvas,
        Offset(zx - textPainter.width / 2, zy - textPainter.height / 2)
      );
    }

    // Draw thick border at each zodiac sign boundary (inner)
    for (int i = 0; i < 12; i++) {
      final angle = (-pi) - ((i * 30 - ascDegree) * pi / 180); // Rotated base
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

double angleForDegree(double deg, double ascDegree) {
  return (-pi / 2) - (deg - ascDegree) * pi / 180; // Changed + to -
}