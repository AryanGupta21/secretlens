import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class RiskWarningBox extends StatelessWidget {
  final String riskLevel;
  final int findingCount;

  const RiskWarningBox({
    super.key,
    required this.riskLevel,
    required this.findingCount,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = riskLevel == 'CRITICAL';
    final accentColor = isCritical ? AppColors.danger : AppColors.warning;
    final bgColor = isCritical ? AppColors.dangerDim : AppColors.warningDim;
    final borderColor =
        isCritical ? AppColors.dangerBorder : AppColors.warningBorder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCritical ? Icons.gpp_bad_outlined : Icons.warning_amber_outlined,
                color: accentColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'SECURITY RISK: $riskLevel',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Committing $findingCount detected secret${findingCount > 1 ? 's' : ''} poses a $riskLevel security risk. '
            'Exposed credentials can lead to unauthorized access, data breaches, and significant financial damage. '
            'Use "Fix All Issues" to securely store these secrets in AWS Secrets Manager.',
            style: TextStyle(
              color: accentColor.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
