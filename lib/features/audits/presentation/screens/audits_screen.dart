import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/secret_incident.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/glass_card.dart';
import '../providers/audits_provider.dart';

class AuditsScreen extends ConsumerWidget {
  const AuditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(auditsProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: () => ref.read(auditsProvider.notifier).load(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, ref, state),
                  const SizedBox(height: 20),
                  _buildStatsRow(state),
                  const SizedBox(height: 16),
                  _buildFilterRow(ref, state),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (state.status == LoadStatus.loading && state.incidents.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShimmerTimelineCard(),
                  ),
                  childCount: 5,
                ),
              ),
            )
          else if (state.status == LoadStatus.error &&
              state.incidents.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _ErrorCard(
                  message: state.error ?? 'Failed to load incidents',
                  onRetry: () => ref.read(auditsProvider.notifier).load(),
                ),
              ),
            )
          else if (state.filteredIncidents.isEmpty)
            const SliverFillRemaining(child: _EmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final incident = state.filteredIncidents[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TimelineItem(incident: incident)
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: index * 50),
                            duration: 400.ms,
                          )
                          .slideY(
                            begin: 0.15,
                            end: 0,
                            delay: Duration(milliseconds: index * 50),
                            duration: 400.ms,
                            curve: Curves.easeOut,
                          ),
                    );
                  },
                  childCount: state.filteredIncidents.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, AuditsState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Security Incidents',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  StatusChip(
                    label: 'SUPABASE',
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${state.stats['total'] ?? 0} total incidents'
                '${state.lastRefreshed != null ? ' · Updated ${DateFormat('HH:mm:ss').format(state.lastRefreshed!)}' : ''}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => ref.read(auditsProvider.notifier).load(),
          icon: const Icon(Icons.refresh_rounded, size: 20),
          color: AppColors.textSecondary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Widget _buildStatsRow(AuditsState state) {
    final items = [
      ('CRITICAL', AppColors.critical, state.stats['critical'] ?? 0),
      ('HIGH', AppColors.high, state.stats['high'] ?? 0),
      ('MEDIUM', AppColors.medium, state.stats['medium'] ?? 0),
      ('LOW', AppColors.low, state.stats['low'] ?? 0),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final (label, color, count) = item;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color.withOpacity(0.7),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterRow(WidgetRef ref, AuditsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in ['all', 'critical', 'high', 'medium', 'low'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: filter.toUpperCase(),
                    isActive: state.riskFilter == filter,
                    onTap: () => ref
                        .read(auditsProvider.notifier)
                        .setRiskFilter(filter),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in ['all', 'pending', 'resolved', 'skipped', 'failed'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: filter.toUpperCase(),
                    isActive: state.statusFilter == filter,
                    onTap: () => ref
                        .read(auditsProvider.notifier)
                        .setStatusFilter(filter),
                    activeColor: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? activeColor.withOpacity(0.5)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isActive ? activeColor : AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatefulWidget {
  final SecretIncident incident;
  const _TimelineItem({required this.incident});

  @override
  State<_TimelineItem> createState() => _TimelineItemState();
}

class _TimelineItemState extends State<_TimelineItem> {
  bool _expanded = false;

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return DateFormat('MMM dd').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final riskColor = incident.toRiskColor();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line + dot
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: riskColor,
                  boxShadow: [
                    BoxShadow(
                      color: riskColor.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              Container(
                width: 2,
                height: _expanded ? 180 : 80,
                color: riskColor.withOpacity(0.25),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Card
        Expanded(
          child: GlassCard(
            padding: EdgeInsets.zero,
            borderColor: riskColor.withOpacity(0.2),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusChip(
                            label: incident.riskLabel,
                            color: riskColor,
                          ),
                          const SizedBox(width: 6),
                          StatusChip(
                            label: incident.statusLabel,
                            color: incident.statusColor,
                          ),
                          const Spacer(),
                          Text(
                            _relativeTime(incident.detectedAt),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Secret type
                      Text(
                        incident.secretType,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Repo + file path
                      Row(
                        children: [
                          const Icon(
                            Icons.folder_outlined,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${incident.repoName} · ${incident.filePath}:${incident.lineNumber}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Detected by ${incident.detectedBy}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      // Expanded details
                      if (_expanded) ...[
                        const SizedBox(height: 14),
                        Container(height: 1, color: AppColors.border),
                        const SizedBox(height: 14),
                        _detailRow('Incident ID', incident.incidentId,
                            mono: true, copyable: true, context: context),
                        _detailRow('Scan ID', incident.scanId, mono: true),
                        _detailRow(
                          'Secret Hash',
                          incident.secretHash.length > 16
                              ? '${incident.secretHash.substring(0, 16)}...'
                              : incident.secretHash,
                          mono: true,
                        ),
                        if (incident.remediationDate != null)
                          _detailRow(
                            'Resolved At',
                            DateFormat('MMM dd, yyyy · HH:mm')
                                .format(incident.remediationDate!),
                          ),
                        _detailRow(
                          'Created',
                          DateFormat('MMM dd, yyyy · HH:mm')
                              .format(incident.createdAt),
                        ),
                        _detailRow(
                          'Updated',
                          DateFormat('MMM dd, yyyy · HH:mm')
                              .format(incident.updatedAt),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool mono = false,
    bool copyable = false,
    BuildContext? context,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: copyable && context != null
                  ? () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
              child: Text(
                value,
                style: mono
                    ? GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: copyable
                            ? AppColors.mono
                            : AppColors.textSecondary,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerTimelineCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: AppColors.card,
          highlightColor: AppColors.cardHover,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card,
                ),
              ),
              Container(width: 2, height: 80, color: AppColors.card),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: AppColors.card,
            highlightColor: AppColors.cardHover,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.critical.withOpacity(0.4),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.critical, size: 28),
          const SizedBox(height: 10),
          Text(
            message,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(120, 36),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_outlined,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'No incidents found',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No security incidents match\nthe current filters.',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 13, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
