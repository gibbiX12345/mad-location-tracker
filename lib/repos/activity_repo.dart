import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/activity_model.dart';

class ActivityRepo {
  static ActivityRepo? _instance;

  final FirebaseAuth _auth;
  final CollectionReference<Map<String, dynamic>> _collection;

  ActivityRepo({required FirebaseAuth auth, required FirebaseFirestore db})
      : _auth = auth,
        _collection = db.collection("activities");

  Future<List<ActivityModel>> latestN(int n) async {
    var snapshot = await _collection
        .where("userUid", isEqualTo: "${_auth.currentUser?.uid}")
        .orderBy("startTime", descending: true)
        .limit(n)
        .get();

    return snapshot.docs.map((doc) => ActivityModel.fromDoc(doc)).toList();
  }

  Future<String?> currentlyActiveId() async {
    var snapshot = await _collection
        .where("userUid", isEqualTo: "${_auth.currentUser?.uid}")
        .where("isActive", isEqualTo: true)
        .limit(1)
        .get();
    return snapshot.docs.firstOrNull?.id;
  }

  Future<String> insert(ActivityModel activityModel) async {
    var ref = await _collection.add(activityModel.data());
    return ref.id;
  }

  Future<void> finishActivity(String id) async {
    await _collection
        .doc(id)
        .update({"endTime": DateTime.now().toString(), "isActive": false});
  }

  Future<void> setName(String id, String name) async {
    await _collection.doc(id).update({"name": name});
  }

  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  static ActivityRepo get instance => _instance ??=
      ActivityRepo(auth: FirebaseAuth.instance, db: FirebaseFirestore.instance);
}
