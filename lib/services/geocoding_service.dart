// lib/services/geocoding_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static GeocodingService? _instance;
  
  // Singleton pattern
  factory GeocodingService() {
    _instance ??= GeocodingService._internal();
    return _instance!;
  }
  
  GeocodingService._internal();

  /// Fetch city suggestions from OpenStreetMap Nominatim API
  Future<List<Map<String, dynamic>>> fetchCitySuggestions(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?city=$query&format=json&addressdetails=1&limit=10',
      );
      
      final response = await http.get(url, headers: {
        'User-Agent': 'HolisticWitchPOC/1.0',
      });
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map<Map<String, dynamic>>((item) {
          return {
            'display_name': item['display_name'] ?? '',
            'lat': item['lat'] ?? '',
            'lon': item['lon'] ?? '',
          };
        }).toList();
      } else {
        print('❌ Geocoding API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching city suggestions: $e');
      return [];
    }
  }

  /// Get timezone from coordinates using basic geographic mapping
  String getTimezoneFromCoordinates(double latitude, double longitude) {
    // Europe
    if (latitude >= 35 && latitude <= 70 && longitude >= -10 && longitude <= 40) {
      if (longitude >= -5 && longitude <= 25) {
        return 'Europe/Paris'; // Western/Central Europe
      } else if (longitude >= 25 && longitude <= 40) {
        return 'Europe/Bucharest'; // Eastern Europe
      }
    }
    
    // North America
    if (latitude >= 25 && latitude <= 70 && longitude >= -170 && longitude <= -50) {
      if (longitude >= -85) return 'America/New_York'; // Eastern US
      else if (longitude >= -105) return 'America/Chicago'; // Central US
      else if (longitude >= -125) return 'America/Denver'; // Mountain US
      else return 'America/Los_Angeles'; // Pacific US
    }
    
    // Asia
    if (latitude >= 0 && latitude <= 70 && longitude >= 40 && longitude <= 180) {
      if (longitude >= 40 && longitude <= 80) return 'Europe/Moscow'; // Western Asia
      else if (longitude >= 80 && longitude <= 120) return 'Asia/Shanghai'; // Central/Eastern Asia
      else return 'Asia/Tokyo'; // Far East Asia
    }
    
    // Africa
    if (latitude >= -35 && latitude <= 35 && longitude >= -20 && longitude <= 50) {
      return 'Africa/Cairo'; // General Africa
    }
    
    // Australia/Oceania
    if (latitude >= -50 && latitude <= -10 && longitude >= 110 && longitude <= 180) {
      return 'Australia/Sydney';
    }
    
    // South America
    if (latitude >= -60 && latitude <= 15 && longitude >= -85 && longitude <= -30) {
      return 'America/Sao_Paulo';
    }
    
    // Default fallback to UTC for unknown regions
    return 'UTC';
  }

  /// Get timezone from external API (GeoNames - requires free account)
  Future<String> getTimezoneFromAPI(double latitude, double longitude, {String? username}) async {
    if (username == null || username.isEmpty) {
      print('⚠️ No GeoNames username provided, using coordinate mapping');
      return getTimezoneFromCoordinates(latitude, longitude);
    }

    try {
      final url = Uri.parse(
        'http://api.geonames.org/timezoneJSON?lat=$latitude&lng=$longitude&username=$username'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['timezoneId'] != null) {
          return data['timezoneId'];
        } else {
          print('⚠️ No timezone ID in API response');
          return getTimezoneFromCoordinates(latitude, longitude);
        }
      } else {
        print('❌ Timezone API error: ${response.statusCode}');
        return getTimezoneFromCoordinates(latitude, longitude);
      }
    } catch (e) {
      print('❌ Error getting timezone from API: $e');
      return getTimezoneFromCoordinates(latitude, longitude);
    }
  }

  /// Search for places with more detailed query options
  Future<List<Map<String, dynamic>>> searchPlaces(
    String query, {
    int limit = 10,
    String? countryCode,
    String? language = 'en',
  }) async {
    if (query.isEmpty) return [];
    
    try {
      String searchUrl = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=$limit';
      
      if (countryCode != null) {
        searchUrl += '&countrycodes=$countryCode';
      }
      
      if (language != null) {
        searchUrl += '&accept-language=$language';
      }
      
      final url = Uri.parse(searchUrl);
      
      final response = await http.get(url, headers: {
        'User-Agent': 'HolisticWitchPOC/1.0',
      });
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map<Map<String, dynamic>>((item) {
          return {
            'display_name': item['display_name'] ?? '',
            'lat': item['lat'] ?? '',
            'lon': item['lon'] ?? '',
            'type': item['type'] ?? '',
            'importance': item['importance'] ?? 0.0,
            'address': item['address'] ?? {},
          };
        }).toList();
      } else {
        print('❌ Places search API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error searching places: $e');
      return [];
    }
  }

  /// Reverse geocoding - get address from coordinates
  Future<Map<String, dynamic>?> reverseGeocode(
    double latitude, 
    double longitude, {
    String? language = 'en',
  }) async {
    try {
      String reverseUrl = 'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1';
      
      if (language != null) {
        reverseUrl += '&accept-language=$language';
      }
      
      final url = Uri.parse(reverseUrl);
      
      final response = await http.get(url, headers: {
        'User-Agent': 'HolisticWitchPOC/1.0',
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'display_name': data['display_name'] ?? '',
          'address': data['address'] ?? {},
          'type': data['type'] ?? '',
        };
      } else {
        print('❌ Reverse geocoding API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error in reverse geocoding: $e');
      return null;
    }
  }
}