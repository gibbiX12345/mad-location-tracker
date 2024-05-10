import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:mad_location_tracker/app_bar.dart';
import 'package:mad_location_tracker/map.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required by FlutterConfig
  await FlutterConfig.loadEnvVariables();
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'List main view',
            ),
            ElevatedButton(
                onPressed: () {
                  _askForLocationPermissions(context: context);
                },
                child: const Text("Ask for Location Permissions"))
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

  _askForLocationPermissions({required BuildContext context}) async {
    String message;
    Duration duration;
    if (await Permission.locationWhenInUse.shouldShowRequestRationale) {
      message = "You've already denied Location Access...";
      duration = const Duration(seconds: 2);
    } else {
      var status = await Permission.locationWhenInUse.request();
      message = status.isGranted
          ? "Location Access granted"
          : "Location Access denied";
      duration = const Duration(seconds: 1);
    }

    if (context.mounted) {
      var snackBar = SnackBar(
        content: Text(message),
        duration: duration,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}
