import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/tour_model.dart';

class TourCard extends StatelessWidget {
  final TourModel tour;
  final VoidCallback onTap;
  final bool showDate;

  const TourCard({
    super.key,
    required this.tour,
    required this.onTap,
    this.showDate = true,
  });

  Color get _statusColor {
    switch (tour.status) {
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
    switch (tour.status) {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _statusColor.withOpacity(0.3),
            width: 1.2,
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
                      // Status icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _statusIcon,
                          color: _statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tour.locationName,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tour.address,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _statusColor.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          tour.status.label,
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (tour.description != null &&
                      tour.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      tour.description!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (showDate) ...[
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd.MM.yyyy').format(tour.tourDate),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (tour.acceptedAt != null) ...[
                        const Icon(
                          Icons.login_rounded,
                          size: 13,
                          color: AppTheme.info,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Angenommen: ${DateFormat('HH:mm').format(tour.acceptedAt!)}',
                          style: const TextStyle(
                            color: AppTheme.info,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (tour.completedAt != null) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.logout_rounded,
                          size: 13,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Beendet: ${DateFormat('HH:mm').format(tour.completedAt!)}',
                          style: const TextStyle(
                            color: AppTheme.success,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
