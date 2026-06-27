import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/stundenzettel_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/neon_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/signature_pad_dialog.dart';

class MyStundenzettelDetailScreen extends StatefulWidget {
  final StundenzettelModel sz;

  const MyStundenzettelDetailScreen({super.key, required this.sz});

  @override
  State<MyStundenzettelDetailScreen> createState() =>
      _MyStundenzettelDetailScreenState();
}

class _MyStundenzettelDetailScreenState
    extends State<MyStundenzettelDetailScreen> {
  late StundenzettelModel _sz;
  bool _isLoading = true;
  bool _isSigning = false;

  @override
  void initState() {
    super.initState();
    _sz = widget.sz;
    _reloadSz();
  }

  Future<void> _reloadSz() async {
    setState(() => _isLoading = true);
    try {
      final fresh = await NeonService.getStundenzettelById(_sz.id);
      if (fresh != null && mounted) setState(() => _sz = fresh);
    } catch (_) {
      // fallback to widget.sz
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color get _statusColor {
    switch (_sz.status) {
      case StundenzettelStatus.draft:
        return AppTheme.textSecondary;
      case StundenzettelStatus.adminSigned:
        return AppTheme.warning;
      case StundenzettelStatus.completed:
        return AppTheme.success;
    }
  }

  String get _statusLabel => _sz.status.label;

  Future<void> _signAsEmployee() async {
    final signature = await SignaturePadDialog.show(
      context,
      title: 'Ihre Unterschrift',
    );
    if (signature == null || !mounted) return;

    setState(() => _isSigning = true);
    try {
      await NeonService.signStundenzettelEmployee(
        id: _sz.id,
        signature: signature,
      );
      await _reloadSz();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 18),
                SizedBox(width: 8),
                Text('Erfolgreich unterschrieben!'),
              ],
            ),
            backgroundColor: AppTheme.bgCardElevated,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }

      // Auto-generate and upload PDF when both signatures present
      if (_sz.isFullySigned && mounted) {
        await _generateAndUploadPdf();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigning = false);
    }
  }

  Future<void> _generateAndUploadPdf() async {
    final auth = context.read<AuthProvider>();
    final employeeName = auth.user?.name ?? _sz.employeeName ?? 'Mitarbeiter';
    final employeeId = _sz.employeeId;

    try {
      final pdfBytes = await PdfService.generateStundenzettel(_sz, employeeName);
      final base64Data = base64Encode(pdfBytes);

      final fileName =
          'Stundenzettel_${_sz.monthYearLabel.replaceAll(' ', '_')}_$employeeName.pdf';

      await NeonService.uploadDocument(
        employeeId: employeeId,
        folderId: 11,
        fileName: fileName,
        fileType: 'application/pdf',
        fileData: base64Data,
        uploadedBy: auth.user?.id ?? employeeId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.picture_as_pdf_rounded,
                    color: AppTheme.goldPrimary, size: 18),
                SizedBox(width: 8),
                Text('PDF gespeichert in Arbeitszeitnachweis'),
              ],
            ),
            backgroundColor: AppTheme.bgCardElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF-Fehler: $e')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'de_DE');
    final canSign = _sz.status == StundenzettelStatus.adminSigned &&
        _sz.employeeSignature == null;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(_sz.monthYearLabel),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldPrimary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _statusColor.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _sz.status == StundenzettelStatus.completed
                              ? Icons.check_circle_rounded
                              : _sz.status ==
                                      StundenzettelStatus.adminSigned
                                  ? Icons.draw_rounded
                                  : Icons.edit_document,
                          color: _statusColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Status: $_statusLabel',
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Employee header card
                  _card(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppTheme.bgDark,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _sz.employeeName ?? 'Mitarbeiter',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _sz.monthYearLabel,
                                  style: const TextStyle(
                                    color: AppTheme.textGold,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppTheme.divider),
                      const SizedBox(height: 12),
                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _statBox(
                              label: 'Arbeitstage',
                              value: '${_sz.totalDays ?? 0}',
                              unit: 'Tage',
                              icon: Icons.calendar_month_rounded,
                              color: AppTheme.info,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statBox(
                              label: 'Gesamtstunden',
                              value:
                                  ((_sz.totalHours ?? 0)).toStringAsFixed(1),
                              unit: 'Std.',
                              icon: Icons.access_time_rounded,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Work entries table
                  if (_sz.workEntries.isNotEmpty) ...[
                    const Text(
                      'Arbeitszeiten',
                      style: TextStyle(
                        color: AppTheme.textGold,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              AppTheme.bgCardElevated,
                            ),
                            dataRowColor: WidgetStateProperty.resolveWith(
                              (states) => AppTheme.bgCard,
                            ),
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                color: AppTheme.divider,
                                width: 0.5,
                              ),
                            ),
                            headingTextStyle: const TextStyle(
                              color: AppTheme.textGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            dataTextStyle: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                            ),
                            columnSpacing: 20,
                            horizontalMargin: 14,
                            columns: const [
                              DataColumn(label: Text('Datum')),
                              DataColumn(label: Text('Von')),
                              DataColumn(label: Text('Bis')),
                              DataColumn(label: Text('Std.')),
                              DataColumn(label: Text('Notiz')),
                            ],
                            rows: _sz.workEntries.map((entry) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(
                                    DateFormat('dd.MM.yy')
                                        .format(entry.date),
                                  )),
                                  DataCell(Text(entry.startTime)),
                                  DataCell(Text(entry.endTime)),
                                  DataCell(Text(
                                    entry.hours.toStringAsFixed(1),
                                    style: const TextStyle(
                                        color: AppTheme.goldLight,
                                        fontWeight: FontWeight.w600),
                                  )),
                                  DataCell(Text(
                                    entry.note ?? '–',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary),
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Signatures section
                  const Text(
                    'Unterschriften',
                    style: TextStyle(
                      color: AppTheme.textGold,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Admin signature box
                  _signatureBox(
                    title: 'Admin / Arbeitgeber',
                    icon: Icons.admin_panel_settings_rounded,
                    iconColor: AppTheme.info,
                    signatureBase64: _sz.adminSignature,
                    signedAt: _sz.adminSignedAt != null
                        ? dateFormat.format(_sz.adminSignedAt!)
                        : null,
                    pendingText: 'Ausstehend',
                  ),
                  const SizedBox(height: 12),

                  // Employee signature box
                  _sz.employeeSignature != null
                      ? _signatureBox(
                          title: 'Meine Unterschrift',
                          icon: Icons.person_rounded,
                          iconColor: AppTheme.success,
                          signatureBase64: _sz.employeeSignature,
                          signedAt: _sz.employeeSignedAt != null
                              ? dateFormat.format(_sz.employeeSignedAt!)
                              : null,
                          pendingText: null,
                        )
                      : _employeeSignatureAction(canSign),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _employeeSignatureAction(bool canSign) {
    if (_sz.status == StundenzettelStatus.draft) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.infoBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.info.withOpacity(0.35)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Warten auf Admin-Unterschrift',
                style: TextStyle(
                  color: AppTheme.info,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canSign
              ? AppTheme.warning.withOpacity(0.5)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                color: AppTheme.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Meine Unterschrift',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GoldButton(
            label: 'Jetzt unterschreiben',
            icon: Icons.draw_rounded,
            isLoading: _isSigning,
            width: double.infinity,
            onPressed: canSign ? _signAsEmployee : null,
          ),
        ],
      ),
    );
  }

  Widget _signatureBox({
    required String title,
    required IconData icon,
    required Color iconColor,
    String? signatureBase64,
    String? signedAt,
    String? pendingText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: signatureBase64 != null
              ? AppTheme.success.withOpacity(0.4)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (signatureBase64 != null) ...[
                const Spacer(),
                const Icon(
                    Icons.verified_rounded,
                    color: AppTheme.success,
                    size: 16),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (signatureBase64 != null) ...[
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderGold),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(signatureBase64),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (signedAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Unterschrieben: $signedAt',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ] else
            Text(
              pendingText ?? 'Ausstehend',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _statBox({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
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
