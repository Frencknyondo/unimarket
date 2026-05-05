import 'package:flutter/material.dart';

import '../message_list.dart';
import '../models/user_model.dart';
import '../profile.dart';
import '../provider/create_listing.dart';
import '../provider/my_sales.dart';

class ProviderBottomNav extends StatelessWidget {
  final User user;
  final int currentIndex;
  final Widget? homePage;

  const ProviderBottomNav({
    super.key,
    required this.user,
    required this.currentIndex,
    this.homePage,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SizedBox(
        height: 66,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x180F172A),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              _ProviderNavItem(
                icon: Icons.home_filled,
                label: 'Home',
                active: currentIndex == 0,
                onTap: () => _goHome(context),
              ),
              _ProviderNavItem(
                icon: Icons.storefront_outlined,
                label: 'Sales',
                active: currentIndex == 1,
                onTap: () => _open(context, 1, MySalesPage(user: user)),
              ),
              _ProviderAddItem(
                onTap: () => _push(context, CreateListingPage(user: user)),
              ),
              _ProviderNavItem(
                icon: Icons.message_outlined,
                label: 'Messages',
                active: currentIndex == 2,
                onTap: () => _open(
                  context,
                  2,
                  MessageListPage(currentUser: user),
                ),
              ),
              _ProviderNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                active: currentIndex == 3,
                onTap: () => _open(context, 3, ProfilePage(user: user)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    if (currentIndex == 0) return;
    final page = homePage;
    if (page == null) return;
    _replaceWith(context, page);
  }

  void _open(BuildContext context, int index, Widget page) {
    if (currentIndex == index) return;
    _replaceWith(context, page);
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _replaceWith(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

class _ProviderAddItem extends StatelessWidget {
  final VoidCallback onTap;

  const _ProviderAddItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF4A3DE0),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x334A3DE0),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ProviderNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF4A3DE0) : const Color(0xFF8A8FA3);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 50,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEDEBFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
