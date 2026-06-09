import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

class PresenceStatus {
  final bool isOnline;
  final DateTime? lastSeen;

  PresenceStatus({required this.isOnline, this.lastSeen});
}

class PresenceService {
  PresenceService._internal();
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  DatabaseReference? _statusRef;
  StreamSubscription<DatabaseEvent>? _connectedSubscription;

  Future<void> initializePresence(String userId) async {
    if (userId.trim().isEmpty) return;

    final statusRef = _database.ref('status/$userId');
    _statusRef = statusRef;
    final connectedRef = _database.ref('.info/connected');

    await _connectedSubscription?.cancel();
    _connectedSubscription = connectedRef.onValue.listen((event) {
      final isConnected = event.snapshot.value == true;
      if (!isConnected) return;

      statusRef.onDisconnect().set({
        'state': 'offline',
        'lastSeen': ServerValue.timestamp,
      });

      statusRef.set({'state': 'online', 'lastSeen': ServerValue.timestamp});
    });
  }

  Future<void> setOnline() async {
    if (_statusRef == null) return;
    await _statusRef!.set({
      'state': 'online',
      'lastSeen': ServerValue.timestamp,
    });
  }

  Future<void> setOffline() async {
    if (_statusRef == null) return;
    await _statusRef!.set({
      'state': 'offline',
      'lastSeen': ServerValue.timestamp,
    });
  }

  Stream<PresenceStatus?> statusStream(String userId) {
    if (userId.trim().isEmpty) return const Stream.empty();

    final statusRef = _database.ref('status/$userId');
    return statusRef.onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null) return null;
      if (raw is! Map<Object?, Object?>) return null;

      final state = raw['state'] as String?;
      final lastSeenRaw = raw['lastSeen'];
      final lastSeen = lastSeenRaw is int
          ? DateTime.fromMillisecondsSinceEpoch(lastSeenRaw)
          : null;

      return PresenceStatus(isOnline: state == 'online', lastSeen: lastSeen);
    });
  }

  Future<void> dispose() async {
    await _connectedSubscription?.cancel();
    _connectedSubscription = null;
    _statusRef = null;
  }
}
