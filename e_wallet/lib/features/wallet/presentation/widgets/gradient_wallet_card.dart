import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Interactive credit card visual displaying account balance and card details.
class GradientWalletCard extends StatelessWidget {
  const GradientWalletCard({
    super.key,
    required this.balance,
    required this.hidden,
    required this.onVisibilityTap,
    required this.onCopyTap,
    this.cardHolder = 'Jordan Davis',
    this.walletNumber = '••••  ••••  5318',
  });

  final String balance;
  final bool hidden;
  final VoidCallback onVisibilityTap;
  final VoidCallback onCopyTap;
  final String cardHolder;
  final String walletNumber;

  @override
  Widget build(BuildContext context) => Container(
    height: 214,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [AppColors.accentGreen, Color(0xFF22C55E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x4538E54D),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          top: -88,
          right: -54,
          child: _orb(190, Colors.white.withValues(alpha: .18)),
        ),
        Positioned(
          bottom: -105,
          right: 38,
          child: _orb(175, AppColors.primaryDark.withValues(alpha: .11)),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'NOVA WALLET',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onVisibilityTap,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(5),
                      icon: Icon(
                        hidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  hidden ? '••••••••' : balance,
                  style: const TextStyle(
                    fontSize: 31,
                    letterSpacing: -1.25,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                Text(
                  cardHolder,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      walletNumber,
                      style: const TextStyle(
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onCopyTap,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: AppColors.primaryDark,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'COPY ID',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: .8,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const _MastercardMark(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _MastercardMark extends StatelessWidget {
  const _MastercardMark();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 34,
    height: 22,
    child: Stack(
      children: const [
        Positioned(
          left: 0,
          child: CircleAvatar(radius: 11, backgroundColor: Color(0xFFE84242)),
        ),
        Positioned(
          right: 0,
          child: CircleAvatar(radius: 11, backgroundColor: Color(0xFFFFB13B)),
        ),
      ],
    ),
  );
}
