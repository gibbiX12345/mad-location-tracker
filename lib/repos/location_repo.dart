import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/location_model.dart';

class LocationRepo {
  static LocationRepo? _instance;

  final FirebaseAuth _auth;
  final CollectionReference<Map<String, dynamic>> _collection;

  LocationRepo({required FirebaseAuth auth, required FirebaseFirestore db})
      : _auth = auth,
        _collection = db.collection("locations");

  Future<void> insert(LocationModel locationModel) async {
    await _collection.add(locationModel.data());
  }

  Future<List<LocationModel>> byActivityId(String activityUid) async {
    var snapshot = await _collection
        .where("userUid", isEqualTo: _auth.currentUser?.uid)
        .where("activityUid", isEqualTo: activityUid)
        .orderBy("time", descending: false)
        .get();
    return snapshot.docs.map(LocationModel.fromDoc).toList();
  }

  StreamSubscription<dynamic> listenByActivityId(
    String activityUid,
    void Function(List<LocationModel> locations) onData,
  ) {
    return _collection
        .where("userUid", isEqualTo: _auth.currentUser?.uid)
        .where("activityUid", isEqualTo: activityUid)
        .orderBy("time", descending: false)
        .snapshots()
        .listen((change) => onData(
            change.docs.map(LocationModel.fromDoc).toList()));
  }

  static LocationRepo get instance => _instance ??=
      LocationRepo(auth: FirebaseAuth.instance, db: FirebaseFirestore.instance);
}
