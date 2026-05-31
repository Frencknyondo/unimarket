import 'package:cloud_firestore/cloud_firestore.dart';

class FCMPushService {
  static const String _usersCollection = 'unimarket_db';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sends a push notification to a user via their saved FCM token.
  /// This method calls a Cloud Function on the backend to handle the actual sending.
  Future<bool> sendPushToUser({
    required String userId,
    required String title,
    required String message,
    Map<String, String>? data,
  }) async {
    try {
      if (userId.trim().isEmpty) return false;

      // Retrieve the user's FCM token from Firestore
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId.trim())
          .get();

      if (!userDoc.exists) return false;

      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) return false;

      final notificationsEnabled =
          userDoc.data()?['notificationsEnabled'] == true;
      if (!notificationsEnabled) return false;

      // In a real app, you would call a Cloud Function here to send the push
      // For now, we create a push_queue document that a Cloud Function can listen to
      await _createPushQueue(
        userId: userId,
        fcmToken: fcmToken,
        title: title,
        message: message,
        data: data,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sends push notifications to multiple users.
  Future<void> sendPushToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, String>? data,
  }) async {
    try {
      final cleanUserIds = userIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (cleanUserIds.isEmpty) return;

      for (final userId in cleanUserIds) {
        await sendPushToUser(
          userId: userId,
          title: title,
          message: message,
          data: data,
        );
      }
    } catch (e) {
      return;
    }
  }

  /// Internal method: Creates a push queue document for a Cloud Function to process
  Future<void> _createPushQueue({
    required String userId,
    required String fcmToken,
    required String title,
    required String message,
    Map<String, String>? data,
  }) async {
    await _firestore.collection('push_queue').add({
      'userId': userId,
      'fcmToken': fcmToken,
      'title': title,
      'message': message,
      'data': data ?? {},
      'createdAt': FieldValue.serverTimestamp(),
      'sent': false,
      'error': null,
    });
  }
}
