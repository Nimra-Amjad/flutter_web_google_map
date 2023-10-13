import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:nexus_googlemap/driverModel.dart';
import 'package:nexus_googlemap/googleMapServices.dart';

class GoogleMaps extends StatefulWidget {
  const GoogleMaps({super.key});

  @override
  State<GoogleMaps> createState() => _GoogleMapsState();
}

class _GoogleMapsState extends State<GoogleMaps> {
  final TextEditingController pickupLocationController =
      TextEditingController();
  final TextEditingController dropoffLocationController =
      TextEditingController();
  bool _showDropoffPlacesContainer = false;
  bool _showPickUpPlacesContainer = false;
  LatLng? pickupLocation;
  LatLng? dropoffLocation;
  List<dynamic> _placesList = [];
  String pickupAPIKey = 'AIzaSyDtDERmAeC1z18cOj0b5qiJWIxu9jKSkQ4';
  String dropoffAPIKey = 'AIzaSyBaXpJ2zz_aelMDtgyfAVP9Xsb9e9MxRIA';
  GoogleMapController? mapController;
  GoogleMapController? newGoogleMapController;
  final Set<Marker> _pickupLocationMarkers = <Marker>{};
  final Set<Marker> _dropoffLocationMarkers = <Marker>{};
  final Set<Marker> _markers = <Marker>{};
  final Set<Marker> _driverLocationMarkers = <Marker>{};

  @override
  void initState() {
    super.initState();
    fetchAvailableDrivers();
  }

  Driver convertToDriver(Map<String, dynamic> driverJson) {
    final String id = driverJson['_id'];
    final String name = driverJson['driverName'];
    final double latitude = double.parse(driverJson['latitude']);
    final double longitude = double.parse(driverJson['longitude']);
    final LatLng location = LatLng(latitude, longitude);

    return Driver(id: id, name: name, location: location);
  }

  List<Driver> drivers = [];
  List<dynamic> availableDrivers = [];
  List<String> availableDriversName = [];
  String? selectedDriver = "";

  void fetchAvailableDrivers() async {
    try {
      final response = await http
          .get(Uri.parse("http://95.111.254.11:3000/api/driversLocation"));
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        availableDrivers.clear();
        availableDriversName.clear();

        for (var driverJson in jsonResponse) {
          if (driverJson['isLoggedIn'] == true) {
            final Driver driver = convertToDriver(driverJson);
            final String username = driverJson['driverName'];

            availableDrivers.add(driver);
            availableDriversName.add(username);
            final double latitude = double.parse(driverJson['latitude']);
            final double longitude = double.parse(driverJson['longitude']);
            print("Adding marker for driver: $latitude, $longitude");
            addDriverMarkers();
          }
        }
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error fetching driver data: $e');
    }
  }

  void addDriverMarkers() async {
    for (final driver in availableDrivers) {
      _driverLocationMarkers.add(
        Marker(
          markerId: MarkerId(driver.id),
          position: driver.location,
          icon: await BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(
              devicePixelRatio: 5.5,
              size: Size(25, 25),
            ),
            'assets/driver_marker.png',
          ),
          infoWindow: InfoWindow(
            title: driver.name,
          ),
        ),
      );
    }
    _markers.addAll(_driverLocationMarkers);

