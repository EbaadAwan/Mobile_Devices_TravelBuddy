import 'package:geolocator/geolocator.dart';

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
    await Future.delayed(const Duration(seconds: 2));

    print('DEBUG: Mocking API call for lat: $latitude, lon: $longitude');

    return [
      NearbyAttraction(
        name: 'Oshawa Museum',
        address: '1450 Simcoe St S, Oshawa, ON',
        rating: 4.3,
        distanceKm: 1.8,
        imageUrl: 'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1b/7f/af/78/lakeview-park.jpg?w=1100&h=600&s=1',
        category: 'Museum',
      ),
      NearbyAttraction(
        name: 'Lakeview Park',
        address: 'Lakeview Park, Oshawa, ON',
        rating: 4.8,
        distanceKm: 2.4,
        imageUrl: 'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1b/7f/af/78/lakeview-park.jpg?w=1100&h=600&s=1',
        category: 'Park',
      ),
      NearbyAttraction(
        name: 'Parkwood Estate',
        address: '270 Simcoe St S, Oshawa, ON',
        rating: 4.6,
        distanceKm: 3.1,
        imageUrl: 'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1b/7f/af/78/lakeview-park.jpg?w=1100&h=600&s=1',
        category: 'Historic Site',
      ),
      NearbyAttraction(
        name: 'Robert McLaughlin Gallery',
        address: '72 Queen St, Oshawa, ON',
        rating: 4.5,
        distanceKm: 3.5,
        imageUrl: 'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1b/7f/af/78/lakeview-park.jpg?w=1100&h=600&s=1',
        category: 'Art Gallery',
      ),
    ];
  }
}