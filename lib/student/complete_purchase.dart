import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/product_listing.dart';
import '../models/user_model.dart';
import 'my_purchases.dart';

enum _DeliveryOption { campusPickup, delivery }
enum _ContactMethod { whatsapp, inApp }

class CompletePurchasePage extends StatefulWidget {
  final ProductListing product;
  final User currentUser;

  const CompletePurchasePage({
    super.key,
    required this.product,
    required this.currentUser,
  });

  @override
  State<CompletePurchasePage> createState() => _CompletePurchasePageState();
}

class _CompletePurchasePageState extends State<CompletePurchasePage> {
  _DeliveryOption _selectedDelivery = _DeliveryOption.campusPickup;
  _ContactMethod _selectedContact = _ContactMethod.whatsapp;
  bool _agreeTerms = false;
  bool _isSubmitting = false;

  String _formatTsh(double value) => 'Tsh${value.round()}';

  Future<void> _confirmPurchase() async {
    if (_isSubmitting || !_agreeTerms) return;
    setState(() => _isSubmitting = true);

    final product = widget.product;
    final buyer = widget.currentUser;
    final deliveryOption =
        _selectedDelivery == _DeliveryOption.campusPickup ? 'Campus Pickup' : 'Delivery';
    final deliveryFeeLabel =
        _selectedDelivery == _DeliveryOption.campusPickup ? 'Free' : 'By seller';
    final contactMethod =
        _selectedContact == _ContactMethod.whatsapp ? 'WhatsApp' : 'In-App Messaging';

    try {
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      await orderRef.set({
        'orderId': orderRef.id,
        'productId': product.productId,
        'productTitle': product.title.trim(),
        'category': product.category.trim(),
        'productDescription': product.description.trim(),
        'location': product.location.trim(),
        'specificLocation': product.specificLocation.trim(),
        'video': product.video,
        'primaryImage': product.primaryImage,
        'images': product.images,
        'price': product.price,
        'currency': 'Tsh',
        'buyerId': buyer.uid,
        'buyerName': buyer.fullName.trim(),
        'buyerEmail': buyer.email.trim().toLowerCase(),
        'sellerId': product.sellerId,
        'sellerName': product.sellerName.trim(),
        'sellerEmail': product.sellerEmail.trim().toLowerCase(),
        'paymentMethod': 'Cash on Delivery',
        'deliveryOption': deliveryOption,
        'deliveryFeeLabel': deliveryFeeLabel,
        'contactMethod': contactMethod,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MyPurchasesPage(user: buyer)),
        (route) => route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase request submitted successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit purchase request.')),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final itemPrice = _formatTsh(product.price);
    final confirmEnabled = _agreeTerms && !_isSubmitting;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Complete Purchase',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Item Summary', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: product.images.isEmpty
                              ? Container(
                                  color: const Color(0xFFE6E6E6),
                                  child: const Icon(Icons.image_not_supported_outlined),
                                )
                              : Image.network(product.images.first, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(itemPrice, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E88E5))),
                            const SizedBox(height: 2),
                            Text(
                              product.sellerName.trim().isEmpty ? 'Unknown seller' : product.sellerName.trim(),
                              style: const TextStyle(fontSize: 16, color: Color(0xFF696969)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text('Delivery Option', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _OptionCard(
                        title: 'Campus Pickup',
                        subtitle: 'Arrange to meet the seller on campus',
                        footer: 'Free',
                        icon: Icons.store_mall_directory_outlined,
                        selected: _selectedDelivery == _DeliveryOption.campusPickup,
                        onTap: () => setState(() => _selectedDelivery = _DeliveryOption.campusPickup),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OptionCard(
                        title: 'Delivery',
                        subtitle: 'Get it delivered to your location',
                        footer: 'Determined by seller',
                        icon: Icons.local_shipping_outlined,
                        selected: _selectedDelivery == _DeliveryOption.delivery,
                        onTap: () => setState(() => _selectedDelivery = _DeliveryOption.delivery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text('Payment Method', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _OptionCard(
                  title: 'Pay with Cash',
                  subtitle: 'Pay the seller directly when you receive the item',
                  footer: '',
                  icon: Icons.payments_outlined,
                  selected: true,
                  onTap: () {},
                ),
                const SizedBox(height: 22),
                const Text('Contact Method', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _ChoiceTile(
                  title: 'WhatsApp',
                  icon: Icons.chat_bubble_outline_rounded,
                  selected: _selectedContact == _ContactMethod.whatsapp,
                  onTap: () => setState(() => _selectedContact = _ContactMethod.whatsapp),
                ),
                const SizedBox(height: 10),
                _ChoiceTile(
                  title: 'In-App Messaging',
                  icon: Icons.message_outlined,
                  selected: _selectedContact == _ContactMethod.inApp,
                  onTap: () => setState(() => _selectedContact = _ContactMethod.inApp),
                ),
                const SizedBox(height: 22),
                const Text('Order Summary', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _SummaryRow(label: 'Item Price', value: itemPrice),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: 'Delivery Fee',
                        value: _selectedDelivery == _DeliveryOption.campusPickup ? 'Free' : 'By seller',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      _SummaryRow(label: 'Total Amount', value: itemPrice, emphasize: true),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreeTerms,
                          onChanged: (value) => setState(() => _agreeTerms = value ?? false),
                          activeColor: const Color(0xFF2F65FF),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'I agree to the Terms & Conditions and understand that this initiates a purchase request.',
                            style: TextStyle(fontSize: 15, color: Color(0xFF4E4E4E), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: confirmEnabled ? _confirmPurchase : null,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.lock_outline_rounded),
                      label: Text('Confirm Purchase - $itemPrice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmEnabled ? const Color(0xFF2F65FF) : const Color(0xFFD0D0D0),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD0D0D0),
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Secure transaction • Your order is protected',
                    style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String footer;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? const Color(0xFF2F65FF) : const Color(0xFFE5E5E5);
    final bgColor = selected ? const Color(0xFFF1F6FF) : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF5A5A5A)),
                const Spacer(),
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? const Color(0xFF2F65FF) : const Color(0xFFBDBDBD),
                  size: 19,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.35),
            ),
            if (footer.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                footer,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1E88E5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF2F65FF) : const Color(0xFFE5E5E5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? const Color(0xFF2F65FF) : const Color(0xFF6D6D6D)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? const Color(0xFF2ECC71) : const Color(0xFFBDBDBD),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 18 : 16,
              color: const Color(0xFF5C5C5C),
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 18 : 16,
            fontWeight: FontWeight.w900,
            color: emphasize ? const Color(0xFF1E88E5) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
