import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class FooterBranding extends StatelessWidget {
  const FooterBranding({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Lock icon + app name
          const Icon(
            Icons.lock_outlined,
            color: AppColors.textMuted,
            size: 14,
          ),
          const SizedBox(width: 6),
          const Text(
            'SecretLens',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          // Gemini AI branding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.infoDim),
              borderRadius: BorderRadius.circular(20),
              color: AppColors.infoDim,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.info,
                  size: 11,
                ),
                SizedBox(width: 4),
                Text(
                  'Powered by Gemini AI',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
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
