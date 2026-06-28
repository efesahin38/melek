import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'package:desktop_drop/desktop_drop.dart';
import '../../config/theme.dart';
import '../../models/document_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/gold_button.dart';

class FolderDocumentsScreen extends StatefulWidget {
  final String employeeId;
  final int folderId;
  final String folderName;
  final bool isAdmin;

  const FolderDocumentsScreen({
    super.key,
    required this.employeeId,
    required this.folderId,
    required this.folderName,
    required this.isAdmin,
  });

  @override
  State<FolderDocumentsScreen> createState() => _FolderDocumentsScreenState();
}

class _FolderDocumentsScreenState extends State<FolderDocumentsScreen> {
  List<DocumentModel> documents = [];
  bool isLoading = true;
  bool _isUploading = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => isLoading = true);
    try {
      final docs = await SupabaseService.getDocuments(
        employeeId: widget.employeeId,
        folderId: widget.folderId,
      );
      if (mounted) {
        setState(() {
          documents = docs;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showError('Fehler beim Laden: ${e.toString()}');
      }
    }
  }

  // ─── Upload ────────────────────────────────────────────────────────────────

  Future<void> _uploadFile() async {
    final authProvider = context.read<AuthProvider>();
    final uploader = authProvider.user;
    if (uploader == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        _showError('Datei konnte nicht gelesen werden.');
        return;
      }

      setState(() => _isUploading = true);

      final base64Data = base64Encode(file.bytes!);
      final fileType = _getMimeType(file.name);

      await SupabaseService.uploadDocument(
        employeeId: widget.employeeId,
        folderId: widget.folderId,
        fileName: file.name,
        fileType: fileType,
        fileData: base64Data,
        uploadedBy: uploader.id,
      );

      await _loadDocuments();

      if (mounted) {
        _showSuccess('„${file.name}" erfolgreich hochgeladen.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Fehler beim Hochladen: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _handleDrop(DropDoneDetails detail) async {
    setState(() => _isDragging = false);
    if (detail.files.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final uploader = authProvider.user;
    if (uploader == null) return;

    setState(() => _isUploading = true);

    try {
      for (final xfile in detail.files) {
        final bytes = await xfile.readAsBytes();
        final base64Data = base64Encode(bytes);
        final fileType = _getMimeType(xfile.name);

        await SupabaseService.uploadDocument(
          employeeId: widget.employeeId,
          folderId: widget.folderId,
          fileName: xfile.name,
          fileType: fileType,
          fileData: base64Data,
          uploadedBy: uploader.id,
        );
      }
      await _loadDocuments();
      if (mounted) {
        _showSuccess('${detail.files.length} Datei(en) erfolgreich hochgeladen.');
      }
    } catch (e) {
      if (mounted) _showError('Fehler beim Hochladen: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ─── Open File ─────────────────────────────────────────────────────────────

  Future<void> _openFile(DocumentModel doc) async {
    if (doc.fileData == null || doc.fileData!.isEmpty) {
      _showError('Keine Dateidaten verfügbar.');
      return;
    }
    try {
      if (kIsWeb) {
        final mimeType = doc.fileType;
        final uri = 'data:$mimeType;base64,${doc.fileData}';
        html.AnchorElement(href: uri)
          ..setAttribute('download', doc.fileName)
          ..click();
        return;
      }

      final bytes = base64Decode(doc.fileData!);
      final tempDir = await getTemporaryDirectory();
      final safeFileName = doc.fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final tempFile = File('${tempDir.path}/$safeFileName');
      await tempFile.writeAsBytes(bytes);
      final result = await OpenFile.open(tempFile.path);
      if (result.type != ResultType.done && mounted) {
        _showError('Datei konnte nicht geöffnet werden: ${result.message}');
      }
    } catch (e) {
      if (mounted) {
        _showError('Fehler beim Öffnen: ${e.toString()}');
      }
    }
  }

  // ─── Share File ────────────────────────────────────────────────────────────

  Future<void> _shareFile(DocumentModel doc) async {
    if (doc.fileData == null || doc.fileData!.isEmpty) {
      _showError('Keine Dateidaten verfügbar.');
      return;
    }
    try {
      if (kIsWeb) {
        // On web, sharing is identical to downloading for our purposes
        final mimeType = doc.fileType;
        final uri = 'data:$mimeType;base64,${doc.fileData}';
        html.AnchorElement(href: uri)
          ..setAttribute('download', doc.fileName)
          ..click();
        return;
      }

      final bytes = base64Decode(doc.fileData!);
      final tempDir = await getTemporaryDirectory();
      final safeFileName = doc.fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final tempFile = File('${tempDir.path}/$safeFileName');
      await tempFile.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: doc.fileType)],
        subject: doc.fileName,
      );
    } catch (e) {
      if (mounted) {
        _showError('Fehler beim Teilen: ${e.toString()}');
      }
    }
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  Future<void> _deleteDocument(DocumentModel doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderGold),
        ),
        title: const Text(
          'Dokument löschen?',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Möchten Sie dieses Dokument wirklich löschen?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_rounded,
                      color: AppTheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doc.fileName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseService.deleteDocument(doc.id);
      await _loadDocuments();
      if (mounted) {
        _showSuccess('Dokument wurde gelöscht.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Fehler beim Löschen: ${e.toString()}');
      }
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.bgCardElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.errorBg,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  IconData _fileIcon(DocumentModel doc) {
    if (doc.isPdf) return Icons.picture_as_pdf_rounded;
    if (doc.isImage) return Icons.image_rounded;
    final ext = doc.fileExtension.toLowerCase();
    if (ext == 'doc' || ext == 'docx') return Icons.description_rounded;
    if (ext == 'xls' || ext == 'xlsx') return Icons.table_chart_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _fileIconColor(DocumentModel doc) {
    if (doc.isPdf) return AppTheme.error;
    if (doc.isImage) return AppTheme.info;
    final ext = doc.fileExtension.toLowerCase();
    if (ext == 'doc' || ext == 'docx') return const Color(0xFF4488FF);
    if (ext == 'xls' || ext == 'xlsx') return AppTheme.success;
    return AppTheme.textSecondary;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
          widget.folderName,
          style: const TextStyle(
            color: AppTheme.goldLight,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _isUploading ? null : _uploadFile,
                tooltip: 'Datei hochladen',
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.goldPrimary,
                        ),
                      )
                    : const Icon(
                        Icons.upload_file_rounded,
                        color: AppTheme.goldPrimary,
                      ),
              ),
            ),
        ],
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
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: _isUploading ? null : _uploadFile,
              backgroundColor: AppTheme.goldPrimary,
              foregroundColor: AppTheme.bgDark,
              tooltip: 'Datei hochladen',
              child: _isUploading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.bgDark,
                      ),
                    )
                  : const Icon(Icons.upload_file_rounded),
            )
          : null,
      body: DropTarget(
        onDragDone: widget.isAdmin ? _handleDrop : null,
        onDragEntered: (_) {
          if (widget.isAdmin) setState(() => _isDragging = true);
        },
        onDragExited: (_) {
          if (widget.isAdmin) setState(() => _isDragging = false);
        },
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadDocuments,
              color: AppTheme.goldPrimary,
              backgroundColor: AppTheme.bgCard,
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.goldPrimary),
                    )
                  : documents.isEmpty
                      ? _buildEmptyState()
                      : _buildDocumentList(),
            ),
            if (_isDragging)
              Container(
                color: AppTheme.goldPrimary.withOpacity(0.15),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCardElevated,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.goldPrimary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldPrimary.withOpacity(0.3),
                          blurRadius: 24,
                          spreadRadius: 8,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.upload_file_rounded, size: 64, color: AppTheme.goldPrimary),
                        const SizedBox(height: 16),
                        const Text(
                          'Dateien hier ablegen',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  color: AppTheme.textMuted,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Keine Dokumente in diesem Ordner',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tippen Sie auf „+" um eine Datei hochzuladen.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
              if (widget.isAdmin) ...[
                const SizedBox(height: 28),
                GoldButton(
                  label: 'Datei hochladen',
                  icon: Icons.upload_file_rounded,
                  isLoading: _isUploading,
                  onPressed: _uploadFile,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── Document List ─────────────────────────────────────────────────────────

  Widget _buildDocumentList() {
    final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        widget.isAdmin ? 100 : 24,
      ),
      itemCount: documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = documents[index];
        return _DocumentCard(
          doc: doc,
          dateFormatter: dateFormatter,
          isAdmin: widget.isAdmin,
          fileIcon: _fileIcon(doc),
          fileIconColor: _fileIconColor(doc),
          onOpen: () => _openFile(doc),
          onShare: () => _shareFile(doc),
          onDelete: widget.isAdmin ? () => _deleteDocument(doc) : null,
        );
      },
    );
  }
}

