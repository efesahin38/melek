import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/tour_model.dart';
import '../../services/neon_service.dart';
import '../../widgets/gold_button.dart';

class MyTourDetailScreen extends StatefulWidget {
  final TourModel tour;

  const MyTourDetailScreen({super.key, required this.tour});

  @override
  State<MyTourDetailScreen> createState() => _MyTourDetailScreenState();
}

class _MyTourDetailScreenState extends State<MyTourDetailScreen> {
  late TourModel _tour;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tour = widget.tour;
    _reloadTour();
  }

  Future<void> _reloadTour() async {
    try {
      final fetchedTour = await NeonService.getTourById(_tour.id);
      if (fetchedTour != null && mounted) {
        setState(() => _tour = fetchedTour);
      }
    } catch (_) {
      // Use widget.tour as fallback
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

  IconData get _statusIcon {
    switch (_tour.status) {
      case TourStatus.pending:
        return Icons.hourglass_empty_rounded;
      case TourStatus.accepted:
        return Icons.check_circle_outline_rounded;
      case TourStatus.inProgress:
        return Icons.directions_car_rounded;
      case TourStatus.completed:
        return Icons.check_circle_rounded;
    }
  }

  Future<void> _acceptTour() async {
    setState(() => _isLoading = true);
    try {
      await NeonService.updateTourStatus(
        tourId: _tour.id,
        status: TourStatus.inProgress,
        acceptedAt: DateTime.now(),
      );
      await _reloadTour();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 18),
                SizedBox(width: 8),
                Text('Auftrag angenommen!'),
              ],
            ),
            backgroundColor: AppTheme.bgCardElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeTour() async {
    setState(() => _isLoading = true);
    try {
      await NeonService.updateTourStatus(
        tourId: _tour.id,
        status: TourStatus.completed,
        completedAt: DateTime.now(),
      );
      await _reloadTour();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.task_alt_rounded,
                    color: AppTheme.success, size: 18),
                SizedBox(width: 8),
                Text('Auftrag abgeschlossen!'),
              ],
            ),
            backgroundColor: AppTheme.bgCardElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy', 'de_DE');

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Auftrag Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _statusColor.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon, color: _statusColor, size: 22),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _tour.status.label,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info card
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
            const SizedBox(height: 24),

            // Action buttons based on status
            if (_tour.status == TourStatus.pending)
              GoldButton(
                label: 'Auftrag annehmen',
                icon: Icons.check_rounded,
                isLoading: _isLoading,
                width: double.infinity,
                onPressed: _acceptTour,
              )
            else if (_tour.status == TourStatus.inProgress)
              _completeButton()
            else if (_tour.status == TourStatus.completed)
              _completedBox(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _completeButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A5C35), Color(0xFF44DD88), Color(0xFF2ECC71)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withOpacity(0.3),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _completeTour,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.task_alt_rounded, size: 20),
        label: const Text(
          'Auftrag abschließen',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _completedBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withOpacity(0.4)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 24),
          SizedBox(width: 10),
          Text(
            'Auftrag abgeschlossen ✓',
            style: TextStyle(
              color: AppTheme.success,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({String? title, required List<Widget> children}) {
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
                    color: large ? AppTheme.goldLight : AppTheme.textPrimary,
                    fontSize: large ? 20 : 14,
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
}
