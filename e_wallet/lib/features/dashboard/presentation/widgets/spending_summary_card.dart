import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_card.dart';

/// Card showing monthly income vs spent metrics with progress indicator.
class SpendingSummaryCard extends StatelessWidget {
  const SpendingSummaryCard({
    super.key,
    this.income = 0.0,
    this.spent = 0.0,
  });

  final double income;
  final double spent;

  @override
  Widget build(BuildContext context) {
    final double budget = income > 0 ? (income > spent ? income : spent * 1.25) : 1000.0;
    final double progress = spent == 0
        ? 1.0
        : ((budget - spent) / budget).clamp(0.0, 1.0);
    final String statusText = spent == 0
        ? 'No spending yet this month'
        : '${(progress * 100).toInt()}% of your monthly budget remains';

    return FintechCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _metric('INCOME', '\$${income.toStringAsFixed(2)}', const Color(0xFF16A34A)),
              Container(width: 1, height: 42, color: AppColors.border),
              _metric('SPENT', '\$${spent.toStringAsFixed(2)}', AppColors.textPrimary),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: AppColors.accentGreen,
              backgroundColor: AppColors.surfaceRaised,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            statusText,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.05,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    ),
  );
}
