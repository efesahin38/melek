import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../models/stundenzettel_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/gold_button.dart';
import 'create_stundenzettel_screen.dart';
import 'stundenzettel_detail_screen.dart';

class StundenzettelTab extends StatefulWidget {
  const StundenzettelTab({super.key});

  @override
  State<StundenzettelTab> createState() => _StundenzettelTabState();
}

class _StundenzettelTabState extends State<StundenzettelTab> {
  List<StundenzettelModel> _stundenzettels = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStundenzettels();
  }

  Future<void> _loadStundenzettels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await SupabaseService.getStundenzettels();
      if (mounted) {
        setState(() {
          _stundenzettels = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler beim Laden der Stundenzettel: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToCreate() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateStundenzettelScreen()),
    );
    if (result == true) _loadStundenzettels();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderGold, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_rounded,
                    color: AppTheme.goldPrimary, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stundenzettel',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _isLoading
                            ? 'Wird geladen…'
                            : '${_stundenzettels.length} Einträge',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GoldButton(
                  label: 'Neu erstellen',
                  icon: Icons.add,
                  onPressed: _navigateToCreate,
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildShimmer();
    if (_error != null) return _buildError();
    if (_stundenzettels.isEmpty) return _buildEmptyState();
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
          height: 110,
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
            const Icon(Icons.error_outline_rounded,
                color: AppTheme.error, size: 56),
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
              onPressed: _loadStundenzettels,
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
            child: const Icon(Icons.assignment_outlined,
                color: AppTheme.textMuted, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keine Stundenzettel',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Erstellen Sie den ersten Stundenzettel',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          GoldButton(
            label: 'Neu erstellen',
            icon: Icons.add,
            onPressed: _navigateToCreate,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    // Group by Employee Name -> Year -> List of Stundenzettel
    final grouped = <String, Map<int, List<StundenzettelModel>>>{};
    for (final sz in _stundenzettels) {
      final empName = sz.employeeName ?? 'Unbekannt';
      final year = sz.year;
      grouped.putIfAbsent(empName, () => {});
      grouped[empName]!.putIfAbsent(year, () => []);
      grouped[empName]![year]!.add(sz);
    }

    final employeeNames = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadStundenzettels,
      color: AppTheme.goldPrimary,
      backgroundColor: AppTheme.bgCard,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: employeeNames.length,
        itemBuilder: (context, index) {
          final empName = employeeNames[index];
          final yearMap = grouped[empName]!;
          final years = yearMap.keys.toList()..sort((a, b) => b.compareTo(a));

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: ExpansionTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              iconColor: AppTheme.goldPrimary,
              collapsedIconColor: AppTheme.textMuted,
              title: Row(
                children: [
                  const Icon(Icons.person_rounded, color: AppTheme.goldPrimary),
                  const SizedBox(width: 12),
                  Text(
                    empName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              children: years.map((year) {
                final stundenzettelsForYear = yearMap[year]!;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderGold.withValues(alpha: 0.3)),
                  ),
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    iconColor: AppTheme.goldPrimary,
                    collapsedIconColor: AppTheme.textMuted,
                    title: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: AppTheme.textSecondary, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          year.toString(),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCardElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${stundenzettelsForYear.length}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    children: stundenzettelsForYear.map((sz) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _StundenzettelCard(
                          sz: sz,
                          onTap: () async {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StundenzettelDetailScreen(sz: sz),
                              ),
                            );
                            if (result == true) _loadStundenzettels();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _StundenzettelCard extends StatelessWidget {
  final StundenzettelModel sz;
  final VoidCallback onTap;

  const _StundenzettelCard({required this.sz, required this.onTap});

  Color get _statusColor {
    switch (sz.status) {
      case StundenzettelStatus.draft:
        return AppTheme.warning;
      case StundenzettelStatus.adminSigned:
        return AppTheme.info;
      case StundenzettelStatus.completed:
        return AppTheme.success;
    }
  }

  Color get _statusBgColor {
    switch (sz.status) {
      case StundenzettelStatus.draft:
        return AppTheme.warningBg;
      case StundenzettelStatus.adminSigned:
        return AppTheme.infoBg;
      case StundenzettelStatus.completed:
        return AppTheme.successBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = sz.status == StundenzettelStatus.completed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient:
                          isCompleted ? AppTheme.goldGradient : null,
                      color:
                          isCompleted ? null : AppTheme.bgCardLight,
                      borderRadius: BorderRadius.circular(12),
                      border: isCompleted
                          ? null
                          : Border.all(color: AppTheme.borderGold),
                    ),
                    child: Icon(
                      Icons.assignment_rounded,
                      color: isCompleted
                          ? AppTheme.bgDark
                          : AppTheme.goldPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sz.employeeName ?? 'Unbekannt',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          sz.monthYearLabel,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      sz.status.label,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
                height: 1, thickness: 1, color: AppTheme.divider),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  _statChip(Icons.calendar_today_rounded,
                      '${sz.totalDays ?? 0} Tage'),
                  const SizedBox(width: 12),
                  _statChip(Icons.access_time_rounded,
                      '${(sz.totalHours ?? 0).toStringAsFixed(1)} Stunden'),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textMuted, size: 20),
                ],
              ),
            ),
            if (sz.status == StundenzettelStatus.adminSigned)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.infoBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.info.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppTheme.info, size: 15),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Wartet auf Mitarbeiter-Unterschrift',
                        style: TextStyle(
                          color: AppTheme.info,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.goldPrimary, size: 14),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
