import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'mitarbeiter_tab.dart';
import 'touren_tab.dart';
import 'stundenzettel_tab.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  // Keep tabs alive when switching between them
  static const List<Widget> _tabs = [
    MitarbeiterTab(),
    TourenTab(),
    StundenzettelTab(),
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
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.goldGradient.createShader(bounds),
          child: const Text(
            'MELEK Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
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
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
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
              icon: Icon(Icons.people_alt_rounded),
              label: 'Mitarbeiter',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Touren',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time_rounded),
              label: 'Stundenzettel',
            ),
          ],
        ),
      ),
    );
  }
}
