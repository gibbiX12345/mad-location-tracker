import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mad_location_tracker/app_bar.dart';
import 'package:mad_location_tracker/models/location_model.dart';
import 'package:mad_location_tracker/repos/activity_repo.dart';
import 'package:mad_location_tracker/repos/location_repo.dart';

class MapView extends StatelessWidget {
  const MapView({super.key, this.activityId});

  final String? activityId;

  @override
  Widget build(BuildContext context) {
    return MapSample(activityId: activityId);
  }
}

class MapSample extends StatefulWidget {
  const MapSample({super.key, this.activityId});

  final String? activityId;

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> with WidgetsBindingObserver {
  static late Completer<GoogleMapController> _controllerCompleter;
  late GoogleMapController _controller;
  Timer? _timer;
  Set<Marker> _markers = {};

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _controllerCompleter = Completer<GoogleMapController>();
    _fetchLocations();
    _timer = Timer.periodic(
        const Duration(seconds: 15), (Timer t) => _fetchLocations());
    super.initState();
  }

  Future<void> _fetchLocations() async {
    var locations = await _getLocations();
    if (!_controllerCompleter.isCompleted) {
      _controller = await _controllerCompleter.future;
    }
    setState(() {
      _markers = Set.from(locations.map((entry) => Marker(
            markerId: MarkerId(entry.time),
            infoWindow: InfoWindow(title: entry.time),
            position: LatLng(
                double.parse(entry.latitude), double.parse(entry.longitude)),
          )));
      _setInitialCameraPosition(_controller);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _fetchLocations();
      _timer?.cancel();
      _timer = Timer.periodic(
          const Duration(seconds: 15), (Timer t) => _fetchLocations());
    }
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
              if (!_controllerCompleter.isCompleted) {
                _controllerCompleter.complete(controller);
              }
              _controller = controller;
            },
            markers: _markers,
            compassEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => _finishActivity(),
                child: const Text("Finish Activity"),
              ),
            ),
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

  Future<List<LocationModel>> _getLocations() async {
    var currentActivity = widget.activityId ?? await _getCurrentActivity();
    if (currentActivity == null) {
      return [];
    }
    return LocationRepo.instance.byActivityId(currentActivity);
  }

  Future<String?> _getCurrentActivity() async {
    return ActivityRepo.instance.currentlyActiveId();
  }

  _finishActivity() {
    _finishActivityStuff();
  }

  _finishActivityStuff() async {
    var currentActivity = await _getCurrentActivity();
    if (currentActivity != null) {
      await ActivityRepo.instance.setActive(currentActivity, false);
      _logFinishedActivity();
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  _logFinishedActivity() {
    FirebaseAnalytics.instance.logEvent(name: 'activity_finished');
  }
}
