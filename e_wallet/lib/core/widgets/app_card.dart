import 'package:flutter/material.dart';

/// Reusable fintech card with elevation and outline styling.
class FintechCard extends StatelessWidget {
  const FintechCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? const [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: padding ?? const EdgeInsets.all(18),
        child: child,
      ),
    ),
  );
}

/// Backwards-compatible alias for FintechCard.
class DarkCard extends FintechCard {
  const DarkCard({super.key, required super.child, super.padding, super.onTap});
}
