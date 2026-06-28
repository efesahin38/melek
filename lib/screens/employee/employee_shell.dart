import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../screens/login_screen.dart';
import 'my_touren_tab.dart';
import 'my_dokumente_tab.dart';
import 'my_stundenzettel_tab.dart';
import '../chat_screen.dart';
import '../settings_screen.dart';

class EmployeeShell extends StatefulWidget {
  const EmployeeShell({super.key});

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    MyTourenTab(),
    MyDokumenteTab(),
    MyStundenzettelTab(),
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
              child: Text(
                user?.name ?? 'Mitarbeiter',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Text(
              'MELEK',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 2,
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
                  icon: Icon(Icons.work_rounded),
                  label: Text('Meine Aufträge'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder_rounded),
                  label: Text('Meine Dokumente'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assignment_rounded),
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
                    color: Colors.black.withOpacity(0.4),
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
                    icon: Icon(Icons.work_rounded),
                    label: 'Meine Aufträge',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.folder_rounded),
                    label: 'Meine Dokumente',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.assignment_rounded),
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
