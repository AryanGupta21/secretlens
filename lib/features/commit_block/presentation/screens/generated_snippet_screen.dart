import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/commit_block_provider.dart';

class GeneratedSnippetScreen extends ConsumerStatefulWidget {
  const GeneratedSnippetScreen({super.key});

  @override
  ConsumerState<GeneratedSnippetScreen> createState() =>
      _GeneratedSnippetScreenState();
}

class _GeneratedSnippetScreenState
    extends ConsumerState<GeneratedSnippetScreen> {
  final Set<String> _copiedIds = {};

  void _copyCode(String id, String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copiedIds.add(id));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedIds.remove(id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commitBlockProvider);
    final fixedFindings =
        state.findings.where((f) => f.generatedCode != null).toList();

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
          'Generated Code',
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
              color: AppColors.successDim,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.successBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppColors.success, size: 11),
                const SizedBox(width: 4),
                Text(
                  '${fixedFindings.length} GENERATED',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
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
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.infoDim,
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 15),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Replace hardcoded secrets in your source files with these generated code snippets.',
                    style: TextStyle(
                      color: AppColors.info,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Snippets list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: fixedFindings.length,
              itemBuilder: (context, index) {
                final finding = fixedFindings[index];
                final isCopied = _copiedIds.contains(finding.id);

                return _SnippetCard(
                  finding: finding,
                  isCopied: isCopied,
                  onCopy: () =>
                      _copyCode(finding.id, finding.generatedCode ?? ''),
                );
              },
            ),
          ),

          // Bottom action
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.warningDim,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_outlined,
                          color: AppColors.warning, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Remember to remove the original hardcoded secrets from your source files before committing.',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('COMMIT IS CLEAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.black,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnippetCard extends StatelessWidget {
  final dynamic finding;
  final bool isCopied;
  final VoidCallback onCopy;

  const _SnippetCard({
    required this.finding,
    required this.isCopied,
    required this.onCopy,
  });

  String get _languageLabel {
    switch (finding.language) {
      case 'javascript':
        return 'JavaScript';
      case 'python':
        return 'Python';
      case 'shell':
        return 'Shell';
      default:
        return 'Code';
    }
  }

  Color get _languageColor {
    switch (finding.language) {
      case 'javascript':
        return const Color(0xFFFFD700);
      case 'python':
        return const Color(0xFF4D9FFF);
      case 'shell':
        return const Color(0xFF7EFFA0);
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.lock_outlined,
                    color: AppColors.success, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        finding.secretType,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                ),
              ],
            ),
          ),

          // Code block
          Container(
            decoration: const BoxDecoration(
              color: AppColors.codeBlock,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Code header with language + copy button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _languageColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: _languageColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _languageLabel,
                          style: TextStyle(
                            color: _languageColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onCopy,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCopied
                                ? AppColors.successDim
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isCopied
                                  ? AppColors.successBorder
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCopied
                                    ? Icons.check
                                    : Icons.copy_outlined,
                                color: isCopied
                                    ? AppColors.success
                                    : AppColors.textMuted,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCopied ? 'COPIED' : 'COPY',
                                style: TextStyle(
                                  color: isCopied
                                      ? AppColors.success
                                      : AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Code content
                const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: SelectableText(
                    finding.generatedCode ?? '',
                    style: const TextStyle(
                      color: AppColors.textCode,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ARN footer
          if (finding.storedSecretArn != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_outlined,
                      color: AppColors.success, size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      finding.storedSecretArn!,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
