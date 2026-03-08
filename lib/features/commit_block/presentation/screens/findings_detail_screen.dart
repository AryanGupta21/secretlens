import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/finding.dart';
import '../providers/commit_block_provider.dart';

class FindingsDetailScreen extends ConsumerStatefulWidget {
  final String? selectedFindingId;

  const FindingsDetailScreen({super.key, this.selectedFindingId});

  @override
  ConsumerState<FindingsDetailScreen> createState() =>
      _FindingsDetailScreenState();
}

class _FindingsDetailScreenState extends ConsumerState<FindingsDetailScreen> {
  late String? _activeFindingId;

  @override
  void initState() {
    super.initState();
    _activeFindingId = widget.selectedFindingId;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commitBlockProvider);
    final findings = state.findings;

    // Default to first finding if none selected
    _activeFindingId ??= findings.isNotEmpty ? findings.first.id : null;
    final activeFinding =
        findings.where((f) => f.id == _activeFindingId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Security Findings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.dangerDim,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.dangerBorder),
            ),
            child: Text(
              '${state.unfixedCount} UNRESOLVED',
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          // Finding selector tabs
          Container(
            height: 56,
            color: AppColors.surface,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: findings.length,
              itemBuilder: (context, index) {
                final f = findings[index];
                final isActive = f.id == _activeFindingId;
                final severityColor = Color(f.severity.colorValue);
                return GestureDetector(
                  onTap: () => setState(() => _activeFindingId = f.id),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.card : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isActive ? severityColor.withValues(alpha: 0.5) : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: f.fixStatus == FixStatus.stored
                                ? AppColors.success
                                : severityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          f.secretType,
                          style: TextStyle(
                            color: isActive
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Detail view
          if (activeFinding != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _FindingDetailCard(finding: activeFinding),
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text(
                  'No findings',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FindingDetailCard extends StatelessWidget {
  final Finding finding;

  const _FindingDetailCard({required this.finding});

  @override
  Widget build(BuildContext context) {
    final severityColor = Color(finding.severity.colorValue);
    final isFixed = finding.fixStatus == FixStatus.stored;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFixed ? AppColors.successBorder : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isFixed ? Icons.verified_user_outlined : Icons.security_outlined,
                    color: isFixed ? AppColors.success : severityColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      finding.secretType,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFixed
                          ? AppColors.successDim
                          : severityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isFixed
                            ? AppColors.successBorder
                            : severityColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      isFixed ? 'SECURED' : finding.severity.label,
                      style: TextStyle(
                        color: isFixed ? AppColors.success : severityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow(
                icon: Icons.insert_drive_file_outlined,
                label: 'File',
                value: finding.file,
                isCode: true,
              ),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.tag,
                label: 'Line',
                value: '${finding.line}',
                isCode: true,
              ),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.layers_outlined,
                label: 'Type',
                value: finding.secretType,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Masked value section
        _SectionLabel(label: 'DETECTED VALUE (MASKED)'),
        const SizedBox(height: 8),
        _CopyableCodeBlock(
          code: finding.maskedValue,
          language: finding.language ?? 'text',
        ),

        if (isFixed && finding.storedSecretArn != null) ...[
          const SizedBox(height: 20),
          _SectionLabel(label: 'AWS SECRETS MANAGER ARN'),
          const SizedBox(height: 8),
          _CopyableCodeBlock(
            code: finding.storedSecretArn!,
            language: 'arn',
            accentColor: AppColors.success,
          ),
        ],

        if (!isFixed) ...[
          const SizedBox(height: 20),
          // Impact description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dangerDim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.dangerBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: severityColor, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      'POTENTIAL IMPACT',
                      style: TextStyle(
                        color: severityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getImpactDescription(finding.secretType),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  String _getImpactDescription(String secretType) {
    switch (secretType) {
      case 'AWS Access Key':
        return 'Exposed AWS credentials can allow attackers to provision resources, '
            'access S3 buckets, read database contents, and incur significant AWS charges. '
            'Rotate immediately via AWS IAM console.';
      case 'RSA Private Key':
        return 'An exposed private key compromises all services using the corresponding '
            'public key for authentication. This includes SSH access, TLS certificates, '
            'and JWT signing. Revoke and regenerate immediately.';
      case 'Stripe API Secret':
        return 'Exposed Stripe secret keys allow attackers to create charges, '
            'access customer payment data, and initiate refunds or transfers. '
            'Rotate immediately via the Stripe dashboard.';
      default:
        return 'This credential may allow unauthorized access to the associated service. '
            'Rotate or revoke this secret immediately and audit recent access logs.';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isCode;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isCode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontFamily: isCode ? 'monospace' : null,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _CopyableCodeBlock extends StatelessWidget {
  final String code;
  final String language;
  final Color? accentColor;

  const _CopyableCodeBlock({
    required this.code,
    required this.language,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.codeBlock,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor?.withValues(alpha: 0.3) ?? AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code block header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: accentColor?.withValues(alpha: 0.2) ?? AppColors.border,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  language.toUpperCase(),
                  style: TextStyle(
                    color: accentColor ?? AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 2),
                        backgroundColor: AppColors.card,
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.copy_outlined,
                          color: AppColors.textMuted, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'COPY',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Code content
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              style: TextStyle(
                color: accentColor ?? AppColors.textCode,
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
