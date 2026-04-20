import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'account_settings.dart';
import 'models/user_model.dart';
import 'message_list.dart';
import 'my_favorites.dart';
import 'provider/create_listing.dart';
import 'provider/my_listings.dart';
import 'provider/my_sales.dart';
import 'signin.dart';
import 'student/my_purchases.dart';

class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _pushNotifications = false;
  late final Future<_ProfileStats> _statsFuture = _loadProfileStats();

  bool get _isProvider => widget.user.role.trim().toLowerCase() == 'provider';
  bool get _isStudent => !_isProvider;

  Future<void> _signOut() async {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }

  Future<_ProfileStats> _loadProfileStats() async {
    final userId = widget.user.uid.trim();
    final favouritesSnapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .get();
    final favouritesCount = favouritesSnapshot.size;
    final chatsSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .get();
    final chatsCount = chatsSnapshot.docs.where((doc) {
      final data = doc.data();
      final participantIds =
          (data['participantIds'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .map((id) => id.trim())
              .toSet();
      final lastMessageText = ((data['lastMessageText'] as String?) ?? '')
          .trim();
      return participantIds.length > 1 && lastMessageText.isNotEmpty;
    }).length;

    if (_isProvider) {
      final listingsSnapshot = await FirebaseFirestore.instance
          .collection('listings')
          .get();
      final listingsCount = listingsSnapshot.docs.where((doc) {
        final data = doc.data();
        final sellerId = ((data['sellerId'] as String?) ?? '').trim();
        final ownerId = ((data['userId'] as String?) ?? '').trim();
        return sellerId == userId || ownerId == userId;
      }).length;
      return _ProfileStats(
        listings: listingsCount,
        chats: chatsCount,
        favourites: favouritesCount,
        purchases: 0,
        showListings: true,
        showPurchases: false,
      );
    }

    final purchasesSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('buyerId', isEqualTo: userId)
        .get();
    return _ProfileStats(
      listings: 0,
      chats: chatsCount,
      favourites: favouritesCount,
      purchases: purchasesSnapshot.size,
      showListings: false,
      showPurchases: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user.fullName.trim().isEmpty
        ? 'UniMarket User'
        : widget.user.fullName.trim();
    final email = widget.user.email.trim();

    final accountItems = <_MenuItem>[
      if (_isProvider)
        const _MenuItem(
          title: 'My Listings',
          subtitle: 'Manage your listings',
          icon: Icons.list_alt_rounded,
          iconBg: Color(0xFFE7F2FF),
          iconColor: Color(0xFF2F65FF),
        ),
      const _MenuItem(
        title: 'My Favourites',
        subtitle: 'Check your saved items',
        icon: Icons.favorite_rounded,
        iconBg: Color(0xFFEAF2FF),
        iconColor: Color(0xFF3B82F6),
      ),
      const _MenuItem(
        title: 'Messages',
        subtitle: 'Chat with buyers & sellers',
        icon: Icons.message_outlined,
        iconBg: Color(0xFFF3EAFE),
        iconColor: Color(0xFFA855F7),
      ),
      if (_isStudent)
        const _MenuItem(
          title: 'My Purchases',
          subtitle: 'Manage your orders',
          icon: Icons.shopping_cart_checkout_rounded,
          iconBg: Color(0xFFE8F8EC),
          iconColor: Color(0xFF22C55E),
        ),
      if (_isProvider)
        const _MenuItem(
          title: 'My Sales',
          subtitle: 'Track your sold items',
          icon: Icons.local_offer_outlined,
          iconBg: Color(0xFFFFF3E5),
          iconColor: Color(0xFFF59E0B),
        ),
      const _MenuItem(
        title: 'Account Settings',
        subtitle: 'Profile, security & preferences',
        icon: Icons.manage_accounts_outlined,
        iconBg: Color(0xFFFFF7E5),
        iconColor: Color(0xFFEAB308),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      floatingActionButton: _isProvider
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
      floatingActionButtonLocation: _isProvider
          ? FloatingActionButtonLocation.centerDocked
          : null,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shape: _isProvider ? const CircularNotchedRectangle() : null,
        notchMargin: _isProvider ? 10 : 0,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_filled, 'Home', 0),
              _navItem(
                _isProvider
                    ? Icons.storefront_outlined
                    : Icons.receipt_long_outlined,
                _isProvider ? 'Mysales' : 'Order',
                1,
              ),
              if (_isProvider) ...[
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundColor: Color(0xFFF0F0F0),
                          child: Icon(
                            Icons.person,
                            color: Color(0xFFB5B5B5),
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 33,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF5C5C5C),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Member since ${widget.user.createdAt.year}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF8A8A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<_ProfileStats>(
                      future: _statsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 86,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const SizedBox(
                            height: 86,
                            child: Center(
                              child: Text(
                                'Unable to load stats',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          );
                        }
                        return _StatsPanel(stats: snapshot.data!);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'My Account',
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: accountItems
                      .map(
                        (item) => _AccountItemTile(
                          item: item,
                          onTap: () => _onAccountItemTap(item.title),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Preferences',
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() {
                          _pushNotifications = value;
                        });
                      },
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF2F65FF),
                      title: const Text(
                        'Push Notifications',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      secondary: const Icon(Icons.notifications_none_rounded),
                    ),
                    const Divider(height: 1),
                    _PrivacySecurityTile(),
                    const Divider(height: 1),
                    _HelpSupportTile(),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFFDA4AF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final activeIndex = _isProvider ? 3 : 2;
    final isActive = activeIndex == index;
    return InkWell(
      onTap: () {
        if (label == 'Home') {
          Navigator.of(context).pop();
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
            MaterialPageRoute(builder: (_) => MySalesPage(user: widget.user)),
          );
          return;
        }
        return;
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

  void _onAccountItemTap(String title) {
    if (title == 'Messages') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MessageListPage(currentUser: widget.user),
        ),
      );
      return;
    }
    if (title == 'My Purchases') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MyPurchasesPage(user: widget.user)),
      );
      return;
    }
    if (title == 'My Favourites') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MyFavoritesPage(user: widget.user)),
      );
      return;
    }
    if (title == 'My Listings') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MyListingsPage(user: widget.user)),
      );
      return;
    }
    if (title == 'My Sales') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => MySalesPage(user: widget.user)));
      return;
    }
    if (title == 'Account Settings') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AccountSettingsPage(user: widget.user),
        ),
      );
      return;
    }
  }
}

