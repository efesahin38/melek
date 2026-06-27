import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../config/theme.dart';
import '../widgets/gold_button.dart';

class SignaturePadDialog extends StatefulWidget {
  final String title;

  const SignaturePadDialog({super.key, required this.title});

  static Future<String?> show(BuildContext context, {String title = 'Unterschrift'}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SignaturePadDialog(title: title),
    );
  }

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  late SignatureController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 2.5,
      penColor: AppTheme.bgDark,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte zuerst unterschreiben!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Uint8List? pngBytes = await _controller.toPngBytes(height: 200, width: 400);
      if (pngBytes != null) {
        final base64Str = base64Encode(pngBytes);
        if (mounted) Navigator.of(context).pop(base64Str);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderGold),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.draw_rounded, color: AppTheme.goldPrimary, size: 22),
                const SizedBox(width: 10),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppTheme.textGold,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Bitte im weißen Bereich unterschreiben:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGold, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Signature(
                  controller: _controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GoldButton(
                    label: 'Löschen',
                    outline: true,
                    icon: Icons.refresh_rounded,
                    onPressed: () => _controller.clear(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GoldButton(
                    label: 'Bestätigen',
                    icon: Icons.check_rounded,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
