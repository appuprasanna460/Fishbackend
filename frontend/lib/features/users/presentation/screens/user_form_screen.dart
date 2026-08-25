import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../providers/user_provider.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  final String? userId;
  const UserFormScreen({super.key, this.userId});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _subLocationCtrl = TextEditingController();

  String _selectedRole = 'STAFF';
  String? _selectedAgentId;
  bool _isEdit = false;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Password strength
  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = AppColors.border;

  // Email duplicate tracking
  String? _emailError;
  bool _isEmailValid = false;

  AnimationController? _animCtrl;
  Animation<double> _fadeAnim = const AlwaysStoppedAnimation(1.0);

  static const List<Map<String, dynamic>> _roles = [
    {
      'value': 'SUPER_ADMIN',
      'label': 'Super Admin',
      'icon': Icons.admin_panel_settings_rounded,
      'color': AppColors.roleSuperAdmin,
    },
    {
      'value': 'COMMISSION_AGENT',
      'label': 'Commission Agent',
      'icon': Icons.assignment_ind_rounded,
      'color': AppColors.roleAgent,
    },
    {
      'value': 'STAFF',
      'label': 'Staff',
      'icon': Icons.badge_rounded,
      'color': AppColors.roleStaff,
    },
    {
      'value': 'FISH_BUYER',
      'label': 'Fish Buyer',
      'icon': Icons.shopping_bag_rounded,
      'color': AppColors.roleBuyer,
    },
    {
      'value': 'BOAT_OWNER',
      'label': 'Boat Owner',
      'icon': Icons.directions_boat_rounded,
      'color': AppColors.roleOwner,
    },
  ];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.userId != null;

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl!, curve: Curves.easeOut);
    _animCtrl!.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => _isLoading = true);
      await ref.read(userProvider.notifier).loadAgents();
      if (_isEdit) {
        final ok = await ref
            .read(userProvider.notifier)
            .loadById(widget.userId!);
        if (ok) {
          final user = ref.read(userProvider).selected;
          if (user != null && mounted) {
            _nameCtrl.text = user.name;
            _emailCtrl.text = user.email;
            _phoneCtrl.text = user.phone;
            _selectedRole = user.role;
            _locationCtrl.text = user.locationId ?? '';
            _subLocationCtrl.text = user.subLocationId ?? '';
            _selectedAgentId = user.agentId;
          }
        }
      }
      if (mounted) setState(() => _isLoading = false);
    });

    _passwordCtrl.addListener(_evaluatePasswordStrength);
    
    // Clear email error when user types
    _emailCtrl.addListener(() {
      if (_emailError != null) {
        setState(() => _emailError = null);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _locationCtrl.dispose();
    _subLocationCtrl.dispose();
    _animCtrl?.dispose();
    super.dispose();
  }

  // ── Password strength ───────────────────────────────────────────────────────

  void _evaluatePasswordStrength() {
    final val = _passwordCtrl.text;
    if (val.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _passwordStrengthLabel = '';
        _passwordStrengthColor = AppColors.border;
      });
      return;
    }

    int score = 0;
    if (val.length >= 8) score++;
    if (val.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(val)) score++;
    if (RegExp(r'[0-9]').hasMatch(val)) score++;
    if (RegExp(r'[!@#\$&*~%^()_\-+=]').hasMatch(val)) score++;

    final strength = score / 5.0;
    String label;
    Color color;
    if (score <= 1) {
      label = 'Very weak';
      color = AppColors.error;
    } else if (score == 2) {
      label = 'Weak';
      color = Colors.orange;
    } else if (score == 3) {
      label = 'Fair';
      color = Colors.amber;
    } else if (score == 4) {
      label = 'Strong';
      color = AppColors.success;
    } else {
      label = 'Very strong';
      color = const Color(0xFF1B5E20);
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthLabel = label;
      _passwordStrengthColor = color;
    });
  }

  // ── Email duplicate check ───────────────────────────────────────────────────

  void _checkEmailDuplicate(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _emailError = null;
        _isEmailValid = false;
      });
      return;
    }
    
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      setState(() {
        _emailError = null;
        _isEmailValid = false;
      });
      return;
    }
    
    _isEmailValid = true;
    final users = ref.read(userProvider).users;
    final duplicate = users.any(
      (u) =>
          u.email.trim().toLowerCase() == value.trim().toLowerCase() &&
          (_isEdit ? u.id != widget.userId : true),
    );
    
    setState(
      () => _emailError = duplicate ? 'This email is already registered' : null,
    );
  }

  // ── Phone digit counter ────────────────────────────────────────────────────

  String _getPhoneCounter() {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    return '${digits.length}/10 digits';
  }

  // ── Save ────────────────────────────────────────────────────────────────────
