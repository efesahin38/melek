import 'package:flutter/material.dart';
import '../config/theme.dart';

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outline;
  final IconData? icon;
  final double? width;

  const GoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.outline = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (outline) {
      return SizedBox(
        width: width,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.goldPrimary,
            side: const BorderSide(color: AppTheme.goldPrimary, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.goldPrimary,
                  ),
                )
              : (icon != null
                  ? Icon(icon, size: 18)
                  : const SizedBox.shrink()),
          label: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isLoading ? [] : AppTheme.goldShadow,
        ),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppTheme.bgDark,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.bgDark,
                  ),
                )
              : (icon != null
                  ? Icon(icon, size: 18)
                  : const SizedBox.shrink()),
          label: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.bgDark,
            ),
          ),
        ),
      ),
    );
  }
}
