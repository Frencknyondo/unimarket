import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/cloudinary_service.dart';
import '../services/notifications_service.dart';

class AdsPage extends StatefulWidget {
  final User user;

  const AdsPage({super.key, required this.user});

  @override
  State<AdsPage> createState() => _AdsPageState();
}

class _AdsPageState extends State<AdsPage> {
  final _notificationsService = NotificationsService();
  final _businessController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _durationController = TextEditingController(text: '7');
  String _category = 'Food / Drinks';
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;
  static const _adsCollection = 'ads';

  static const _ctaByCategory = {
    'Food / Drinks': 'Order Now',
    'Studies / Tuition': 'Book Time',
    'Barber / Salon': 'Book Appointment',
    'Repairs (PC, Phone)': 'Contact Them',
    'Rentals': 'Request Rental',
    'Products for Sale': 'Buy Now',
    'Other': 'View More',
  };

  @override
  void dispose() {
    _businessController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final url = kIsWeb
          ? await CloudinaryService.uploadImageBytes(
              bytes: await image.readAsBytes(),
              filename: image.name,
            )
          : await CloudinaryService.uploadImageFromPath(File(image.path).path);

      if (!mounted) return;
      setState(() => _imageUrl = url);
      await _showAlert(
        title: url == null ? 'Upload Failed' : 'Image Uploaded',
        message: url == null
            ? 'The image did not upload to Cloudinary. Please try another image or check your internet.'
            : 'The image has been uploaded to Cloudinary and the URL is ready for Firebase.',
        isSuccess: url != null,
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _showAlert({
    required String title,
    required String message,
    bool isSuccess = false,
  }) async {
    if (!mounted) return;

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

  Future<void> _showSubmittedDialog({
    required String businessName,
    required String adId,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E)),
              SizedBox(width: 10),
              Text('Banner Sent'),
            ],
          ),
          content: Text(
            '$businessName has been submitted for admin approval.\n\nCollection: $_adsCollection\nDocument ID: $adId',
          ),
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

  Future<void> _submit() async {
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    final businessName = _businessController.text.trim();
    final adTitle = _titleController.text.trim();
    if (_businessController.text.trim().isEmpty ||
        _titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _imageUrl == null ||
        duration < 1) {
      await _showAlert(
        title: 'Complete Details',
        message:
            'Please fill all banner details, upload an image, and enter valid duration days.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final adRef = await FirebaseFirestore.instance
          .collection(_adsCollection)
          .add({
        'providerId': widget.user.uid,
        'providerName': widget.user.fullName.trim(),
        'businessName': businessName,
        'title': adTitle,
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'category': _category,
        'ctaLabel': _ctaByCategory[_category] ?? 'View More',
        'imageUrl': _imageUrl!,
        'cloudinaryUrl': _imageUrl!,
        'imageProvider': 'cloudinary',
        'durationDays': duration,
        'status': 'pending',
        'rejectionReason': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      try {
        await _notificationsService.createNotificationsForUsers(
          userIds: const ['system_admin'],
          title: 'New banner ad submitted',
          message:
              '${widget.user.fullName.trim()} submitted "$businessName" for approval.',
          type: 'ad_submitted',
          orderId: adRef.id,
        );

        await _notificationsService.createNotification(
          userId: widget.user.uid,
          title: 'Banner submitted',
          message:
              'Your banner "$businessName" has been sent to admin for approval.',
          type: 'ad_submitted',
          orderId: adRef.id,
        );
      } catch (_) {
        // The ad is already saved. Notification delivery should not block submission.
      }

      if (!mounted) return;
      _businessController.clear();
      _titleController.clear();
      _descriptionController.clear();
      _phoneController.clear();
      _durationController.text = '7';
      setState(() => _imageUrl = null);
      await _showSubmittedDialog(businessName: businessName, adId: adRef.id);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      await _showAlert(
        title: 'Submit Failed',
        message:
            'Firebase could not save the banner to the $_adsCollection collection.\n\n${e.message ?? e.code}',
      );
    } catch (e) {
      if (!mounted) return;
      await _showAlert(
        title: 'Submit Failed',
        message: 'The banner was not saved. Please try again.\n\n$e',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cta = _ctaByCategory[_category] ?? 'View More';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Ads', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Banner Preview',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _AdPreview(
            category: _category,
            title: _businessController.text.trim().isEmpty
                ? 'Business Name'
                : _businessController.text.trim(),
            subtitle: _titleController.text.trim().isEmpty
                ? 'Your tagline will appear here'
                : _titleController.text.trim(),
            cta: cta,
            imageUrl: _imageUrl,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _businessController,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration('Business name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration('Short ad title / tagline'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: _inputDecoration('Description'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('WhatsApp phone number'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: _inputDecoration('Category'),
            items: _ctaByCategory.keys
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _category = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('How many days should it run?'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickImage,
            icon: Icon(_isUploading ? Icons.hourglass_top : Icons.image_outlined),
            label: Text(_imageUrl == null ? 'Upload Banner Image' : 'Change Image'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F65FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(_isSubmitting ? 'Submitting...' : 'Submit for Approval'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdPreview extends StatelessWidget {
  final String category;
  final String title;
  final String subtitle;
  final String cta;
  final String? imageUrl;

  const _AdPreview({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164,
      decoration: BoxDecoration(
        color: const Color(0xFF2458D8),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            Image.network(imageUrl!, fit: BoxFit.cover)
          else
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 38),
                child: Icon(Icons.image_outlined, color: Colors.white54, size: 42),
              ),
            ),
          if (imageUrl == null) Container(color: const Color(0xCC2458D8)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    cta,
                    style: const TextStyle(
                      color: Color(0xFF2458D8),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            right: 14,
            top: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x5520247C),
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'AD',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
