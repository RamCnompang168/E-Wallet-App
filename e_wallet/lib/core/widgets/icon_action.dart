import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Top bar action button with badge indicator.
class IconAction extends StatelessWidget {
  const IconAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.badge = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool badge;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Badge(
      isLabelVisible: badge,
      smallSize: 8,
      backgroundColor: AppColors.accentGreen,
      child: Material(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    ),
  );
}
