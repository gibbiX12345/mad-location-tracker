import 'package:background_location/background_location.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mad_location_tracker/app_bar.dart';
import 'package:mad_location_tracker/firebase_options.dart';
import 'package:mad_location_tracker/map.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required by FlutterConfig
  await FlutterConfig.loadEnvVariables();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
                  _requestPermissions(context: context);
                },
                child: const Text("Request Permissions")),
            ElevatedButton(
                onPressed: () {
                  _signInWithGoogle(context: context);
                },
                child: const Text("Sign in with Google")),
            ElevatedButton(
                onPressed: () {
                  _startLocationService(context: context);
                },
                child: const Text("Start Location-Service")),
            ElevatedButton(
                onPressed: () {
                  _stopLocationService(context: context);
                },
                child: const Text("Stop Location-Service"))
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

  _requestPermissions({required BuildContext context}) async {
    await _requestLocationPermission(context: context);
    await _requestNotificationPermission(context: context);
  }

  _requestLocationPermission({required BuildContext context}) async {
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
  
  _requestNotificationPermission({required BuildContext context}) async {
    String message;
    Duration duration;
    if (await Permission.notification.shouldShowRequestRationale) {
      message = "You've already denied Notification Access...";
      duration = const Duration(seconds: 2);
    } else {
      var status = await Permission.notification.request();
      message = status.isGranted
          ? "Notification Permission granted"
          : "Notification Permission denied";
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

  _signInWithGoogle({required BuildContext context}) async {
    var message = "";
    if (FirebaseAuth.instance.currentUser != null) {
      message =
          "already signed in! user id: ${FirebaseAuth.instance.currentUser?.uid}";
    } else {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Sign in
      await FirebaseAuth.instance
          .signInWithCredential(credential)
          .then((authResult) {
        final user = authResult.user;
        if (user != null) {
          message =
              "successfully signed in! user id: ${FirebaseAuth.instance.currentUser?.uid}";
        } else {
          message = "error on sign-in";
        }
      });
    }

    if (context.mounted) {
      var snackBar = SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  _startLocationService({required BuildContext context}) async {
    await BackgroundLocation.setAndroidNotification(
      title: 'Background service is running',
      message: 'Background location in progress',
      icon: '@mipmap/ic_launcher',
    );
    await BackgroundLocation.setAndroidConfiguration(30000);
    await BackgroundLocation.startLocationService(distanceFilter: 0);
    BackgroundLocation.getLocationUpdates((location) {
      var latitude = location.latitude.toString();
      var longitude = location.longitude.toString();
      var accuracy = location.accuracy.toString();
      var altitude = location.altitude.toString();
      var bearing = location.bearing.toString();
      var speed = location.speed.toString();
      var time = DateTime.fromMillisecondsSinceEpoch(location.time!.toInt())
          .toString();

      var message = '''\n
                        Latitude:  $latitude
                        Longitude: $longitude
                        Altitude: $altitude
                        Accuracy: $accuracy
                        Bearing:  $bearing
                        Speed: $speed
                        Time: $time
                      ''';
      if (context.mounted) {
        var snackBar = SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });
  }

  _stopLocationService({required BuildContext context}) async {
    BackgroundLocation.stopLocationService();
  }
}
