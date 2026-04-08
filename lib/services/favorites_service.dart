import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_listing.dart';
import '../models/user_model.dart';

class FavoritesService {
  FavoritesService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'favorites';

  static String documentIdFor({
    required String userId,
    required String productId,
  }) {
    return '${userId}_$productId';
  }

  static DocumentReference<Map<String, dynamic>> favoriteDoc({
    required String userId,
    required String productId,
  }) {
    return _firestore
        .collection(_collection)
        .doc(documentIdFor(userId: userId, productId: productId));
  }

  static Stream<bool> isFavoriteStream({
    required String userId,
    required String productId,
  }) {
    return favoriteDoc(userId: userId, productId: productId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  static Query<Map<String, dynamic>> favoritesQuery(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId);
  }

  static Future<bool> toggleFavorite({
    required User user,
    required ProductListing product,
  }) async {
    final doc = favoriteDoc(userId: user.uid, productId: product.productId);
    final snapshot = await doc.get();

    if (snapshot.exists) {
      await doc.delete();
      return false;
    }

    await doc.set({
      'userId': user.uid,
      'productId': product.productId,
      'sellerId': product.sellerId,
      'sellerName': product.sellerName,
      'sellerEmail': product.sellerEmail,
      'title': product.title,
      'price': product.price,
      'currency': product.currency,
      'category': product.category,
      'location': product.location,
      'specificLocation': product.specificLocation,
      'description': product.description,
      'images': product.images,
      'video': product.video,
      'createdAt': product.createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(product.createdAt!),
      'savedAt': FieldValue.serverTimestamp(),
    });

    return true;
  }
}
