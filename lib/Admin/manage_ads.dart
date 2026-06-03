import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/ad_model.dart';
import '../services/notifications_service.dart';
import '../student/ad_details.dart';

class ManageAdsPage extends StatelessWidget {
  const ManageAdsPage({super.key});

  static const _ctaByCategory = {
    'Food / Drinks': 'Order Now',
    'Studies / Tuition': 'Book Time',
    'Barber / Salon': 'Book Appointment',
    'Repairs (PC, Phone)': 'Contact Them',
    'Rentals': 'Request Rental',
    'Products for Sale': 'Buy Now',
    'Other': 'View More',
  };

  Future<void> _showAlert(
    BuildContext context, {
    required String title,
    required String message,
    bool isSuccess = false,
  }) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Icon(
                isSuccess
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: isSuccess
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F65FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    AdModel ad,
    String status, {
    String rejectionReason = '',
  }) async {
    final notificationsService = NotificationsService();
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'approved') {
      final now = DateTime.now();
      data['approvedAt'] = FieldValue.serverTimestamp();
      data['expiresAt'] = Timestamp.fromDate(
        now.add(Duration(days: ad.durationDays)),
      );
      data['rejectionReason'] = '';
    } else {
      data['rejectionReason'] = rejectionReason.trim();
    }

    try {
      await FirebaseFirestore.instance
          .collection('ads')
          .doc(ad.id)
          .set(data, SetOptions(merge: true));

      try {
        await notificationsService.createNotification(
          userId: ad.providerId,
          title: status == 'approved' ? 'Banner approved' : 'Banner rejected',
          message: status == 'approved'
              ? 'Your banner "${ad.businessName}" has been approved and is now live.'
              : 'Your banner "${ad.businessName}" was rejected. Reason: ${rejectionReason.trim()}',
          type: status == 'approved' ? 'ad_approved' : 'ad_rejected',
          orderId: ad.id,
        );
      } catch (_) {
        // Status is already saved. Notification delivery should not block admin action.
      }

      if (!context.mounted) return;
      await _showAlert(
        context,
        title: status == 'approved' ? 'Banner Approved' : 'Banner Rejected',
        message: status == 'approved'
            ? '"${ad.businessName}" is now live on the home banner.'
            : '"${ad.businessName}" has been rejected with reason: ${rejectionReason.trim()}',
        isSuccess: true,
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      await _showAlert(
        context,
        title: 'Action Failed',
        message:
            'Firebase could not update this banner in the ads collection.\n\n${e.message ?? e.code}',
      );
    } catch (e) {
      if (!context.mounted) return;
      await _showAlert(
        context,
        title: 'Action Failed',
        message: 'The banner status was not updated.\n\n$e',
      );
    }
  }

