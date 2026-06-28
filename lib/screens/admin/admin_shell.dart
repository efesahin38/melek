import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'mitarbeiter_tab.dart';
import 'touren_tab.dart';
import 'stundenzettel_tab.dart';
import '../chat_screen.dart';

import '../settings_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    MitarbeiterTab(),
    TourenTab(),
    StundenzettelTab(),
    ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.goldGradient.createShader(bounds),
              child: const Text(
                'MELEK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            const Text(
              'Admin',
              style: TextStyle(
                color: AppTheme.goldPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.borderGold,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(
              Icons.settings_rounded,
              color: AppTheme.goldPrimary,
            ),
            tooltip: 'Einstellungen',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              backgroundColor: AppTheme.bgCard,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              selectedIconTheme:
                  const IconThemeData(color: AppTheme.goldPrimary),
              unselectedIconTheme:
                  const IconThemeData(color: AppTheme.textMuted),
              selectedLabelTextStyle: const TextStyle(
                  color: AppTheme.goldPrimary, fontWeight: FontWeight.bold),
              unselectedLabelTextStyle:
                  const TextStyle(color: AppTheme.textMuted),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.people_alt_rounded),
                  label: Text('Mitarbeiter'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.directions_car_filled_rounded),
                  label: Text('Touren'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.access_time_filled_rounded),
                  label: Text('Stundenzettel'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.forum_rounded),
                  label: Text('Chat'),
                ),
              ],
            ),
          if (isDesktop)
            const VerticalDivider(
                thickness: 1, width: 1, color: AppTheme.borderGold),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: IndexedStack(
                  index: _currentIndex,
                  children: _tabs,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : Container(
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                border: const Border(
                  top: BorderSide(color: AppTheme.borderGold, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                backgroundColor: Colors.transparent,
                selectedItemColor: AppTheme.goldPrimary,
                unselectedItemColor: AppTheme.textMuted,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_alt_rounded),
                    label: 'Mitarbeiter',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.directions_car_filled_rounded),
                    label: 'Touren',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.access_time_filled_rounded),
                    label: 'Stundenzettel',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.forum_rounded),
                    label: 'Chat',
                  ),
                ],
              ),
            ),
    );
  }
}
