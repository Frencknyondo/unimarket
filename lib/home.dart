import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'layout/provider_bottom_nav.dart';
import 'layout/student_bottom_nav.dart';
import 'searching.dart';
import 'models/ad_model.dart';
import 'models/product_listing.dart';
import 'models/user_model.dart';
import 'services/favorites_service.dart';
import 'services/notifications_service.dart';
import 'student/ad_details.dart';
import 'student/listing_details.dart';

class HomePage extends StatefulWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NotificationsService _notificationsService = NotificationsService();
  bool _showAllCategories = false;
  String _selectedCategory = 'All';

  final List<_CategoryItem> _categories = const [
    _CategoryItem(label: 'Clothing', icon: Icons.checkroom_rounded),
    _CategoryItem(label: 'Medicine', icon: Icons.medication_rounded),
    _CategoryItem(label: 'Beauty', icon: Icons.brush_rounded),
    _CategoryItem(label: 'Baby', icon: Icons.child_friendly_rounded),
    _CategoryItem(label: 'Stationary', icon: Icons.menu_book_rounded),
    _CategoryItem(label: 'Food', icon: Icons.fastfood_rounded),
  ];

  List<_CategoryItem> get _visibleCategories =>
      _showAllCategories ? _categories : _categories.take(4).toList();

  String _normalizeCategory(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'stationery') return 'stationary';
    return normalized;
  }

  final Set<String> _sellerNameBackfills = {};

  bool _needsSellerName(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'unknown seller';
  }

  void _backfillSellerName({
    required String listingId,
    required String sellerName,
  }) {
    final cleanName = sellerName.trim();
    if (listingId.isEmpty || _needsSellerName(cleanName)) return;
    if (!_sellerNameBackfills.add(listingId)) return;

    unawaited(
      FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId)
          .update({'sellerName': cleanName})
          .catchError((_) {
            _sellerNameBackfills.remove(listingId);
          }),
    );
  }

  Future<void> _showNotificationsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF8FAFF),
      builder: (context) {
        return _NotificationsSheet(
          user: widget.user,
          notificationsService: _notificationsService,
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.user.fullName.trim().isEmpty
        ? 'UniMarket User'
        : widget.user.fullName.trim();
    final normalizedRole = widget.user.role.trim().toLowerCase();
    final isProvider = normalizedRole == 'provider';
    final profileImageUrl = widget.user.profilePicture?.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: isProvider
          ? ProviderBottomNav(user: widget.user, currentIndex: 0)
          : StudentBottomNav(user: widget.user, currentIndex: 0),
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
                    backgroundImage:
                        profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : NetworkImage(
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
                          style: TextStyle(fontSize: 8, color: Colors.black54),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<int>(
                    stream: _notificationsService.unreadCountStream(
                      widget.user.uid,
                    ),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data ?? 0;
                      return InkWell(
                        onTap: _showNotificationsSheet,
                        borderRadius: BorderRadius.circular(999),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
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
                            if (unreadCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      unreadCount > 9 ? '9+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 7,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  // Search Icon - styled like notification icon
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchPage()),
                      );
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F7F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const _HomeAdsBanner(),
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
                    .collection('unimarket_db')
                    .snapshots(),
                builder: (context, usersSnapshot) {
                  final sellerNames = <String, String>{};
                  for (final doc in usersSnapshot.data?.docs ?? const []) {
                    final data = doc.data();
                    if (data != null && data['role'] == 'provider') {
                      sellerNames[doc.id] = data['fullName'] ?? 'Unknown';
                    }
                  }

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                            final data = doc.data();
                            final storedName =
                                (data['sellerName'] as String? ?? '').trim();
                            final sellerId =
                                (data['sellerId'] as String? ??
                                        data['userId'] as String? ??
                                        '')
                                    .trim();
                            final sellerName = (!_needsSellerName(storedName))
                                ? storedName
                                : (sellerNames[sellerId] ?? 'Unknown seller');
                            final map = <String, dynamic>{
                              ...data,
                              'productId':
                                  (data['productId'] as String?) ?? doc.id,
                              'sellerName': sellerName,
                            };

                            if (_needsSellerName(
                              data['sellerName'] as String? ?? '',
                            )) {
                              _backfillSellerName(
                                listingId: doc.id,
                                sellerName: sellerName,
                              );
                            }

                            return ProductListing.fromMap(map);
                          })
                          .where(
                            (item) =>
                                item.images.isNotEmpty || item.video != null,
                          )
                          .toList();
                      if (listings.isEmpty) {
                        return const _ProductsStateCard(
                          message:
                              'No listings found yet. products and they will appear here.',
                        );
                      }

                      final filteredListings = listings.where((item) {
                        if (_selectedCategory == 'All') return true;
                        return _normalizeCategory(item.category) ==
                            _normalizeCategory(_selectedCategory);
                      }).toList();

                      if (filteredListings.isEmpty) {
                        final message = _selectedCategory == 'All'
                            ? 'No listings found yet. Products will appear here soon.'
                            : '$_selectedCategory listings are coming soon.';
                        return _ProductsStateCard(message: message);
                      }

                      return _MasonryProductGrid(
                        listings: filteredListings,
                        currentUser: widget.user,
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
            fontSize: 20,
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
}

class _NotificationsSheet extends StatelessWidget {
  final User user;
  final NotificationsService notificationsService;

  const _NotificationsSheet({
    required this.user,
    required this.notificationsService,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.86;

    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        notificationsService.markAllAsRead(user.uid),
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<AppNotification>>(
                  stream: notificationsService.notificationsStream(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const _NotificationEmptyState(
                        title: 'Notifications unavailable',
                        subtitle:
                            'Failed to load your notifications right now.',
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final notifications =
                        snapshot.data ?? const <AppNotification>[];
                    final unreadCount = notifications
                        .where((item) => !item.isRead)
                        .length;

                    if (notifications.isEmpty) {
                      return const _NotificationEmptyState(
                        title: 'No notifications yet',
                        subtitle:
                            'Notifications from admin and order updates will appear here.',
                      );
                    }

                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            unreadCount == 1
                                ? '1 unread notification'
                                : '$unreadCount unread notifications',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: ListView.separated(
                            itemCount: notifications.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = notifications[index];
                              return _NotificationTile(
                                notification: item,
                                onTap: () =>
                                    notificationsService.markAsRead(item.id),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeAdsBanner extends StatefulWidget {
  const _HomeAdsBanner();

  @override
  State<_HomeAdsBanner> createState() => _HomeAdsBannerState();
}

class _HomeAdsBannerState extends State<_HomeAdsBanner> {
  int _activeAdIndex = 0;
  int _adCount = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _startRotationTimer();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _startRotationTimer() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _adCount < 2) return;
      setState(() {
        _activeAdIndex = (_activeAdIndex + 1) % _adCount;
      });
    });
  }

  Future<void> _openWhatsApp(BuildContext context, AdModel ad) async {
    final phone = ad.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) return;
    final normalized = phone.startsWith('+') ? phone.substring(1) : phone;
    final uri = Uri.parse(
      'https://wa.me/$normalized?text=${Uri.encodeComponent('Hello, I saw your ad on UniMarket: ${ad.title}')}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('ads')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        final ads =
            (snapshot.data?.docs ?? const [])
                .map((doc) => AdModel.fromFirestore(doc))
                .where((ad) => ad.isActive)
                .toList()
              ..sort((a, b) {
                final aDate =
                    a.approvedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                final bDate =
                    b.approvedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                return bDate.compareTo(aDate);
              });

        _adCount = ads.length;
        if (_activeAdIndex >= _adCount) {
          _activeAdIndex = 0;
        }

        if (ads.isEmpty) return const SizedBox.shrink();
        final ad = ads[_activeAdIndex];

        return GestureDetector(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => AdDetailsPage(ad: ad)));
          },
          child: Container(
            height: 164,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF2458D8),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (ad.imageUrl.isNotEmpty)
                  Image.network(ad.imageUrl, fit: BoxFit.cover),
                if (ad.imageUrl.isEmpty)
                  Container(color: const Color(0xCC2458D8)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ad.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        ad.businessName.isEmpty ? ad.title : ad.businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ad.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () => _openWhatsApp(context, ad),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            ad.ctaLabel,
                            style: const TextStyle(
                              color: Color(0xFF2458D8),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  top: 12,
                  right: 14,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0x5520247C),
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'AD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
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
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  IconData _iconForType() {
    switch (notification.type) {
      case 'admin':
        return Icons.campaign_rounded;
      case 'ad_submitted':
        return Icons.hourglass_top_rounded;
      case 'ad_approved':
        return Icons.verified_rounded;
      case 'ad_rejected':
        return Icons.cancel_rounded;
      case 'order_placed':
        return Icons.shopping_bag_rounded;
      case 'order_confirmed':
        return Icons.verified_rounded;
      case 'order_received':
        return Icons.shopping_cart_checkout_rounded;
      case 'order_completed':
        return Icons.task_alt_rounded;
      case 'order_cancelled':
        return Icons.cancel_rounded;
      case 'listing_created':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _iconColor() {
    switch (notification.type) {
      case 'admin':
        return const Color(0xFF4A3DE0);
      case 'ad_submitted':
        return const Color(0xFFF59E0B);
      case 'ad_approved':
        return const Color(0xFF22C55E);
      case 'ad_rejected':
        return const Color(0xFFEF4444);
      case 'order_placed':
        return const Color(0xFF2563EB);
      case 'order_confirmed':
        return const Color(0xFFF59E0B);
      case 'order_received':
        return const Color(0xFF2563EB);
      case 'order_completed':
        return const Color(0xFF22C55E);
      case 'order_cancelled':
        return const Color(0xFFEF4444);
      case 'listing_created':
        return const Color(0xFFA855F7);
      default:
        return const Color(0xFF4A3DE0);
    }
  }

  String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    final diff = DateTime.now().difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hrs ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${(diff.inDays / 365).floor()} years ago';
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: notification.isRead
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFFD6E4FF),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconForType(), color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _timeAgo(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _NotificationEmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF2563EB),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String label;
  final IconData icon;

  const _CategoryItem({required this.label, required this.icon});
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
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4A3DE0)
                    : const Color(0xFFF7F7F7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFF4A3DE0),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              category.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
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

  const _FilterChip({required this.label, this.isActive = false, this.onTap});

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

class _MasonryProductGrid extends StatelessWidget {
  final List<ProductListing> listings;
  final User currentUser;

  const _MasonryProductGrid({
    required this.listings,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final leftItems = <ProductListing>[];
    final rightItems = <ProductListing>[];

    for (var index = 0; index < listings.length; index++) {
      if (index.isEven) {
        leftItems.add(listings[index]);
      } else {
        rightItems.add(listings[index]);
      }
    }

    Widget column(List<ProductListing> items) {
      return Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _ListingCard(
              product: items[index],
              currentUser: currentUser,
              compactLayout: true,
            ),
            if (index != items.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column(leftItems)),
        const SizedBox(width: 10),
        Expanded(child: column(rightItems)),
      ],
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
    required this.compactLayout,
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
          borderRadius: BorderRadius.circular(12),
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
                compactLayout ? 7 : 9,
                compactLayout ? 6 : 9,
                compactLayout ? 7 : 9,
                compactLayout ? 7 : 9,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: compactLayout ? 8 : 9,
                        backgroundColor: Color(0xFFE6E6E6),
                        child: Icon(
                          Icons.person,
                          size: compactLayout ? 10 : 11,
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
                            fontSize: compactLayout ? 10 : 12,
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
                              size: compactLayout ? 16 : 18,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: compactLayout ? 4 : 6),
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compactLayout ? 13 : 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D1D1D),
                    ),
                  ),
                  SizedBox(height: compactLayout ? 1 : 3),
                  Text(
                    product.description.trim().isEmpty
                        ? 'No description'
                        : product.description.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compactLayout ? 10 : 12,
                      color: Color(0xFF606060),
                    ),
                  ),
                  SizedBox(height: compactLayout ? 4 : 6),
                  Text(
                    _formatPrice(product.price),
                    style: TextStyle(
                      fontSize: compactLayout ? 14 : 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                  if (hasVideo) ...[
                    SizedBox(height: compactLayout ? 3 : 5),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compactLayout ? 6 : 9,
                        vertical: compactLayout ? 3 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A3DE0),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.videocam_rounded,
                            size: compactLayout ? 10 : 13,
                            color: Colors.white,
                          ),
                          SizedBox(width: compactLayout ? 4 : 6),
                          Text(
                            'Video available',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compactLayout ? 8 : 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: compactLayout ? 1 : 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          detailsLocation.isEmpty
                              ? 'No location'
                              : detailsLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compactLayout ? 10 : 12,
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
                          fontSize: compactLayout ? 9 : 11,
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
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  Timer? _timer;
  int _index = 0;
  double _aspectRatio = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _resolveAspectRatio();
    _startAutoSlide();
  }

  void _resolveAspectRatio() {
    final oldListener = _imageStreamListener;
    if (oldListener != null) {
      _imageStream?.removeListener(oldListener);
    }
    _imageStream = null;
    _imageStreamListener = null;

    if (widget.images.isEmpty) {
      _aspectRatio = 1;
      return;
    }

    final provider = NetworkImage(widget.images.first);
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((info, _) {
      final width = info.image.width;
      final height = info.image.height;
      if (!mounted || height == 0) return;
      setState(() {
        _aspectRatio = (width / height).clamp(0.56, 1.35).toDouble();
      });
    });

    _imageStream = stream;
    _imageStreamListener = listener;
    stream.addListener(listener);
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
      _resolveAspectRatio();
      _startAutoSlide();
    } else if (oldWidget.images.isNotEmpty &&
        widget.images.isNotEmpty &&
        oldWidget.images.first != widget.images.first) {
      _index = 0;
      _resolveAspectRatio();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    final listener = _imageStreamListener;
    if (listener != null) {
      _imageStream?.removeListener(listener);
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasNoImages = widget.images.isEmpty;

    return AspectRatio(
      aspectRatio: hasNoImages ? 1 : _aspectRatio,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                          size: 34,
                          color: Color(0xFF4A3DE0),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Video only listing',
                          style: TextStyle(
                            color: Color(0xFF4A3DE0),
                            fontSize: 11,
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
                  height: double.infinity,
                  fit: BoxFit.contain,
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
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(150),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                hasNoImages ? 'Video' : '${_index + 1}/${widget.images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
          height: 1.5,
        ),
      ),
    );
  }
}
