import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../message_list.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import 'order_details.dart';

enum _OrderFilter { all, pending, confirmed, completed }

class MyPurchasesPage extends StatelessWidget {
  final User user;

  const MyPurchasesPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return OrdersListPage(title: 'My Purchases', user: user, buyerView: true);
  }
}

class OrdersListPage extends StatefulWidget {
  final String title;
  final User user;
  final bool buyerView;

  const OrdersListPage({
    super.key,
    required this.title,
    required this.user,
    required this.buyerView,
  });

  @override
  State<OrdersListPage> createState() => _OrdersListBaseState();
}

class _OrdersListBaseState extends State<OrdersListPage> {
  _OrderFilter _filter = _OrderFilter.all;

  Color _statusBg(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFFEAF4FF);
      case 'completed':
        return const Color(0xFFE8F8EC);
      case 'cancelled':
        return const Color(0xFFFDECEC);
      default:
        return const Color(0xFFFFF7DC);
    }
  }

  Color _statusText(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'completed':
        return const Color(0xFF22C55E);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFCA8A04);
    }
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Pending';
    return '${status[0].toUpperCase()}${status.substring(1)}';
  }

  String _formatMoney(double amount, String currency) {
    return '$currency${amount.round()}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--/--/----';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  List<OrderModel> _applyFilter(List<OrderModel> input) {
    switch (_filter) {
      case _OrderFilter.pending:
        return input.where((o) => o.status == 'pending').toList();
      case _OrderFilter.confirmed:
        return input.where((o) => o.status == 'confirmed').toList();
      case _OrderFilter.completed:
        return input.where((o) => o.status == 'completed').toList();
      case _OrderFilter.all:
        return input;
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.buyerView
        ? FirebaseFirestore.instance
              .collection('orders')
              .where('buyerId', isEqualTo: widget.user.uid)
        : FirebaseFirestore.instance
              .collection('orders')
              .where('sellerId', isEqualTo: widget.user.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (!widget.buyerView)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                ),
                label: const Text('Wallet'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('All', _OrderFilter.all),
                _filterChip('Pending', _OrderFilter.pending),
                _filterChip('Confirmed', _OrderFilter.confirmed),
                _filterChip('Completed', _OrderFilter.completed),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Failed to load orders: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? const [];

                final orders = docs
                    .map((doc) {
                      final data = {'orderId': doc.id, ...doc.data()};
                      try {
                        return OrderModel.fromMap(data);
                      } catch (e) {
                        return null;
                      }
                    })
                    .where((order) => order != null)
                    .map((order) => order!)
                    .toList();

                orders.sort((a, b) {
                  final aDate =
                      a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bDate =
                      b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bDate.compareTo(aDate);
                });

                final filtered = _applyFilter(orders);

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      widget.buyerView
                          ? 'No purchase orders found. Make a purchase to see them here.'
                          : 'No sales orders found.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    final orderNo = order.orderId.substring(
                      0,
                      order.orderId.length >= 8 ? 8 : order.orderId.length,
                    );
                    final secondName = widget.buyerView
                        ? order.sellerName
                        : order.buyerName;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.timelapse_rounded,
                                color: Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.buyerView ? 'Purchase' : 'Sale'} #$orderNo',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusBg(order.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _statusLabel(order.status),
                                  style: TextStyle(
                                    color: _statusText(order.status),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 58,
                                  height: 58,
                                  child: order.primaryImage.isEmpty
                                      ? Container(
                                          color: const Color(0xFFE5E7EB),
                                          child: const Icon(
                                            Icons.image_not_supported_outlined,
                                          ),
                                        )
                                      : Image.network(
                                          order.primaryImage,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.productTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      _formatMoney(order.price, order.currency),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF1E88E5),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      '${widget.buyerView ? 'Seller' : 'Buyer'}: $secondName',
                                      style: const TextStyle(
                                        color: Color(0xFF555555),
                                      ),
                                    ),
                                    Text(
                                      _formatDate(order.createdAt),
                                      style: const TextStyle(
                                        color: Color(0xFF777777),
                                      ),
                                    ),
                                    Text(
                                      'Payment: ${order.paymentMethod}',
                                      style: const TextStyle(
                                        color: Color(0xFF666666),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MessageListPage(
                                          currentUser: widget.user,
                                          initialPeer: User(
                                            uid: widget.buyerView
                                                ? order.sellerId
                                                : order.buyerId,
                                            registrationNo: '',
                                            email: widget.buyerView
                                                ? order.sellerEmail
                                                : order.buyerEmail,
                                            fullName: widget.buyerView
                                                ? order.sellerName
                                                : order.buyerName,
                                            password: '',
                                            role: widget.buyerView
                                                ? 'provider'
                                                : 'student',
                                            createdAt: DateTime.now(),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    widget.buyerView
                                        ? 'Message Seller'
                                        : 'Message Buyer',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => OrderDetailsPage(
                                          currentUser: widget.user,
                                          order: order,
                                          isSellerView: !widget.buyerView,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.remove_red_eye_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('View Details'),
                                ),
                              ),
                              if (!widget.buyerView) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () => _showUpdateStatus(order),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Update Status'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemCount: filtered.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateStatus(OrderModel order) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final orderNo = order.orderId.substring(
          0,
          order.orderId.length >= 8 ? 8 : order.orderId.length,
        );
        final maxHeight = MediaQuery.of(context).size.height * 0.75;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Order Status',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Order #$orderNo',
                    style: const TextStyle(color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 12),
                  _statusOption(order, 'pending'),
                  _statusOption(order, 'confirmed'),
                  _statusOption(order, 'completed'),
                  _statusOption(order, 'cancelled'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusOption(OrderModel order, String status) {
    final isSelected = order.status == status;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(order.orderId)
              .update({
                'status': status,
                'updatedAt': FieldValue.serverTimestamp(),
              });
          if (!mounted) return;
          Navigator.of(context).pop();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEAF4FF)
                : const Color(0xFFF6F7F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 10),
              Text(
                '${status[0].toUpperCase()}${status.substring(1)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, _OrderFilter value) {
    final active = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: active,
        onSelected: (_) {
          setState(() {
            _filter = value;
          });
        },
        label: Text(label),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: active ? const Color(0xFF2563EB) : const Color(0xFF555555),
        ),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFEAF4FF),
      ),
    );
  }
}
