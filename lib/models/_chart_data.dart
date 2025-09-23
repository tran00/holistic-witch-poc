class ChartData {
  final String name;
  final String date;
  final String time;
  final String location;
  final double julianDay;
  final Map<String, dynamic> planets;
  final Map<String, dynamic> houses;
  final double? ascendant;
  final double? mc;

  ChartData({
    required this.name,
    required this.date,
    required this.time,
    required this.location,
    required this.julianDay,
    required this.planets,
    required this.houses,
    this.ascendant,
    this.mc,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': date,
      'time': time,
      'location': location,
      'julianDay': julianDay,
      'planets': planets,
      'houses': houses,
      'ascendant': ascendant,
      'mc': mc,
    };
  }
}