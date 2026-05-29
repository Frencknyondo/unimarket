import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/ad_model.dart';
import '../services/notifications_service.dart';
import '../student/ad_details.dart';

class ManageAdsPage extends StatelessWidget {
  const ManageAdsPage({super.key});

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
      data['expiresAt'] = Timestamp.fromDate(now.add(Duration(days: ad.durationDays)));
      data['rejectionReason'] = '';
    } else {
      data['rejectionReason'] = rejectionReason.trim();
    }

    try {
      await FirebaseFirestore.instance.collection('ads').doc(ad.id).set(
        data,
        SetOptions(merge: true),
      );

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
          style: TextStyle(fontWeight: FontWeight.w800),
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

  const _AdminAdCard({
    required this.ad,
    required this.onView,
    required this.onApprove,
    required this.onReject,
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
                child: OutlinedButton(
                  onPressed: onView,
                  child: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F65FF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
