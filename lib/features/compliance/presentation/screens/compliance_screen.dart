import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../providers/compliance_provider.dart';

class ComplianceScreen extends ConsumerStatefulWidget {
  const ComplianceScreen({super.key});

  @override
  ConsumerState<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends ConsumerState<ComplianceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Upload tab
  PlatformFile? _pickedFile;

  // Validate tab
  final _filePathCtrl = TextEditingController(text: 'app/main.py');
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _filePathCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(complianceProvider);

    return Column(
      children: [
        _Header(state: state),
        _TabBar(controller: _tabs),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _UploadTab(
                state: state,
                pickedFile: _pickedFile,
                onPickFile: _pickFile,
                onUpload: _upload,
                onClear: () => setState(() => _pickedFile = null),
              ),
              _RulesTab(state: state),
              _ValidateTab(
                state: state,
                filePathCtrl: _filePathCtrl,
                codeCtrl: _codeCtrl,
                onValidate: _validate,
              ),
              _DocumentsTab(state: state),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'md', 'txt'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _upload() async {
    final file = _pickedFile;
    if (file == null || file.bytes == null) return;
    await ref
        .read(complianceProvider.notifier)
        .ingestDocument(file.bytes!, file.name);
  }

  Future<void> _validate() async {
    final path = _filePathCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (path.isEmpty || code.isEmpty) return;
    await ref.read(complianceProvider.notifier).validateCode(path, code);
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ComplianceState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final isOnline = state.engineStatus == EngineStatus.online;
    final isUnknown = state.engineStatus == EngineStatus.unknown;

    Color statusColor;
    String statusLabel;
    if (isUnknown) {
      statusColor = AppColors.textMuted;
      statusLabel = 'CHECKING';
    } else if (isOnline) {
      statusColor = AppColors.success;
      statusLabel = 'ONLINE';
    } else {
      statusColor = AppColors.critical;
      statusLabel = 'OFFLINE';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
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
          // Engine status badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isUnknown)
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: statusColor,
                    ),
                  )
                else
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          if (state.engineVersion.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              'v${state.engineVersion}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const Spacer(),
          // Stats
          _StatPill(label: 'DOCS', value: '${state.documents.length}'),
          const SizedBox(width: 6),
          _StatPill(label: 'RULES', value: '${state.rules.length}'),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            TextSpan(
              text: ' $label',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(3),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Upload'),
          Tab(text: 'Rules'),
          Tab(text: 'Validate'),
          Tab(text: 'Documents'),
        ],
      ),
    );
  }
}

// ── Upload Tab ────────────────────────────────────────────────────────────────

class _UploadTab extends StatelessWidget {
  final ComplianceState state;
  final PlatformFile? pickedFile;
  final VoidCallback onPickFile;
  final VoidCallback onUpload;
  final VoidCallback onClear;

