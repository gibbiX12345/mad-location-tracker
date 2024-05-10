import 'package:flutter/material.dart';
import 'package:mad_location_tracker/app_bar.dart';
import 'package:mad_location_tracker/map.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocationTracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
        useMaterial3: true,
      ),
      home: const ListView(title: 'LocationTracker'),
    );
  }
}

class ListView extends StatelessWidget {
  const ListView({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(context),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'List main view',
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapView()),
          )
        },
        tooltip: 'Add a new activity',
        label: const Row(children: [Icon(Icons.add), Text('Activity')]),
      ),
    );
  }
}
