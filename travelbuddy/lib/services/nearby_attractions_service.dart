import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NearbyAttraction {
  final String name;
  final String address;
  final double rating;
  final double distanceKm;
  final String imageUrl;
  final String category;

  const NearbyAttraction({
    required this.name,
    required this.address,
    required this.rating,
    required this.distanceKm,
    required this.imageUrl,
    required this.category,
  });
}

class NearbyAttractionsService {
  
  static Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<List<NearbyAttraction>> fetchNearbyAttractions({
    required double latitude,
    required double longitude,
    int radius = 5000,
  }) async {
    
    final url = Uri.parse(
      'https://en.wikipedia.org/w/api.php?'
      'action=query&list=geosearch&gscoord=$latitude|$longitude'
      '&gsradius=$radius&gslimit=10&format=json&origin=*'
    );

    print('Fetching from Wikipedia API...');

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'TravelBuddyApp/1.0 (Flutter; Educational Project)',
      },
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Request timeout');
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load attractions: HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final results = data['query']['geosearch'] as List<dynamic>? ?? [];

    return results.map((item) {
      final distMeters = (item['dist'] as num?)?.toDouble() ?? 0.0;
      final title = item['title']?.toString() ?? 'Unknown';
      final category = item['type']?.toString() ?? 'attraction';

      String formattedCategory = category[0].toUpperCase() + category.substring(1);

      return NearbyAttraction(
        name: title,
        address: item['primary']?.toString() ?? '$formattedCategory near you',
        rating: 3.5 + (distMeters % 100) / 100 * 1.5,
        distanceKm: (distMeters / 1000).roundToDouble(),
        imageUrl: 'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1b/7f/af/78/lakeview-park.jpg?w=1100&h=600&s=1',
        category: formattedCategory,
      );
    }).toList();
  }
}