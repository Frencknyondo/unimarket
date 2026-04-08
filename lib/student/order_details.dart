import 'package:flutter/material.dart';

import '../message_list.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class OrderDetailsPage extends StatelessWidget {
  final User currentUser;
  final OrderModel order;
  final bool isSellerView;

  const OrderDetailsPage({
    super.key,
    required this.currentUser,
    required this.order,
    required this.isSellerView,
  });

  String _formatMoney(double amount, String currency) {
    return '$currency${amount.round()}';
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown time';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(dateTime.day)}/${two(dateTime.month)}/${dateTime.year} at ${two(dateTime.hour)}:${two(dateTime.minute)}:${two(dateTime.second)}';
  }

  String _statusTitle(String status) {
    switch (status) {
      case 'confirmed':
        return 'Order Confirmed';
      case 'completed':
        return 'Order Completed';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return 'Order Pending';
    }
  }

  String _statusSubtitle(String status) {
    switch (status) {
      case 'confirmed':
        return 'Seller confirmed your order';
      case 'completed':
        return 'Order has been completed';
      case 'cancelled':
        return 'This order was cancelled';
      default:
        return 'Waiting for seller confirmation';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'completed':
        return const Color(0xFF22C55E);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buyerName = order.buyerName.trim().isEmpty ? 'Unknown buyer' : order.buyerName.trim();
    final sellerName = order.sellerName.trim().isEmpty ? 'Unknown seller' : order.sellerName.trim();
    final personName = isSellerView ? buyerName : sellerName;
    final amount = _formatMoney(order.price, order.currency);
    final statusColor = _statusColor(order.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timelapse_rounded, color: statusColor, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusTitle(order.status),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #${order.orderId.substring(0, order.orderId.length >= 8 ? 8 : order.orderId.length)}',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusSubtitle(order.status),
                    style: const TextStyle(fontSize: 17, color: Color(0xFF4B4B4B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Payment Information', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      Text(order.paymentMethod, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(order.status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8DD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Pay the seller directly when you receive the item',
                      style: TextStyle(fontSize: 16, color: Color(0xFF6A5A1C)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Item Details', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 66,
                      height: 66,
                      child: order.primaryImage.isEmpty
                          ? Container(
                              color: const Color(0xFFE5E7EB),
                              alignment: Alignment.center,
                              child: const Icon(Icons.image_not_supported_outlined),
                            )
                          : Image.network(order.primaryImage, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.productTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                        Text(amount, style: const TextStyle(fontSize: 18, color: Color(0xFF1E88E5), fontWeight: FontWeight.w900)),
                        Text(order.category.isEmpty ? 'Other' : order.category, style: const TextStyle(color: Color(0xFF5F5F5F))),
                        const Text('Condition: new', style: TextStyle(color: Color(0xFF5F5F5F))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isSellerView ? 'Buyer Information' : 'Seller Information',
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(personName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('Contact via: ${order.contactMethod}', style: const TextStyle(fontSize: 16, color: Color(0xFF555555))),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MessageListPage()),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF3B82F6)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Order Summary', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  _SummaryRow(label: 'Item Price', value: amount),
                  const SizedBox(height: 8),
                  _SummaryRow(label: 'Delivery Fee', value: order.deliveryFeeLabel),
                  const Divider(height: 20),
                  _SummaryRow(label: 'Total Amount', value: amount, emphasize: true),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Delivery Information', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.store_mall_directory_outlined, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.deliveryOption, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          order.deliveryOption == 'Campus Pickup'
                              ? 'Arrange to meet the seller on campus'
                              : 'Delivery details will be arranged with seller',
                          style: const TextStyle(fontSize: 16, color: Color(0xFF555555)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Order Timeline', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 10, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Order Placed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(_formatDateTime(order.createdAt), style: const TextStyle(fontSize: 16, color: Color(0xFF666666))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Actions', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MessageListPage()),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: Text(isSellerView ? 'Contact Buyer' : 'Contact Seller'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F8FF),
                  foregroundColor: const Color(0xFF3B82F6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
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
              fontSize: emphasize ? 24 : 16,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
              color: const Color(0xFF555555),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 24 : 16,
            fontWeight: FontWeight.w900,
            color: emphasize ? const Color(0xFF1E88E5) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
