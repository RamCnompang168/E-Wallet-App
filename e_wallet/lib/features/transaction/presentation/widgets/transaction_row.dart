import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Presentation list row for individual transactions.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.credit,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool credit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (credit ? AppColors.accentGreen : AppColors.primaryDark)
                    .withValues(alpha: .10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                credit ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: credit ? const Color(0xFF16A34A) : AppColors.primaryDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: credit
                    ? const Color(0xFF16A34A)
                    : Theme.of(context).colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
