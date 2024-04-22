import 'package:flutter/material.dart';


class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocationTracker - Map',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
        useMaterial3: true,
      ),
      home: const MapView(title: 'LocationTracker'),
    );
  }
}

class MapView extends StatelessWidget {
  const MapView({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Center(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold))),
      ),
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
