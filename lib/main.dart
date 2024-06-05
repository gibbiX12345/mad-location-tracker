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
  String? _currentActivityId;

  var _activities = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _user = FirebaseAuth.instance.currentUser;
    _authStateSubscription = FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) => _onAuthStateChange(user));

    _retrieveActivities();
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
      _retrieveActivities();
    }
  }

  @override
  void didPopNext() {
    _retrieveActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(context),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _isSignedIn()
                    ? Text("Signed in as ${_user?.displayName}")
                    : const Text("Not signed in"),
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
              ]),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _activityList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => {_startNewActivity(context)},
        tooltip: 'Add a new activity',
        label: _currentActivityId == null
            ? const Row(children: [Icon(Icons.add), Text('Activity')])
            : const Text('Resume Activity'),
      ),
    );
  }

  List<Widget> _activityList() {
    List<Widget> list = _activities.map((activity) {
      return ListTile(
        title: Text(activity["name"]),
        subtitle: Text(activity["time"]),
      ) as Widget;
    }).toList();
    list.add(Container(height: 80.0));
    return list;
  }

  _onAuthStateChange(User? user) {
    setState(() {
      _user = user;
    });
    _retrieveActivities();
  }

  Future<void> _onRefresh() async {
    await _retrieveActivities();
  }

  _isSignedIn() {
    return _user != null;
  }

  _startNewActivity(BuildContext context) async {
    if (_currentActivityId == null) {
      if (FirebaseAuth.instance.currentUser == null) {
        _reportNotLoggedIn();
        return;
      }

      if (!await _requestPermissions(context: context)) {
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

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MapView()),
      );
    }
    _retrieveActivities();
  }

  _logNewActivity() {
    FirebaseAnalytics.instance.logEvent(name: 'new_activity_created');
  }

  Future<bool> _requestPermissions({required BuildContext context}) async {
    if (!await _requestLocationPermission(context: context)) {
      return false;
    }
    if (!context.mounted ||
        !await _requestNotificationPermission(context: context)) {
      return false;
    }

    return true;
  }

  Future<bool> _requestLocationPermission(
      {required BuildContext context}) async {
    String message;
    Duration duration;
    if (await Permission.locationWhenInUse.shouldShowRequestRationale) {
      message = "You've already denied Location Access...";
      duration = const Duration(seconds: 3);
    } else {
      var status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        return true;
      }
      message = "Location Access denied";
      duration = const Duration(seconds: 2);
    }

    if (context.mounted) {
      var snackBar = SnackBar(
        content: Text(message),
        duration: duration,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    return false;
  }

  _reportNotLoggedIn() {
    if (context.mounted) {
      var snackBar = const SnackBar(
        content: Text("You're not signed in."),
        duration: Duration(seconds: 3),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<bool> _requestNotificationPermission(
      {required BuildContext context}) async {
    String message;
    Duration duration;
    if (await Permission.notification.shouldShowRequestRationale) {
      message = "You've already denied Notification Access...";
      duration = const Duration(seconds: 3);
    } else {
      var status = await Permission.notification.request();
      if (status.isGranted) {
        return true;
      }
      message = "Notification Permission denied";
      duration = const Duration(seconds: 2);
    }

    if (context.mounted) {
      var snackBar = SnackBar(
        content: Text(message),
        duration: duration,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    return false;
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
      "activityUid": _currentActivityId
    };
    db.collection("locations").add(locationMap);
  }

  _retrieveActivities() async {
    if (!_isSignedIn()) {
      setState(() {
        _currentActivityId = null;
        _activities = [];
      });
      return;
    }

    var db = FirebaseFirestore.instance;
    var snapshot = await db
        .collection("activities")
        .where("userUid",
            isEqualTo: "${FirebaseAuth.instance.currentUser?.uid}")
        .orderBy("time", descending: true)
        .limit(50)
        .get();

    var activities = snapshot.docs;
    setState(() {
      _activities = activities.map((activity) {
        return {
          "id": activity.id,
          "name": activity["name"],
          "time": activity["time"],
          "isActive": activity["isActive"]
        };
      }).toList();

      _currentActivityId =
          activities.where((activity) => activity["isActive"]).firstOrNull?.id;
    });

    if (!mounted) return;

    if (activities.isNotEmpty) {
      await _startLocationService(context: context);
    } else {
      await _stopLocationService(context: context);
    }
  }
}
