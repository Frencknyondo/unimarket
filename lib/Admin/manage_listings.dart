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

  Future<void> _editListing(ProductListing listing) async {
    final titleController = TextEditingController(text: listing.title);
    final priceController = TextEditingController(
      text: listing.price.toStringAsFixed(0),
    );
    final categoryController = TextEditingController(text: listing.category);
    final locationController = TextEditingController(text: listing.location);
    final specificLocationController = TextEditingController(
      text: listing.specificLocation,
    );
    final descriptionController = TextEditingController(
      text: listing.description,
    );
    final imageUrlsController = TextEditingController(
      text: listing.images.join('\n'),
    );
    final videoUrlController = TextEditingController(text: listing.video ?? '');
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
            Future<void> saveListing() async {
              final price = double.tryParse(priceController.text.trim());
              if (titleController.text.trim().isEmpty ||
                  categoryController.text.trim().isEmpty ||
                  locationController.text.trim().isEmpty ||
                  descriptionController.text.trim().isEmpty ||
                  price == null) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Fill all required fields')),
                );
                return;
              }

              final images = imageUrlsController.text
                  .split('\n')
                  .map((url) => url.trim())
                  .where((url) => url.isNotEmpty)
                  .toList();

              setSheetState(() => isSaving = true);
              try {
                await FirebaseFirestore.instance
                    .collection('listings')
                    .doc(listing.productId)
                    .set({
                      'title': titleController.text.trim(),
                      'title_lower': titleController.text.trim().toLowerCase(),
                      'price': price,
                      'currency': listing.currency,
                      'category': categoryController.text.trim(),
                      'location': locationController.text.trim(),
                      'specificLocation': specificLocationController.text
                          .trim(),
                      'description': descriptionController.text.trim(),
                      'imageUrls': images,
                      'images': images,
                      'videoUrl': videoUrlController.text.trim().isEmpty
                          ? null
                          : videoUrlController.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                      'keywords': _buildSearchKeywords(
                        title: titleController.text.trim(),
                        category: categoryController.text.trim(),
                        location: locationController.text.trim(),
                        specificLocation: specificLocationController.text
                            .trim(),
                      ),
                    }, SetOptions(merge: true));

                if (!mounted || !sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                await _loadListings();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Listing updated successfully')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Error updating listing: $e')),
                );
              } finally {
                if (mounted) setSheetState(() => isSaving = false);
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
                      'Edit Listing',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AdminTextField(controller: titleController, label: 'Title'),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: priceController,
                      label: 'Price',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: categoryController,
                      label: 'Category',
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: locationController,
                      label: 'Location',
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: specificLocationController,
                      label: 'Specific location',
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: descriptionController,
                      label: 'Description',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: imageUrlsController,
                      label: 'Image URLs, one per line',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: videoUrlController,
                      label: 'Video URL',
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveListing,
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
                          backgroundColor: const Color(0xFF4A3DE0),
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

    titleController.dispose();
    priceController.dispose();
    categoryController.dispose();
    locationController.dispose();
    specificLocationController.dispose();
    descriptionController.dispose();
    imageUrlsController.dispose();
    videoUrlController.dispose();
  }

  Future<void> _deleteListing(ProductListing listing) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Listing'),
            content: Text('Delete "${listing.title}" permanently?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
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
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(listing.productId)
          .delete();
      if (!mounted) return;
      setState(() {
        listings.removeWhere((item) => item.productId == listing.productId);
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

  List<String> _buildSearchKeywords({
    required String title,
    required String category,
    required String location,
    required String specificLocation,
  }) {
    final normalized = <String>{};

    void addWordAndPrefixes(String value) {
      final tokens = value
          .toLowerCase()
          .trim()
          .split(RegExp(r'[\s,.-]+'))
          .where((token) => token.isNotEmpty);

      for (final token in tokens) {
        normalized.add(token);
        for (var length = 2; length <= token.length; length++) {
          normalized.add(token.substring(0, length));
        }
      }
    }

    normalized.add(title.toLowerCase().trim());
    normalized.add(category.toLowerCase().trim());
    normalized.add(location.toLowerCase().trim());
    normalized.add(specificLocation.toLowerCase().trim());
    addWordAndPrefixes(title);
    addWordAndPrefixes(category);
    addWordAndPrefixes(location);
    addWordAndPrefixes(specificLocation);

    return normalized.toList();
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
                            'All Listings',
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
                                onDelete: () => _deleteListing(listing),
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

class _AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  const _AdminTextField({
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
          borderSide: const BorderSide(color: Color(0xFF4A3DE0), width: 1.2),
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
