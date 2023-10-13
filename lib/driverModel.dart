import 'package:google_maps_flutter/google_maps_flutter.dart';

class Driver {
  final String id;
  final String name;
  final LatLng location;
  String estimatedTravelTime;

  Driver(
      {required this.id,
      required this.name,
      required this.location,
      this.estimatedTravelTime = ''});
}
