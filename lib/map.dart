import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mad_location_tracker/app_bar.dart';
import 'package:mad_location_tracker/models/location_model.dart';
import 'package:mad_location_tracker/repos/activity_repo.dart';
import 'package:mad_location_tracker/repos/location_repo.dart';

class MapView extends StatelessWidget {
  const MapView({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context) {
    return MapSample(activityId: activityId);
  }
}

class MapSample extends StatefulWidget {
  const MapSample({super.key, required this.activityId});

  final String activityId;

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> with WidgetsBindingObserver {
  static late Completer<GoogleMapController> _controllerCompleter;
  late GoogleMapController _controller;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  StreamSubscription<dynamic>? _locationSubscription;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _controllerCompleter = Completer<GoogleMapController>();
    _locationSubscription = _subscribeToLocations();
    super.initState();
  }

  StreamSubscription<dynamic> _subscribeToLocations() =>
      LocationRepo.instance.listenByActivityId(
          widget.activityId, (locations) => _onUpdateLocations(locations));

  Future<void> _onUpdateLocations(List<LocationModel> locations) async {
    var lineColor = Theme.of(context).colorScheme.inversePrimary;

    _controller = await _controllerCompleter.future;

    var markers = _createMarkers(locations);

    var polylines = {
      Polyline(
        polylineId: const PolylineId("path"),
        color: lineColor,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        width: 5,
        points: locations.map((entry) => entry.toLatLng()).toList(),
      )
    };

    setState(() {
      _polylines = polylines;
      _markers = markers;
      _setInitialCameraPosition(_controller);
    });
  }

  Set<Marker> _createMarkers(List<LocationModel> locations) {
    if (locations.isEmpty) return {};
    if (locations.length == 1) return {_startMarker(locations.first)};
    return {_startMarker(locations.first), _endMarker(locations.last)};
  }

  Marker _startMarker(LocationModel start) {
    return Marker(
      markerId: const MarkerId("start"),
      position: start.toLatLng(),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );
  }

  Marker _endMarker(LocationModel start) {
    return Marker(
      markerId: const MarkerId("end"),
      position: start.toLatLng(),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel().ignore();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _locationSubscription?.cancel().ignore();
    } else if (state == AppLifecycleState.resumed) {
      _locationSubscription?.cancel().ignore();
      _locationSubscription = _subscribeToLocations();
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
            polylines: _polylines,
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
    if (_polylines.isNotEmpty) {
      LatLngBounds bounds = calculateBounds(
        _polylines.expand((polyline) => polyline.points).toList(),
      );
      moveCameraToFitBounds(controller, bounds);
    }
  }

  LatLngBounds calculateBounds(List<LatLng> markers) {
    final latitudes = markers.map((element) => element.latitude).toList();
    final longitudes = markers.map((element) => element.longitude).toList();

    final southWestLat = latitudes.reduce((a, b) => a < b ? a : b);
    final southWestLng = longitudes.reduce((a, b) => a < b ? a : b);
    final northEastLat = latitudes.reduce((a, b) => a > b ? a : b);
    final northEastLng = longitudes.reduce((a, b) => a > b ? a : b);

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
      await ActivityRepo.instance.finishActivity(currentActivity);
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
