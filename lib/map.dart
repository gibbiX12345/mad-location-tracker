import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mad_location_tracker/app_bar.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return const MapSample();
  }
}

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  static late GoogleMapController _controller;
  Timer? _timer;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  Set<Marker> _markers = {};

  @override
  void initState() {
    _fetchLocations();
    super.initState();
  }

  Future<void> _fetchLocations() async {
    var locations = await _getLocations();
    setState(() {
      _markers = Set.from(locations.map((entry) => Marker(
            markerId: MarkerId(entry['time']),
            infoWindow: InfoWindow(title: entry['time']),
            position: LatLng(double.parse(entry['latitude']),
                double.parse(entry['longitude'])),
          )));

      _setInitialCameraPosition(_controller);
    });
    _timer = Timer.periodic(const Duration(seconds: 15), (Timer t) => _fetchLocations());
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(context),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: const CameraPosition(
              target: (LatLng(46.9577191, 7.4556732)),
              zoom: 10,
            ),
            onMapCreated: (controller) {
              _controller = controller;
            },
            markers: _markers,
            compassEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
        ],
      ),
    );
  }

  void _setInitialCameraPosition(GoogleMapController controller) {
    if (_markers.isNotEmpty) {
      LatLngBounds bounds = calculateBounds(_markers);
      moveCameraToFitBounds(controller, bounds);
    }
  }

  LatLngBounds calculateBounds(Set<Marker> markers) {
    double southWestLat =
        markers.map((m) => m.position.latitude).reduce((a, b) => a < b ? a : b);
    double southWestLng = markers
        .map((m) => m.position.longitude)
        .reduce((a, b) => a < b ? a : b);
    double northEastLat =
        markers.map((m) => m.position.latitude).reduce((a, b) => a > b ? a : b);
    double northEastLng = markers
        .map((m) => m.position.longitude)
        .reduce((a, b) => a > b ? a : b);

    return LatLngBounds(
      southwest: LatLng(southWestLat, southWestLng),
      northeast: LatLng(northEastLat, northEastLng),
    );
  }

  void moveCameraToFitBounds(
      GoogleMapController controller, LatLngBounds bounds) {
    controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50)); // 50 is padding
  }

  _getLocations() async {
    var snapshot = await db
        .collection("locations")
        .where("userUid",
            isEqualTo: "${FirebaseAuth.instance.currentUser?.uid}")
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
