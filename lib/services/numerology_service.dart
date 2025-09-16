// lib/services/numerology_service.dart

/// Service class for numerology calculations
class NumerologyService {
  
  /// Calculate life path number from birth date (JJMMAAAA format)
  static int calculateLifePathNumber(String birthDate) {
    if (birthDate.length != 8) return 0;
    final digits = birthDate.split('').map(int.parse).toList();
    int sum = digits.reduce((a, b) => a + b);
    return _reduceToSingleDigitOrMaster(sum);
  }

  /// Calculate expression number from full name
  static int calculateExpressionNumber(String firstName, String lastName) {
    final all = (firstName + lastName).replaceAll(RegExp(r'[^A-Za-z]'), '');
    int sum = all.split('').map(_letterValue).reduce((a, b) => a + b);
    return _reduceToSingleDigitOrMaster(sum);
  }

  /// Calculate intimate number from vowels only
  static int calculateIntimeNumber(String firstName, String lastName) {
    final all = (firstName + lastName).replaceAll(RegExp(r'[^AEIOUYaeiouy]'), '');
    if (all.isEmpty) return 0;
    int sum = all.split('').map(_letterValue).reduce((a, b) => a + b);
    return _reduceToSingleDigitOrMaster(sum);
  }

  /// Calculate personal year number
  static int calculatePersonalYear(String birthDate, String currentYear) {
    if (birthDate.length != 8 || currentYear.length != 4) return 0;
    final day = int.parse(birthDate.substring(0, 2));
    final month = int.parse(birthDate.substring(2, 4));
    final year = int.parse(currentYear);
    int sum = day + month + year;
    return _reduceToSingleDigitOrMaster(sum);
  }

  /// Calculate Sphere 1: Identity (A, J, S letters)
  static int calculateSphere1(String firstName, String lastName) {
    return _calculateSphereWithLetters(firstName, lastName, ['A', 'J', 'S'], 1);
  }

  /// Calculate Sphere 2: Sentiment (B, K, T letters × 2)
  static int calculateSphere2(String firstName, String lastName) {
    return _calculateSphereWithLetters(firstName, lastName, ['B', 'K', 'T'], 2);
  }

  /// Calculate Sphere 3: Communication (C, L, U letters × 3)
  static int calculateSphere3(String firstName, String lastName) {
    return _calculateSphereWithLetters(firstName, lastName, ['C', 'L', 'U'], 3);
  }

  /// Calculate Sphere 4: Work (D, M, V letters × 4)
  static int calculateSphere4(String firstName, String lastName) {
    return _calculateSphereWithLetters(firstName, lastName, ['D', 'M', 'V'], 4);
  }

  /// Calculate Sphere 5: Analytical (E, N, W letters × 5)
  static int calculateSphere5(String firstName, String lastName) {
    return _calculateSphereWithLetters(firstName, lastName, ['E', 'N', 'W'], 5);
  }

  /// Calculate Sphere 6: Family (F, O, X letters × 6)
  static int calculateSphere6(String firstName, String lastName) {
    return _calculateSphereWithLetters(firstName, lastName, ['F', 'O', 'X'], 6);
  }

  /// Calculate Sphere 7: Spirituality (G, P, Y letters × 7)
  static int calculateSphere7(String firstName, String lastName) {
    return _calculateSphereWithLetters(firstName, lastName, ['G', 'P', 'Y'], 7);
  }

  /// Calculate Sphere 8: Talents (H, Q, Z letters × 8)
  static int calculateSphere8(String firstName, String lastName) {
    return _calculateSphereWithLetters(firstName, lastName, ['H', 'Q', 'Z'], 8);
  }

  /// Calculate Sphere 9: Empathy (I, R letters × 9)
  static int calculateSphere9(String firstName, String lastName) {
    return _calculateSphereWithLetters(firstName, lastName, ['I', 'R'], 9);
  }

  /// Calculate soul number (sum of all vowels)
  static int calculateSoulNumber(String firstName, String lastName) {
    final all = (firstName + lastName).replaceAll(RegExp(r'[^AEIOUYaeiouy]'), '');
    if (all.isEmpty) return 0;
    int sum = all.split('').map(_letterValue).reduce((a, b) => a + b);
    return _reduceToSingleDigitOrMaster(sum);
  }

  /// Calculate personality number (sum of all consonants)
  static int calculatePersonalityNumber(String firstName, String lastName) {
    final all = (firstName + lastName).replaceAll(RegExp(r'[^A-Za-z]'), '');
    final consonants = all.replaceAll(RegExp(r'[AEIOUYaeiouy]'), '');
    if (consonants.isEmpty) return 0;
    int sum = consonants.split('').map(_letterValue).reduce((a, b) => a + b);
    return _reduceToSingleDigitOrMaster(sum);
  }

