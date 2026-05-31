import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../account_settings.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../signin.dart';
import 'manage_ads.dart';
import 'manage_listings.dart';
import 'manage_users.dart';
import 'reports_page.dart';
import 'send_notifications.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isCollapsed = true;
  User? _currentUser;
  bool _isUserLoading = true;
  bool _isFetchingNotifications = false;
  bool _isLoadingAdminSummary = true;
  _AdminNotificationSummary _adminSummary = _AdminNotificationSummary.empty();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadAdminSummary();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService().getSavedSession();
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _isUserLoading = false;
    });
  }

  Future<void> _showAdminNotifications() async {
    final summary = await _fetchAdminNotifications();
    if (!mounted) return;

    setState(() {
      _adminSummary = summary;
      _isLoadingAdminSummary = false;
    });

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Admin Alerts'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationRow(
                  summary.newOrdersCount,
                  'New orders in last 24h',
                ),
                const SizedBox(height: 8),
                _buildNotificationRow(
                  summary.newListingCount,
                  'New marketplace listings',
                ),
                const SizedBox(height: 8),
                _buildNotificationRow(
                  summary.newAdsCount,
                  'New banner ads submitted',
                ),
                const SizedBox(height: 8),
                _buildNotificationRow(
                  summary.newUserCount,
                  'New users signed up',
                ),
                const SizedBox(height: 16),
                if (summary.recentOrderIds.isNotEmpty) ...[
                  const Text(
                    'Recent orders',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...summary.recentOrderIds.map(
                    (id) => Text('- $id', style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],
                if (summary.recentListingTitles.isNotEmpty) ...[
                  const Text(
                    'Recent listings',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...summary.recentListingTitles.map(
                    (title) =>
                        Text('- $title', style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],
                if (summary.recentAdNames.isNotEmpty) ...[
                  const Text(
                    'Recent ads',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...summary.recentAdNames.map(
                    (title) =>
                        Text('- $title', style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],
                if (summary.recentUserNames.isNotEmpty) ...[
                  const Text(
                    'Recent users',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...summary.recentUserNames.map(
                    (name) =>
                        Text('- $name', style: const TextStyle(fontSize: 13)),
                  ),
                ],
                if (summary.isEmpty) ...[
                  const Text(
                    'No recent admin updates found.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationRow(int count, String label) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Color(0xFF4A3DE0),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Future<_AdminNotificationSummary> _fetchAdminNotifications() async {
    setState(() => _isFetchingNotifications = true);
    try {
      final since = DateTime.now().subtract(const Duration(hours: 24));

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('unimarket_db')
          .get();
      final listingsSnapshot = await FirebaseFirestore.instance
          .collection('listings')
          .get();
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .get();
      final adsSnapshot = await FirebaseFirestore.instance
          .collection('ads')
          .get();

      final recentUsers = usersSnapshot.docs
          .where((doc) => _isRecent(doc.data()['createdAt'], since))
          .map(
            (doc) => (
              name: (doc.data()['fullName'] as String?)?.trim() ?? 'Unknown',
            ),
          )
          .toList();

      final recentListings = listingsSnapshot.docs
          .where((doc) => _isRecent(doc.data()['createdAt'], since))
          .map(
            (doc) => (
              title:
                  (doc.data()['title'] as String?)?.trim() ??
                  'Untitled listing',
            ),
          )
          .toList();

      final recentOrders = ordersSnapshot.docs
          .where((doc) => _isRecent(doc.data()['createdAt'], since))
          .map((doc) => (id: doc.id))
          .toList();

      final recentAds = adsSnapshot.docs
          .where((doc) => _isRecent(doc.data()['createdAt'], since))
          .map(
            (doc) => (
              title:
                  (doc.data()['businessName'] as String?)?.trim() ??
                  (doc.data()['title'] as String?)?.trim() ??
                  'Untitled ad',
            ),
          )
          .toList();

      return _AdminNotificationSummary(
        newUserCount: recentUsers.length,
        newListingCount: recentListings.length,
        newOrdersCount: recentOrders.length,
        newAdsCount: recentAds.length,
        recentUserNames: recentUsers.map((item) => item.name).take(5).toList(),
        recentListingTitles: recentListings
            .map((item) => item.title)
            .take(5)
            .toList(),
        recentOrderIds: recentOrders.map((item) => item.id).take(5).toList(),
        recentAdNames: recentAds.map((item) => item.title).take(5).toList(),
      );
    } finally {
      if (mounted) {
        setState(() => _isFetchingNotifications = false);
      }
    }
  }

  Future<void> _loadAdminSummary() async {
    if (!mounted) return;
    setState(() => _isLoadingAdminSummary = true);
    final summary = await _fetchAdminNotifications();
    if (!mounted) return;
    setState(() {
      _adminSummary = summary;
      _isLoadingAdminSummary = false;
    });
  }

  bool _isRecent(dynamic createdAt, DateTime since) {
    if (createdAt is Timestamp) {
      return createdAt.toDate().isAfter(since);
    }
    if (createdAt is String) {
      final parsed = DateTime.tryParse(createdAt);
      if (parsed != null) {
        return parsed.isAfter(since);
      }
    }
    return false;
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthService().clearSession();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }

  void _toggleSidebar() => setState(() => _isCollapsed = !_isCollapsed);

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF6F7FB);
    final primaryA = const Color(0xFF4A3DE0);
    final primaryB = const Color(0xFF6A5AE0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: _toggleSidebar,
        ),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.black54),
            onPressed: () {
              // Search functionality
            },
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_rounded, color: Colors.black54),
                if (!_isLoadingAdminSummary &&
                    _adminSummary.totalNewUpdates > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _adminSummary.totalNewUpdates > 9
                            ? '9+'
                            : '${_adminSummary.totalNewUpdates}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _isFetchingNotifications
                ? null
                : _showAdminNotifications,
          ),
          IconButton(
            icon: _isUserLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFEDEBFF),
                    backgroundImage:
                        _currentUser?.profilePicture?.trim().isNotEmpty == true
                        ? NetworkImage(_currentUser!.profilePicture!.trim())
                        : null,
                    child: _currentUser?.profilePicture?.trim().isEmpty != false
                        ? const Icon(
                            Icons.person,
                            color: Color(0xFF4A3DE0),
                            size: 18,
                          )
                        : null,
                  ),
            onPressed: _currentUser == null
                ? null
                : () {
                    Navigator.of(context)
                        .push<User?>(
                          MaterialPageRoute(
                            builder: (_) =>
                                AccountSettingsPage(user: _currentUser!),
                          ),
                        )
                        .then((updatedUser) {
                          if (updatedUser is User) {
                            setState(() {
                              _currentUser = updatedUser;
                            });
                          }
                        });
                  },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Collapsible Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: _isCollapsed ? 72 : 240,
            constraints: BoxConstraints(
              minWidth: _isCollapsed ? 72 : 240,
              maxWidth: _isCollapsed ? 72 : 240,
            ),
            curve: Curves.easeInOut,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 10)],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isCollapsed ? 0 : 16,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final showText = constraints.maxWidth >= 120;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryA, primaryB],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.dashboard_rounded,
                                color: Colors.white,
                              ),
                            ),
                            if (showText) ...[
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Admin',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Menu items
                  _SidebarItem(
                    collapsed: _isCollapsed,
                    icon: Icons.groups_rounded,
                    label: 'Users',
                    badgeCount: _adminSummary.newUserCount,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManageUsersPage(),
                        ),
                      );
                    },
                  ),
                  _SidebarItem(
                    collapsed: _isCollapsed,
                    icon: Icons.notifications_active_rounded,
                    label: 'Notifications',
                    badgeCount: _adminSummary.totalNewUpdates,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SendNotificationsPage(),
                        ),
                      );
                    },
                  ),
                  _SidebarItem(
                    collapsed: _isCollapsed,
                    icon: Icons.campaign_rounded,
                    label: 'Ads',
                    badgeCount: _adminSummary.newAdsCount,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManageAdsPage(),
                        ),
                      );
                    },
                  ),
                  _SidebarItem(
                    collapsed: _isCollapsed,
                    icon: Icons.storefront_rounded,
                    label: 'Marketplace',
                    badgeCount: _adminSummary.newListingCount,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManageListingsPage(),
                        ),
                      );
                    },
                  ),
                  _SidebarItem(
                    collapsed: _isCollapsed,
                    icon: Icons.analytics_rounded,
                    label: 'Reports',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ReportsPage()),
                      );
                    },
                  ),

                  const Spacer(),

                  // Logout at bottom of sidebar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isCollapsed ? 6 : 12,
                      vertical: 12,
                    ),
                    child: GestureDetector(
                      onTap: () => _signOut(context),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final showText = constraints.maxWidth >= 120;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDEBFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  color: Color(0xFF4A3DE0),
                                ),
                              ),
                              if (showText) ...[
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryA, primaryB],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${_currentUser?.fullName.trim().isNotEmpty == true ? _currentUser!.fullName.trim() : 'Admin'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Manage students, providers, and marketplace activity from one place.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isLoadingAdminSummary)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else ...[
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _AdminStatCard(
                            label: 'Users',
                            value: _adminSummary.newUserCount,
                            description: 'New signups',
                            color: const Color(0xFF4A3DE0),
                          ),
                          _AdminStatCard(
                            label: 'Listings',
                            value: _adminSummary.newListingCount,
                            description: 'New marketplace items',
                            color: const Color(0xFF2F65FF),
                          ),
                          _AdminStatCard(
                            label: 'Orders',
                            value: _adminSummary.newOrdersCount,
                            description: 'Recent orders',
                            color: const Color(0xFF16A34A),
                          ),
                          _AdminStatCard(
                            label: 'Ads',
                            value: _adminSummary.newAdsCount,
                            description: 'New banners',
                            color: const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    _AdminTile(
                      title: 'Users Management',
                      subtitle: 'Review students, admins, and providers.',
                      icon: Icons.groups_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ManageUsersPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _AdminTile(
                      title: 'Send Notifications',
                      subtitle: 'Send updates to everyone or one user.',
                      icon: Icons.notifications_active_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SendNotificationsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _AdminTile(
                      title: 'Ads Management',
                      subtitle: 'Approve, reject, and preview banner ads.',
                      icon: Icons.campaign_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ManageAdsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    const _AdminTile(
                      title: 'Marketplace Control',
                      subtitle: 'Monitor listings and future approvals.',
                      icon: Icons.storefront_rounded,
                    ),
                    const SizedBox(height: 14),
                    const _AdminTile(
                      title: 'Reports Overview',
                      subtitle: 'Track activity and platform performance.',
                      icon: Icons.analytics_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNotificationSummary {
  final int newUserCount;
  final int newListingCount;
  final int newOrdersCount;
  final int newAdsCount;
  final List<String> recentUserNames;
  final List<String> recentListingTitles;
  final List<String> recentOrderIds;
  final List<String> recentAdNames;

  int get totalNewUpdates {
    return newUserCount + newListingCount + newOrdersCount + newAdsCount;
  }

  bool get isEmpty {
    return newUserCount == 0 &&
        newListingCount == 0 &&
        newOrdersCount == 0 &&
        newAdsCount == 0 &&
        recentUserNames.isEmpty &&
        recentListingTitles.isEmpty &&
        recentOrderIds.isEmpty &&
        recentAdNames.isEmpty;
  }

  const _AdminNotificationSummary({
    required this.newUserCount,
    required this.newListingCount,
    required this.newOrdersCount,
    required this.newAdsCount,
    required this.recentUserNames,
    required this.recentListingTitles,
    required this.recentOrderIds,
    required this.recentAdNames,
  });

  factory _AdminNotificationSummary.empty() {
    return const _AdminNotificationSummary(
      newUserCount: 0,
      newListingCount: 0,
      newOrdersCount: 0,
      newAdsCount: 0,
      recentUserNames: <String>[],
      recentListingTitles: <String>[],
      recentOrderIds: <String>[],
      recentAdNames: <String>[],
    );
  }
}

class _AdminTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _AdminTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconOnlyMode = constraints.maxWidth < 90;
            final showSubtitle = constraints.maxWidth >= 180;

            return Padding(
              padding: const EdgeInsets.all(18),
              child: iconOnlyMode
                  ? Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDEBFF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: const Color(0xFF4A3DE0)),
                      ),
                    )
                  : Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDEBFF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: const Color(0xFF4A3DE0)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (showSubtitle) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.black38,
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String label;
  final int value;
  final String description;
  final Color color;

  const _AdminStatCard({
    required this.label,
    required this.value,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final bool collapsed;
  final IconData icon;
  final String label;
  final int badgeCount;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.collapsed,
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: collapsed ? 6 : 12,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showLabel = constraints.maxWidth >= 120;
              if (!showLabel) {
                return Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDEBFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: const Color(0xFF4A3DE0),
                          size: 22,
                        ),
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.8,
                              ),
                            ),
                            child: Text(
                              badgeCount > 9 ? '9+' : '$badgeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }

              return Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEBFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: const Color(0xFF4A3DE0)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badgeCount > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
