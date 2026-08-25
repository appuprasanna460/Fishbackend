import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../subscription_plan/presentation/providers/subscription_plan_provider.dart';

// ─── Registration State & Provider ───────────────────────────────────────────

class _RegistrationState {
  final bool isLoading;
  final String? error;
  final bool success;
  const _RegistrationState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });
  _RegistrationState copyWith(
          {bool? isLoading, String? error, bool? success, bool clearError = false}) =>
      _RegistrationState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        success: success ?? this.success,
      );
}

final _regStateProvider =
    StateNotifierProvider.autoDispose<_RegNotifier, _RegistrationState>(
        (ref) => _RegNotifier());

class _RegNotifier extends StateNotifier<_RegistrationState> {
  _RegNotifier() : super(const _RegistrationState());

  Future<void> register(Map<String, dynamic> payload) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      await dio.post(ApiConstants.register, data: payload);
      state = state.copyWith(isLoading: false, success: true);
    } on DioException catch (e) {
      final msg = (e.response?.data as Map<dynamic, dynamic>?)?['message']
              as String? ??
          e.message ??
          'Registration failed. Please try again.';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  final String harbourId;
  final String harbourName;

  const RegisterScreen({
    super.key,
    required this.harbourId,
    required this.harbourName,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  
  // New profile controllers
  final _aboutCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emergNameCtrl = TextEditingController();
  final _emergRelCtrl = TextEditingController();
  final _emergPhoneCtrl = TextEditingController();

  DateTime? _dobDate;
  String _selectedRole = 'COMMISSION_AGENT';
  String? _selectedPlanId; // ObjectId of the selected plan
  bool _obscurePass = true;

  static const _roles = [
    ('COMMISSION_AGENT', 'Commission Agent', Icons.handshake_outlined),
    ('BOAT_OWNER', 'Boat Owner', Icons.sailing_rounded),
    ('FISH_BUYER', 'Fish Buyer', Icons.shopping_bag_outlined),
  ];

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionPlanProvider.notifier).loadActivePlans();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _referenceCtrl.dispose();
    _aboutCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    _emergNameCtrl.dispose();
    _emergRelCtrl.dispose();
    _emergPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(_regStateProvider.notifier).register({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text,
      'phone': _phoneCtrl.text.trim(),
      'companyName': _companyCtrl.text.trim(),
      'referenceBy': _referenceCtrl.text.trim(),
      'role': _selectedRole,
      'harbourId': widget.harbourId,
      // Send the plan ObjectId for dynamic duration lookup
      if (_selectedPlanId != null) 'subscriptionPlanId': _selectedPlanId,
      // New profile fields
      'aboutYou': _aboutCtrl.text.trim(),
      if (_dobDate != null) 'dateOfBirth': _dobDate!.toIso8601String(),
      'address': _addressCtrl.text.trim(),
      'emergencyContactName': _emergNameCtrl.text.trim(),
      'emergencyContactRelationship': _emergRelCtrl.text.trim(),
      'emergencyContactPhone': _emergPhoneCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(_regStateProvider);
    final planState = ref.watch(subscriptionPlanProvider);
    final activePlans = planState.activePlans ?? [];

    ref.listen(_regStateProvider, (prev, next) {
      if (next.success && !(prev?.success ?? false)) {
        _showSuccessDialog();
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          'Create Account',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.anchor_rounded,
                          color: Colors.white, size: 15),
                      const SizedBox(width: 8),
                      Text(
                        widget.harbourName,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('PERSONAL DETAILS'),
                            const SizedBox(height: 12),
                            _Field(
                              controller: _nameCtrl,
                              label: 'Full Name',
                              icon: Icons.person_outline_rounded,
                              validator: (v) => (v?.trim().isEmpty ?? true)
                                  ? 'Name is required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              controller: _emailCtrl,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Email is required';
                                if (!v.contains('@'))
                                  return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscurePass,
                              style: GoogleFonts.inter(fontSize: 14),
                              decoration:
                                  _inputDeco('Password', Icons.lock_outline_rounded)
                                      .copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                      () => _obscurePass = !_obscurePass),
                                  icon: Icon(_obscurePass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Password is required';
                                if (v.length < 8)
                                  return 'At least 8 characters required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              controller: _phoneCtrl,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Phone is required';
                                if (v.length != 10)
                                  return 'Enter 10-digit phone number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              controller: _companyCtrl,
                              label: 'Company Name',
                              icon: Icons.business_outlined,
                              validator: (v) => (v?.trim().isEmpty ?? true)
                                  ? 'Company name is required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                             _Field(
                               controller: _referenceCtrl,
                               label: 'Referred By (optional)',
                               icon: Icons.people_outline_rounded,
                             ),
                             const SizedBox(height: 12),
                             _SectionLabel('PROFILE DETAILS'),
                             const SizedBox(height: 12),
                             _Field(
                               controller: _aboutCtrl,
                               label: 'About You',
                               icon: Icons.info_outline_rounded,
                             ),
                             const SizedBox(height: 12),
                             TextFormField(
                               controller: _dobCtrl,
                               readOnly: true,
                               style: GoogleFonts.inter(fontSize: 14),
                               decoration: _inputDeco('Date of Birth', Icons.calendar_today_outlined),
                               onTap: () async {
                                 final picked = await showDatePicker(
                                   context: context,
                                   initialDate: DateTime(1990),
                                   firstDate: DateTime(1900),
                                   lastDate: DateTime.now(),
                                 );
                                 if (picked != null) {
                                   setState(() {
                                     _dobDate = picked;
                                     _dobCtrl.text = "${picked.day}-${_months[picked.month - 1]}-${picked.year}";
                                   });
                                 }
                               },
                             ),
                             const SizedBox(height: 12),
                             _Field(
                               controller: _addressCtrl,
                               label: 'Address',
                               icon: Icons.home_outlined,
                             ),
                             const SizedBox(height: 12),
                             _Field(
                               controller: _emergNameCtrl,
                               label: 'Emergency Contact Name',
                               icon: Icons.contact_phone_outlined,
                             ),
                             const SizedBox(height: 12),
                             _Field(
                               controller: _emergRelCtrl,
                               label: 'Emergency Contact Relationship (e.g. Wife)',
                               icon: Icons.people_outline_rounded,
                             ),
                             const SizedBox(height: 12),
                             _Field(
                               controller: _emergPhoneCtrl,
                               label: 'Emergency Contact Phone Number',
                               icon: Icons.phone_outlined,
                               keyboardType: TextInputType.phone,
                               inputFormatters: [
                                 FilteringTextInputFormatter.digitsOnly,
                                 LengthLimitingTextInputFormatter(10),
                               ],
                             ),
                             const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                            _SectionLabel('SELECT ROLE'),
                            const SizedBox(height: 12),
                            ..._roles.map((r) {
                              final isSelected = _selectedRole == r.$1;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _RoleCard(
                                  id: r.$1,
                                  label: r.$2,
                                  icon: r.$3,
                                  isSelected: isSelected,
                                  onTap: () =>
                                      setState(() => _selectedRole = r.$1),
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                            _SectionLabel('SUBSCRIPTION PLAN'),
                            const SizedBox(height: 12),
                            if (activePlans.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  'No active plans available',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            else
                              ...activePlans.map((p) {
                                final isSelected = _selectedPlanId == p.id;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _PlanCard(
                                    id: p.id ?? '',
                                    label: p.name,
                                    duration: p.durationDaysLabel,
                                    price: p.priceLabel,
                                    isSelected: isSelected,
                                    onTap: () => setState(
                                        () => _selectedPlanId = p.id),
                                  ),
                                );
                              }),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFFFCC02)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded,
                                      color: Color(0xFFF59E0B), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Admin will review and approve your account within 24-48 hours.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF78350F),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed:
                                    regState.isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(27)),
                                ),
                                child: regState.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Submit Registration',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.shade50,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 44),
              ),
              const SizedBox(height: 18),
              Text(
                'Registration Submitted!',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your account is pending approval.\nAdmin will approve within 24-48 hours.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/welcome');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text('Back to Home',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9FF),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: _inputDeco(label, icon),
        validator: validator,
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      );
}

class _RoleCard extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _RoleCard({
    required this.id,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                    : null,
              ),
            ],
          ),
        ),
      );
}

class _PlanCard extends StatelessWidget {
  final String id, label, duration, price;
  final bool isSelected;
  final VoidCallback onTap;
  const _PlanCard({
    required this.id,
    required this.label,
    required this.duration,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade400,
                      width: 2),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        )),
                    Text(duration,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(price,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    )),
              ),
            ],
          ),
        ),
      );
}
