import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityModel {
  String id;
  String name;
  String startTime;
  String endTime = "";
  String userUid;
  bool isActive;

  ActivityModel(
      required this.startTime,
      required this.time,
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
    "time": time,
    "userUid": userUid,
    "isActive": isActive,
  };
}
