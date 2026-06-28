import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/tour_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/tour_card.dart';
import 'my_tour_detail_screen.dart';

class MyTourenTab extends StatefulWidget {
  const MyTourenTab({super.key});

  @override
  State<MyTourenTab> createState() => _MyTourenTabState();
}

class _MyTourenTabState extends State<MyTourenTab> {
  List<TourModel> _tours = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        final tours = await SupabaseService.getTours(driverId: userId);
        if (mounted) setState(() => _tours = tours);
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

  int get _pendingCount =>
      _tours.where((t) => t.status == TourStatus.pending).length;
  int get _activeCount =>
      _tours.where((t) => t.status == TourStatus.inProgress).length;
  int get _completedCount =>
      _tours.where((t) => t.status == TourStatus.completed).length;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadTours,
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
                  // Header row
                  Row(
                    children: [
                      const Icon(
                        Icons.work_rounded,
                        color: AppTheme.goldPrimary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Meine Aufträge',
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
                          '${_tours.length}',
                          style: const TextStyle(
                            color: AppTheme.textGold,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pending info banner
                  if (_pendingCount > 0)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.infoBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.info.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications_active_rounded,
                            color: AppTheme.info,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Sie haben $_pendingCount neue Auftrag${_pendingCount == 1 ? '' : 'ä'}ge!',
                            style: const TextStyle(
                              color: AppTheme.info,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Stats chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statChip(
                          label: 'Ausstehend',
                          count: _pendingCount,
                          color: AppTheme.warning,
                        ),
                        const SizedBox(width: 8),
                        _statChip(
                          label: 'Aktiv',
                          count: _activeCount,
                          color: AppTheme.goldPrimary,
                        ),
                        const SizedBox(width: 8),
                        _statChip(
                          label: 'Fertig',
                          count: _completedCount,
                          color: AppTheme.success,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Body
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.goldPrimary),
              ),
            )
          else if (_tours.isEmpty)
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
                        Icons.work_off_rounded,
                        color: AppTheme.textMuted,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Keine Aufträge',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ihnen wurden noch keine Aufträge zugewiesen.',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tour = _tours[index];
                    return TourCard(
                      tour: tour,
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MyTourDetailScreen(tour: tour),
                          ),
                        );
                        if (result == true) _loadTours();
                      },
                    );
                  },
                  childCount: _tours.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statChip({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label ($count)',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