  const _UploadTab({
    required this.state,
    required this.pickedFile,
    required this.onPickFile,
    required this.onUpload,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Drop zone / file picker
        GestureDetector(
          onTap: state.uploading ? null : onPickFile,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: pickedFile != null
                  ? AppColors.primary.withOpacity(0.06)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: pickedFile != null
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: pickedFile == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file_outlined,
                          size: 32, color: AppColors.textMuted),
                      const SizedBox(height: 10),
                      Text(
                        'Tap to select a compliance document',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PDF · Markdown · Text',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.description_outlined,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                pickedFile!.name,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatBytes(pickedFile!.size),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: state.uploading ? null : onClear,
                          icon: Icon(Icons.close,
                              size: 18, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // Upload button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: (pickedFile == null || state.uploading) ? null : onUpload,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.border,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: state.uploading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Extracting rules…',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  )
                : Text(
                    pickedFile == null
                        ? 'Select a file first'
                        : 'Upload & Extract Rules',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: pickedFile == null
                          ? AppColors.textMuted
                          : Colors.white,
                    ),
                  ),
          ),
        ),

        // Error
        if (state.uploadError != null) ...[
          const SizedBox(height: 12),
          _ErrorCard(message: state.uploadError!),
        ],

        // Success result
        if (state.lastIngest != null) ...[
          const SizedBox(height: 16),
          _IngestResultCard(result: state.lastIngest!)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0, duration: 400.ms),
        ],
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _IngestResultCard extends StatelessWidget {
  final IngestResponse result;
  const _IngestResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.success.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.check_circle_outline,
                    size: 16, color: AppColors.success),
              ),
              const SizedBox(width: 10),
              Text(
                'Ingestion Successful',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ResultRow(label: 'Document', value: result.filename),
          _ResultRow(
              label: 'Rules Extracted',
              value: '${result.rulesExtracted}',
              valueColor: AppColors.primary),
          if (result.message.isNotEmpty)
            _ResultRow(label: 'Message', value: result.message),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _ResultRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                color: valueColor ?? AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rules Tab ─────────────────────────────────────────────────────────────────

class _RulesTab extends ConsumerWidget {
  final ComplianceState state;
  const _RulesTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(complianceProvider.notifier);
    final severities = ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];
    final categories = <String>['ALL'];

    // Collect unique categories from rules
    for (final r in state.rules) {
      final cat = r.category.toUpperCase();
      if (cat.isNotEmpty && !categories.contains(cat)) categories.add(cat);
    }

    final filtered = state.filteredRules;

    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilterRow(
                label: 'SEVERITY',
                options: severities,
                selected: state.severityFilter,
                onSelect: notifier.setSeverityFilter,
                activeColor: _severityColor,
              ),
              const SizedBox(height: 8),
              _FilterRow(
                label: 'CATEGORY',
                options: categories,
                selected: state.categoryRuleFilter,
                onSelect: notifier.setCategoryRuleFilter,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              Text(
                '${filtered.length} rule${filtered.length == 1 ? '' : 's'}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              if (state.loadingRules) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.primary,
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () => ref.read(complianceProvider.notifier).loadRules(),
                child: Text(
                  'Refresh',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: state.loadingRules && state.rules.isEmpty
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : filtered.isEmpty
                  ? _EmptyState(
                      icon: Icons.rule_outlined,
                      message: state.rules.isEmpty
                          ? 'No rules yet.\nUpload a compliance document to extract rules.'
                          : 'No rules match the selected filters.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RuleCard(rule: filtered[i])
                            .animate()
                            .fadeIn(
                              delay: Duration(milliseconds: i * 40),
                              duration: 300.ms,
                            )
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              delay: Duration(milliseconds: i * 40),
                              duration: 300.ms,
                            ),
                      ),
                    ),
        ),
      ],
    );
  }

  Color _severityColor(String s) {
    switch (s.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.critical;
      case 'HIGH':
        return AppColors.high;
      case 'MEDIUM':
        return AppColors.medium;
      case 'LOW':
        return AppColors.low;
      default:
        return AppColors.primary;
    }
  }
}

