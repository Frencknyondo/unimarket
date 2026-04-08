import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String buyerId;
  final String buyerName;
  final String buyerEmail;
  final String sellerId;
  final String sellerName;
  final String sellerEmail;
  final String productId;
  final String productTitle;
  final String category;
  final String primaryImage;
  final List<String> images;
  final double price;
  final String currency;
  final String paymentMethod;
  final String deliveryOption;
  final String deliveryFeeLabel;
  final String contactMethod;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    required this.buyerEmail,
    required this.sellerId,
    required this.sellerName,
    required this.sellerEmail,
    required this.productId,
    required this.productTitle,
    required this.category,
    required this.primaryImage,
    required this.images,
    required this.price,
    required this.currency,
    required this.paymentMethod,
    required this.deliveryOption,
    required this.deliveryFeeLabel,
    required this.contactMethod,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final created = map['createdAt'];
    final updated = map['updatedAt'];
    final rawImages = map['images'];
    final images = rawImages is List
        ? rawImages
              .whereType<String>()
              .where((item) => item.trim().isNotEmpty)
              .toList()
        : const <String>[];

    final primary = (map['primaryImage'] as String?)?.trim() ?? '';

    return OrderModel(
      orderId: (map['orderId'] as String?) ?? '',
      buyerId: (map['buyerId'] as String?) ?? '',
      buyerName: (map['buyerName'] as String?) ?? '',
      buyerEmail: (map['buyerEmail'] as String?) ?? '',
      sellerId: (map['sellerId'] as String?) ?? '',
      sellerName: (map['sellerName'] as String?) ?? '',
      sellerEmail: (map['sellerEmail'] as String?) ?? '',
      productId: (map['productId'] as String?) ?? '',
      productTitle: (map['productTitle'] as String?) ?? '',
      category: (map['category'] as String?) ?? '',
      primaryImage: primary.isNotEmpty ? primary : (images.isNotEmpty ? images.first : ''),
      images: images,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      currency: (map['currency'] as String?)?.trim().isNotEmpty == true
          ? (map['currency'] as String)
          : 'Tsh',
      paymentMethod: (map['paymentMethod'] as String?) ?? 'Cash on Delivery',
      deliveryOption: (map['deliveryOption'] as String?) ?? 'Campus Pickup',
      deliveryFeeLabel: (map['deliveryFeeLabel'] as String?) ?? 'Free',
      contactMethod: (map['contactMethod'] as String?) ?? 'WhatsApp',
      status: ((map['status'] as String?) ?? 'pending').toLowerCase(),
      createdAt: created is Timestamp ? created.toDate() : null,
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }
}
