import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../../../users/domain/entities/user_entity.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).loadMyStaff();
    });
  }

  void _showStaffForm({UserEntity? staff}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StaffFormSheet(
        staff: staff,
        onSave: (data) async {
          final notifier = ref.read(userProvider.notifier);
          bool success = false;
          String? errorMessage;
          
          try {
            if (staff == null) {
              success = await notifier.createMyStaff(data);
            } else {
              success = await notifier.updateMyStaff(staff.id, data);
            }
            
            if (success && mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    staff == null
                        ? 'Staff created successfully'
                        : 'Staff updated successfully',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            } else if (mounted) {
              final state = ref.read(userProvider);
              errorMessage = state.error ?? 'Operation failed';
              // Throw the error to be caught by the form sheet
              throw Exception(errorMessage);
            }
          } catch (e) {
            // Re-throw to let the form sheet handle it
            rethrow;
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(UserEntity staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Are you sure you want to delete "${staff.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(userProvider.notifier)
          .deleteMyStaff(staff.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Staff deleted successfully' : 'Failed to delete staff',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userState = ref.watch(userProvider);
    final notifier = ref.read(userProvider.notifier);
    final myStaff = notifier.myStaff;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.roleStaff, Color(0xFF00897B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Staff Management',
              style: AppTextStyles.h4.copyWith(color: Colors.white),
            ),
            Text(
              '${myStaff.length} assigned staff',
              style: AppTextStyles.caption.copyWith(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => notifier.loadMyStaff(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStaffForm(),
        backgroundColor: AppColors.roleStaff,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Add Staff',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: AppLoadingOverlay(
        isLoading: userState.isLoading,
        child: RefreshIndicator(
          color: AppColors.roleStaff,
          onRefresh: () => notifier.loadMyStaff(),
          child: myStaff.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 120),
                    _EmptyStaffCard(
                      message: 'No staff members yet',
                      subtitle:
                          'Tap the button below to add your first staff member',
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.p16,
                    AppSizes.p16,
                    AppSizes.p16,
                    80,
                  ),
                  itemCount: myStaff.length,
                  itemBuilder: (context, index) {
                    final staff = myStaff[index];
                    return _StaffTile(
                      name: staff.name,
                      email: staff.email,
                      phone: staff.phone,
                      role: staff.role,
                      isActive: staff.isActive,
                      onEdit: () => _showStaffForm(staff: staff),
                      onDelete: () => _confirmDelete(staff),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

// ─── Staff Form Bottom Sheet ────────────────────────────────────────────────

class _StaffFormSheet extends ConsumerStatefulWidget {
  final UserEntity? staff;
  final Function(Map<String, dynamic> data) onSave;

  const _StaffFormSheet({this.staff, required this.onSave});

  @override
  ConsumerState<_StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends ConsumerState<_StaffFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passwordCtrl;
  bool _isSaving = false;
  bool _obscurePassword = true;
  
  // Email duplicate tracking - like in UserFormScreen
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.staff?.name ?? '');
    _emailCtrl = TextEditingController(text: widget.staff?.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.staff?.phone ?? '');
    _passwordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // Email duplicate check - like in UserFormScreen
  void _checkEmailDuplicate(String value) {
    if (value.trim().isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      setState(() => _emailError = null);
      return;
    }
    // Check with existing staff list
    final staffList = ref.read(userProvider.notifier).myStaff;
    final duplicate = staffList.any(
      (u) =>
          u.email.trim().toLowerCase() == value.trim().toLowerCase() &&
          (widget.staff != null ? u.id != widget.staff!.id : true),
    );
     setState(
       () => _emailError = duplicate ? 'This email is already registered' : null,
     );
  }

  Future<void> _submit() async {
    // Clear previous email error
    setState(() => _emailError = null);
    
    // Check duplicate first
    _checkEmailDuplicate(_emailCtrl.text);
    if (_emailError != null) return;
    
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    };

    // Only send password when creating or when explicitly changed
    if (widget.staff == null) {
      data['password'] = _passwordCtrl.text;
    } else if (_passwordCtrl.text.isNotEmpty) {
      data['password'] = _passwordCtrl.text;
    }

    try {
      await widget.onSave(data);
      // If successful, the form will close via the parent
    } catch (e) {
      // Catch any errors thrown from the parent
      if (mounted) {
        setState(() => _isSaving = false);
        
        final errorMessage = e.toString().toLowerCase();
        
        // Check for email-related errors
        if (errorMessage.contains('email') || 
            errorMessage.contains('duplicate') || 
            errorMessage.contains('already registered') ||
            errorMessage.contains('already exists')) {
          
          // setState(() {
          //   _emailError = 'This email is already registered';
          // });
        } else {
          // Show other errors in a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.staff != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p20),

              // Title
              Text(
                isEditing ? 'Edit Staff' : 'Add New Staff',
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSizes.p24),

              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSizes.p16),

              // Email with duplicate check - like in UserFormScreen
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                  errorText: _emailError, // Show email-specific error
                  errorMaxLines: 2,
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: _checkEmailDuplicate, // Check on change
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return _emailError; // Return the duplicate error
                },
              ),
              // Show duplicate warning below email field - like in UserFormScreen
              

              const SizedBox(height: AppSizes.p16),

              // Phone
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (v) {
                  if (v != null &&
                      v.trim().isNotEmpty &&
                      v.trim().length != 10) {
                    return 'Phone must be 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.p8),

              // Password (required for create, optional for edit)
              TextFormField(
                controller: _passwordCtrl,
                decoration: InputDecoration(
                  labelText: isEditing
                      ? 'New Password (leave blank to keep current)'
                      : 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  helperText: 'Min 8 chars, 1 uppercase, 1 lowercase, 1 number',
                  helperMaxLines: 2,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (v) {
                  if (!isEditing && (v == null || v.trim().isEmpty)) {
                    return 'Password is required';
                  }
                  if (v != null && v.trim().isNotEmpty) {
                    if (v.trim().length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(v)) {
                      return 'Must contain at least one uppercase letter';
                    }
                    if (!RegExp(r'[a-z]').hasMatch(v)) {
                      return 'Must contain at least one lowercase letter';
                    }
                    if (!RegExp(r'[0-9]').hasMatch(v)) {
                      return 'Must contain at least one number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.p24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roleStaff,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditing ? 'Update Staff' : 'Create Staff',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSizes.p16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Staff Tile ──────────────────────────────────────────────────────────────

class _StaffTile extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isActive;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _StaffTile({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.roleStaff.withOpacity(0.1)
                  : AppColors.textHint.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radius8),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTextStyles.h4.copyWith(
                  color: isActive ? AppColors.roleStaff : AppColors.textHint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          // Status
          AppStatusBadge.fromString(isActive ? 'ACTIVE' : 'INACTIVE'),
          const SizedBox(width: AppSizes.p8),
          // Edit button
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.roleStaff,
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          // Delete button
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.error,
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}

// ─── Empty Staff Card ────────────────────────────────────────────────────────

class _EmptyStaffCard extends StatelessWidget {
  final String message;
  final String subtitle;

  const _EmptyStaffCard({
    required this.message,
    this.subtitle = 'Staff members assigned to you will appear here',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      padding: const EdgeInsets.all(AppSizes.p32),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 56,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: AppSizes.p12),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}