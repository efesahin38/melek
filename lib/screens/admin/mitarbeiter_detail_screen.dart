import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../models/document_model.dart';
import '../../services/neon_service.dart';
import '../../widgets/folder_card.dart';
import 'folder_documents_screen.dart';

class MitarbeiterDetailScreen extends StatefulWidget {
  final UserModel employee;

  const MitarbeiterDetailScreen({super.key, required this.employee});

  @override
  State<MitarbeiterDetailScreen> createState() =>
      _MitarbeiterDetailScreenState();
}

class _MitarbeiterDetailScreenState extends State<MitarbeiterDetailScreen> {
  Map<int, int> documentCounts = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocumentCounts();
  }

  Future<void> _loadDocumentCounts() async {
    setState(() => isLoading = true);
    try {
      final counts = await NeonService.getDocumentCountsByEmployee(
        widget.employee.id,
      );
      if (mounted) {
        setState(() {
          documentCounts = counts;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fehler beim Laden: ${e.toString()}',
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            backgroundColor: AppTheme.errorBg,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  int get _totalDocuments =>
      documentCounts.values.fold(0, (sum, count) => sum + count);

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;
    final dateFormatter = DateFormat('dd.MM.yyyy');

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.goldPrimary),
        ),
        title: Text(
          employee.name,
          style: const TextStyle(
            color: AppTheme.goldLight,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
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
      ),
      body: RefreshIndicator(
        onRefresh: _loadDocumentCounts,
        color: AppTheme.goldPrimary,
        backgroundColor: AppTheme.bgCard,
        child: CustomScrollView(
          slivers: [
            // ─── Header Card ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: _EmployeeHeaderCard(
                  employee: employee,
                  totalDocuments: _totalDocuments,
                  dateFormatter: dateFormatter,
                ),
              ),
            ),

            // ─── Section Title ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Dokumente',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.goldPrimary,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.goldGlow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderGold),
                        ),
                        child: Text(
                          '$_totalDocuments Gesamt',
                          style: const TextStyle(
                            color: AppTheme.textGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ─── Folder Grid ──────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final folder = DocumentFolder.defaultFolders[index];
                    return FolderCard(
                      folder: folder,
                      documentCount: documentCounts[folder.id] ?? 0,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FolderDocumentsScreen(
                              employeeId: employee.id,
                              folderId: folder.id,
                              folderName: folder.name,
                              isAdmin: true,
                            ),
                          ),
                        ).then((_) => _loadDocumentCounts());
                      },
                    );
                  },
                  childCount: DocumentFolder.defaultFolders.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Employee Header Card ─────────────────────────────────────────────────────

class _EmployeeHeaderCard extends StatelessWidget {
  final UserModel employee;
  final int totalDocuments;
  final DateFormat dateFormatter;

  const _EmployeeHeaderCard({
    required this.employee,
    required this.totalDocuments,
    required this.dateFormatter,
  });

  String get _roleLabel {
    switch (employee.role) {
      case 'admin':
        return 'Administrator';
      case 'employee':
        return 'Mitarbeiter';
      default:
        return employee.role;
    }
  }

  Color get _roleBadgeColor {
    return employee.isAdmin ? AppTheme.goldPrimary : AppTheme.info;
  }

  @override
  Widget build(BuildContext context) {
    final initials = employee.name.isNotEmpty
        ? employee.name
            .trim()
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGold),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Avatar + Name Row
          Row(
            children: [
              // Avatar circle with gold gradient
              Container(
                width: 72,
                height: 72,
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
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name, email, role badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.email,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _roleBadgeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _roleBadgeColor.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        _roleLabel,
                        style: TextStyle(
                          color: _roleBadgeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 16),

          // Info Row: phone, created date, document count
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.phone_rounded,
                  label: 'Telefon',
                  value:
                      (employee.phone != null && employee.phone!.isNotEmpty)
                          ? employee.phone!
                          : '–',
                ),
              ),
              Container(width: 1, height: 36, color: AppTheme.border),
              Expanded(
                child: _InfoTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Erstellt',
                  value: dateFormatter.format(employee.createdAt),
                ),
              ),
              Container(width: 1, height: 36, color: AppTheme.border),
              Expanded(
                child: _InfoTile(
                  icon: Icons.folder_rounded,
                  label: 'Dokumente',
                  value: '$totalDocuments',
                  valueColor: AppTheme.textGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.goldPrimary, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
