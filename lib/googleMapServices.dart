import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

class GoogleMapsServices {
  // String dropoffAPIKey = 'AIzaSyBaXpJ2zz_aelMDtgyfAVP9Xsb9e9MxRIA';

  // Future<LatLng?> getLatLngDropOffLocation(String dropoffLoc) async {
  //   const apiUrl = 'http://localhost:3000/getdropofflocationlatandlng';
  //   final Map<String, dynamic> requestBody = {
  //     'input': dropoffLoc,
  //     'apikey': dropoffAPIKey,
  //   };

  //   final response = await http.post(
  //     Uri.parse(apiUrl),
  //     headers: <String, String>{
  //       'Content-Type': 'application/json',
  //     },
  //     body: jsonEncode(requestBody),
  //   );

  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic> data = json.decode(response.body);
  //     final results = data['results'] as List<dynamic>;
  //     if (results.isNotEmpty) {
  //       final location = results[0]['geometry']['location'];
  //       final lat = location['lat'];
  //       final lng = location['lng'];
  //       print(lat);
  //       print(lng);
  //       return LatLng(lat, lng);
  //     }
  //   } else {
  //     throw Exception('Failed to fetch latitude and longitude');
  //   }
  //   return null;
  // }

  LatLngBounds getBoundsForMarkers(Set<Marker> markers) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final marker in markers) {
      final position = marker.position;
      minLat = math.min(minLat, position.latitude);
      maxLat = math.max(maxLat, position.latitude);
      minLng = math.min(minLng, position.longitude);
      maxLng = math.max(maxLng, position.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
