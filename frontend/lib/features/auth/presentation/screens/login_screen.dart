import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  late AnimationController _cardCtrl;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardOpacity;

  bool _passwordVisible = false;

  static const _navy = AppColors.primary;
  static const _blue = AppColors.primary;
  static const _blueLight = AppColors.primaryDark;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onFocusChange);
    _passFocus.addListener(_onFocusChange);

    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));

    _cardOpacity = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);

    _cardCtrl.forward();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _emailFocus.removeListener(_onFocusChange);
    _passFocus.removeListener(_onFocusChange);
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);

    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        final route = AuthNotifier.dashboardRouteFor(user.role);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(route);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // ── Responsive helpers ──────────────────────────────────────────────────
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallHeight = screenHeight < 700;
    // Lock system font scaling so it doesn't compound spacing issues
    final textScaler = MediaQuery.of(context).textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.1,
        );

    // Scale vertical gaps proportionally on short screens
    double sp(double base) => isSmallHeight ? base * 0.75 : base;

    final logoSize = isSmallHeight ? 64.0 : 88.0;
    final headerPadding = EdgeInsets.fromLTRB(
      20,
      isSmallHeight ? 4 : 8,
      20,
      isSmallHeight ? 12 : 20,
    );
    final cardPadding = EdgeInsets.fromLTRB(
      24,
      isSmallHeight ? 20 : 32,
      24,
      24,
    );
    final signInBtnHeight = isSmallHeight ? 46.0 : 52.0;
    final createBtnHeight = isSmallHeight ? 44.0 : 50.0;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: Scaffold(
        backgroundColor: _navy,
        body: Column(
          children: [
            // ── Dark header: back arrow + logo + brand + tagline ────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: headerPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
  onPressed: () {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/welcome');
    }
  },
  icon: const Icon(Icons.arrow_back, color: Colors.white),
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(),
),
                    SizedBox(height: sp(8)),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(height: sp(12)),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: isSmallHeight ? 22 : 26,
                                fontWeight: FontWeight.w800,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'HARBOUR ',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const TextSpan(
                                  text: 'PRO',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: sp(6)),
                          Text(
                            'One Smart Platform. All Seafood Businesses.',
                            style: GoogleFonts.inter(
                              fontSize: isSmallHeight ? 11 : 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: sp(4)),
                          Text(
                            'Your Fishing. Our Technology.',
                            style: GoogleFonts.inter(
                              fontSize: isSmallHeight ? 13 : 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── White rounded card with the login form ──────────────────
            Expanded(
              child: SlideTransition(
                position: _cardSlide,
                child: FadeTransition(
                  opacity: _cardOpacity,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: cardPadding,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight -
                                    cardPadding.vertical,
                              ),
                              child: IntrinsicHeight(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Welcome back',
                                        style: GoogleFonts.inter(
                                          fontSize: isSmallHeight ? 21 : 24,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF10192E),
                                        ),
                                      ),
                                      SizedBox(height: sp(6)),
                                      Text(
                                        'Sign in to continue',
                                        style: GoogleFonts.inter(
                                          fontSize: isSmallHeight ? 13 : 14,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                      SizedBox(height: sp(28)),

                                      if (authState.errorMessage != null) ...[
                                        AppErrorBanner(
                                          message: authState.errorMessage!,
                                          onDismiss: () => ref
                                              .read(authProvider.notifier)
                                              .clearError(),
                                        ),
                                        SizedBox(height: sp(16)),
                                      ],

                                      // ── Card holding the two fields ────
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.04),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            _buildEmailField(),
                                            const Divider(height: 1),
                                            _buildPasswordField(),
                                          ],
                                        ),
                                      ),

                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () =>
                                              context.push('/forgot-password'),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                          ),
                                          child: Text(
                                            'Forgot password?',
                                            style: GoogleFonts.inter(
                                              fontSize: isSmallHeight ? 12 : 13,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF10192E),
                                            ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: sp(10)),

                                      // ── Sign In button ─────────────────
                                      SizedBox(
                                        width: double.infinity,
                                        height: signInBtnHeight,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [_blue, _blueLight],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(26),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _blue.withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(26),
                                              onTap: authState.isLoading
                                                  ? null
                                                  : _onLogin,
                                              splashColor: _blueLight,
                                              highlightColor: _blueLight.withOpacity(0.5),
                                              child: Center(
                                                child: authState.isLoading
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2.2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation(
                                                            Colors.white,
                                                          ),
                                                        ),
                                                      )
                                                    : Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            'Sign In',
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize:
                                                                  isSmallHeight
                                                                      ? 15
                                                                      : 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: Colors.white,
                                                              letterSpacing: 0.4,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          const Icon(
                                                            Icons
                                                                .arrow_forward,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: sp(22)),

                                      Text(
                                        "Don't have an account?",
                                        style: GoogleFonts.inter(
                                          fontSize: isSmallHeight ? 12.5 : 13.5,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),

                                      SizedBox(height: sp(10)),

                                      // ── Create Account button ──────────
                                      SizedBox(
                                        width: double.infinity,
                                        height: createBtnHeight,
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              context.push('/select-harbour'),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: _blue,
                                              width: 1.4,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                            ),
                                          ),
                                          child: Text(
                                            'Create Account',
                                            style: GoogleFonts.inter(
                                              fontSize: isSmallHeight ? 14 : 15,
                                              fontWeight: FontWeight.w500,
                                              color: _blue,
                                            ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: sp(12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailCtrl,
      focusNode: _emailFocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _passFocus.requestFocus(),
      style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF10192E)),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email is required';
        final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
        if (!emailRegex.hasMatch(v.trim())) {
          return 'Enter a valid email address';
        }
        return null;
      },
      decoration: _fieldDecoration(
        hint: 'Email',
        icon: Icons.email_outlined,
        isFocused: _emailFocus.hasFocus,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passCtrl,
      focusNode: _passFocus,
      obscureText: !_passwordVisible,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _onLogin(),
      style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF10192E)),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        if (v.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
      decoration: _fieldDecoration(
        hint: 'Password',
        icon: Icons.lock_outline_rounded,
        isFocused: _passFocus.hasFocus,
        suffix: IconButton(
          icon: Icon(
            _passwordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: const Color(0xFF9CA3AF),
          ),
          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    required bool isFocused,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 15,
        color: const Color(0xFF9CA3AF),
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: isFocused ? AppColors.primary : const Color(0xFF9CA3AF),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.transparent,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      errorStyle: GoogleFonts.inter(
        fontSize: 11,
        color: const Color(0xFFD32F2F),
      ),
    );
  }
}