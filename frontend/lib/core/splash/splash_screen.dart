import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// A refined, classical splash screen — elegant fade/scale reveal,
/// serif typography, and restrained motion instead of busy effects.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  // Logo
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Ring / glow that gently blooms in behind the logo
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;
  late final Animation<double> _glowOpacity;

  // Divider line
  late final Animation<double> _lineWidth;
  late final Animation<double> _lineOpacity;

  // Title
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleSlide;

  // Subtitle
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _subtitleSlide;

  // Footer
  late final Animation<double> _footerOpacity;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // Logo: gentle scale + fade in, settles by ~35%
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOutCubic),
      ),
    );

    // Ring blooms outward slightly behind the logo
    _ringOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.42, curve: Curves.easeOut),
      ),
    );
    _ringScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.50, curve: Curves.easeOutCubic),
      ),
    );
    _glowOpacity = Tween<double>(begin: 0.0, end: 0.30).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.10, 0.45, curve: Curves.easeOut),
      ),
    );

    // Divider line draws out
    _lineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.55, curve: Curves.easeOut),
    );
    _lineWidth = Tween<double>(begin: 0.0, end: 64.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    // Title
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.48, 0.72, curve: Curves.easeOut),
    );
    _titleSlide = Tween<double>(begin: 14.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    // Subtitle
    _subtitleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.82, curve: Curves.easeOut),
    );
    _subtitleSlide = Tween<double>(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    // Footer version tag, last to appear
    _footerOpacity = Tween<double>(begin: 0.0, end: 0.55).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.80, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 3400), _navigateAway);
  }

  void _navigateAway() {
    if (!mounted || _navigated) return;
    _navigated = true;
    context.go('/welcome');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFFFFFFFF),
              AppColors.primarySurface,
              Color(0xFFE3EEFF),
              Color(0xFFD3E4FF),
            ],
            stops: [0.0, 0.35, 0.72, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Centered logo + title block ────────────────────────
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Glow + rings behind logo ─────────────────
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: _glowOpacity.value,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.primaryLight.withOpacity(0.9),
                                    blurRadius: 90,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: _ringScale.value,
                            child: Opacity(
                              opacity: _ringOpacity.value,
                              child: Container(
                                width: 188,
                                height: 188,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.18),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: _ringScale.value,
                            child: Opacity(
                              opacity: _ringOpacity.value * 0.7,
                              child: Container(
                                width: 224,
                                height: 224,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.10),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ── Logo ──────────────────────────────────
                          Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: Container(
                                width: 148,
                                height: 148,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.primary.withOpacity(0.12),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Title ─────────────────────────────────────
                      Opacity(
                        opacity: _titleOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _titleSlide.value),
                          child: Text(
                            'HARBOUR',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              letterSpacing: 6,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ── Subtitle ──────────────────────────────────
                      Opacity(
                        opacity: _subtitleOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _subtitleSlide.value),
                          child: Text(
                            'P R O',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary.withOpacity(0.75),
                              letterSpacing: 6,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Divider line ──────────────────────────────
                      Opacity(
                        opacity: _lineOpacity.value,
                        child: Container(
                          width: _lineWidth.value,
                          height: 1.2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primary.withOpacity(0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Footer version tag ────────────────────────────────
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Opacity(
                    opacity: _footerOpacity.value,
                    child: Center(
                      child: Text(
                        'v1.0.0',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}