class _AccountItemTile extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onTap;

  const _AccountItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F1F1))),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(shape: BoxShape.circle, color: item.iconBg),
          child: Icon(item.icon, color: item.iconColor, size: 22),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          item.subtitle,
          style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.black54,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final _ProfileStats stats;

  const _StatsPanel({required this.stats});

  @override
  Widget build(BuildContext context) {
    Widget cell(String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF2F65FF),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5A5A5A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final cells = <Widget>[];
    if (stats.showListings) {
      cells.add(cell('${stats.listings}', 'Listings'));
    }
    cells.add(cell('${stats.chats}', 'Chats'));
    cells.add(cell('${stats.favourites}', 'Favourites'));
    if (stats.showPurchases) {
      cells.add(cell('${stats.purchases}', 'Purchases'));
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: cells),
    );
  }
}

class _ProfileStats {
  final int listings;
  final int chats;
  final int favourites;
  final int purchases;
  final bool showListings;
  final bool showPurchases;

  const _ProfileStats({
    required this.listings,
    required this.chats,
    required this.favourites,
    required this.purchases,
    required this.showListings,
    required this.showPurchases,
  });
}

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

class _PrivacySecurityTile extends StatefulWidget {
  const _PrivacySecurityTile();

  @override
  State<_PrivacySecurityTile> createState() => _PrivacySecurityTileState();
}

class _PrivacySecurityTileState extends State<_PrivacySecurityTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.security_outlined, color: Colors.black54),
          title: const Text(
            'Privacy & Security',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          trailing: Icon(
            _isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: Colors.black54,
          ),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _faqItem(
                  question: 'How is my data protected?',
                  answer:
                      'We use industry-standard encryption to protect your personal information and only share data with trusted parties for transaction purposes.',
                ),
                const SizedBox(height: 8),
                _faqItem(
                  question: 'Can I delete my account?',
                  answer:
                      'Yes, you can delete your account from the Account Settings section. This action is permanent and cannot be undone.',
                ),
                const SizedBox(height: 8),
                _faqItem(
                  question: 'How do I change my password?',
                  answer:
                      'Go to Account Settings and select "Security" to change your password. Make sure to use a strong, unique password.',
                ),
                const SizedBox(height: 8),
                _faqItem(
                  question: 'Is my payment information secure?',
                  answer:
                      'We do not store your payment information. All transactions are processed securely through trusted payment providers.',
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _faqItem({required String question, required String answer}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _HelpSupportTile extends StatefulWidget {
  const _HelpSupportTile();

  @override
  State<_HelpSupportTile> createState() => _HelpSupportTileState();
}

class _HelpSupportTileState extends State<_HelpSupportTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(
            Icons.help_outline_rounded,
            color: Colors.black54,
          ),
          title: const Text(
            'Help & Support',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          trailing: Icon(
            _isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: Colors.black54,
          ),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _faqItem(
                  question: 'How do I create a listing?',
                  answer:
                      'To create a listing, tap the + button on the home screen, fill in the details, and upload photos or a video of your item.',
                ),
                const SizedBox(height: 8),
                _faqItem(
                  question: 'How do I contact a seller?',
                  answer:
                      'You can message a seller directly from the listing details page by tapping the message button.',
                ),
                const SizedBox(height: 8),
                _faqItem(
                  question: 'What payment methods are accepted?',
                  answer:
                      'We currently support cash on delivery and mobile money payments.',
                ),
                const SizedBox(height: 8),
                _faqItem(
                  question: 'How do I report an issue?',
                  answer:
                      'If you encounter any issues, please contact our support team through the app settings or email us at support@unimarket.com.',
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _faqItem({required String question, required String answer}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }
}