class _FilterRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selected;
  final void Function(String) onSelect;
  final Color Function(String)? activeColor;

  const _FilterRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((opt) {
                final isActive = selected == opt;
                final color = (activeColor != null && opt != 'ALL')
                    ? activeColor!(opt)
                    : AppColors.primary;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onSelect(opt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? color.withOpacity(0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isActive
                              ? color.withOpacity(0.5)
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        opt,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive ? color : AppColors.textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _RuleCard extends StatelessWidget {
  final ComplianceRule rule;
  const _RuleCard({required this.rule});

  Color get _sevColor {
    switch (rule.severity.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.critical;
      case 'HIGH':
        return AppColors.high;
      case 'MEDIUM':
        return AppColors.medium;
      default:
        return AppColors.low;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _sevColor;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
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
                              rule.category.isNotEmpty
                                  ? rule.category.toUpperCase()
                                  : 'GENERAL',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const Spacer(),
                          StatusChip(
                            label: rule.severity.toUpperCase(),
                            color: color,
                            fontSize: 9,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '#${rule.id}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rule.ruleTitle,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (rule.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          rule.description,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (rule.remediation.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  size: 12, color: AppColors.warning),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  rule.remediation,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (rule.languages.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: rule.languages
                              .map((l) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: AppColors.primary
                                              .withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      l.toLowerCase(),
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 9,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Validate Tab ──────────────────────────────────────────────────────────────

class _ValidateTab extends StatelessWidget {
  final ComplianceState state;
  final TextEditingController filePathCtrl;
  final TextEditingController codeCtrl;
  final VoidCallback onValidate;

  const _ValidateTab({
    required this.state,
    required this.filePathCtrl,
    required this.codeCtrl,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // File path input
        Text(
          'FILE PATH',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: filePathCtrl,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. app/config.py',
            hintStyle: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Code input
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SOURCE CODE',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            GestureDetector(
              onTap: () async {
                final data = await Clipboard.getData('text/plain');
                if (data?.text != null) {
                  codeCtrl.text = data!.text!;
                }
              },
              child: Text(
                'Paste from clipboard',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: codeCtrl,
          maxLines: 12,
          style: GoogleFonts.sourceCodePro(
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Paste your source code here…',
            hintStyle: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Validate button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: state.validating ? null : onValidate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.border,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: state.validating
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Scanning…',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Run Compliance Check',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),

        // Error
        if (state.validateError != null) ...[
          const SizedBox(height: 12),
          _ErrorCard(message: state.validateError!),
        ],

        // Results
        if (state.validationRan && state.validateError == null) ...[
          const SizedBox(height: 16),
          if (state.findings.isEmpty)
            _SuccessBanner()
              .animate()
              .fadeIn(duration: 400.ms)
          else ...[
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                Text(
                  '${state.findings.length} violation${state.findings.length == 1 ? '' : 's'} found',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...state.findings.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FindingCard(finding: e.value)
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: e.key * 60),
                          duration: 300.ms,
                        )
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          delay: Duration(milliseconds: e.key * 60),
                          duration: 300.ms,
                        ),
                  ),
                ),
          ],
        ],
      ],
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.verified_outlined,
                size: 20, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All checks passed',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  'No compliance violations detected in this file.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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

class _FindingCard extends StatelessWidget {
  final FindingResult finding;
  const _FindingCard({required this.finding});

  Color get _color {
    switch (finding.severity.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.critical;
      case 'HIGH':
        return AppColors.high;
      case 'MEDIUM':
        return AppColors.medium;
      default:
        return AppColors.low;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusChip(
                            label: finding.severity.toUpperCase(),
                            color: color,
                            fontSize: 9,
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Rule #${finding.ruleId}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (finding.lineNumber > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Line ${finding.lineNumber}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        finding.message,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (finding.remediation.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  size: 12, color: AppColors.warning),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  finding.remediation,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Documents Tab ─────────────────────────────────────────────────────────────

class _DocumentsTab extends ConsumerWidget {
  final ComplianceState state;
  const _DocumentsTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                '${state.documents.length} document${state.documents.length == 1 ? '' : 's'}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              if (state.loadingDocuments) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.primary,
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    ref.read(complianceProvider.notifier).loadDocuments(),
                child: Text(
                  'Refresh',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.loadingDocuments && state.documents.isEmpty
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : state.documents.isEmpty
                  ? _EmptyState(
                      icon: Icons.folder_outlined,
                      message:
                          'No documents ingested yet.\nUpload a compliance document to get started.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: state.documents.length,
                      itemBuilder: (context, i) {
                        final doc = state.documents[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _DocumentCard(doc: doc)
                              .animate()
                              .fadeIn(
                                delay: Duration(milliseconds: i * 50),
                                duration: 300.ms,
                              ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentInfo doc;
  const _DocumentCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final extracted = doc.rulesExtracted;
    final color = extracted ? AppColors.success : AppColors.warning;

    DateTime? ingested;
    try {
      ingested = DateTime.parse(doc.ingestedAt);
    } catch (_) {}

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              doc.fileType.toLowerCase() == 'pdf'
                  ? Icons.picture_as_pdf_outlined
                  : Icons.article_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.filename,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      doc.fileType.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (ingested != null) ...[
                      Text(
                        '  ·  ${DateFormat('MMM d, y').format(ingested)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(
                label: extracted ? 'EXTRACTED' : 'PENDING',
                color: color,
                fontSize: 9,
              ),
              const SizedBox(height: 4),
              Text(
                '${doc.ruleCount} rule${doc.ruleCount == 1 ? '' : 's'}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.critical.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.critical.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 16, color: AppColors.critical),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                color: AppColors.critical,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

