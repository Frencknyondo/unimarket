import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_model.dart';
import '../models/product_listing.dart';
import '../message_list.dart';
import '../services/favorites_service.dart';
import 'complete_purchase.dart';

class ListingDetailsPage extends StatefulWidget {
  final ProductListing product;
  final User currentUser;

  const ListingDetailsPage({
    super.key,
    required this.product,
    required this.currentUser,
  });

  @override
  State<ListingDetailsPage> createState() => _ListingDetailsPageState();
}

class _ListingDetailsPageState extends State<ListingDetailsPage> {
  String _formatPrice(double value) {
    final whole = value.round();
    return '${widget.product.currency}$whole';
  }

  String _formatPostedTime(DateTime? createdAt) {
    if (createdAt == null) return 'just now';
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  String _formatMemberSince(DateTime? createdAt) {
    if (createdAt == null) return '2026';
    return createdAt.year.toString();
  }

  Future<void> _makePhoneCall() async {
    // Use a placeholder phone number - in production, get from seller profile
    final Uri launchUri = Uri(scheme: 'tel', path: '+255123456789');
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone call')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final detailsLocation = product.specificLocation.trim().isEmpty
        ? product.location.trim()
        : '${product.location.trim()}, ${product.specificLocation.trim()}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Listing Details',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StreamBuilder<bool>(
              stream: FavoritesService.isFavoriteStream(
                userId: widget.currentUser.uid,
                productId: product.productId,
              ),
              builder: (context, snapshot) {
                final isFavorite = snapshot.data ?? false;
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    await FavoritesService.toggleFavorite(
                      user: widget.currentUser,
                      product: product,
                    );
                  },
                  child: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite
                        ? const Color(0xFFE53935)
                        : const Color(0xFF8A8A8A),
                    size: 24,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.black87),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Carousel
                _ListingImageCarousel(
                  images: product.images,
                  hasVideo: product.video?.trim().isNotEmpty == true,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price
                      Text(
                        _formatPrice(product.price),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D1D1D),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: Color(0xFF8A8A8A),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              detailsLocation.isEmpty
                                  ? 'No location'
                                  : detailsLocation,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4E4E4E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.description.trim().isEmpty
                              ? 'No description provided'
                              : product.description.trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4E4E4E),
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Seller Information
                      const Text(
                        'Seller Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Color(0xFFE6E6E6),
                                  child: Icon(
                                    Icons.person,
                                    size: 28,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.sellerName.trim().isEmpty
                                            ? 'Unknown seller'
                                            : product.sellerName.trim(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Member since ${_formatMemberSince(product.createdAt)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF8A8A8A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const MessageListPage(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.mail_outline_rounded,
                                    ),
                                    label: const Text('Message'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2F65FF),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _makePhoneCall,
                                    icon: const Icon(Icons.phone_outlined),
                                    label: const Text('Call Now'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2F65FF),
                                      side: const BorderSide(
                                        color: Color(0xFF2F65FF),
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Listing Details
                      const Text(
                        'Listing Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                              label: 'Listed',
                              value: _formatPostedTime(product.createdAt),
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Category',
                              value: product.category.trim().isEmpty
                                  ? 'Other'
                                  : product.category.trim(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CompletePurchasePage(
                              product: product,
                              currentUser: widget.currentUser,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F65FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF8A8A8A)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _ListingImageCarousel extends StatefulWidget {
  final List<String> images;
  final bool hasVideo;

  const _ListingImageCarousel({required this.images, this.hasVideo = false});

  @override
  State<_ListingImageCarousel> createState() => _ListingImageCarouselState();
}

class _ListingImageCarouselState extends State<_ListingImageCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    if (widget.images.length < 2) return;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_index + 1) % widget.images.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _ListingImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images.length != widget.images.length) {
      _index = 0;
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasNoImages = widget.images.isEmpty;

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: hasNoImages ? 1 : widget.images.length,
            onPageChanged: (value) {
              setState(() {
                _index = value;
              });
            },
            itemBuilder: (context, index) {
              if (hasNoImages) {
                return Container(
                  color: const Color(0xFFE7E7E7),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.play_circle_fill_rounded,
                        size: 56,
                        color: Color(0xFF4A3DE0),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Video only listing',
                        style: TextStyle(
                          color: Color(0xFF4A3DE0),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Image.network(
                widget.images[index],
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFE7E7E7),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.black38,
                      size: 44,
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(150),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                hasNoImages ? 'Video' : '${_index + 1}/${widget.images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
