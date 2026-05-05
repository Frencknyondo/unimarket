import 'package:cloud_firestore/cloud_firestore.dart';

class ProductListing {
  final String productId;
  final String sellerId;
  final String sellerName;
  final String sellerEmail;
  final String title;
  final double price;
  final String currency;
  final String category;
  final String location;
  final String specificLocation;
  final String description;
  final List<String> images;
  final String? video;
  final DateTime? createdAt;

  const ProductListing({
    required this.productId,
    required this.sellerId,
    required this.sellerName,
    required this.sellerEmail,
    required this.title,
    required this.price,
    required this.currency,
    required this.category,
    required this.location,
    required this.specificLocation,
    required this.description,
    required this.images,
    required this.video,
    required this.createdAt,
  });

  String get primaryImage => images.isNotEmpty ? images.first : '';

  factory ProductListing.fromMap(Map<String, dynamic> map) {
    final imageList = map['images'] ?? map['imageUrls'];
    final timestamp = map['createdAt'];
    final rawSellerName =
        map['sellerName'] as String? ??
        map['userName'] as String? ??
        map['fullName'] as String? ??
        '';
    final sellerName = rawSellerName.trim();

    return ProductListing(
      productId: map['productId'] as String? ?? '',
      sellerId: (map['sellerId'] as String?) ?? (map['userId'] as String?) ?? '',
      sellerName: sellerName.isEmpty ? 'Unknown seller' : sellerName,
      sellerEmail: map['sellerEmail'] as String? ?? '',
      title: map['title'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'Tsh',
      category: map['category'] as String? ?? '',
      location: map['location'] as String? ?? '',
      specificLocation: map['specificLocation'] as String? ?? '',
      description: map['description'] as String? ?? '',
      images: imageList is List
          ? imageList.whereType<String>().where((item) => item.isNotEmpty).toList()
          : const [],
      video: map['video'] as String? ?? map['videoUrl'] as String?,
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