  /// Calculate perception number (how others see you)
  static int calculatePerceptionNumber(String firstName, String lastName) {
    // This is typically the same as personality number or derived from it
    // Some systems use first name only for perception
    final consonants = firstName.replaceAll(RegExp(r'[^A-Za-z]'), '').replaceAll(RegExp(r'[AEIOUYaeiouy]'), '');
    if (consonants.isEmpty) return 0;
    int sum = consonants.split('').map(_letterValue).reduce((a, b) => a + b);
    return _reduceToSingleDigitOrMaster(sum);
  }

  /// Calculate all numbers at once
  static Map<String, int> calculateAllNumbers(
    String birthDate,
    String firstName,
    String lastName,
    String currentYear,
  ) {
    return {
      'lifePathNumber': calculateLifePathNumber(birthDate),
      'expressionNumber': calculateExpressionNumber(firstName, lastName),
      'intimeNumber': calculateIntimeNumber(firstName, lastName),
      'personalYearNumber': calculatePersonalYear(birthDate, currentYear),
      'soulNumber': calculateSoulNumber(firstName, lastName), // Add this
      'personalityNumber': calculatePersonalityNumber(firstName, lastName), // Add this
      'perceptionNumber': calculatePerceptionNumber(firstName, lastName), // Add this
      'sphere1': calculateSphere1(firstName, lastName),
      'sphere2': calculateSphere2(firstName, lastName),
      'sphere3': calculateSphere3(firstName, lastName),
      'sphere4': calculateSphere4(firstName, lastName),
      'sphere5': calculateSphere5(firstName, lastName),
      'sphere6': calculateSphere6(firstName, lastName),
      'sphere7': calculateSphere7(firstName, lastName),
      'sphere8': calculateSphere8(firstName, lastName),
      'sphere9': calculateSphere9(firstName, lastName),
    };
  }

  /// Get sphere names and descriptions
  static Map<int, Map<String, String>> getSphereInfo() {
    return {
      1: {
        'name': 'Identité',
        'description': 'Identité profonde',
        'letters': 'A, J, S',
      },
      2: {
        'name': 'Sentiment',
        'description': 'Sentiment, couple, relations aux autres',
        'letters': 'B, K, T',
      },
      3: {
        'name': 'Communication',
        'description': 'Communication, créativité, ami(e)s, relations sociales',
        'letters': 'C, L, U',
      },
      4: {
        'name': 'Travail',
        'description': 'Travail quotidien pro/école famille d\'origine',
        'letters': 'D, M, V',
      },
      5: {
        'name': 'Analytique',
        'description': 'Analytique',
        'letters': 'E, N, W',
      },
      6: {
        'name': 'Famille',
        'description': 'La famille que j\'ai construite/que je construis',
        'letters': 'F, O, X',
      },
      7: {
        'name': 'Spiritualité',
        'description': 'Connaissances spirituelles et intellectuelles',
        'letters': 'G, P, Y',
      },
      8: {
        'name': 'Talents',
        'description': 'Talents argent',
        'letters': 'H, Q, Z',
      },
      9: {
        'name': 'Empathie',
        'description': 'L\'empathie les autres',
        'letters': 'I, R',
      },
    };
  }

  // Private helper methods

  /// Calculate letter value (A=1, B=2, ..., I=9, J=1, ..., R=9, S=1, ..., Z=8)
  static int _letterValue(String letter) {
    final l = letter.toUpperCase();
    if (RegExp(r'[A-Z]').hasMatch(l)) {
      return ((l.codeUnitAt(0) - 65) % 9) + 1;
    }
    return 0;
  }

  /// Reduce number to single digit or master number (11, 22, 33)
  static int _reduceToSingleDigitOrMaster(int sum) {
    while (sum > 9 && sum != 11 && sum != 22 && sum != 33) {
      sum = sum.toString().split('').map(int.parse).reduce((a, b) => a + b);
    }
    return sum;
  }

  /// Calculate sphere with specific letters and multiplier
  static int _calculateSphereWithLetters(
    String firstName,
    String lastName,
    List<String> targetLetters,
    int multiplier,
  ) {
    // Combine all names and remove spaces/special characters
    final allNames = (firstName + lastName)
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z]'), '');

    // Count target letters
    int count = 0;
    for (String letter in allNames.split('')) {
      if (targetLetters.contains(letter)) {
        count++;
      }
    }

    // If count is 0, return 0
    if (count == 0) return 0;

    // Calculate result with multiplier and reduce
    int result = count * multiplier;
    return _reduceToSingleDigitOrMaster(result);
  }

  /// Validate input data
  static bool validateInputs(
    String birthDate,
    String firstName,
    String lastName,
    String currentYear,
  ) {
    return birthDate.length == 8 &&
        firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        currentYear.length == 4;
  }

  /// Format birth date for display
  static String formatBirthDate(String birthDate) {
    if (birthDate.length != 8) return birthDate;
    final day = birthDate.substring(0, 2);
    final month = birthDate.substring(2, 4);
    final year = birthDate.substring(4, 8);
    return '$day/$month/$year';
  }
}