// ─── Document Card ─────────────────────────────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  final DocumentModel doc;
  final DateFormat dateFormatter;
  final bool isAdmin;
  final IconData fileIcon;
  final Color fileIconColor;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback? onDelete;

  const _DocumentCard({
    required this.doc,
    required this.dateFormatter,
    required this.isAdmin,
    required this.fileIcon,
    required this.fileIconColor,
    required this.onOpen,
    required this.onShare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── File Info Row ───────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File type icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: fileIconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: fileIconColor.withOpacity(0.3)),
                  ),
                  child: Icon(fileIcon, color: fileIconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.fileName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: AppTheme.textMuted,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormatter.format(doc.createdAt),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // File extension badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: fileIconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: fileIconColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    doc.fileExtension,
                    style: TextStyle(
                      color: fileIconColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 10),

            // ─── Action Buttons ──────────────────────────────────────
            Row(
              children: [
                // Öffnen
                Expanded(
                  child: _ActionButton(
                    icon: Icons.open_in_new_rounded,
                    label: 'Öffnen',
                    color: AppTheme.goldPrimary,
                    onTap: onOpen,
                  ),
                ),
                const SizedBox(width: 8),
                // Teilen
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share_rounded,
                    label: 'Teilen',
                    color: AppTheme.info,
                    onTap: onShare,
                  ),
                ),
                if (isAdmin && onDelete != null) ...[
                  const SizedBox(width: 8),
                  // Löschen
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Löschen',
                      color: AppTheme.error,
                      onTap: onDelete!,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: color.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
