import 'dart:async';

import 'package:background_location/background_location.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:intl/intl.dart';
import 'package:mad_location_tracker/app_bar.dart';
import 'package:mad_location_tracker/firebase_options.dart';
import 'package:mad_location_tracker/map.dart';
import 'package:mad_location_tracker/models/activity_model.dart';
import 'package:mad_location_tracker/models/location_model.dart';
import 'package:mad_location_tracker/repos/activity_repo.dart';
import 'package:mad_location_tracker/repos/location_repo.dart';
import 'package:mad_location_tracker/widgets/activity_delete_dialog.dart';
import 'package:mad_location_tracker/widgets/activity_list.dart';
import 'package:mad_location_tracker/widgets/activity_rename_dialog.dart';
import 'package:mad_location_tracker/widgets/sign_in_form.dart';
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
  ActivityModel? _currentActivity;

  var _activities = <ActivityModel>[];

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: SignInForm(
                onSignOut: () => _signOut(context: context),
                onSignIn: () => _signInWithGoogle(context: context),
                user: _user,
              ),
            ),
            Expanded(
              child: ActivityList(
                padding: const EdgeInsets.only(bottom: 80),
                onOpen: (activity) => _showMapView(context, activity),
                onRename: (activity) => _showRenameActivityDialog(activity),
                onDelete: (activity) => _showDeleteActivityDialog(activity),
                activities: _activities,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  FloatingActionButton _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _currentActivity == null
          ? _requestNameAndStartNewActivity()
          : _showMapView(context, _currentActivity!),
      tooltip: 'Add a new activity',
      label: _currentActivity == null
          ? const Row(children: [Icon(Icons.add), Text('Activity')])
          : const Text('Resume Activity'),
    );
  }

  void _showRenameActivityDialog(ActivityModel activity) {
    showDialog(
      context: context,
      builder: (context) => ActivityRenameDialog(
        onCancel: () => Navigator.pop(context),
        onRename: (newName) {
          _updateActivity(activity.id, newName);
          Navigator.pop(context);
        },
        activity: activity,
      ),
    );
  }

  void _showDeleteActivityDialog(activity) {
    showDialog(
      context: context,
      builder: (context) => ActivityDeleteDialog(
        activity: activity,
        onCancel: () => Navigator.pop(context),
        onDelete: () {
          _deleteActivity(activity.id);
          Navigator.pop(context);
        },
      ),
    );
  }

  _onAuthStateChange(User? user) {
    setState(() => _user = user);
    _retrieveActivities();
  }

  Future<void> _onRefresh() async {
    await _retrieveActivities();
  }

  _isSignedIn() {
    return _user != null;
  }

  _startNewActivity(String activityName) async {
    if (_currentActivity == null) {
      if (FirebaseAuth.instance.currentUser == null) {
        _reportNotLoggedIn();
        return;
      }

      if (!await _requestPermissions(context: context)) {
        return;
      }
      await ActivityRepo.instance.insert(ActivityModel(
        name: activityName,
        startTime: DateTime.now().toString(),
        isActive: true,
      ));
      _currentActivity = await ActivityRepo.instance.currentlyActive();
      _logNewActivity();
    }
    if (mounted) {
      _showMapView(context, _currentActivity!);
    }
    _retrieveActivities();
  }

  _requestNameAndStartNewActivity() {
    final activityNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Activity"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewActivity(activityNameController.text);
            },
            child: const Text("Create"),
          )
        ],
        content: SingleChildScrollView(
          child: TextFormField(
            autofocus: true,
            decoration: const InputDecoration(
                hintText: 'Enter activity name',
                border: UnderlineInputBorder()),
            controller: activityNameController,
          ),
        ),
      ),
    );
  }

  _updateActivity(String activityId, String newName) async {
    ActivityRepo.instance.setName(activityId, newName);
    _retrieveActivities();
    _logRenameActivity();
  }

  _logRenameActivity() {
    FirebaseAnalytics.instance.logEvent(name: 'activity_renamed');
  }

  _deleteActivity(String activityId) async {
    ActivityRepo.instance.delete(activityId);
    _retrieveActivities();
    _logDeleteActivity();
  }

  _logDeleteActivity() {
    FirebaseAnalytics.instance.logEvent(name: 'activity_deleted');
  }

  _logNewActivity() {
    FirebaseAnalytics.instance.logEvent(name: 'new_activity_created');
  }

  _showMapView(BuildContext context, ActivityModel activity) {
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MapView(activity: activity)),
      );
    }
  }

  Future<bool> _requestPermissions({required BuildContext context}) async {
    if (!await _requestLocationPermission(context)) {
      return false;
    }
    if (!context.mounted || !await _requestNotificationPermission(context)) {
      return false;
    }

    return true;
  }

  Future<bool> _requestLocationPermission(BuildContext context) async {
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

  Future<bool> _requestNotificationPermission(BuildContext context) async {
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
      final authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = authResult.user;
      if (user != null) {
        message =
            "successfully signed in! user id: ${FirebaseAuth.instance.currentUser?.uid}";
        _logSignedIn();
      } else {
        message = "error on sign-in";
      }
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
    if (_currentActivity != null) {
      await LocationRepo.instance.insert(
          LocationModel.fromBackgroundLocation(location, _currentActivity!.id));
    }
  }

  _retrieveActivities() async {
    var activities = _isSignedIn()
        ? await ActivityRepo.instance.latestN(50)
        : <ActivityModel>[];

    setState(() {
      _activities = activities;
      _currentActivity =
          _activities.where((activity) => activity.isActive).firstOrNull;
    });

    if (!mounted) return;

    if (_currentActivity != null) {
      await _startLocationService(context: context);
    } else {
      await _stopLocationService(context: context);
    }
  }
}
