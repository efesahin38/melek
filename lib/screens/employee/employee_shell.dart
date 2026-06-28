import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../screens/login_screen.dart';
import 'my_touren_tab.dart';
import 'my_dokumente_tab.dart';
import 'my_stundenzettel_tab.dart';

class EmployeeShell extends StatefulWidget {
  const EmployeeShell({super.key});

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    MyTourenTab(),
    MyDokumenteTab(),
    MyStundenzettelTab(),
  ];

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderGold),
        ),
        title: const Text(
          'Abmelden',
          style: TextStyle(
            color: AppTheme.textGold,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Möchten Sie sich wirklich abmelden?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Abmelden',
              style: TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

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
            onPressed: () => _logout(context),
            icon: const Icon(
              Icons.logout_rounded,
              color: AppTheme.error,
            ),
            tooltip: 'Abmelden',
          ),
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
                ],
              ),
            ),
    );
  }
}