  Future<void> _showRejectDialog(BuildContext context, AdModel ad) async {
    final reasonController = TextEditingController(text: ad.rejectionReason);

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject Banner'),
          content: TextField(
            controller: reasonController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Write rejection reason',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) return;
                Navigator.of(dialogContext).pop(reason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();
    if (reason == null || reason.trim().isEmpty) return;
    if (!context.mounted) return;
    await _updateStatus(
      context,
      ad,
      'rejected',
      rejectionReason: reason.trim(),
    );
  }

  Future<void> _editAd(BuildContext context, AdModel ad) async {
    final businessController = TextEditingController(text: ad.businessName);
    final titleController = TextEditingController(text: ad.title);
    final descriptionController = TextEditingController(text: ad.description);
    final phoneController = TextEditingController(text: ad.phone);
    final imageController = TextEditingController(text: ad.imageUrl);
    final durationController = TextEditingController(
      text: ad.durationDays.toString(),
    );
    var selectedCategory = _ctaByCategory.containsKey(ad.category)
        ? ad.category
        : 'Other';
    var selectedStatus = ad.status;
    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> saveAd() async {
              final duration = int.tryParse(durationController.text.trim());
              if (businessController.text.trim().isEmpty ||
                  titleController.text.trim().isEmpty ||
                  descriptionController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty ||
                  imageController.text.trim().isEmpty ||
                  duration == null ||
                  duration < 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fill all required fields')),
                );
                return;
              }

              final data = <String, dynamic>{
                'businessName': businessController.text.trim(),
                'title': titleController.text.trim(),
                'description': descriptionController.text.trim(),
                'phone': phoneController.text.trim(),
                'category': selectedCategory,
                'ctaLabel': _ctaByCategory[selectedCategory] ?? 'View More',
                'imageUrl': imageController.text.trim(),
                'cloudinaryUrl': imageController.text.trim(),
                'durationDays': duration,
                'status': selectedStatus,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              if (selectedStatus == 'approved') {
                data['approvedAt'] = ad.approvedAt == null
                    ? FieldValue.serverTimestamp()
                    : Timestamp.fromDate(ad.approvedAt!);
                data['expiresAt'] = Timestamp.fromDate(
                  DateTime.now().add(Duration(days: duration)),
                );
                data['rejectionReason'] = '';
              }

              setSheetState(() => isSaving = true);
              try {
                await FirebaseFirestore.instance
                    .collection('ads')
                    .doc(ad.id)
                    .set(data, SetOptions(merge: true));

                if (!context.mounted) return;
                Navigator.of(sheetContext).pop();
                await _showAlert(
                  context,
                  title: 'Banner Updated',
                  message: '"${businessController.text.trim()}" was updated successfully.',
                  isSuccess: true,
                );
              } catch (e) {
                if (!context.mounted) return;
                await _showAlert(
                  context,
                  title: 'Update Failed',
                  message: 'The banner was not updated.\n\n$e',
                );
              } finally {
                if (context.mounted) setSheetState(() => isSaving = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Banner',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AdminAdField(
                      controller: businessController,
                      label: 'Business name',
                    ),
                    const SizedBox(height: 12),
                    _AdminAdField(controller: titleController, label: 'Title'),
                    const SizedBox(height: 12),
                    _AdminAdField(
                      controller: descriptionController,
                      label: 'Description',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    _AdminAdField(controller: phoneController, label: 'Phone'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: _dialogDecoration('Category'),
                      items: _ctaByCategory.keys
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => selectedCategory = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: _dialogDecoration('Status'),
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => selectedStatus = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _AdminAdField(
                      controller: durationController,
                      label: 'Duration days',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _AdminAdField(
                      controller: imageController,
                      label: 'Image URL',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveAd,
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(isSaving ? 'Saving...' : 'Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F65FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    businessController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    imageController.dispose();
    durationController.dispose();
  }

  Future<void> _deleteAd(BuildContext context, AdModel ad) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Banner'),
            content: Text('Delete "${ad.businessName}" permanently?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    try {
      await FirebaseFirestore.instance.collection('ads').doc(ad.id).delete();
      if (!context.mounted) return;
      await _showAlert(
        context,
        title: 'Banner Deleted',
        message: '"${ad.businessName}" was deleted successfully.',
        isSuccess: true,
      );
    } catch (e) {
      if (!context.mounted) return;
      await _showAlert(
        context,
        title: 'Delete Failed',
        message: 'The banner was not deleted.\n\n$e',
      );
    }
  }

  InputDecoration _dialogDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2F65FF), width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Ads Management',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('ads')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final ads = (snapshot.data?.docs ?? const [])
              .map((doc) => AdModel.fromFirestore(doc))
              .toList();

          if (ads.isEmpty) {
            return const Center(child: Text('No ads submitted yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ads.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ad = ads[index];
              return _AdminAdCard(
                ad: ad,
                onView: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AdDetailsPage(ad: ad)),
                  );
                },
                onApprove: () => _updateStatus(context, ad, 'approved'),
                onReject: () => _showRejectDialog(context, ad),
                onEdit: () => _editAd(context, ad),
                onDelete: () => _deleteAd(context, ad),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminAdCard extends StatelessWidget {
  final AdModel ad;
  final VoidCallback onView;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminAdCard({
    required this.ad,
    required this.onView,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (ad.status) {
      'approved' => const Color(0xFF22C55E),
      'rejected' => const Color(0xFFEF4444),
      _ => const Color(0xFFF59E0B),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 86,
                  height: 64,
                  child: ad.imageUrl.isEmpty
                      ? Container(
                          color: const Color(0xFFEAF2FF),
                          child: const Icon(Icons.image_outlined),
                        )
                      : Image.network(ad.imageUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      ad.category,
                      style: const TextStyle(color: Color(0xFF666666)),
                    ),
                    Text(
                      ad.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ad.status == 'rejected' && ad.rejectionReason.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reason: ${ad.rejectionReason}',
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_rounded, size: 17),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 17),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.block_rounded, size: 17),
                  label: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_rounded, size: 17),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F65FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminAdField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  const _AdminAdField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2F65FF), width: 1.2),
        ),
      ),
    );
  }
}
