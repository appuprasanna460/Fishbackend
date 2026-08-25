import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/utils/secure_storage.dart';
import '../providers/pin_provider.dart';

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPinCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _hasStoredPin = false;

  @override
  void initState() {
    super.initState();
    _checkStoredPin();
  }

  Future<void> _checkStoredPin() async {
    final pin = await SecureStorage.getPin();
    setState(() {
      _hasStoredPin = pin != null && pin.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _currentPinCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitChangePin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasStoredPin) {
      final storedPin = await SecureStorage.getPin();
      if (storedPin != _currentPinCtrl.text) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Current PIN is incorrect'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    if (_newPinCtrl.text != _confirmPinCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ New PIN and Confirm PIN do not match'), backgroundColor: Colors.red),
      );
      return;
    }

    await ref.read(pinProvider.notifier).setPin(_newPinCtrl.text);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Security PIN changed successfully!'),
        backgroundColor: Color(0xFF2ECC71),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Change PIN',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update App Lock PIN',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Set a 4-digit PIN to secure your app from unauthorized access.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSizes.p24),

              // Current PIN (Only show if PIN exists)
              if (_hasStoredPin) ...[
                _buildPinField(
                  controller: _currentPinCtrl,
                  label: 'Current 4-Digit PIN',
                  obscure: _obscureCurrent,
                  toggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Current PIN is required';
                    if (v.length != 4) return 'PIN must be 4 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // New PIN
              _buildPinField(
                controller: _newPinCtrl,
                label: 'New 4-Digit PIN',
                obscure: _obscureNew,
                toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'New PIN is required';
                  if (v.length != 4) return 'PIN must be 4 digits';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm PIN
              _buildPinField(
                controller: _confirmPinCtrl,
                label: 'Confirm New 4-Digit PIN',
                obscure: _obscureConfirm,
                toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirm PIN is required';
                  if (v.length != 4) return 'PIN must be 4 digits';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Change PIN Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Change PIN',
                  onPressed: _submitChangePin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggleObscure,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      style: GoogleFonts.inter(fontSize: 16, letterSpacing: 8, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13, letterSpacing: 0, fontWeight: FontWeight.normal),
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: toggleObscure,
        ),
      ),
      validator: validator,
    );
  }
}
