import 'dart:async';

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
  final _controller = Completer<GoogleMapController>();
  var _pos = 0;

  static const _positions = {
    "Informaticon": LatLng(46.7559, 7.6149),
    "Bahnhof": LatLng(46.7548, 7.6297),
    "Schloss": LatLng(46.7598, 7.6299),
  };
  static final Set<Marker> _markers =
  Set.from(_positions.entries.map((entry) =>
      Marker(
        markerId: MarkerId(entry.key),
        infoWindow: InfoWindow(title: entry.key),
        position: entry.value,
      )));

  @override
  Widget build(BuildContext context) {
    var firstPosition = _positions.values.first;

    return Scaffold(
      appBar: getAppBar(context),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: CameraPosition(
              target: firstPosition,
              zoom: 19,
            ),
            onMapCreated: (controller) {
              _controller.complete(controller);
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
                onPressed: _nextPos,
                child: const Text("Next"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _nextPos() async {
    _pos += 1;
    var next = CameraPosition(
      target: List.from(_positions.values)[_pos % _positions.length]!,
      zoom: 20,
    );

    final controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(next));
  }
}