    final bounds =
        GoogleMapsServices().getBoundsForMarkers(_driverLocationMarkers);
    newGoogleMapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );

    if (mounted) {
      setState(() {});
    }
  }

  getSuggestion(String pickupLocation) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/autocomplete-places'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'input': pickupLocation,
        'apikey': pickupAPIKey,
      }),
    );
    if (response.statusCode == 200) {
      setState(() {
        _placesList = json.decode(response.body)['predictions'];
      });
    } else {
      throw Exception('Failed to load autocomplete predictions');
    }
  }

  Future<void> getDropOffLatLngLocation(String dropoffLoc) async {
    const apiUrl = 'http://localhost:3000/getlatandlng';
    final Map<String, dynamic> requestBody = {
      'input': dropoffLoc,
      'apikey': dropoffAPIKey,
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final results = data['results'] as List<dynamic>;
      if (results.isNotEmpty) {
        final location = results[0]['geometry']['location'];
        final lat = location['lat'];
        final lng = location['lng'];
        print(lat);
        print(lng);
        final locationLatLng = LatLng(lat, lng);
        await addDropOffMarker(locationLatLng, dropoffLoc);
      }
    } else {
      throw Exception('Failed to fetch latitude and longitude');
    }
  }

  Future<void> getPickUpLatLngLocation(String pickUpLoc) async {
    const apiUrl = 'http://localhost:3000/getlatandlng';
    final Map<String, dynamic> requestBody = {
      'input': pickUpLoc,
      'apikey': pickupAPIKey,
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final results = data['results'] as List<dynamic>;
      if (results.isNotEmpty) {
        final location = results[0]['geometry']['location'];
        final lat = location['lat'];
        final lng = location['lng'];
        print(lat);
        print(lng);
        final locationLatLng = LatLng(lat, lng);
        await addPickupMarker(locationLatLng, pickUpLoc);
      }
    } else {
      throw Exception('Failed to fetch latitude and longitude');
    }
  }

  Future<void> addPickupMarker(LatLng location, String pickupLoc) async {
    _pickupLocationMarkers.clear();
    if (location != null) {
      _pickupLocationMarkers.add(
        Marker(
            markerId: MarkerId(pickupLoc),
            position: location,
            icon: await BitmapDescriptor.fromAssetImage(
              const ImageConfiguration(
                devicePixelRatio: 5.5,
                size: Size(25, 40),
              ),
              'assets/red_marker.png',
            )),
      );

      // You can also move the camera to the pickup location if needed
      mapController?.animateCamera(
        CameraUpdate.newLatLng(location),
      );
      _markers.addAll(_pickupLocationMarkers);
    }
  }

  Future<void> addDropOffMarker(LatLng location, String dropOffLoc) async {
    _markers.clear(); // Clear existing markers
    if (location != null) {
      _dropoffLocationMarkers.add(
        Marker(
            markerId: MarkerId(dropOffLoc),
            position: location,
            icon: await BitmapDescriptor.fromAssetImage(
              const ImageConfiguration(
                devicePixelRatio: 5.5,
                size: Size(25, 35),
              ),
              'assets/green_marker.png',
            )),
      );
      _markers.addAll(_dropoffLocationMarkers);
      // You can also move the camera to the pickup location if needed
      mapController?.animateCamera(
        CameraUpdate.newLatLng(location),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    LatLng initialCameraPosition = const LatLng(24.860966, 66.990501);
    return Scaffold(
        body: Row(
      children: [
        SizedBox(
          width: 400,
          child: Column(
            children: [
              TextFormField(
                controller: pickupLocationController,
                decoration: const InputDecoration(
                  hintText: "Pickup Location",
                  labelText: "Pickup Location",
                ),
                onChanged: (value) {
                  if (pickupLocationController.text.length > 2) {
                    getSuggestion(pickupLocationController.text);
                    _showPickUpPlacesContainer = true;
                  }
                },
              ),
              Visibility(
                visible: _showPickUpPlacesContainer && _placesList.length > 2,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.225,
                  width: MediaQuery.of(context).size.width * 0.3,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: ListView.builder(
                    itemCount: _placesList.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          ListTile(
                              onTap: () async {
                                pickupLocationController.text =
                                    _placesList[index]['description'];
                                getPickUpLatLngLocation(_placesList[index]
                                    ['structured_formatting']['main_text']);
                                setState(() {
                                  _showPickUpPlacesContainer = false;
                                });
                                // await _addMarkerForDropoffLocation(
                                //   _placesList[index]['description'],
                                //   _placesList[index]
                                //       ['structured_formatting']['main_text'],
                                // );
                              },
                              title: Text(
                                  _placesList[index]['structured_formatting']
                                      ['main_text'],
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.0085,
                                  ))),
                          Container(
                            color: Colors.grey,
                            width: MediaQuery.of(context).size.width * 0.325,
                            height: MediaQuery.of(context).size.height * 0.0025,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: dropoffLocationController,
                decoration: const InputDecoration(
                  hintText: "Dropoff Location",
                  labelText: "Dropoff Location",
                ),
                onChanged: (value) {
                  if (dropoffLocationController.text.length > 2) {
                    getSuggestion(dropoffLocationController.text);
                    _showDropoffPlacesContainer = true;
                  }
                },
              ),
              Visibility(
                visible: _showDropoffPlacesContainer && _placesList.length > 2,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.225,
                  width: MediaQuery.of(context).size.width * 0.3,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: ListView.builder(
                    itemCount: _placesList.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          ListTile(
                              onTap: () async {
                                dropoffLocationController.text =
                                    _placesList[index]['description'];
                                getDropOffLatLngLocation(_placesList[index]
                                    ['structured_formatting']['main_text']);
                                setState(() {
                                  _showDropoffPlacesContainer = false;
                                });
                                // await _addMarkerForDropoffLocation(
                                //   _placesList[index]['description'],
                                //   _placesList[index]
                                //       ['structured_formatting']['main_text'],
                                // );
                              },
                              title: Text(
                                  _placesList[index]['structured_formatting']
                                      ['main_text'],
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.0085,
                                  ))),
                          Container(
                            color: Colors.grey,
                            width: MediaQuery.of(context).size.width * 0.325,
                            height: MediaQuery.of(context).size.height * 0.0025,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 800,
          child: GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: initialCameraPosition,
              zoom: 11,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              mapController = controller;
            },
          ),
        ),
      ],
    ));
  }
}
