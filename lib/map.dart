import 'package:flutter/material.dart';
import 'package:mad_location_tracker/app_bar.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(context),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'map view',
            )
          ],
        ),
      ),
    );
  }
}
