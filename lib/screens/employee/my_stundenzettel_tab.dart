import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/stundenzettel_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import 'my_stundenzettel_detail_screen.dart';

class MyStundenzettelTab extends StatefulWidget {
  const MyStundenzettelTab({super.key});

  @override
  State<MyStundenzettelTab> createState() => _MyStundenzettelTabState();
}

class _MyStundenzettelTabState extends State<MyStundenzettelTab> {
  List<StundenzettelModel> _stundenzettels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStundenzettels();
  }

  Future<void> _loadStundenzettels() async {
    setState(() => _isLoading = true);
    try {
      final employeeId = context.read<AuthProvider>().user?.id;
      if (employeeId != null) {
        final list =
            await SupabaseService.getStundenzettels(employeeId: employeeId);
        if (mounted) setState(() => _stundenzettels = list);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _hasAdminSigned => _stundenzettels
      .any((sz) => sz.status == StundenzettelStatus.adminSigned);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStundenzettels,
      color: AppTheme.goldPrimary,
      backgroundColor: AppTheme.bgCard,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(
                        Icons.assignment_rounded,
                        color: AppTheme.goldPrimary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Stundenzettel',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.goldGlow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderGold),
                        ),
                        child: Text(
                          '${_stundenzettels.length}',
                          style: const TextStyle(
                            color: AppTheme.textGold,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Info banner if admin has signed
                  if (_hasAdminSigned)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.warningBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.warning.withOpacity(0.5),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.draw_rounded,
                            color: AppTheme.warning,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sie haben Stundenzettel zu unterschreiben!',
                              style: TextStyle(
                                color: AppTheme.warning,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child:
                    CircularProgressIndicator(color: AppTheme.goldPrimary),
              ),
            )
          else if (_stundenzettels.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Icon(
                        Icons.assignment_outlined,
                        color: AppTheme.textMuted,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Keine Stundenzettel vorhanden',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildSliverList(),
        ],
      ),
    );
  }

  Widget _buildSliverList() {
    final grouped = <int, List<StundenzettelModel>>{};
    for (final sz in _stundenzettels) {
      grouped.putIfAbsent(sz.year, () => []).add(sz);
    }
    final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final year = years[index];
            final stundenzettelsForYear = grouped[year]!;

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
                initiallyExpanded: index == 0,
                iconColor: AppTheme.goldPrimary,
                collapsedIconColor: AppTheme.textMuted,
                title: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppTheme.goldPrimary),
                    const SizedBox(width: 12),
                    Text(
                      year.toString(),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
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
                            builder: (_) => MyStundenzettelDetailScreen(sz: sz),
                          ),
                        );
                        if (result == true) _loadStundenzettels();
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          },
          childCount: years.length,
        ),
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
        return AppTheme.textSecondary;
      case StundenzettelStatus.adminSigned:
        return AppTheme.warning;
      case StundenzettelStatus.completed:
        return AppTheme.success;
    }
  }

  String get _statusLabel {
    switch (sz.status) {
      case StundenzettelStatus.draft:
        return 'Entwurf';
      case StundenzettelStatus.adminSigned:
        return 'Unterschrift erforderlich';
      case StundenzettelStatus.completed:
        return 'Abgeschlossen';
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsSignature = sz.status == StundenzettelStatus.adminSigned;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: needsSignature
                ? AppTheme.warning.withOpacity(0.5)
                : AppTheme.border,
            width: needsSignature ? 1.5 : 1,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.assignment_rounded,
                          color: _statusColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sz.monthYearLabel,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${sz.totalDays ?? 0} Tage · ${(sz.totalHours ?? 0).toStringAsFixed(1)} Std.',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      if (needsSignature)
                        _PulsingBadge(label: _statusLabel, color: _statusColor)
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _statusColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            _statusLabel,
                            style: TextStyle(
                              color: _statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingBadge extends StatefulWidget {
  final String label;
  final Color color;
  const _PulsingBadge({required this.label, required this.color});

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.12 + 0.08 * _anim.value),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.color.withOpacity(_anim.value),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.draw_rounded, color: widget.color, size: 12),
            const SizedBox(width: 4),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
