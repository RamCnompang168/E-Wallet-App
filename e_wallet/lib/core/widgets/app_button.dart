import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Primary action button with loading state support.
class YellowButton extends StatelessWidget {
  const YellowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: isLoading ? null : onPressed,
    icon: isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryDark,
            ),
          )
        : icon == null
        ? const SizedBox.shrink()
        : Icon(icon),
    label: Text(isLoading ? 'Working…' : label),
  );
}
