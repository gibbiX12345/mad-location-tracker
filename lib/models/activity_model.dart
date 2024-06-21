import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ActivityModel {
  String id;
  String name;
  String startTime;
  String endTime = "";
  String userUid;
  bool isActive;

  ActivityModel(
      {required this.name,
      required this.startTime,
      required this.isActive,
      FirebaseAuth? auth})
      : id = "",
        userUid = (auth ?? FirebaseAuth.instance).currentUser!.uid;

  ActivityModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc)
      : id = doc.id,
        name = doc["name"],
        startTime = doc["startTime"],
        endTime = doc["endTime"],
        userUid = doc["userUid"],
        isActive = doc["isActive"];

  Map<String, dynamic> data() => <String, dynamic>{
    "name": name,
    "startTime": startTime,
    "endTime": endTime,
    "userUid": userUid,
    "isActive": isActive,
  };

  String readableStartTime() {
    if (startTime == "") return "-";
    var dateTime = DateTime.parse(startTime);
    return DateFormat.Hm().format(dateTime);
  }

  String readableEndTime() {
    if (endTime == "") return "-";
    var dateTime = DateTime.parse(endTime);
    return DateFormat.Hm().format(dateTime);
  }

  Duration duration() {
    if (startTime == "") return Duration.zero;
    var calcEnd = endTime;
    if (calcEnd == "") {
      calcEnd = DateTime.now().toString();
    }
    var startDateTime = DateTime.parse(startTime);
    var endDateTime = DateTime.parse(calcEnd);
    return endDateTime.difference(startDateTime);
  }
}
