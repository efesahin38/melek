import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/tour_model.dart';
import '../../services/neon_service.dart';
import '../../widgets/gold_button.dart';

class TourDetailAdminScreen extends StatefulWidget {
  final TourModel tour;

  const TourDetailAdminScreen({super.key, required this.tour});

  @override
  State<TourDetailAdminScreen> createState() => _TourDetailAdminScreenState();
}

class _TourDetailAdminScreenState extends State<TourDetailAdminScreen> {
  late TourModel _tour;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tour = widget.tour;
  }

  Future<void> _deleteTour() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderGold),
        ),
        title: const Text('Tour löschen?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Diese Tour wird permanent gelöscht.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await NeonService.deleteTour(_tour.id);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler: $e')),
          );
        }
      }
    }
  }

  Color get _statusColor {
    switch (_tour.status) {
      case TourStatus.pending:
        return AppTheme.warning;
      case TourStatus.accepted:
        return AppTheme.info;
      case TourStatus.inProgress:
        return AppTheme.goldPrimary;
      case TourStatus.completed:
        return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy', 'de_DE');
    final timeFormat = DateFormat('HH:mm', 'de_DE');

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Tour Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _deleteTour,
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: _statusColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Status: ${_tour.status.label}',
                    style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main info card
            _infoCard(
              children: [
                _infoRow(
                  Icons.location_on_rounded,
                  'Standort',
                  _tour.locationName,
                  AppTheme.goldPrimary,
                  large: true,
                ),
                const Divider(color: AppTheme.divider),
                _infoRow(
                  Icons.map_rounded,
                  'Adresse',
                  _tour.address,
                  AppTheme.info,
                ),
                if (_tour.description != null &&
                    _tour.description!.isNotEmpty) ...[
                  const Divider(color: AppTheme.divider),
                  _infoRow(
                    Icons.description_rounded,
                    'Beschreibung',
                    _tour.description!,
                    AppTheme.textSecondary,
                  ),
                ],
                const Divider(color: AppTheme.divider),
                _infoRow(
                  Icons.calendar_today_rounded,
                  'Datum',
                  dateFormat.format(_tour.tourDate),
                  AppTheme.goldLight,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Timing card (admin-only detail)
            _infoCard(
              title: '⏱ Zeiterfassung (nur Admin)',
              children: [
                _timingRow(
                  'Angenommen um',
                  _tour.acceptedAt != null
                      ? timeFormat.format(_tour.acceptedAt!)
                      : '–',
                  AppTheme.info,
                  Icons.login_rounded,
                ),
                const Divider(color: AppTheme.divider),
                _timingRow(
                  'Beendet um',
                  _tour.completedAt != null
                      ? timeFormat.format(_tour.completedAt!)
                      : '–',
                  AppTheme.success,
                  Icons.logout_rounded,
                ),
                if (_tour.acceptedAt != null && _tour.completedAt != null) ...[
                  const Divider(color: AppTheme.divider),
                  _timingRow(
                    'Dauer',
                    () {
                      final diff = _tour.completedAt!
                          .difference(_tour.acceptedAt!);
                      final h = diff.inHours;
                      final m = diff.inMinutes % 60;
                      return '${h}h ${m}min';
                    }(),
                    AppTheme.goldPrimary,
                    Icons.timer_rounded,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Driver card
            if (_tour.driverId != null)
              _infoCard(
                title: '🚗 Fahrer',
                children: [
                  _infoRow(
                    Icons.person_rounded,
                    'Mitarbeiter',
                    _tour.driverName ?? _tour.driverId ?? '–',
                    AppTheme.textPrimary,
                    large: true,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
      {String? title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textGold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor, {
    bool large = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: large ? 18 : 14,
                    fontWeight:
                        large ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timingRow(String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
