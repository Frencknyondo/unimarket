import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final String id;
  final String providerId;
  final String providerName;
  final String businessName;
  final String title;
  final String description;
  final String category;
  final String ctaLabel;
  final String phone;
  final String imageUrl;
  final int durationDays;
  final String status;
  final String rejectionReason;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? expiresAt;

  const AdModel({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.businessName,
    required this.title,
    required this.description,
    required this.category,
    required this.ctaLabel,
    required this.phone,
    required this.imageUrl,
    required this.durationDays,
    required this.status,
    required this.rejectionReason,
    required this.createdAt,
    required this.approvedAt,
    required this.expiresAt,
  });

  factory AdModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    DateTime? dateFrom(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return AdModel(
      id: doc.id,
      providerId: (data['providerId'] as String?)?.trim() ?? '',
      providerName: (data['providerName'] as String?)?.trim() ?? '',
      businessName: (data['businessName'] as String?)?.trim() ?? '',
      title: (data['title'] as String?)?.trim() ?? '',
      description: (data['description'] as String?)?.trim() ?? '',
      category: (data['category'] as String?)?.trim() ?? 'Other',
      ctaLabel: (data['ctaLabel'] as String?)?.trim() ?? 'View More',
      phone: (data['phone'] as String?)?.trim() ?? '',
      imageUrl: (data['imageUrl'] as String?)?.trim() ?? '',
      durationDays: (data['durationDays'] as num?)?.toInt() ?? 1,
      status: ((data['status'] as String?) ?? 'pending').trim().toLowerCase(),
      rejectionReason: (data['rejectionReason'] as String?)?.trim() ?? '',
      createdAt: dateFrom(data['createdAt']),
      approvedAt: dateFrom(data['approvedAt']),
      expiresAt: dateFrom(data['expiresAt']),
    );
  }

  bool get isActive {
    final expiry = expiresAt;
    return status == 'approved' &&
        (expiry == null || expiry.isAfter(DateTime.now()));
  }
}
