import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'communities/communities_screen.dart';
import 'feed/feed_screen.dart';
import 'my_events/my_events_screen.dart';
import 'profile/profile_screen.dart';
import 'scan/qr_scan_screen.dart';

/// App shell after sign-in: bottom navigation across Feed, My Events, Scan,
/// Communities, and Profile.
///
/// Uses [IndexedStack] rather than swapping widgets so each tab keeps its
/// scroll position and local state (search text, filters, tab selection)
/// when the user switches away and back. The middle "Scan" item opens the
/// camera screen on top instead of switching tabs, since it owns a camera
/// controller that shouldn't stay alive in the background.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _tabIndex = 0;

  static const _tabs = [
    FeedScreen(),
    MyEventsScreen(),
    CommunitiesScreen(),
    ProfileScreen(),
  ];

  /// Bottom-nav item index -> [_tabs] index. Index 2 (Scan) has no tab.
  static const _navToTab = {0: 0, 1: 1, 3: 2, 4: 3};
  static const _tabToNav = {0: 0, 1: 1, 2: 3, 3: 4};

  void _onNavTap(int navIndex) {
    if (navIndex == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QrScanScreen()),
      );
      return;
    }
    setState(() => _tabIndex = _navToTab[navIndex]!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabToNav[_tabIndex]!,
        onTap: _onNavTap,
        backgroundColor: AppColors.surface,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore_rounded), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.event_outlined), activeIcon: Icon(Icons.event_rounded), label: 'My Events'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), activeIcon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.diversity_3_outlined), activeIcon: Icon(Icons.diversity_3_rounded), label: 'Communities'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
