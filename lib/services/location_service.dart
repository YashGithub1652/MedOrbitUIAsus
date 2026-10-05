import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/symptom_models.dart';

class LocationService {
  /// Gets the user's current GPS coordinates
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    }
  }

  /// Fetches real hospitals from OpenStreetMap (Overpass API)
  static Future<List<NearbyFacility>> getNearbyHospitals({
    required double lat,
    required double lng,
    String? specialistType,
  }) async {
    try {
      final url = Uri.parse('https://overpass-api.de/api/interpreter');

      // Query for hospitals, clinics, and doctors within 10km
      final query = '''
[out:json][timeout:25];
(
  node["amenity"~"hospital|clinic|doctors"](around:10000,$lat,$lng);
  way["amenity"~"hospital|clinic|doctors"](around:10000,$lat,$lng);
  node["healthcare"~"hospital|clinic"](around:10000,$lat,$lng);
  way["healthcare"~"hospital|clinic"](around:10000,$lat,$lng);
);
out center;
''';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': query},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List<dynamic>;

        List<NearbyFacility> facilities = [];

        for (final element in elements) {
          final tags = element['tags'] as Map<String, dynamic>? ?? {};
          final name = tags['name'] as String?;
          if (name == null || name.isEmpty) continue;

          double? elLat;
          double? elLng;

          if (element['type'] == 'node') {
            elLat = (element['lat'] as num).toDouble();
            elLng = (element['lon'] as num).toDouble();
          } else if (element['type'] == 'way' && element['center'] != null) {
            elLat = (element['center']['lat'] as num).toDouble();
            elLng = (element['center']['lon'] as num).toDouble();
          }

          if (elLat != null && elLng != null) {
            final distance = _calculateDistance(lat, lng, elLat, elLng);

            facilities.add(NearbyFacility(
              id: element['id'].toString(),
              name: name,
              type: _classifyFacility(tags['amenity'] as String? ?? 'hospital'),
              distanceKm: distance,
              address: _buildAddress(tags),
              phone: tags['phone'] ?? tags['contact:phone'] ?? '',
              isOpen24h: tags['opening_hours'] == '24/7' || tags['emergency'] == 'yes',
              rating: 0.0,
              specialties: specialistType != null ? [specialistType] : _getSpecialties(tags),
              lat: elLat,
              lng: elLng,
            ));
          }
        }

        facilities.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        return facilities.take(8).toList();
      }
    } catch (e) {
      debugPrint('OpenStreetMap API error: $e');
    }
    return _demoFacilities(lat, lng);
  }

  static String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    if (tags['addr:street'] != null) parts.add(tags['addr:street']);
    if (tags['addr:city'] != null) parts.add(tags['addr:city']);
    return parts.isEmpty ? 'Address unavailable' : parts.join(', ');
  }

  static List<String> _getSpecialties(Map<String, dynamic> tags) {
    if (tags['healthcare:speciality'] != null) {
      return (tags['healthcare:speciality'] as String).split(';').toList();
    }
    return ['General Medicine'];
  }

  static String _classifyFacility(String type) {
    if (type.contains('clinic')) return 'clinic';
    return 'hospital';
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return double.parse((R * c).toStringAsFixed(1));
  }

  static List<NearbyFacility> _demoFacilities(double lat, double lng) => [
    NearbyFacility(
      id: 'demo1',
      name: 'City Care Hospital (Demo)',
      type: 'hospital',
      distanceKm: 1.5,
      address: 'Main St, Health City',
      phone: '+91 99999 00000',
      isOpen24h: true,
      rating: 4.5,
      specialties: ['Emergency', 'General'],
      lat: lat + 0.01,
      lng: lng + 0.01,
    ),
  ];
}