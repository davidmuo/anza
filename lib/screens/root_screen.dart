import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'communities/communities_screen.dart';
import 'feed/feed_screen.dart';
import 'my_events/my_events_screen.dart';
import 'profile/profile_screen.dart';

/// App shell after sign-in: bottom navigation across Feed, My Events,
/// Communities, and Profile.
///
/// Uses [IndexedStack] rather than swapping widgets so each tab keeps its
/// scroll position and local state (search text, filters, tab selection)
/// when the user switches away and back.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _tabs = [
    FeedScreen(),
    MyEventsScreen(),
    CommunitiesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        backgroundColor: AppColors.surface,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore_rounded), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.event_outlined), activeIcon: Icon(Icons.event_rounded), label: 'My Events'),
          BottomNavigationBarItem(icon: Icon(Icons.diversity_3_outlined), activeIcon: Icon(Icons.diversity_3_rounded), label: 'Communities'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
