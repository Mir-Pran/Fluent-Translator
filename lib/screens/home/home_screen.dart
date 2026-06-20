/// Root screen: flat solid background + glass bottom nav switching between
/// the 4 MVP tabs via an IndexedStack (keeps state alive).
library;
import 'package:flutter/material.dart';

import '../../widgets/glass_bottom_nav.dart';
import '../history/history_screen.dart';
import '../saved/saved_screen.dart';
import '../settings/settings_screen.dart';
import '../translate/translate_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        // IndexedStack keeps each tab's state alive across switches.
        child: IndexedStack(
          index: _index,
          children: [
            TranslateScreen(onOpenSettings: () => _goTo(3)),
            const HistoryScreen(),
            const SavedScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _index,
        onTap: _goTo,
      ),
    );
  }
}
