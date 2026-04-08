import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/product_listing.dart';
import '../models/user_model.dart';
import '../student/listing_details.dart';

enum _ListingFilter { all, active, sold }

class MyListingsPage extends StatefulWidget {
  final User user;

  const MyListingsPage({super.key, required this.user});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  _ListingFilter _filter = _ListingFilter.all;

  @override
  Widget build(BuildContext context) {
    final listingsStream = FirebaseFirestore.instance
        .collection('listings')
        .where('sellerId', isEqualTo: widget.user.uid)
        .snapshots();
    final soldOrdersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('sellerId', isEqualTo: widget.user.uid)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Listings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: listingsStream,
        builder: (context, listingsSnapshot) {
          if (listingsSnapshot.hasError) {
            return const Center(child: Text('Failed to load your listings.'));
          }

          if (listingsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allListings = (listingsSnapshot.data?.docs ?? const [])
              .map((doc) {
                final data = <String, dynamic>{
                  ...doc.data(),
                  'productId': (doc.data()['productId'] as String?) ?? doc.id,
                };
                try {
                  return ProductListing.fromMap(data);
                } catch (_) {
                  return null;
                }
              })
              .whereType<ProductListing>()
              .toList()
            ..sort((a, b) {
              final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: soldOrdersStream,
            builder: (context, ordersSnapshot) {
              final soldIds = (ordersSnapshot.data?.docs ?? const [])
                  .map((doc) => (doc.data()['productId'] as String?) ?? '')
                  .where((id) => id.trim().isNotEmpty)
                  .toSet();

              final activeListings = allListings
                  .where((listing) => !soldIds.contains(listing.productId))
                  .toList();
              final soldListings = allListings
                  .where((listing) => soldIds.contains(listing.productId))
                  .toList();

              final visibleListings = switch (_filter) {
                _ListingFilter.all => allListings,
                _ListingFilter.active => activeListings,
                _ListingFilter.sold => soldListings,
              };

              return Column(
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ListingFilterChip(
                            label: 'All (${allListings.length})',
                            isActive: _filter == _ListingFilter.all,
                            onTap: () {
                              setState(() {
                                _filter = _ListingFilter.all;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ListingFilterChip(
                            label: 'Active (${activeListings.length})',
                            isActive: _filter == _ListingFilter.active,
                            onTap: () {
                              setState(() {
                                _filter = _ListingFilter.active;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ListingFilterChip(
                            label: 'Sold (${soldListings.length})',
                            isActive: _filter == _ListingFilter.sold,
                            onTap: () {
                              setState(() {
                                _filter = _ListingFilter.sold;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: visibleListings.isEmpty
                        ? const Center(
                            child: Text(
                              'No listings found in this section.',
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: visibleListings.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final listing = visibleListings[index];
                              final isSold = soldIds.contains(listing.productId);
                              return _MyListingTile(
                                listing: listing,
                                currentUser: widget.user,
                                isSold: isSold,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ListingFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ListingFilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEAF4FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }
}

class _MyListingTile extends StatelessWidget {
  final ProductListing listing;
  final User currentUser;
  final bool isSold;

  const _MyListingTile({
    required this.listing,
    required this.currentUser,
    required this.isSold,
  });

  String _formatMoney(double value, String currency) {
    return '$currency${value.round()}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--/--/----';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ListingDetailsPage(
              product: listing,
              currentUser: currentUser,
            ),
          ),
        );
      },
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 90,
                height: 90,
                child: listing.primaryImage.isEmpty
                    ? Container(
                        color: const Color(0xFFE5E7EB),
                        child: const Icon(Icons.image_not_supported_outlined),
                      )
                    : Image.network(
                        listing.primaryImage,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.category.trim().isEmpty
                        ? 'Other'
                        : listing.category.trim(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSold
                          ? const Color(0xFFE8F8EC)
                          : const Color(0xFFEAF4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isSold ? 'Sold' : 'Active',
                      style: TextStyle(
                        color: isSold
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF2563EB),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatMoney(listing.price, listing.currency),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF1E88E5),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _formatDate(listing.createdAt),
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
