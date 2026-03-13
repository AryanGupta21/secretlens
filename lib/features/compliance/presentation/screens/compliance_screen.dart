import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../providers/compliance_provider.dart';

class ComplianceScreen extends ConsumerWidget {
  const ComplianceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(complianceProvider);

    final categories = ['ALL', 'IAM', 'SECRETS', 'LOGGING', 'ENCRYPTION', 'ACCESS', 'NETWORK'];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Compliance',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warningDim,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        'MOCK DATA',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Score card
                _ScoreCard(state: state)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 600.ms, curve: Curves.easeOut),

                const SizedBox(height: 20),

                // Category filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isActive = state.categoryFilter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => ref
                              .read(complianceProvider.notifier)
                              .setCategoryFilter(cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary.withOpacity(0.15)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.primary.withOpacity(0.5)
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final check = state.filteredChecks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ComplianceCard(check: check)
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: index * 70),
                        duration: 400.ms,
                      )
                      .slideY(
                        begin: 0.15,
                        end: 0,
                        delay: Duration(milliseconds: index * 70),
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                );
              },
              childCount: state.filteredChecks.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final ComplianceState state;
  const _ScoreCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final score = state.score;
    final pct   = (score * 100).round();

    Color scoreColor;
    if (pct >= 80) {
      scoreColor = AppColors.success;
    } else if (pct >= 60) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.critical;
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Circular score ring
          SizedBox(
            width: 96,
            height: 96,
            child: CustomPaint(
              painter: _ScoreRingPainter(score: score, color: scoreColor),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$pct%',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SECURITY SCORE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ScoreStat(
                        label: 'PASS',
                        count: state.passCount,
                        color: AppColors.success,
                      ),
                    ),
                    Expanded(
                      child: _ScoreStat(
                        label: 'WARN',
                        count: state.warningCount,
                        color: AppColors.warning,
                      ),
                    ),
                    Expanded(
                      child: _ScoreStat(
                        label: 'FAIL',
                        count: state.failCount,
                        color: AppColors.critical,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${state.checks.length} checks total',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    color: AppColors.textMuted,
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

class _ScoreStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _ScoreStat({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color.withOpacity(0.7),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double score;
  final Color color;

  const _ScoreRingPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background ring
    final bgPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * score,
      false,
      fgPaint,
    );

    // Glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * score,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) =>
      old.score != score || old.color != color;
}

class _ComplianceCard extends StatelessWidget {
  final ComplianceCheck check;
  const _ComplianceCard({required this.check});

  Color get _statusColor {
    switch (check.status) {
      case ComplianceStatus.pass:    return AppColors.success;
      case ComplianceStatus.fail:    return AppColors.critical;
      case ComplianceStatus.warning: return AppColors.warning;
      case ComplianceStatus.pending: return AppColors.textSecondary;
    }
  }

  IconData get _statusIcon {
    switch (check.status) {
      case ComplianceStatus.pass:    return Icons.check_circle_outline;
      case ComplianceStatus.fail:    return Icons.cancel_outlined;
      case ComplianceStatus.warning: return Icons.warning_amber_outlined;
      case ComplianceStatus.pending: return Icons.hourglass_empty;
    }
  }

  String get _statusLabel {
    switch (check.status) {
      case ComplianceStatus.pass:    return 'PASS';
      case ComplianceStatus.fail:    return 'FAIL';
      case ComplianceStatus.warning: return 'WARNING';
      case ComplianceStatus.pending: return 'PENDING';
    }
  }

  Color get _severityColor {
    switch (check.severity.toLowerCase()) {
      case 'critical': return AppColors.critical;
      case 'high':     return AppColors.high;
      case 'medium':   return AppColors.medium;
      default:         return AppColors.low;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 3),
          top: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_statusIcon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          check.category,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    check.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    check.description,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      StatusChip(
                        label: _statusLabel,
                        color: color,
                        fontSize: 9,
                      ),
                      const SizedBox(width: 6),
                      StatusChip(
                        label: check.severity.toUpperCase(),
                        color: _severityColor,
                        fontSize: 9,
                      ),
                      const Spacer(),
                      Text(
                        _relativeTime(check.lastChecked),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM dd').format(dt);
  }
}
