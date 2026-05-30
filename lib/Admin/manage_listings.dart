import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/product_listing.dart';

class ManageListingsPage extends StatefulWidget {
  const ManageListingsPage({super.key});

  @override
  State<ManageListingsPage> createState() => _ManageListingsPageState();
}

class _ManageListingsPageState extends State<ManageListingsPage> {
  List<ProductListing> listings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    try {
      setState(() => isLoading = true);

      final listingsSnap = await FirebaseFirestore.instance
          .collection('listings')
          .get();

      final fetchedListings = listingsSnap.docs.map((doc) {
        final data = doc.data();
        data['productId'] = doc.id;
        return ProductListing.fromMap(data);
      }).toList();

      if (!mounted) return;
      setState(() {
        listings = fetchedListings;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading listings: $e')));
      setState(() => isLoading = false);
    }
  }

  void _editListing(ProductListing listing) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit: ${listing.title}')));
  }

  void _deleteListing(String id) async {
    try {
      await FirebaseFirestore.instance.collection('listings').doc(id).delete();
      if (!mounted) return;
      setState(() {
        listings.removeWhere((item) => item.productId == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting listing: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Marketplace - Manage Listings',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: listings.isEmpty
                  ? const Center(child: Text('No listings available'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Listings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: listings.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final listing = listings[index];
                              return _ListingCard(
                                listing: listing,
                                onEdit: () => _editListing(listing),
                                onDelete: () =>
                                    _deleteListing(listing.productId),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final ProductListing listing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ListingCard({
    required this.listing,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEBFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: listing.primaryImage.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        listing.primaryImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.image_rounded,
                              color: Color(0xFF4A3DE0),
                            ),
                      ),
                    )
                  : const Icon(Icons.image_rounded, color: Color(0xFF4A3DE0)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          '${listing.currency} ${listing.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A3DE0),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          listing.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Color(0xFF4A3DE0)),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
