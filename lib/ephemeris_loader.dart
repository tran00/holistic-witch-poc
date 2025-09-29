import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart';

class EphemerisLoader {
  static bool _initialized = false;

  /// Initialize Swiss Ephemeris with bundled ephemeris files
  static Future<void> init() async {
    if (_initialized) return;

    // 1. Initialize sweph library
    await Sweph.init();

    // 2. Prepare writable folder
    final appDir = await getApplicationDocumentsDirectory();
    final epheDir = Directory("${appDir.path}/sweph");

    // 3. Copy files from assets if not already present
    if (!await epheDir.exists()) {
      await epheDir.create(recursive: true);

      final files = [
        "seas_18.se1", // Needed for asteroids like Chiron
        "seas_18.se2",
        "sepl_18.se1", // Needed for planets
        "sepl_18.se2",
      ];

      for (final f in files) {
        try {
          final data = await rootBundle.load("assets/sweph/$f");
          final bytes = data.buffer.asUint8List();
          final outFile = File("${epheDir.path}/$f");
          await outFile.writeAsBytes(bytes, flush: true);
        } catch (e) {
          print("⚠️ Warning: Could not copy $f ($e)");
        }
      }
    }

    // 4. Tell sweph where the ephemeris files are
    Sweph.swe_set_ephe_path(epheDir.path);

    _initialized = true;
    print("✅ Swiss Ephemeris initialized with path: ${epheDir.path}");
  }
}
