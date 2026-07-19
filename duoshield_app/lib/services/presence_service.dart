import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class PresenceService with WidgetsBindingObserver {
  static final PresenceService _instance = PresenceService._();
  static PresenceService get instance => _instance;

  PresenceService._();

  void init() {
    WidgetsBinding.instance.addObserver(this);
    _setOnline(true);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnline(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnline(true);
    } else if (state == AppLifecycleState.paused) {
      _setOnline(false);
    }
  }

  Future<void> _setOnline(bool online) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'online': online,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
