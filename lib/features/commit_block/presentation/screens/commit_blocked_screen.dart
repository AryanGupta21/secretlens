import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/commit_block_provider.dart';
import '../widgets/finding_tile.dart';
import '../widgets/risk_warning_box.dart';
import '../widgets/footer_branding.dart';
import 'findings_detail_screen.dart';
import 'fix_issues_progress_screen.dart';
import '../../../backend_explorer/presentation/screens/backend_explorer_screen.dart';

class CommitBlockedScreen extends ConsumerWidget {
  const CommitBlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(commitBlockProvider);

    // If commit was allowed anyway, show a different state
    if (state.commitOverridden) {
      return _CommitOverrideScreen(
        onReset: () => ref.read(commitBlockProvider.notifier).reset(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar with close button
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    iconSize: 22,
                    tooltip: 'Dismiss',
                  ),
                  const Spacer(),
                  // Backend Explorer entry point
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BackendExplorerScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.infoDim,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.infoBorder),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_outlined,
                              color: AppColors.info, size: 11),
                          SizedBox(width: 4),
                          Text(
                            'EXPLORE API',
                            style: TextStyle(
                              color: AppColors.info,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.dangerDim,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.dangerBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.block,
                          color: AppColors.danger,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'BLOCKED',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scan line decoration
                  Row(
                    children: List.generate(
                      3,
                      (i) => Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(
                              alpha: i == 0
                                  ? 1.0
                                  : i == 1
                                      ? 0.5
                                      : 0.25),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.danger, Color(0xFFFF7070)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: const Text(
                      'COMMIT\nBLOCKED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.danger.withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${state.findings.length} secret${state.findings.length > 1 ? 's' : ''} detected in staged changes',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Findings list - scrollable
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: state.findings.length,
                itemBuilder: (context, index) {
                  final finding = state.findings[index];
                  return FindingTile(
                    finding: finding,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProviderScope(
                            overrides: const [],
                            child: FindingsDetailScreen(
                              selectedFindingId: finding.id,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Warning box
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: RiskWarningBox(
                riskLevel: state.riskLevel,
                findingCount: state.findings.length,
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Review Findings
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const FindingsDetailScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('REVIEW FINDINGS'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: AppColors.borderBright),
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Fix All Issues - primary CTA
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FixIssuesProgressScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shield_outlined, size: 16),
                    label: const Text('FIX ALL ISSUES'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.textPrimary,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Commit Anyway - danger text button
                  TextButton(
                    onPressed: () => _showCommitAnywayDialog(context, ref),
                    child: const Text(
                      'COMMIT ANYWAY',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            const FooterBranding(),
          ],
        ),
      ),
    );
  }

  void _showCommitAnywayDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.dangerBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
            SizedBox(width: 8),
            Text(
              'Override Security Block?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Committing with exposed secrets puts your infrastructure at critical risk. '
          'This action will be logged for security audit purposes.\n\n'
          'Are you absolutely sure you want to proceed?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'GO BACK',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(commitBlockProvider.notifier).commitAnyway();
              Navigator.pop(ctx);
            },
            child: const Text(
              'COMMIT ANYWAY',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommitOverrideScreen extends StatelessWidget {
  final VoidCallback onReset;

  const _CommitOverrideScreen({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'COMMIT OVERRIDDEN',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The security block was overridden. This action has been logged. '
                  'Please remediate the exposed secrets immediately.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                OutlinedButton(
                  onPressed: onReset,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderBright),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: const Text('RESTART DEMO'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
