import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _awsAccessKeyCtrl   = TextEditingController();
  final _awsSecretKeyCtrl   = TextEditingController();
  final _supabaseUrlCtrl    = TextEditingController();
  final _supabaseAnonKeyCtrl = TextEditingController();

  bool _awsSecretVisible      = false;
  bool _supabaseAnonKeyVisible = false;

  @override
  void dispose() {
    _awsAccessKeyCtrl.dispose();
    _awsSecretKeyCtrl.dispose();
    _supabaseUrlCtrl.dispose();
    _supabaseAnonKeyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(authProvider.notifier).login(
          awsAccessKey:    _awsAccessKeyCtrl.text.trim(),
          awsSecretKey:    _awsSecretKeyCtrl.text.trim(),
          supabaseUrl:     _supabaseUrlCtrl.text.trim(),
          supabaseAnonKey: _supabaseAnonKeyCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background grid pattern
          Positioned.fill(child: _BackgroundGrid()),

          // Gradient overlays
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.bg.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo + Title
                      _buildHeader()
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: -0.2, end: 0, duration: 600.ms, curve: Curves.easeOut),

                      const SizedBox(height: 40),

                      // Error banner
                      if (auth.error != null)
                        _ErrorBanner(message: auth.error!)
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: -0.1, end: 0),

                      if (auth.error != null) const SizedBox(height: 16),

                      // AWS Credentials card
                      _buildAwsSection()
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 600.ms, curve: Curves.easeOut),

                      const SizedBox(height: 16),

                      // Supabase card
                      _buildSupabaseSection()
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0, delay: 350.ms, duration: 600.ms, curve: Curves.easeOut),

                      const SizedBox(height: 28),

                      // Connect button
                      _buildConnectButton(auth.isLoading)
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0, delay: 500.ms, duration: 600.ms, curve: Curves.easeOut),

                      const SizedBox(height: 24),

                      // Footer note
                      Center(
                        child: Text(
                          'Credentials are stored securely on this device only',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Shield icon with glow
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDim,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.shield_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'SecretLens',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Secure DevOps Dashboard',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAwsSection() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2A0A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.cloud_outlined,
                  size: 16,
                  color: Color(0xFF90D26B),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AWS Credentials',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: _awsAccessKeyCtrl,
            label: 'Access Key ID',
            placeholder: 'AKIAIOSFODNN7EXAMPLE',
            prefixIcon: Icons.key_outlined,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _awsSecretKeyCtrl,
            label: 'Secret Access Key',
            placeholder: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
            prefixIcon: Icons.lock_outline,
            obscure: !_awsSecretVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _awsSecretVisible ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _awsSecretVisible = !_awsSecretVisible),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupabaseSection() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.successDim,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.storage_outlined,
                  size: 16,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Supabase Database',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: _supabaseUrlCtrl,
            label: 'Project URL',
            placeholder: 'https://xxxxxxxxxxxx.supabase.co',
            prefixIcon: Icons.link_outlined,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _supabaseAnonKeyCtrl,
            label: 'Anon Key',
            placeholder: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
            prefixIcon: Icons.vpn_key_outlined,
            obscure: !_supabaseAnonKeyVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _supabaseAnonKeyVisible ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(
                  () => _supabaseAnonKeyVisible = !_supabaseAnonKeyVisible),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required IconData prefixIcon,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
            prefixIcon: Icon(prefixIcon, size: 16, color: AppColors.textSecondary),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectButton(bool isLoading) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF4D9FFF), Color(0xFF1A6FDB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isLoading ? null : _submit,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'CONNECT',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.criticalDim,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.critical.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.critical),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: AppColors.critical,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withOpacity(0.4)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
