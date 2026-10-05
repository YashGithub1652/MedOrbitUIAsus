// // lib/services/google_places_service.dart

// import 'dart:math' as math;
// import 'package:dio/dio.dart';
// import 'package:geolocator/geolocator.dart';
// import '../models/symptom_models.dart';

// class GooglePlacesService {
//   static const String apiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
//   static const String baseUrl = 'https://maps.googleapis.com/maps/api';

//   final Dio _dio = Dio(
//     BaseOptions(
//       baseUrl: baseUrl,
//       connectTimeout: const Duration(seconds: 15),
//       receiveTimeout: const Duration(seconds: 15),
//     ),
//   );

//   Future<Position?> getCurrentLocation() async {
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) return null;

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) return null;
//       }
//       if (permission == LocationPermission.deniedForever) return null;

//       return await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 10),
//       );
//     } catch (_) {
//       return null;
//     }
//   }

//   Future<List<NearbyFacility>> findNearbyDoctors({
//     required double latitude,
//     required double longitude,
//     String? specialistType,
//     int radiusMeters = 5000,
//   }) async {
//     if (apiKey == 'YOUR_GOOGLE_PLACES_API_KEY') {
//       return _getDemoFacilities(latitude, longitude);
//     }

//     try {
//       String keyword = 'doctor hospital clinic';
//       if (specialistType != null && specialistType.isNotEmpty) {
//         keyword = '$specialistType clinic hospital';
//       }

//       final response = await _dio.get(
//         '/place/nearbysearch/json',
//         queryParameters: {
//           'location': '$latitude,$longitude',
//           'radius': radiusMeters,
//           'keyword': keyword,
//           'type': 'hospital',
//           'key': apiKey,
//         },
//       );

//       if (response.statusCode != 200) {
//         return _getDemoFacilities(latitude, longitude);
//       }

//       final status = response.data['status'] as String?;
//       if (status != 'OK' && status != 'ZERO_RESULTS') {
//         return _getDemoFacilities(latitude, longitude);
//       }

//       final results = response.data['results'] as List<dynamic>? ?? [];
//       if (results.isEmpty) {
//         return _getDemoFacilities(latitude, longitude);
//       }

//       final facilities = <NearbyFacility>[];

//       for (final place in results.take(8)) {
//         try {
//           final location =
//               place['geometry']['location'] as Map<String, dynamic>;
//           final lat = (location['lat'] as num).toDouble();
//           final lng = (location['lng'] as num).toDouble();
//           final dist = _calculateDistance(latitude, longitude, lat, lng);

//           String phone = '';
//           try {
//             final details = await _getPlaceDetails(place['place_id'] as String);
//             phone = details['phone'] ?? '';
//           } catch (_) {}

//           facilities.add(
//             NearbyFacility(
//               id: place['place_id'] as String? ?? '',
//               name: place['name'] as String? ?? 'Medical Facility',
//               type: _classifyFacility(place as Map<String, dynamic>),
//               distanceKm: dist,
//               address: place['vicinity'] as String? ?? 'Address not available',
//               phone: phone,
//               isOpen24h:
//                   (place['opening_hours'] as Map?)?['open_now'] as bool? ??
//                       false,
//               rating: (place['rating'] as num?)?.toDouble() ?? 0.0,
//               specialties: specialistType != null ? [specialistType] : [],
//               lat: lat,
//               lng: lng,
//             ),
//           );
//         } catch (_) {
//           continue;
//         }
//       }

//       facilities.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
//       return facilities;
//     } on DioException catch (_) {
//       return _getDemoFacilities(latitude, longitude);
//     } catch (_) {
//       return _getDemoFacilities(latitude, longitude);
//     }
//   }

//   Future<Map<String, String>> _getPlaceDetails(String placeId) async {
//     try {
//       final response = await _dio.get(
//         '/place/details/json',
//         queryParameters: {
//           'place_id': placeId,
//           'fields': 'formatted_phone_number,website',
//           'key': apiKey,
//         },
//       );

//       if (response.statusCode == 200) {
//         final result = response.data['result'] as Map<String, dynamic>? ?? {};
//         return {
//           'phone': result['formatted_phone_number'] as String? ?? '',
//           'website': result['website'] as String? ?? '',
//         };
//       }
//     } catch (_) {}
//     return {};
//   }

//   String _classifyFacility(Map<String, dynamic> place) {
//     final types = List<String>.from(place['types'] as List? ?? []);
//     final name = (place['name'] as String? ?? '').toLowerCase();

//     if (types.contains('hospital') || name.contains('hospital')) {
//       return 'hospital';
//     }
//     if (name.contains('emergency') || name.contains('urgent')) {
//       return 'urgent_care';
//     }
//     if (types.contains('doctor') || name.contains('clinic')) {
//       return 'clinic';
//     }
//     return 'clinic';
//   }

//   double _calculateDistance(
//       double lat1, double lon1, double lat2, double lon2) {
//     const double earthRadius = 6371.0;
//     final double dLat = _toRad(lat2 - lat1);
//     final double dLon = _toRad(lon2 - lon1);
//     final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(_toRad(lat1)) *
//             math.cos(_toRad(lat2)) *
//             math.sin(dLon / 2) *
//             math.sin(dLon / 2);
//     final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
//     return double.parse((earthRadius * c).toStringAsFixed(1));
//   }

//   double _toRad(double degrees) => degrees * math.pi / 180.0;

//   List<NearbyFacility> _getDemoFacilities(double lat, double lng) {
//     return [
//       NearbyFacility(
//         id: 'demo_1',
//         name: 'City General Hospital',
//         type: 'hospital',
//         distanceKm: 1.2,
//         address: 'Demo Mode — Add Google Places API key for real results',
//         phone: '+1-555-0100',
//         isOpen24h: true,
//         rating: 4.2,
//         specialties: ['Emergency', 'General Medicine', 'ICU'],
//         lat: lat + 0.010,
//         lng: lng + 0.010,
//       ),
//       NearbyFacility(
//         id: 'demo_2',
//         name: 'Sunrise Family Clinic',
//         type: 'clinic',
//         distanceKm: 0.8,
//         address: 'Demo Mode — Add Google Places API key for real results',
//         phone: '+1-555-0200',
//         isOpen24h: false,
//         rating: 4.5,
//         specialties: ['General Practitioner', 'Pediatrics'],
//         lat: lat - 0.005,
//         lng: lng + 0.008,
//       ),
//       NearbyFacility(
//         id: 'demo_3',
//         name: 'Metro Urgent Care',
//         type: 'urgent_care',
//         distanceKm: 2.1,
//         address: 'Demo Mode — Add Google Places API key for real results',
//         phone: '+1-555-0300',
//         isOpen24h: false,
//         rating: 4.0,
//         specialties: ['Urgent Care', 'Walk-in'],
//         lat: lat + 0.015,
//         lng: lng - 0.010,
//       ),
//       NearbyFacility(
//         id: 'demo_4',
//         name: 'HealthFirst Medical Center',
//         type: 'hospital',
//         distanceKm: 3.4,
//         address: 'Demo Mode — Add Google Places API key for real results',
//         phone: '+1-555-0400',
//         isOpen24h: true,
//         rating: 4.7,
//         specialties: ['Cardiology', 'Neurology', 'Orthopedics'],
//         lat: lat - 0.020,
//         lng: lng + 0.015,
//       ),
//     ];
//   }
// }
