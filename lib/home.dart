import 'package:flutter/material.dart';

import 'models/product_listing.dart';
import 'models/user_model.dart';
import 'provider/create_listing.dart';
import 'services/listing_service.dart';

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
  final ListingService _listingService = ListingService();
  int _activeBanner = 0;
  int _navIndex = 0;

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
  ];

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
                isProvider ? 'Sell' : 'Order',
                1,
              ),
              if (isProvider) ...[
                const SizedBox(width: 40),
                _navItem(Icons.message_outlined, 'Message', 2),
                _navItem(Icons.person_outline_rounded, 'Profile', 3),
              ] else
                _navItem(Icons.person_outline_rounded, 'Profile', 2),
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
              _sectionHeader('Category'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _categories
                    .map(
                      (category) => Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF7F7F7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                category.icon,
                                color: const Color(0xFF4A3DE0),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              category.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 30),
              _sectionHeader('Just For You'),
              const SizedBox(height: 16),
              Row(
                children: const [
                  _FilterChip(label: 'All', isActive: true),
                  SizedBox(width: 10),
                  _FilterChip(label: 'Popular'),
                  SizedBox(width: 10),
                  _FilterChip(label: 'Newest'),
                  SizedBox(width: 10),
                  _FilterChip(label: 'Best Sell'),
                ],
              ),
              const SizedBox(height: 18),
              StreamBuilder<List<ProductListing>>(
                stream: _listingService.watchListings(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _ProductsStateCard(
                      message: 'Failed to load listings from Firestore.',
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final products = snapshot.data ?? const [];
                  if (products.isEmpty) {
                    return const _ProductsStateCard(
                      message: 'No listings yet. Add the first item and it will appear here.',
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 14,
                    ),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductCard(product: product);
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

  Widget _sectionHeader(String title) {
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
        const Spacer(),
        const Text(
          'See All',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6A5AE0),
          ),
        ),
      ],
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _navIndex == index;
    return InkWell(
      onTap: () {
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _FilterChip({
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductListing product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: product.primaryImage.isEmpty
                  ? Container(
                      width: double.infinity,
                      color: const Color(0xFFF3F3F3),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.black38,
                        size: 32,
                      ),
                    )
                  : Image.network(
                      product.primaryImage,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          color: const Color(0xFFF3F3F3),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.black38,
                            size: 32,
                          ),
                        );
                      },
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.sellerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${product.currency}${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2F65FF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.specificLocation.isNotEmpty
                      ? '${product.location}, ${product.specificLocation}'
                      : product.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ],
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
