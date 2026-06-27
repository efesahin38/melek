import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../services/neon_service.dart';
import '../../widgets/gold_button.dart';
import 'mitarbeiter_detail_screen.dart';
import 'add_mitarbeiter_screen.dart';

class MitarbeiterTab extends StatefulWidget {
  const MitarbeiterTab({super.key});

  @override
  State<MitarbeiterTab> createState() => _MitarbeiterTabState();
}

class _MitarbeiterTabState extends State<MitarbeiterTab> {
  List<UserModel> _employees = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final employees = await NeonService.getEmployees();
      if (mounted) {
        setState(() {
          _employees = employees;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler beim Laden der Mitarbeiter: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDelete(UserModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderGold),
        ),
        title: const Text(
          'Mitarbeiter löschen',
          style: TextStyle(
            color: AppTheme.textGold,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Möchten Sie "${employee.name}" wirklich löschen?\nDiese Aktion kann nicht rückgängig gemacht werden.',
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
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
              'Löschen',
              style: TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteEmployee(employee);
    }
  }

  Future<void> _deleteEmployee(UserModel employee) async {
    try {
      await NeonService.deleteUser(employee.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${employee.name} wurde gelöscht.',
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            backgroundColor: AppTheme.bgCardElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _loadEmployees();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fehler beim Löschen: ${e.toString()}',
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            backgroundColor: AppTheme.errorBg,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddMitarbeiter() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddMitarbeiterScreen()),
    );
    if (result == true) {
      _loadEmployees();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderGold, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.people_alt_rounded,
                  color: AppTheme.goldPrimary,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mitarbeiter',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _isLoading
                            ? 'Wird geladen…'
                            : '${_employees.length} Mitarbeiter',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GoldButton(
                  label: 'Hinzufügen',
                  icon: Icons.person_add_rounded,
                  onPressed: _navigateToAddMitarbeiter,
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildShimmer();
    if (_error != null) return _buildError();
    if (_employees.isEmpty) return _buildEmptyState();
    return _buildList();
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppTheme.bgCard,
      highlightColor: AppTheme.bgCardElevated,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 84,
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GoldButton(
              label: 'Erneut versuchen',
              icon: Icons.refresh_rounded,
              outline: true,
              onPressed: _loadEmployees,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderGold),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: AppTheme.textMuted,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keine Mitarbeiter gefunden',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Fügen Sie den ersten Mitarbeiter hinzu',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          GoldButton(
            label: 'Mitarbeiter hinzufügen',
            icon: Icons.person_add_rounded,
            onPressed: _navigateToAddMitarbeiter,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadEmployees,
      color: AppTheme.goldPrimary,
      backgroundColor: AppTheme.bgCard,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _employees.length,
        itemBuilder: (context, index) {
          final employee = _employees[index];
          return _EmployeeCard(
            employee: employee,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MitarbeiterDetailScreen(employee: employee),
              ),
            ).then((_) => _loadEmployees()),
            onDelete: () => _confirmDelete(employee),
          );
        },
      ),
    );
  }
}

// ── Employee Card ────────────────────────────────────────────────────────────

class _EmployeeCard extends StatelessWidget {
  final UserModel employee;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EmployeeCard({
    required this.employee,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = employee.isAdmin;
    final initial =
        employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?';

    return Dismissible(
      key: Key(employee.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // We handle deletion manually inside onDelete
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.errorBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.error.withOpacity(0.4)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppTheme.error,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderGold),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.goldShadow,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppTheme.bgDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.email,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (employee.phone != null &&
                        employee.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        employee.phone!,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Role badge + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? AppTheme.goldGlow
                          : AppTheme.bgCardElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isAdmin
                            ? AppTheme.goldPrimary
                            : AppTheme.border,
                      ),
                    ),
                    child: Text(
                      isAdmin ? 'Admin' : 'Mitarbeiter',
                      style: TextStyle(
                        color: isAdmin
                            ? AppTheme.textGold
                            : AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
