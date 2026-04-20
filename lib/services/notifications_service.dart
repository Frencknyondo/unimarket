import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String orderId;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.orderId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];

    return AppNotification(
      id: doc.id,
      userId: (data['userId'] as String?)?.trim() ?? '',
      title: (data['title'] as String?)?.trim() ?? 'Notification',
      message: (data['message'] as String?)?.trim() ?? '',
      type: (data['type'] as String?)?.trim() ?? 'general',
      orderId: (data['orderId'] as String?)?.trim() ?? '',
      isRead: data['isRead'] == true,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

class NotificationsService {
  NotificationsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _notificationsCollection = 'notifications';

  Stream<List<AppNotification>> notificationsStream(String userId) {
    if (userId.trim().isEmpty) return Stream.value(const <AppNotification>[]);

    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId.trim())
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => AppNotification.fromFirestore(doc))
              .toList();
          notifications.sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
          return notifications;
        });
  }

  Stream<int> unreadCountStream(String userId) {
    return notificationsStream(userId).map(
      (items) => items.where((item) => !item.isRead).length,
    );
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    String orderId = '',
  }) async {
    if (userId.trim().isEmpty) return;

    await _firestore.collection(_notificationsCollection).add({
      'userId': userId.trim(),
      'title': title.trim(),
      'message': message.trim(),
      'type': type.trim().isEmpty ? 'general' : type.trim(),
      'orderId': orderId.trim(),
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAsRead(String notificationId) async {
    if (notificationId.trim().isEmpty) return;

    await _firestore.collection(_notificationsCollection).doc(notificationId).set(
      {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> markAllAsRead(String userId) async {
    if (userId.trim().isEmpty) return;

    final snapshot = await _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId.trim())
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.set(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
