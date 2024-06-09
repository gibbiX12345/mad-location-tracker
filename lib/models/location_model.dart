import 'package:background_location/background_location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationModel {
  String latitude;
  String longitude;
  String altitude;
  String accuracy;
  String bearing;
  String speed;
  String time;
  String userUid;
  String activityUid;

  LocationModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc)
      : latitude = doc["latitude"],
        longitude = doc["longitude"],
        altitude = doc["altitude"],
        accuracy = doc["accuracy"],
        bearing = doc["bearing"],
        speed = doc["speed"],
        time = doc["time"],
        userUid = doc["userUid"],
        activityUid = doc["activityUid"];

  LocationModel.fromBackgroundLocation(Location location, this.activityUid,
      {User? user})
      : latitude = location.latitude.toString(),
        longitude = location.longitude.toString(),
        altitude = location.altitude.toString(),
        accuracy = location.accuracy.toString(),
        bearing = location.bearing.toString(),
        speed = location.speed.toString(),
        time = DateTime.fromMillisecondsSinceEpoch(location.time!.toInt())
            .toString(),
        userUid = (user ?? FirebaseAuth.instance.currentUser!).uid;

  Map<String, dynamic> data() => <String, dynamic>{
        "latitude": latitude,
        "longitude": longitude,
        "altitude": altitude,
        "accuracy": accuracy,
        "bearing": bearing,
        "speed": speed,
        "time": time,
        "userUid": userUid,
        "activityUid": activityUid,
      };
}
