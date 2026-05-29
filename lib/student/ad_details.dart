import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ad_model.dart';

class AdDetailsPage extends StatelessWidget {
  final AdModel ad;

  const AdDetailsPage({super.key, required this.ad});

  Future<void> _openWhatsApp(BuildContext context) async {
    final phone = ad.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is not available')),
      );
      return;
    }

    final normalized = phone.startsWith('+') ? phone.substring(1) : phone;
    final uri = Uri.parse(
      'https://wa.me/$normalized?text=${Uri.encodeComponent('Hello, I saw your ad on UniMarket: ${ad.title}')}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Ad Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ad.imageUrl.isEmpty
                  ? Container(
                      color: const Color(0xFFEAF2FF),
                      child: const Icon(
                        Icons.image_outlined,
                        color: Color(0xFF2F65FF),
                        size: 48,
                      ),
                    )
                  : Image.network(ad.imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            ad.category.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F65FF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ad.businessName.isEmpty ? ad.title : ad.businessName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            ad.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            ad.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Color(0xFF4E4E4E),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _openWhatsApp(context),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: Text(ad.ctaLabel),
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
    );
  }
}
