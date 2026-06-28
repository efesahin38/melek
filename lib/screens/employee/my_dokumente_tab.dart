import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/document_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/folder_card.dart';
import '../admin/folder_documents_screen.dart';

class MyDokumenteTab extends StatefulWidget {
  const MyDokumenteTab({super.key});

  @override
  State<MyDokumenteTab> createState() => _MyDokumenteTabState();
}

class _MyDokumenteTabState extends State<MyDokumenteTab> {
  Map<int, int> _documentCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoading = true);
    try {
      final employeeId = context.read<AuthProvider>().user?.id;
      if (employeeId != null) {
        final counts =
            await SupabaseService.getDocumentCountsByEmployee(employeeId);
        if (mounted) setState(() => _documentCounts = counts);
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

  int get _totalDocuments =>
      _documentCounts.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadCounts,
      color: AppTheme.goldPrimary,
      backgroundColor: AppTheme.bgCard,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(
                        Icons.folder_rounded,
                        color: AppTheme.goldPrimary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Meine Dokumente',
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
                          '$_totalDocuments',
                          style: const TextStyle(
                            color: AppTheme.textGold,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ihre Dokumente (nur Ansicht)',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.goldPrimary),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final folder = DocumentFolder.defaultFolders[index];
                    final count = _documentCounts[folder.id] ?? 0;
                    return FolderCard(
                      folder: folder,
                      documentCount: count,
                      onTap: () async {
                        final employeeId =
                            context.read<AuthProvider>().user?.id ?? '';
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FolderDocumentsScreen(
                              employeeId: employeeId,
                              folderId: folder.id,
                              folderName: folder.name,
                              isAdmin: false,
                            ),
                          ),
                        );
                        _loadCounts();
                      },
                    );
                  },
                  childCount: DocumentFolder.defaultFolders.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
