import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'models/product_listing.dart';
import 'models/user_model.dart';
import 'services/favorites_service.dart';
import 'message_list.dart';
import 'profile.dart';
import 'provider/create_listing.dart';
import 'provider/my_sales.dart';
import 'student/listing_details.dart';
import 'student/my_purchases.dart';

class HomePage extends StatefulWidget {
  final User user;

  const HomePage({
    super.key,
    required this.user,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _bannerController = PageController(viewportFraction: 1);
  int _activeBanner = 0;
  int _navIndex = 0;
  bool _showAllCategories = false;
  String _selectedCategory = 'All';

  final List<_PromoBanner> _banners = const [
    _PromoBanner(
      title: 'NEW COLLECTIONS',
      subtitle: '2024',
      buttonLabel: 'Buy Now',
      imageUrl:
          'https://images.pexels.com/photos/5650026/pexels-photo-5650026.jpeg?auto=compress&cs=tinysrgb&w=1200',
    ),
    _PromoBanner(
      title: 'TRENDING DEALS',
      subtitle: 'SAVE BIG',
      buttonLabel: 'Explore',
      imageUrl:
          'https://images.pexels.com/photos/5872361/pexels-photo-5872361.jpeg?auto=compress&cs=tinysrgb&w=1200',
    ),
  ];

  final List<_CategoryItem> _categories = const [
    _CategoryItem(label: 'Clothing', icon: Icons.checkroom_rounded),
    _CategoryItem(label: 'Medicine', icon: Icons.medication_rounded),
    _CategoryItem(label: 'Beauty', icon: Icons.brush_rounded),
    _CategoryItem(label: 'Baby', icon: Icons.child_friendly_rounded),
    _CategoryItem(label: 'Stationary', icon: Icons.menu_book_rounded),
    _CategoryItem(label: 'Food', icon: Icons.fastfood_rounded),
  ];

  List<_CategoryItem> get _visibleCategories => _showAllCategories
      ? _categories
      : _categories.take(4).toList();

  String _normalizeCategory(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'stationery') return 'stationary';
    return normalized;
  }

  bool _matchesSelectedCategory(ProductListing item) {
    if (_selectedCategory == 'All') return true;
    return _normalizeCategory(item.category) ==
        _normalizeCategory(_selectedCategory);
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.user.fullName.trim().isEmpty
        ? 'UniMarket User'
        : widget.user.fullName.trim();
    final normalizedRole = widget.user.role.trim().toLowerCase();
    final isProvider = normalizedRole == 'provider';

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: isProvider
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateListingPage(user: widget.user),
                  ),
                );
              },
              backgroundColor: const Color(0xFF4A3DE0),
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 32),
            )
          : null,
      floatingActionButtonLocation: isProvider
          ? FloatingActionButtonLocation.centerDocked
          : null,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shape: isProvider ? const CircularNotchedRectangle() : null,
        notchMargin: isProvider ? 10 : 0,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_filled, 'Home', 0),
              _navItem(
                isProvider
                    ? Icons.storefront_outlined
                    : Icons.receipt_long_outlined,
                isProvider ? 'Mysales' : 'Order',
                1,
              ),
              if (isProvider) ...[
                const SizedBox(width: 40),
                _navItem(Icons.message_outlined, 'Message', 2),
                _navItem(Icons.person_outline_rounded, 'Profile', 3),
              ] else ...[
                _navItem(Icons.message_outlined, 'Message', 1),
                _navItem(Icons.person_outline_rounded, 'Profile', 2),
              ],
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFEDEBFF),
                    backgroundImage: NetworkImage(
                      'https://api.dicebear.com/7.x/adventurer-neutral/png?seed=${Uri.encodeComponent(userName)}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F7F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Search',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A3DE0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 148,
                child: PageView.builder(
                  controller: _bannerController,
                  itemCount: _banners.length,
                  onPageChanged: (index) {
                    setState(() {
                      _activeBanner = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final banner = _banners[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A3DE0),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            width: 150,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(18),
                                bottomRight: Radius.circular(18),
                              ),
                              child: Image.network(
                                banner.imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  banner.title,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  banner.subtitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    height: 0.95,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    banner.buttonLabel,
                                    style: const TextStyle(
                                      color: Color(0xFF4A3DE0),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _banners.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _activeBanner == index ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _activeBanner == index
                            ? const Color(0xFF4A3DE0)
                            : const Color(0xFFE5DDF9),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _sectionHeader(
                'Category',
                actionLabel: _showAllCategories ? 'See less' : 'See All',
                onActionTap: () {
                  setState(() {
                    _showAllCategories = !_showAllCategories;
                  });
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 16,
                children: _visibleCategories
                    .map(
                      (category) => _CategoryButton(
                        category: category,
                        isSelected: _selectedCategory == category.label,
                        onTap: () {
                          setState(() {
                            _selectedCategory = category.label;
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 30),
              _sectionHeader('Just For You'),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isActive: _selectedCategory == 'All',
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'All';
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: 'Clothing',
                      isActive: _selectedCategory == 'Clothing',
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'Clothing';
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: 'Food',
                      isActive: _selectedCategory == 'Food',
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'Food';
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: 'Stationary',
                      isActive: _selectedCategory == 'Stationary',
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'Stationary';
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('listings')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _ProductsStateCard(
                      message: 'Failed to load listings.',
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = snapshot.data?.docs ?? const [];
                  final listings = docs
                      .map((doc) {
                        final map = <String, dynamic>{
                          ...doc.data(),
                          'productId': (doc.data()['productId'] as String?) ??
                              doc.id,
                        };
                        return ProductListing.fromMap(map);
                      })
                      .where((item) => item.images.isNotEmpty || item.video != null)
                      .toList();
                  if (listings.isEmpty) {
                    return const _ProductsStateCard(
                      message:
                          'No listings found yet. products and they will appear here.',
                    );
                  }

                  final filteredListings = listings
                      .where(_matchesSelectedCategory)
                      .toList();

                  if (filteredListings.isEmpty) {
                    final message = _selectedCategory == 'All'
                        ? 'No listings found yet. Products will appear here soon.'
                        : '$_selectedCategory listings are coming soon.';
                    return _ProductsStateCard(message: message);
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompactPhone = constraints.maxWidth < 380;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredListings.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: isCompactPhone ? 0.58 : 0.62,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 14,
                        ),
                        itemBuilder: (context, index) {
                          return _ListingCard(
                            product: filteredListings[index],
                            currentUser: widget.user,
                            compactLayout: isCompactPhone,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    String title, {
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        if (actionLabel != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6A5AE0),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _navIndex == index;
    return InkWell(
      onTap: () {
        if (label == 'Profile') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfilePage(user: widget.user),
            ),
          );
          return;
        }
        if (label == 'Message') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MessageListPage(currentUser: widget.user),
            ),
          );
          return;
        }
        if (label == 'Order') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MyPurchasesPage(user: widget.user),
            ),
          );
          return;
        }
        if (label == 'Mysales') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MySalesPage(user: widget.user),
            ),
          );
          return;
        }
        setState(() {
          _navIndex = index;
        });
      },
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF4A3DE0) : Colors.black38,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? const Color(0xFF4A3DE0) : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final String imageUrl;

  const _PromoBanner({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.imageUrl,
  });
}

class _CategoryItem {
  final String label;
  final IconData icon;

  const _CategoryItem({
    required this.label,
    required this.icon,
  });
}

class _CategoryButton extends StatelessWidget {
  final _CategoryItem category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4A3DE0)
                    : const Color(0xFFF7F7F7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                color: isSelected ? Colors.white : const Color(0xFF4A3DE0),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              category.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF4A3DE0) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4A3DE0) : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ListingCard extends StatefulWidget {
  final ProductListing product;
  final User currentUser;
  final bool compactLayout;

  const _ListingCard({
    required this.product,
    required this.currentUser,
    this.compactLayout = false,
  });

  @override
  State<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<_ListingCard> {
  String _formatPrice(double value) {
    final whole = value.round();
    return 'Tsh$whole';
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

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final compactLayout = widget.compactLayout;
    final hasVideo = product.video?.trim().isNotEmpty == true;
    final detailsLocation = product.specificLocation.trim().isEmpty
        ? product.location.trim()
        : '${product.location.trim()}, ${product.specificLocation.trim()}';

    return GestureDetector(
                      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ListingDetailsPage(
              product: product,
              currentUser: widget.currentUser,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ListingImageCarousel(
              images: product.images,
              hasVideo: hasVideo,
              compactLayout: compactLayout,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compactLayout ? 8 : 10,
                compactLayout ? 8 : 10,
                compactLayout ? 8 : 10,
                compactLayout ? 8 : 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: compactLayout ? 9 : 10,
                        backgroundColor: Color(0xFFE6E6E6),
                        child: Icon(
                          Icons.person,
                          size: compactLayout ? 11 : 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                      SizedBox(width: compactLayout ? 4 : 6),
                      Expanded(
                        child: Text(
                          product.sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compactLayout ? 12 : 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF575757),
                          ),
                        ),
                      ),
                      StreamBuilder<bool>(
                        stream: FavoritesService.isFavoriteStream(
                          userId: widget.currentUser.uid,
                          productId: product.productId,
                        ),
                        builder: (context, snapshot) {
                          final isFavorite = snapshot.data ?? false;
                          return GestureDetector(
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
                              size: compactLayout ? 18 : 20,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                SizedBox(height: compactLayout ? 6 : 8),
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compactLayout ? 15 : 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D1D1D),
                  ),
                ),
                SizedBox(height: compactLayout ? 2 : 4),
                Text(
                  product.description.trim().isEmpty
                      ? 'No description'
                      : product.description.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compactLayout ? 12 : 13,
                    color: Color(0xFF606060),
                  ),
                ),
                SizedBox(height: compactLayout ? 6 : 8),
                Text(
                  _formatPrice(product.price),
                  style: TextStyle(
                    fontSize: compactLayout ? 16 : 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                if (hasVideo) ...[
                  SizedBox(height: compactLayout ? 4 : 6),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compactLayout ? 8 : 10,
                      vertical: compactLayout ? 5 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A3DE0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_rounded,
                          size: compactLayout ? 12 : 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: compactLayout ? 4 : 6),
                        Text(
                          'Video available',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compactLayout ? 10 : 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: compactLayout ? 2 : 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        detailsLocation.isEmpty ? 'No location' : detailsLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compactLayout ? 12 : 13,
                          color: Color(0xFF4E4E4E),
                        ),
                      ),
                    ),
                    SizedBox(width: compactLayout ? 4 : 6),
                    Text(
                      _formatPostedTime(product.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compactLayout ? 11 : 12,
                        color: Color(0xFF8A8A8A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _ListingImageCarousel extends StatefulWidget {
  final List<String> images;
  final bool hasVideo;
  final bool compactLayout;

  const _ListingImageCarousel({
    required this.images,
    this.hasVideo = false,
    this.compactLayout = false,
  });

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
      height: widget.compactLayout ? 140 : 155,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: PageView.builder(
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
                          size: 46,
                          color: Color(0xFF4A3DE0),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Video only listing',
                          style: TextStyle(
                            color: Color(0xFF4A3DE0),
                            fontSize: 14,
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(150),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                hasNoImages
                    ? 'Video'
                    : '${_index + 1}/${widget.images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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

class _ProductsStateCard extends StatelessWidget {
  final String message;

  const _ProductsStateCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
          height: 1.5,
        ),
      ),
    );
  }
}
