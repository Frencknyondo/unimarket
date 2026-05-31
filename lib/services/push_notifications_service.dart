import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static const _usersCollection = 'unimarket_db';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> enableNotifications(String userId) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await _messaging.getToken();
      if (token != null && userId.trim().isNotEmpty) {
        await _firestore.collection(_usersCollection).doc(userId).set({
          'fcmToken': token,
          'notificationsEnabled': true,
        }, SetOptions(merge: true));
      }

      return true;
    }

    return false;
  }

  Future<void> disableNotifications(String userId) async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    if (userId.trim().isEmpty) return;
    await _firestore.collection(_usersCollection).doc(userId).set({
      'notificationsEnabled': false,
      'fcmToken': FieldValue.delete(),
    }, SetOptions(merge: true));
  }
}
