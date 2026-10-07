import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/stitch_theme.dart';
import '../services/auth_service.dart';
import '../features/feed/feed_screen.dart';
import '../features/clubs/clubs_screen.dart';
import '../features/communication/communication_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/search/search_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final role = (auth.currentUser?.role ?? 'student').toLowerCase();
    final isAdmin = role == 'admin';

    final List<Widget> screens = [
      if (isAdmin) const AdminDashboardScreen() else const FeedScreen(),
      const CommunicationScreen(),
      const SearchScreen(),
      const ClubsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex < screens.length ? _currentIndex : 0,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex < screens.length ? _currentIndex : 0,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(isAdmin ? Icons.account_balance_rounded : Icons.dynamic_feed_rounded),
            label: isAdmin ? 'College' : 'Feed',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: StitchTheme.primaryGradient,
              ),
              child: const Icon(Icons.search_rounded, color: Colors.black, size: 22),
            ),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_rounded),
            label: 'Clubs',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
