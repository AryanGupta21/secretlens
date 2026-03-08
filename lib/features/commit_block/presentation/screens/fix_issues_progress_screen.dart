import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/finding.dart';
import '../providers/commit_block_provider.dart';
import 'secret_saved_screen.dart';

class FixIssuesProgressScreen extends ConsumerStatefulWidget {
  const FixIssuesProgressScreen({super.key});

  @override
  ConsumerState<FixIssuesProgressScreen> createState() =>
      _FixIssuesProgressScreenState();
}

class _FixIssuesProgressScreenState
    extends ConsumerState<FixIssuesProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Start fix process after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_started) {
        _started = true;
        _startFix();
      }
    });
  }

  Future<void> _startFix() async {
    await ref.read(commitBlockProvider.notifier).fixAllIssues();
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SecretSavedScreen(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commitBlockProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Animated shield icon
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.dangerDim,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.danger.withValues(
                                  alpha: 0.1 + _pulseController.value * 0.3),
                              blurRadius: 20 + _pulseController.value * 20,
                              spreadRadius: 2 + _pulseController.value * 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: AppColors.danger,
                          size: 38,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                const Center(
                  child: Text(
                    'SECURING SECRETS',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    state.fixStatusMessage ?? 'Initializing...',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Progress list
                Expanded(
                  child: ListView.builder(
                    itemCount: state.findings.length,
                    itemBuilder: (context, index) {
                      final finding = state.findings[index];
                      final isCurrent = index == state.currentFixIndex &&
                          state.fixInProgress;
                      final isDone = finding.fixStatus == FixStatus.stored;
                      final isPending = !isDone &&
                          index > state.currentFixIndex;

                      return _ProgressItem(
                        finding: finding,
                        isCurrent: isCurrent,
                        isDone: isDone,
                        isPending: isPending,
                        pulseAnimation: _pulseController,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Overall progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Overall Progress',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${state.fixedCount} / ${state.findings.length}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: state.findings.isEmpty
                            ? 0
                            : state.fixedCount / state.findings.length,
                        backgroundColor: AppColors.card,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.success),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final Finding finding;
  final bool isCurrent;
  final bool isDone;
  final bool isPending;
  final AnimationController pulseAnimation;

  const _ProgressItem({
    required this.finding,
    required this.isCurrent,
    required this.isDone,
    required this.isPending,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.successDim
            : isCurrent
                ? AppColors.card
                : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDone
              ? AppColors.successBorder
              : isCurrent
                  ? AppColors.borderBright
                  : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Status icon
          SizedBox(
            width: 28,
            height: 28,
            child: isDone
                ? const Icon(Icons.check_circle, color: AppColors.success, size: 24)
                : isCurrent
                    ? AnimatedBuilder(
                        animation: pulseAnimation,
                        builder: (context, child) {
                          return SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.danger
                                    .withValues(alpha: 0.5 + pulseAnimation.value * 0.5),
                              ),
                            ),
                          );
                        },
                      )
                    : const Icon(Icons.radio_button_unchecked,
                        color: AppColors.textMuted, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finding.secretType,
                  style: TextStyle(
                    color: isPending
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isDone
                      ? 'Stored in AWS Secrets Manager'
                      : isCurrent
                          ? 'Processing...'
                          : 'Waiting...',
                  style: TextStyle(
                    color: isDone
                        ? AppColors.success
                        : isCurrent
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (isDone && finding.storedSecretArn != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    finding.storedSecretArn!,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            finding.file,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
