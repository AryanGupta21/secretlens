import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../commit_block/data/datasources/secrets_api_datasource.dart';
import '../providers/backend_explorer_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class BackendExplorerScreen extends ConsumerWidget {
  const BackendExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backendExplorerProvider);
    final notifier = ref.read(backendExplorerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(state: state, onRefresh: notifier.checkHealthAndLoad),
            _TabStrip(activeTab: state.activeTab, onSelect: notifier.selectTab),
            const _Divider(),
            Expanded(
              child: _TabBody(state: state, notifier: notifier),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final BackendExplorerState state;
  final VoidCallback onRefresh;

  const _TopBar({required this.state, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textMuted, size: 18),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_outlined,
                        color: AppColors.info, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'BACKEND EXPLORER',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'code-gaurd.onrender.com  ·  AWS Secrets Manager',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // Connection badge
          _ConnectionBadge(state: state),
          const SizedBox(width: 4),

          // Refresh
          IconButton(
            onPressed: state.healthStatus == LoadStatus.loading
                ? null
                : onRefresh,
            icon: state.healthStatus == LoadStatus.loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.info,
                    ),
                  )
                : const Icon(Icons.refresh,
                    color: AppColors.textMuted, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final BackendExplorerState state;

  const _ConnectionBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    Color dot;
    String label;

    if (state.healthStatus == LoadStatus.loading) {
      dot = AppColors.warning;
      label = 'CONNECTING';
    } else if (state.isConnected == true) {
      dot = AppColors.success;
      label = 'LIVE';
    } else if (state.isConnected == false) {
      dot = AppColors.danger;
      label = 'OFFLINE';
    } else {
      dot = AppColors.textMuted;
      label = 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dot.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dot.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: dot.withValues(alpha: 0.6),
                    blurRadius: 4,
                    spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: dot,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab strip
// ─────────────────────────────────────────────────────────────────────────────

class _TabStrip extends StatelessWidget {
  final ExplorerTab activeTab;
  final void Function(ExplorerTab) onSelect;

  const _TabStrip({required this.activeTab, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          _Tab(
            label: 'SECRETS',
            icon: Icons.lock_outline,
            isActive: activeTab == ExplorerTab.secrets,
            onTap: () => onSelect(ExplorerTab.secrets),
          ),
          const SizedBox(width: 8),
          _Tab(
            label: 'AUDIT',
            icon: Icons.history,
            isActive: activeTab == ExplorerTab.audit,
            onTap: () => onSelect(ExplorerTab.audit),
          ),
          const SizedBox(width: 8),
          _Tab(
            label: 'GENERATE',
            icon: Icons.code,
            isActive: activeTab == ExplorerTab.generate,
            onTap: () => onSelect(ExplorerTab.generate),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.info.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.info.withValues(alpha: 0.5) : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.info : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.info : AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      height: 1,
      color: AppColors.border,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab body router
// ─────────────────────────────────────────────────────────────────────────────

class _TabBody extends StatelessWidget {
  final BackendExplorerState state;
  final BackendExplorerNotifier notifier;

  const _TabBody({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    switch (state.activeTab) {
      case ExplorerTab.secrets:
        return _SecretsTab(state: state, onRefresh: notifier.loadSecrets);
      case ExplorerTab.audit:
        return _AuditTab(state: state, onRefresh: notifier.loadAuditLogs);
      case ExplorerTab.generate:
        return _GenerateTab(state: state, notifier: notifier);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECRETS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _SecretsTab extends StatelessWidget {
  final BackendExplorerState state;
  final VoidCallback onRefresh;

  const _SecretsTab({required this.state, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (state.secretsStatus == LoadStatus.loading) {
      return const _LoadingCenter(message: 'Fetching secrets from AWS…');
    }

    if (state.secretsStatus == LoadStatus.error) {
      return _ErrorCenter(
        message: state.secretsError ?? 'Unknown error',
        onRetry: onRefresh,
      );
    }

    if (state.secrets.isEmpty) {
      return _EmptyCenter(
        icon: Icons.lock_open_outlined,
        message: 'No secrets stored yet.',
        onRefresh: onRefresh,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: [
              Text(
                '${state.secrets.length} secret${state.secrets.length > 1 ? 's' : ''} in AWS Secrets Manager',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onRefresh,
                child: const Text(
                  'Refresh',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: state.secrets.length,
            separatorBuilder: (context, i) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _SecretCard(secret: state.secrets[i]),
          ),
        ),
      ],
    );
  }
}

class _SecretCard extends StatelessWidget {
  final StoredSecretItem secret;

  const _SecretCard({required this.secret});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Secret name + type badge
          Row(
            children: [
              Expanded(
                child: Text(
                  secret.name,
                  style: const TextStyle(
                    color: AppColors.textCode,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _TypeBadge(secretType: secret.secretType),
            ],
          ),
          const SizedBox(height: 10),

          // ARN
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              secret.arn,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Meta row
          Row(
            children: [
              _MetaChip(
                icon: Icons.miscellaneous_services_outlined,
                label: secret.service.isEmpty ? 'unknown' : secret.service,
                color: AppColors.info,
              ),
              const SizedBox(width: 6),
              _MetaChip(
                icon: Icons.dns_outlined,
                label: secret.environment.isEmpty
                    ? 'default'
                    : secret.environment,
                color: AppColors.warning,
              ),
              const Spacer(),
              if (secret.createdDate != null)
                Text(
                  _formatDate(secret.createdDate!),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')} '
        '${_month(dt.month)} ${dt.year}';
  }

  String _month(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
  }
}

class _TypeBadge extends StatelessWidget {
  final String secretType;

  const _TypeBadge({required this.secretType});

  @override
  Widget build(BuildContext context) {
    final isJson = secretType.toLowerCase() == 'json';
    final color = isJson ? AppColors.warning : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        isJson ? 'JSON' : 'SIMPLE',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUDIT TAB
// ─────────────────────────────────────────────────────────────────────────────

class _AuditTab extends StatelessWidget {
  final BackendExplorerState state;
  final VoidCallback onRefresh;

  const _AuditTab({required this.state, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (state.auditStatus == LoadStatus.loading) {
      return const _LoadingCenter(message: 'Loading audit logs…');
    }

    if (state.auditStatus == LoadStatus.error) {
      return _ErrorCenter(
        message: state.auditError ?? 'Unknown error',
        onRetry: onRefresh,
      );
    }

    if (state.auditStatus == LoadStatus.idle) {
      return _EmptyCenter(
        icon: Icons.history,
        message: 'Tap refresh to load audit logs.',
        onRefresh: onRefresh,
      );
    }

    if (state.auditLogs.isEmpty) {
      return _EmptyCenter(
        icon: Icons.history_toggle_off,
        message: 'No operations recorded yet.',
        onRefresh: onRefresh,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: [
              Text(
                '${state.auditLogs.length} operation${state.auditLogs.length > 1 ? 's' : ''} recorded',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onRefresh,
                child: const Text(
                  'Refresh',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: state.auditLogs.length,
            separatorBuilder: (context, i) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _AuditCard(log: state.auditLogs[i]),
          ),
        ),
      ],
    );
  }
}

class _AuditCard extends StatelessWidget {
  final AuditLogItem log;

  const _AuditCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final isSuccess = log.operationStatus.toLowerCase() == 'success';
    final statusColor = isSuccess ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: secret_id + status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  log.secretId,
                  style: const TextStyle(
                    color: AppColors.textCode,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSuccess
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 10,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      log.operationStatus.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: op-type, language, time
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _AuditChip(
                label: log.operationType.replaceAll('_', ' ').toUpperCase(),
                color: AppColors.info,
              ),
              if (log.codeLanguage != null)
                _AuditChip(
                  label: log.codeLanguage!.toUpperCase(),
                  color: _langColor(log.codeLanguage!),
                ),
              _AuditChip(
                label: log.secretType.toUpperCase(),
                color: AppColors.textMuted,
              ),
              if (log.operationTimeMs != null)
                _AuditChip(
                  label: '${log.operationTimeMs}ms',
                  color: AppColors.warning,
                ),
            ],
          ),

          // Row 3: audit_id + timestamp
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'ID: ${log.auditId.substring(0, 8)}…',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (log.createdAt != null)
                Text(
                  log.createdAt!.replaceFirst('T', ' '),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _langColor(String lang) {
    switch (lang.toLowerCase()) {
      case 'javascript':
        return const Color(0xFFF7DF1E);
      case 'python':
        return AppColors.info;
      case 'go':
        return const Color(0xFF00ADD8);
      case 'java':
        return const Color(0xFFED8B00);
      case 'php':
        return const Color(0xFF8892BE);
      case 'csharp':
      case 'cs':
        return const Color(0xFF9B4993);
      default:
        return AppColors.success;
    }
  }
}

class _AuditChip extends StatelessWidget {
  final String label;
  final Color color;

  const _AuditChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GENERATE CODE TAB
// ─────────────────────────────────────────────────────────────────────────────

class _GenerateTab extends ConsumerWidget {
  final BackendExplorerState state;
  final BackendExplorerNotifier notifier;

  const _GenerateTab({required this.state, required this.notifier});

  static const _languages = [
    'python',
    'javascript',
    'go',
    'java',
    'php',
    'csharp',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Endpoint hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.infoDim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.infoBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.info, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11.5),
                      children: [
                        const TextSpan(text: 'Calls  '),
                        TextSpan(
                          text: 'POST /api/v1/secrets/generate-code',
                          style: const TextStyle(
                            color: AppColors.textCode,
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                        const TextSpan(
                            text:
                                '  on the live engine to fetch a language-specific retrieval snippet for a stored secret.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Secret selector
          const _FieldLabel(text: 'Select Secret'),
          const SizedBox(height: 8),
          if (state.secrets.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'No secrets available — load the Secrets tab first.',
                style:
                    TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            _SecretDropdown(
              secrets: state.secrets,
              selectedId: state.selectedSecretId,
              onChanged: notifier.selectSecret,
            ),

          const SizedBox(height: 18),

          // Language selector
          const _FieldLabel(text: 'Language'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languages
                .map((lang) => _LangPill(
                      label: lang,
                      isSelected: state.selectedLanguage == lang,
                      onTap: () => notifier.selectLanguage(lang),
                    ))
                .toList(),
          ),

          const SizedBox(height: 24),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (state.selectedSecretId == null ||
                      state.generateStatus == LoadStatus.loading)
                  ? null
                  : notifier.generateCode,
              icon: state.generateStatus == LoadStatus.loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_fix_high, size: 16),
              label: Text(
                state.generateStatus == LoadStatus.loading
                    ? 'GENERATING…'
                    : 'GENERATE SNIPPET',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.info.withValues(alpha: 0.3),
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
                elevation: 0,
              ),
            ),
          ),

          // Error
          if (state.generateStatus == LoadStatus.error &&
              state.generateError != null) ...[
            const SizedBox(height: 16),
            _ErrorBox(message: state.generateError!),
          ],

          // Generated code output
          if (state.generatedCode != null &&
              state.generatedCode!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const _FieldLabel(text: 'Retrieval Snippet'),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: state.generatedCode!));
                    notifier.markCodeCopied();
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: state.codeCopied
                        ? const Row(
                            key: ValueKey('copied'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check,
                                  size: 13, color: AppColors.success),
                              SizedBox(width: 4),
                              Text(
                                'Copied!',
                                style: TextStyle(
                                    color: AppColors.success, fontSize: 12),
                              ),
                            ],
                          )
                        : const Row(
                            key: ValueKey('copy'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy,
                                  size: 13, color: AppColors.info),
                              SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: TextStyle(
                                    color: AppColors.info, fontSize: 12),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.infoBorder.withValues(alpha: 0.4)),
              ),
              child: SelectableText(
                state.generatedCode!,
                style: const TextStyle(
                  color: AppColors.textCode,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SecretDropdown extends StatelessWidget {
  final List<StoredSecretItem> secrets;
  final String? selectedId;
  final void Function(String) onChanged;

  const _SecretDropdown({
    required this.secrets,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderBright),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        value: selectedId,
        dropdownColor: AppColors.card,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.unfold_more,
            color: AppColors.textMuted, size: 18),
        items: secrets
            .map(
              (s) => DropdownMenuItem(
                value: s.name,
                child: Text(
                  s.name,
                  style: const TextStyle(
                    color: AppColors.textCode,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _langColor(label);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textMuted,
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _langColor(String lang) {
    switch (lang.toLowerCase()) {
      case 'javascript':
        return const Color(0xFFF7DF1E);
      case 'python':
        return AppColors.info;
      case 'go':
        return const Color(0xFF00ADD8);
      case 'java':
        return const Color(0xFFED8B00);
      case 'php':
        return const Color(0xFF8892BE);
      case 'csharp':
        return const Color(0xFF9B4993);
      default:
        return AppColors.success;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _LoadingCenter extends StatelessWidget {
  final String message;

  const _LoadingCenter({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorCenter extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCenter({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off,
                color: AppColors.danger, size: 40),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.info,
                side: const BorderSide(color: AppColors.infoBorder),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCenter extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onRefresh;

  const _EmptyCenter({
    required this.icon,
    required this.message,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 40),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.info,
              side: const BorderSide(color: AppColors.infoBorder),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.dangerDim,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.danger, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppColors.danger, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}
