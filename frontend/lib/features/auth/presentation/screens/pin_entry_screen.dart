import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/pin_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

/// Premium numpad-style PIN entry screen shown on app launch
/// when a PIN has been configured by the user.
class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen>
    with TickerProviderStateMixin {
  String _entered = '';
  static const int _pinLength = 4;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onKey(String digit) {
    if (_entered.length < _pinLength) {
      setState(() => _entered += digit);
      if (_entered.length == _pinLength) {
        _verify();
      }
    }
  }

  void _onDelete() {
    if (_entered.isNotEmpty) {
      setState(() => _entered = _entered.substring(0, _entered.length - 1));
    }
  }

  Future<void> _verify() async {
    final success =
        await ref.read(pinProvider.notifier).unlockApp(_entered);
    if (!success) {
      _shakeCtrl.forward(from: 0);
      setState(() => _entered = '');
    } else {
      if (mounted) {
        final authState = ref.read(authProvider);
        final role = authState.user?.role ?? '';
        final route = _dashboardForRole(role);
        context.go(route);
      }
    }
  }

  String _dashboardForRole(String role) {
    return switch (role) {
      'SUPER_ADMIN' => '/admin/dashboard',
      'COMMISSION_AGENT' => '/agent/dashboard',
      'BOAT_OWNER' => '/owner/dashboard',
      'FISH_BUYER' => '/buyer/dashboard',
      'STAFF' => '/staff/dashboard',
      _ => '/login',
    };
  }

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(pinProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.loginGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
            child: Column(
              children: [
                SizedBox(height: size.height * 0.08),

                // Lock icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1.5),
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: Colors.white, size: 36),
                ),

                const SizedBox(height: 20),

                Text(
                  'Enter PIN',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your 4-digit PIN to unlock',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 40),

                // PIN dots with shake animation
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_shakeAnim.value, 0),
                    child: child,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pinLength, (i) {
                      final filled = i < _entered.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? Colors.white
                              : Colors.transparent,
                          border: Border.all(
                            color: filled
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Error message
                const SizedBox(height: 16),
                AnimatedOpacity(
                  opacity: pinState.errorMessage != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    pinState.errorMessage ?? '',
                    style: GoogleFonts.inter(
                      color: Colors.redAccent.shade200,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const Spacer(),

                // Numpad
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      _buildRow(['1', '2', '3']),
                      const SizedBox(height: 16),
                      _buildRow(['4', '5', '6']),
                      const SizedBox(height: 16),
                      _buildRow(['7', '8', '9']),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const SizedBox(width: 80),
                          _NumKey(label: '0', onTap: () => _onKey('0')),
                          _DeleteKey(onTap: _onDelete),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) {
        return _NumKey(label: d, onTap: () => _onKey(d));
      }).toList(),
    );
  }
}

class _NumKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NumKey({required this.label, required this.onTap});

  @override
  State<_NumKey> createState() => _NumKeyState();
}

class _NumKeyState extends State<_NumKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pressed
              ? Colors.white.withOpacity(0.25)
              : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteKey extends StatefulWidget {
  final VoidCallback onTap;
  const _DeleteKey({required this.onTap});

  @override
  State<_DeleteKey> createState() => _DeleteKeyState();
}

class _DeleteKeyState extends State<_DeleteKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pressed
              ? Colors.white.withOpacity(0.25)
              : Colors.transparent,
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
