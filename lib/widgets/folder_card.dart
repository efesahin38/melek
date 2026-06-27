import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/document_model.dart';

class FolderCard extends StatelessWidget {
  final DocumentFolder folder;
  final int documentCount;
  final VoidCallback onTap;

  const FolderCard({
    super.key,
    required this.folder,
    required this.documentCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: documentCount > 0
                ? AppTheme.goldPrimary.withOpacity(0.5)
                : AppTheme.border,
            width: 1.2,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: AppTheme.goldGlow,
            highlightColor: AppTheme.goldGlow.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Folder icon container
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: documentCount > 0
                              ? AppTheme.goldGradient
                              : null,
                          color: documentCount > 0
                              ? null
                              : AppTheme.bgCardLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            folder.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (documentCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$documentCount',
                            style: const TextStyle(
                              color: AppTheme.bgDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    folder.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    documentCount == 0
                        ? 'Keine Dokumente'
                        : '$documentCount Dokument${documentCount == 1 ? '' : 'e'}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
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
