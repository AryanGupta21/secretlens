import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/services/aws_api_service.dart';
import '../providers/secrets_provider.dart';

class SecretManagerScreen extends ConsumerStatefulWidget {
  const SecretManagerScreen({super.key});

  @override
  ConsumerState<SecretManagerScreen> createState() =>
      _SecretManagerScreenState();
}

class _SecretManagerScreenState extends ConsumerState<SecretManagerScreen> {
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(secretsProvider.notifier).startPolling();
    });
  }

  @override
  void dispose() {
    ref.read(secretsProvider.notifier).stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(secretsProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: () => ref.read(secretsProvider.notifier).loadSecrets(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(state),
                  const SizedBox(height: 20),
                  _buildStatsRow(state),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (state.status == LoadStatus.loading && state.secrets.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShimmerCard(),
                  ),
                  childCount: 4,
                ),
              ),
            )
          else if (state.status == LoadStatus.error && state.secrets.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _ErrorCard(
                  message: state.error ?? 'Unknown error',
                  onRetry: () =>
                      ref.read(secretsProvider.notifier).loadSecrets(),
                ),
              ),
            )
          else if (state.secrets.isEmpty && state.status == LoadStatus.success)
            const SliverFillRemaining(
              child: _EmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final secret = state.secrets[index];
                    final isExpanded = _expanded.contains(secret.arn);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SecretCard(
                        secret: secret,
                        isExpanded: isExpanded,
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expanded.remove(secret.arn);
                            } else {
                              _expanded.add(secret.arn);
                            }
                          });
                        },
                      )
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: index * 60),
                            duration: 400.ms,
                          )
                          .slideY(
                            begin: 0.15,
                            end: 0,
                            delay: Duration(milliseconds: index * 60),
                            duration: 400.ms,
                            curve: Curves.easeOut,
                          ),
                    );
                  },
                  childCount: state.secrets.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(SecretsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Secret Manager',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            StatusChip(
              label: state.isConnected ? 'LIVE' : 'OFFLINE',
              color: state.isConnected ? AppColors.success : AppColors.critical,
            ),
            const Spacer(),
            if (state.isPolling)
              _PollingBadge(),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () =>
                  ref.read(secretsProvider.notifier).loadSecrets(),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: AppColors.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'AWS Secrets Manager · code-gaurd.onrender.com',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
        if (state.lastRefreshed != null) ...[
          const SizedBox(height: 4),
          Text(
            'Last updated ${DateFormat('HH:mm:ss').format(state.lastRefreshed!)}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow(SecretsState state) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'TOTAL SECRETS',
            value: '${state.secrets.length}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'STATUS',
            value: state.isConnected ? 'ONLINE' : 'OFFLINE',
            color:
                state.isConnected ? AppColors.success : AppColors.critical,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'POLLING',
            value: state.isPolling ? 'AUTO' : 'PAUSED',
            color:
                state.isPolling ? AppColors.success : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecretCard extends StatelessWidget {
  final StoredSecretItem secret;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SecretCard({
    required this.secret,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lock icon
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDim,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Main content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            secret.name,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            secret.arn,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (secret.environment.isNotEmpty)
                                StatusChip(
                                  label: secret.environment,
                                  color: AppColors.primary,
                                  fontSize: 9,
                                ),
                              if (secret.secretType.isNotEmpty)
                                StatusChip(
                                  label: secret.secretType,
                                  color: AppColors.mono,
                                  fontSize: 9,
                                ),
                              if (secret.service.isNotEmpty)
                                StatusChip(
                                  label: secret.service,
                                  color: AppColors.textSecondary,
                                  fontSize: 9,
                                ),
                            ],
                          ),
                          if (secret.createdDate != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Created ${DateFormat('MMM dd, yyyy').format(secret.createdDate!)}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Chevron
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                // Expanded section
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: 16),
                  _expandedDetail('Full ARN', secret.arn, mono: true),
                  const SizedBox(height: 10),
                  if (secret.service.isNotEmpty)
                    _expandedDetail('Service', secret.service),
                  if (secret.service.isNotEmpty) const SizedBox(height: 10),
                  if (secret.lastUpdated != null)
                    _expandedDetail(
                      'Last Updated',
                      DateFormat('MMM dd, yyyy · HH:mm')
                          .format(secret.lastUpdated!),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _expandedDetail(String label, String value, {bool mono = false}) {
    return Row(
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
          child: Text(
            value,
            style: mono
                ? GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AppColors.mono,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: AppColors.cardHover,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
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
          Icon(
            Icons.lock_open_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No secrets found',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AWS Secrets Manager is empty\nor the API returned no results.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PollingBadge extends StatefulWidget {
  @override
  State<_PollingBadge> createState() => _PollingBadgeState();
}

class _PollingBadgeState extends State<_PollingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.successDim,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: Text(
          'AUTO',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
