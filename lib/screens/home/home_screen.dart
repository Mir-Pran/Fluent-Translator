/// Root screen: ambient background + glass bottom nav switching between
/// 5 tabs via an IndexedStack (keeps state alive).
/// RepaintBoundary is placed around each inactive screen and the nav bar
/// to prevent unnecessary repaints on tab switches.
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/ambient_background.dart';
import '../../widgets/glass_bottom_nav.dart';
import '../analyzer/analyzer_screen.dart';
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
  void initState() {
    super.initState();
    // Transparent status bar so ambient background shows through.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      TranslateScreen(onOpenSettings: () => _goTo(4)),
      const AnalyzerScreen(),
      const HistoryScreen(),
      const SavedScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          // Each screen is wrapped in RepaintBoundary so inactive tabs
          // don't trigger repaints when the active tab updates.
          child: Stack(
            children: [
              for (int i = 0; i < screens.length; i++)
                RepaintBoundary(
                  child: IgnorePointer(
                    ignoring: i != _index,
                    child: AnimatedOpacity(
                      opacity: i == _index ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOutCubic,
                      child: AnimatedScale(
                        scale: i == _index ? 1.0 : 0.97,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        child: screens[i],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: RepaintBoundary(
        child: GlassBottomNav(
          currentIndex: _index,
          onTap: _goTo,
        ),
      ),
    );
  }
}
