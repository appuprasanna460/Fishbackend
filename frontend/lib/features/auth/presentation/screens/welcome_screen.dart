import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Responsive helpers ──────────────────────────────────────────────────
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallHeight = screenHeight < 700;
    // Lock system font scaling so it doesn't compound spacing issues
    final textScaler = MediaQuery.of(context).textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.1,
        );

    // Position the button stack proportionally from the bottom
    final buttonsBottom = isSmallHeight ? 64.0 : 99.0;
    final buttonHeight = isSmallHeight ? 36.0 : 40.0;
    final buttonGap = isSmallHeight ? 6.0 : 8.0;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: Scaffold(
        backgroundColor: AppColors.primary,

        body: SafeArea(
          child: Column(
            children: [
              // ─────────────────────────────────────
              // IMAGE + BUTTONS OVERLAID ON TOP
              // ─────────────────────────────────────
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/image.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),

                    // dark gradient so button text/border stays readable
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.primaryDark.withOpacity(0.75),
                          ],
                          stops: const [0.4, 0.9],
                        ),
                      ),
                    ),

                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: buttonsBottom,
                      child: Column(
                        children: [
                          _WelcomeButton(
                            label: 'Sign In',
                            isPrimary: true,
                            showArrow: true,
                            height: buttonHeight,
                            onTap: () => context.go('/login'),
                          ),
                          SizedBox(height: buttonGap),
                          _WelcomeButton(
                            label: 'Create Account',
                            isPrimary: false,
                            showArrow: false,
                            height: buttonHeight,
                            onTap: () => context.push('/select-harbour'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BUTTON — minimized size
// ─────────────────────────────────────────────

class _WelcomeButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final bool showArrow;
  final double height;
  final VoidCallback onTap;

  const _WelcomeButton({
    required this.label,
    required this.isPrimary,
    required this.showArrow,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: double.infinity,
        height: height,

        decoration: BoxDecoration(
          // Sign In: solid #2063EE. Create Account: transparent with
          // white border/text — palette is #2063EE + white only.
          color: isPrimary ? AppColors.primary : Colors.transparent,

          borderRadius: BorderRadius.circular(20),

          border: isPrimary
              ? null
              : Border.all(
                  color: Colors.white,
                  width: 1.0,
                ),

          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),

            if (showArrow) ...[
              const SizedBox(width: 6),

              const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 15,
              ),
            ],
          ],
        ),
      ),
    );
  }
}