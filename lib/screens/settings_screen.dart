import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/gold_button.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          style: TextStyle(color: AppTheme.textGold, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Möchten Sie sich wirklich abmelden?',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abmelden', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.error),
        ),
        title: const Text(
          'Konto löschen',
          style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Möchten Sie Ihr Konto WIRKLICH löschen?\nAlle Ihre Daten werden dauerhaft entfernt. Dies kann nicht rückgängig gemacht werden!',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Endgültig Löschen', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await SupabaseService.deleteUser(user.id);
        if (context.mounted) {
          await context.read<AuthProvider>().logout();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Löschen: $e', style: const TextStyle(color: AppTheme.textPrimary)),
              backgroundColor: AppTheme.errorBg,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox();

    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.goldPrimary),
        ),
        title: const Text(
          'Einstellungen',
          style: TextStyle(color: AppTheme.goldLight, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppTheme.borderGold, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Avatar
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.goldShadow,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: AppTheme.bgDark,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // User Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderGold),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      _ProfileRow(icon: Icons.person_rounded, label: 'Name', value: user.name),
                      const Divider(color: AppTheme.border, height: 30),
                      _ProfileRow(icon: Icons.email_rounded, label: 'E-Mail', value: user.email),
                      const Divider(color: AppTheme.border, height: 30),
                      _ProfileRow(
                        icon: Icons.phone_rounded,
                        label: 'Telefon',
                        value: (user.phone != null && user.phone!.isNotEmpty) ? user.phone! : 'Nicht angegeben',
                      ),
                      const Divider(color: AppTheme.border, height: 30),
                      _ProfileRow(
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'Rolle',
                        value: user.isAdmin ? 'Administrator' : 'Mitarbeiter',
                        valueColor: user.isAdmin ? AppTheme.goldPrimary : AppTheme.info,
                      ),
                      const Divider(color: AppTheme.border, height: 30),
                      _ProfileRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Mitglied seit',
                        value: DateFormat('dd.MM.yyyy').format(user.createdAt.toLocal()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Actions
                GoldButton(
                  label: 'Abmelden',
                  icon: Icons.logout_rounded,
                  onPressed: () => _logout(context),
                  width: double.infinity,
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => _deleteAccount(context),
                  icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.error),
                  label: const Text('Konto löschen', style: TextStyle(color: AppTheme.error)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.goldPrimary, size: 20),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
