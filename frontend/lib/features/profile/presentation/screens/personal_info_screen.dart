import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  bool _isEditing = false;
  
  // Controllers for editable fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyRelationshipController;
  late TextEditingController _emergencyPhoneController;
  
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _emergencyNameController = TextEditingController(text: user?.emergencyContactName ?? '');
    _emergencyRelationshipController = TextEditingController(text: user?.emergencyContactRelationship ?? '');
    _emergencyPhoneController = TextEditingController(text: user?.emergencyContactPhone ?? '');
    _selectedDate = user?.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationshipController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    if (_isEditing) {
      // Save all changes
      _saveAllChanges();
    } else {
      // Enter edit mode
      setState(() {
        _isEditing = true;
      });
    }
  }

  Future<void> _saveAllChanges() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final updates = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'emergencyContactName': _emergencyNameController.text.trim(),
      'emergencyContactRelationship': _emergencyRelationshipController.text.trim(),
      'emergencyContactPhone': _emergencyPhoneController.text.trim(),
    };

    if (_selectedDate != null) {
      updates['dateOfBirth'] = _selectedDate!.toIso8601String();
    }

    final success = await ref.read(authProvider.notifier).updateProfile(updates);
    
    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  void _cancelEditing() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    
    // Reset controllers to original values
    setState(() {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _emailController.text = user.email;
      _addressController.text = user.address ?? '';
      _emergencyNameController.text = user.emergencyContactName ?? '';
      _emergencyRelationshipController.text = user.emergencyContactRelationship ?? '';
      _emergencyPhoneController.text = user.emergencyContactPhone ?? '';
      _selectedDate = user.dateOfBirth;
      _isEditing = false;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('dd-MMM-yyyy').format(date);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Personal Information'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Edit/Save button
          IconButton(
            onPressed: _toggleEditing,
            icon: Icon(_isEditing ? Icons.save_outlined : Icons.edit_outlined),
          ),
          if (_isEditing)
            IconButton(
              onPressed: _cancelEditing,
              icon: const Icon(Icons.close_outlined),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          children: [
            _buildSection(
              title: 'PERSONAL DETAILS',
              children: [
                _buildEditableRow(
                  icon: Icons.person_outline,
                  label: 'Full Name',
                  controller: _nameController,
                  enabled: _isEditing,
                ),
                const Divider(),
                _buildEditableRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  controller: _phoneController,
                  enabled: _isEditing,
                  keyboardType: TextInputType.phone,
                ),
                const Divider(),
                _buildEditableRow(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  controller: _emailController,
                  enabled: _isEditing,
                  keyboardType: TextInputType.emailAddress,
                ),
                const Divider(),
                _buildDateRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date of Birth',
                  value: _formatDate(_selectedDate),
                  enabled: _isEditing,
                  onTap: _pickDate,
                ),
                const Divider(),
                _buildEditableRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  controller: _addressController,
                  enabled: _isEditing,
                  maxLines: 2,
                ),
                const Divider(),
                _buildEmergencyContactSection(enabled: _isEditing),
              ],
            ),
            const SizedBox(height: AppSizes.p32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
             
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEditableRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textHint, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                enabled
                    ? TextField(
                        controller: controller,
                        keyboardType: keyboardType,
                        maxLines: maxLines,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
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
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      )
                    : Text(
                        controller.text.isEmpty ? 'Not set' : controller.text,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                      ),
              ],
            ),
          ),
          if (!enabled)
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 16),
        ],
      ),
    );
  }

  Widget _buildDateRow({
    required IconData icon,
    required String label,
    required String value,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textHint, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: enabled ? onTap : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: enabled
                        ? BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    child: Text(
                      value,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: enabled ? AppColors.primary : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!enabled)
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 16),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactSection({required bool enabled}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency_outlined, color: AppColors.textHint, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Emergency Contact',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          enabled
              ? Column(
                  children: [
                    TextField(
                      controller: _emergencyNameController,
                      decoration: InputDecoration(
                        hintText: 'Contact Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emergencyRelationshipController,
                      decoration: InputDecoration(
                        hintText: 'Relationship (e.g. Wife)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emergencyPhoneController,
                      decoration: InputDecoration(
                        hintText: 'Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                )
              : Text(
                  _emergencyNameController.text.isEmpty
                      ? 'Not configured'
                      : '${_emergencyNameController.text} (${_emergencyRelationshipController.text.isEmpty ? "Relation" : _emergencyRelationshipController.text}) — ${_emergencyPhoneController.text}',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                ),
        ],
      ),
    );
  }
}