import 'dart:async';

import 'package:background_location/background_location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
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
      navigatorObservers: [routeObserver],
    );
  }
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class ListView extends StatefulWidget {
  const ListView({super.key, required this.title});

  final String title;

  @override
  State<ListView> createState() => _ListViewState();
}

class _ListViewState extends State<ListView>
    with WidgetsBindingObserver, RouteAware {
  late StreamSubscription<User?> _authStateSubscription;
  User? _user;
  var _currentActivity = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _authStateSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
      });
    });

    _retrieveCurrentActivity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _retrieveCurrentActivity();
    }
  }

  @override
  void didPopNext() {
    _retrieveCurrentActivity();
  }

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
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _isSignedIn()
                  ? Text("Signed in as ${_user?.displayName}")
                  : const Text("Not signed in"),
            ),
            ElevatedButton(
                onPressed: () {
                  if (_isSignedIn()) {
                    _signOut(context: context);
                  } else {
                    _signInWithGoogle(context: context);
                  }
                },
                child: _isSignedIn()
                    ? const Text("Sign out")
                    : const Text("Sign in with Google")),
            // ElevatedButton(
            //     onPressed: () {
            //       _startLocationService(context: context);
            //     },
            //     child: const Text("Start Location-Service")),
            // ElevatedButton(
            //     onPressed: () {
            //       _stopLocationService(context: context);
            //     },
            //     child: const Text("Stop Location-Service"))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => {_startNewActivity(context)},
        tooltip: 'Add a new activity',
        label: _currentActivity == ""
            ? const Row(children: [Icon(Icons.add), Text('Activity')])
            : const Text('Resume Activity'),
      ),
    );
  }

  _isSignedIn() {
    return _user != null;
  }

  _startNewActivity(BuildContext context) async {
    if (_currentActivity == "") {
      if (FirebaseAuth.instance.currentUser == null) {
        _reportNotLoggedIn();
        return;
      }
      var db = FirebaseFirestore.instance;
      var activityMap = <String, dynamic>{
        "name": "My Activity",
        "isActive": true,
        "time": DateTime.now().toString(),
        "userUid": FirebaseAuth.instance.currentUser?.uid
      };
      db.collection("activities").add(activityMap);
      _logNewActivity();
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapView()),
    );
    _retrieveCurrentActivity();
  }

  _logNewActivity() {
    FirebaseAnalytics.instance.logEvent(name: 'new_activity_created');
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

  _reportNotLoggedIn() {
    if (context.mounted) {
      var snackBar = const SnackBar(
        content: Text("You're not logged in."),
        duration: Duration(seconds: 3),
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

  _signOut({required BuildContext context}) async {
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }

    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      var snackBar = const SnackBar(
        content: Text("Signed out"),
        duration: Duration(seconds: 1),
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
          _logSignedIn();
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

  _logSignedIn() {
    FirebaseAnalytics.instance.logSignUp(signUpMethod: 'Google');
  }

  _startLocationService({required BuildContext context}) async {
    await BackgroundLocation.setAndroidNotification(
      title: 'Background service is running',
      message: 'Background location in progress',
      icon: '@mipmap/ic_launcher',
    );
    var wasRunning = await BackgroundLocation.isServiceRunning();
    await BackgroundLocation.setAndroidConfiguration(30000);
    await BackgroundLocation.stopLocationService();
    await BackgroundLocation.startLocationService(distanceFilter: 0);
    BackgroundLocation.getLocationUpdates((location) {
      _saveNewLocation(location);
    });

    if (context.mounted && !wasRunning) {
      var snackBar = const SnackBar(
        content: Text("Location Service started"),
        duration: Duration(seconds: 1),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  _stopLocationService({required BuildContext context}) async {
    var wasRunning = await BackgroundLocation.isServiceRunning();
    await BackgroundLocation.stopLocationService();

    if (context.mounted && wasRunning) {
      var snackBar = const SnackBar(
        content: Text("Location Service stopped"),
        duration: Duration(seconds: 1),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  _saveNewLocation(Location location) async {
    var db = FirebaseFirestore.instance;
    var locationMap = <String, dynamic>{
      "latitude": location.latitude.toString(),
      "longitude": location.longitude.toString(),
      "altitude": location.altitude.toString(),
      "accuracy": location.accuracy.toString(),
      "bearing": location.bearing.toString(),
      "speed": location.speed.toString(),
      "time": DateTime.fromMillisecondsSinceEpoch(location.time!.toInt())
          .toString(),
      "userUid": FirebaseAuth.instance.currentUser?.uid,
      "activityUid": _currentActivity
    };
    db.collection("locations").add(locationMap);
  }

  _retrieveCurrentActivity() async {
    var db = FirebaseFirestore.instance;
    var snapshot = await db
        .collection("activities")
        .where("userUid",
            isEqualTo: "${FirebaseAuth.instance.currentUser?.uid}")
        .where("isActive", isEqualTo: true)
        .get();

    var activities = snapshot.docs;
    setState(() {
      if (activities.isNotEmpty) {
        _currentActivity = activities.first.id;
        _startLocationService(context: context);
      } else {
        _currentActivity = "";
        _stopLocationService(context: context);
      }
    });
  }
}