Future<void> _onSave() async {
  // Clear previous email error
  setState(() => _emailError = null);
  
  if (!_formKey.currentState!.validate()) return;
  
  // Check for duplicate email one more time
  _checkEmailDuplicate(_emailCtrl.text);
  if (_emailError != null) {
    FocusScope.of(context).requestFocus(FocusNode());
    return;
  }

  final data = {
    'name': _nameCtrl.text.trim(),
    'email': _emailCtrl.text.trim(),
    'phone': _phoneCtrl.text.trim(),
    'role': _selectedRole,
    'isActive': true,
    if (!_isEdit) 'password': _passwordCtrl.text,
    if (_locationCtrl.text.isNotEmpty)
      'locationId': _locationCtrl.text.trim(),
    if (_subLocationCtrl.text.isNotEmpty)
      'subLocationId': _subLocationCtrl.text.trim(),
    if (_selectedAgentId != null &&
        (_selectedRole == 'STAFF' || _selectedRole == 'FISH_BUYER'))
      'agentId': _selectedAgentId,
  };

  setState(() => _isLoading = true);
  
  try {
    final ok = _isEdit
        ? await ref.read(userProvider.notifier).updateUser(widget.userId!, data)
        : await ref.read(userProvider.notifier).createUser(data);
    
    if (mounted) setState(() => _isLoading = false);

    if (!mounted) return;
    
    if (ok) {
      _showSuccessSnackBar(
        'User ${_isEdit ? 'updated' : 'created'} successfully',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    } else {
      // Get the error from the provider state
      final state = ref.read(userProvider);
      final errorMessage = state.error ?? '';
      
      // Check if error is about duplicate email
      if (errorMessage.toLowerCase().contains('email already registered')) {
        setState(() {
          _emailError = 'This email is already registered';
        });
        // Focus on email field
        Future.delayed(const Duration(milliseconds: 100), () {
          FocusScope.of(context).requestFocus(FocusNode());
        });
      } else {
        _showErrorSnackBar(errorMessage.isNotEmpty 
            ? errorMessage 
            : 'Operation failed. Please check the details and try again.');
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      
      final errorMessage = e.toString();
      
      // Check if error is about duplicate email
      if (errorMessage.toLowerCase().contains('email already registered')) {
        setState(() {
          _emailError = 'This email is already registered';
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          FocusScope.of(context).requestFocus(FocusNode());
        });
      } else {
        _showErrorSnackBar(
          errorMessage.replaceAll('Exception: ', ''),
        );
      }
    }
  }
}
  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius12),
        ),
        margin: const EdgeInsets.all(AppSizes.p16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius12),
        ),
        margin: const EdgeInsets.all(AppSizes.p16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final agents = ref.watch(userProvider).agents;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        surfaceTintColor: const Color.fromARGB(255, 251, 251, 251),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? 'Edit User' : 'Create User',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
            ),
            Text(
              _isEdit ? 'Update account details' : 'Add a new team member',
              style: AppTextStyles.caption.copyWith(
                color: const Color.fromARGB(255, 234, 233, 233),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: AppLoadingOverlay(
        isLoading: _isLoading,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section 1: Personal Info ──────────────────────────────
                  _SectionCard(
                    icon: Icons.person_rounded,
                    title: 'Personal Information',
                    subtitle: '',
                    children: [
                      // Name
                      _FieldLabel(label: 'Full Name', required: true),
                      AppTextField(
                        label: '',
                        hint: 'e.g. Rajan Kumar',
                        controller: _nameCtrl,
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Full name is required';
                          if (val.trim().length < 2)
                            return 'Name must be at least 2 characters';
                          if (!RegExp(
                            r"^[a-zA-Z\s'.]+$",
                          ).hasMatch(val.trim())) {
                            return 'Name can only contain letters and spaces';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSizes.p16),

                      // Email
                      _FieldLabel(label: 'Email Address', required: true),
                      AppTextField(
                        label: '',
                        hint: 'user@example.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        textInputAction: TextInputAction.next,
                        onChanged: _checkEmailDuplicate,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Email address is required';
                          final emailRegex = RegExp(
                            r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(val.trim()))
                            return 'Enter a valid email address';
                          return _emailError;
                        },
                      ),
                      if (_emailError != null)
                        _DuplicateWarning(message: _emailError!),

                      const SizedBox(height: AppSizes.p16),

                      // Phone
                      _FieldLabel(label: 'Phone Number', required: true),
                      AppTextField(
                        label: '',
                        hint: '9876543210',
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: (_) => setState(() {}), // Update counter
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Phone number is required';
                          final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
                          if (digits.length != 10)
                            return 'Phone number must be exactly 10 digits';
                          if (!RegExp(r'^[6-9]').hasMatch(digits))
                            return 'Enter a valid Indian mobile number';
                          return null;
                        },
                      ),
                      // Digit counter - Fixed with proper rebuild
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: ValueListenableBuilder(
                            valueListenable: _phoneCtrl,
                            builder: (context, value, child) {
                              final digits = value.text.replaceAll(RegExp(r'[^0-9]'), '');
                              final length = digits.length;
                              final isComplete = length == 10;
                              return Text(
                                '$length/10 digits',
                                style: AppTextStyles.caption.copyWith(
                                  color: isComplete ? AppColors.success : AppColors.textHint,
                                  fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.p16),

                  // ── Section 2: Password (create only) ────────────────────
                  if (!_isEdit)
                    _SectionCard(
                      icon: Icons.lock_rounded,
                      title: 'Security',
                      subtitle: 'Set a strong password for this account',
                      children: [
                        _FieldLabel(label: 'Password', required: true),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: !_showPassword,
                          textInputAction: TextInputAction.next,
                          style: AppTextStyles.bodyMedium,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: AppSizes.iconMd,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: AppSizes.iconMd,
                                color: AppColors.textHint,
                              ),
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius12,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius12,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius12,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty)
                              return 'Password is required';
                            if (val.length < 8)
                              return 'Password must be at least 8 characters';
                            if (!RegExp(r'[A-Z]').hasMatch(val))
                              return 'Include at least one uppercase letter';
                            if (!RegExp(r'[0-9]').hasMatch(val))
                              return 'Include at least one number';
                            return null;
                          },
                        ),

                        // Strength bar
                        if (_passwordCtrl.text.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.p8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _passwordStrength,
                                    backgroundColor: AppColors.border,
                                    color: _passwordStrengthColor,
                                    minHeight: 5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.p8),
                              Text(
                                _passwordStrengthLabel,
                                style: AppTextStyles.caption.copyWith(
                                  color: _passwordStrengthColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.p6),
                          _PasswordHints(password: _passwordCtrl.text),
                        ],

                        const SizedBox(height: AppSizes.p16),

                        // Confirm password
                        _FieldLabel(label: 'Confirm Password', required: true),
                        TextFormField(
                          controller: _confirmPasswordCtrl,
                          obscureText: !_showConfirmPassword,
                          textInputAction: TextInputAction.done,
                          style: AppTextStyles.bodyMedium,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: AppSizes.iconMd,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirmPassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: AppSizes.iconMd,
                                color: AppColors.textHint,
                              ),
                              onPressed: () => setState(
                                () => _showConfirmPassword =
                                    !_showConfirmPassword,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius12,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius12,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius12,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty)
                              return 'Please confirm the password';
                            if (val != _passwordCtrl.text)
                              return 'Passwords do not match';
                            return null;
                          },
                        ),
                      ],
                    ),

                  if (!_isEdit) const SizedBox(height: AppSizes.p16),

                  // ── Section 3: Role & Assignment ─────────────────────────
                  _SectionCard(
                    icon: Icons.manage_accounts_rounded,
                    title: 'Role & Assignment',
                    subtitle: 'Set permissions and team structure',
                    children: [
                      _FieldLabel(label: 'User Role', required: true),
                      // Role picker grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppSizes.p8,
                        crossAxisSpacing: AppSizes.p8,
                        childAspectRatio: 2.8,
                        children: _roles.map((r) {
                          final selected = _selectedRole == r['value'];
                          final color = r['color'] as Color;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedRole = r['value'] as String;
                              if (_selectedRole != 'STAFF') {
                                _selectedAgentId = null;
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: selected
                                    ? color.withOpacity(0.1)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radius12,
                                ),
                                border: Border.all(
                                  color: selected ? color : AppColors.border,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.p10,
                                vertical: AppSizes.p8,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    r['icon'] as IconData,
                                    size: 16,
                                    color: selected
                                        ? color
                                        : AppColors.textHint,
                                  ),
                                  const SizedBox(width: AppSizes.p6),
                                  Expanded(
                                    child: Text(
                                      r['label'] as String,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: selected
                                            ? color
                                            : AppColors.textSecondary,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (selected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: color,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Agent assignment for STAFF / FISH_BUYER
                      if (_selectedRole == 'STAFF') ...[
                        const SizedBox(height: AppSizes.p16),
                        _FieldLabel(
                          label: 'Linked Commission Agent',
                          required: true,
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedAgentId,
                          decoration: InputDecoration(
                            hintText: 'Select an agent',
                            prefixIcon: const Icon(
                              Icons.assignment_ind_outlined,
                              size: AppSizes.iconMd,
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius12,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius12,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius12,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          items: agents.isEmpty
                              ? [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('No agents available'),
                                  ),
                                ]
                              : agents
                                    .map(
                                      (a) => DropdownMenuItem(
                                        value: a.id,
                                        child: Text(a.name),
                                      ),
                                    )
                                    .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedAgentId = val),
                          validator: (val) => val == null
                              ? 'Please assign a commission agent'
                              : null,
                        ),
                        if (agents.isEmpty)
                          _InfoNote(
                            message:
                                'No commission agents found. Create one first.',
                          ),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppSizes.p16),

                  // ── Section 4: Location ───────────────────────────────────
                  _SectionCard(
                    icon: Icons.location_on_rounded,
                    title: 'Location',
                    subtitle: 'Assign primary and sub location',
                    children: [
                      _FieldLabel(label: 'Primary Location', required: true),
                      AppTextField(
                        label: '',
                        hint: 'e.g. Rameswaram Harbor',
                        controller: _locationCtrl,
                        prefixIcon: Icons.location_on_outlined,
                        textInputAction: TextInputAction.next,
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Primary location is required'
                            : null,
                      ),
                      const SizedBox(height: AppSizes.p16),
                      _FieldLabel(label: 'Sub-Location', required: true),
                      AppTextField(
                        label: '',
                        hint: 'e.g. Dock 3 / Zone B',
                        controller: _subLocationCtrl,
                        prefixIcon: Icons.place_outlined,
                        textInputAction: TextInputAction.done,
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Sub-location is required'
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.p24),

                  // ── Save button ───────────────────────────────────────────
                  AppButton(
                    text: _isEdit ? 'Save Changes' : 'Create User',
                    onPressed: _onSave,
                    leadingIcon: _isEdit
                        ? Icons.save_rounded
                        : Icons.person_add_rounded,
                  ),

                  const SizedBox(height: AppSizes.p32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable sub-widgets ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p16,
              vertical: AppSizes.p14,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radius16),
                topRight: Radius.circular(AppSizes.radius16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: AppSizes.p10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryDark.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p6),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.labelMedium),
          if (required)
            Text(
              ' *',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.error),
            ),
        ],
      ),
    );
  }
}

class _DuplicateWarning extends StatelessWidget {
  const _DuplicateWarning({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p6),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p8,
        ),
        decoration: BoxDecoration(
          color: AppColors.errorSurface,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSizes.p6),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p8),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 13,
            color: AppColors.info,
          ),
          const SizedBox(width: AppSizes.p6),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordHints extends StatelessWidget {
  const _PasswordHints({required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final checks = [
      {'label': '8+ characters', 'pass': password.length >= 8},
      {
        'label': 'Uppercase letter',
        'pass': RegExp(r'[A-Z]').hasMatch(password),
      },
      {'label': 'Number', 'pass': RegExp(r'[0-9]').hasMatch(password)},
      {
        'label': 'Special character',
        'pass': RegExp(r'[!@#\$&*~%^()_\-+=]').hasMatch(password),
      },
    ];

    return Wrap(
      spacing: AppSizes.p8,
      runSpacing: AppSizes.p4,
      children: checks.map((c) {
        final passed = c['pass'] as bool;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 12,
              color: passed ? AppColors.success : AppColors.textHint,
            ),
            const SizedBox(width: 4),
            Text(
              c['label'] as String,
              style: AppTextStyles.caption.copyWith(
                color: passed ? AppColors.success : AppColors.textHint,
                fontWeight: passed ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}