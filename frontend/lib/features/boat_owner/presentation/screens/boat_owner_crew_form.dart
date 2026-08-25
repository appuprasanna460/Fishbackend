import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../providers/crew_provider.dart';
import '../../domain/entities/crew_entity.dart';

class BoatOwnerCrewForm extends ConsumerStatefulWidget {
  final String? crewId;

  const BoatOwnerCrewForm({super.key, this.crewId});

  @override
  ConsumerState<BoatOwnerCrewForm> createState() => _BoatOwnerCrewFormState();
}

class _BoatOwnerCrewFormState extends ConsumerState<BoatOwnerCrewForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _expCtrl = TextEditingController(text: '0');
  final TextEditingController _notesCtrl = TextEditingController();

  String _role = 'CREW'; // CAPTAIN / CREW
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.crewId != null) {
      _loadCrewDetails();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _expCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCrewDetails() async {
    setState(() => _isLoading = true);
    final crew = ref.read(crewProvider).crewMembers.where((c) => c.id == widget.crewId).firstOrNull;
    setState(() => _isLoading = false);

    if (crew != null) {
      setState(() {
        _nameCtrl.text = crew.name;
        _ageCtrl.text = crew.age.toString();
        _phoneCtrl.text = crew.phone;
        _locationCtrl.text = crew.location;
        _role = crew.role;
        _expCtrl.text = (crew.experience ?? 0).toString();
        _notesCtrl.text = crew.notes ?? '';
      });
    } else {
      if (mounted) {
        AppErrorBanner.show(context, 'Failed to load crew details');
        context.pop();
      }
    }
  }

  Future<void> _saveCrew() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameCtrl.text.trim();
    final age = int.tryParse(_ageCtrl.text) ?? 0;
    final phone = _phoneCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final experience = int.tryParse(_expCtrl.text) ?? 0;
    final notes = _notesCtrl.text.trim();

    if (name.length < 2) {
      AppErrorBanner.show(context, 'Name must be at least 2 characters');
      return;
    }

    if (age < 18) {
      AppErrorBanner.show(context, 'Crew member must be at least 18 years old');
      return;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      AppErrorBanner.show(context, 'Phone number must be a valid 10-digit number');
      return;
    }

    if (location.length < 2) {
      AppErrorBanner.show(context, 'Location must be at least 2 characters');
      return;
    }

    setState(() => _isSaving = true);

    final crewObj = CrewEntity(
      id: widget.crewId,
      ownerId: '',
      name: name,
      age: age,
      phone: phone,
      location: location,
      role: _role,
      experience: experience,
      notes: notes,
    );

    bool success = false;
    try {
      if (widget.crewId != null) {
        await ref.read(crewProvider.notifier).updateCrew(widget.crewId!, crewObj);
      } else {
        await ref.read(crewProvider.notifier).createCrew(crewObj);
      }
      success = true;
    } catch (e) {
      success = false;
    }

    setState(() => _isSaving = false);

    if (success) {
      if (mounted) {
        AppErrorBanner.showSuccess(
          context,
          widget.crewId != null ? 'Crew updated successfully' : 'Crew member added successfully',
        );
        context.pop();
      }
    } else {
      if (mounted) {
        final error = ref.read(crewProvider).error ?? 'Failed to save crew member';
        AppErrorBanner.show(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.crewId != null;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Crew Member' : 'Add Crew Member'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.p16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Full Name *',
                      controller: _nameCtrl,
                      prefixIcon: Icons.person_outline,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.p16),
                    AppTextField(
                      label: 'Age *',
                      controller: _ageCtrl,
                      prefixIcon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Age is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.p16),
                    AppTextField(
                      label: 'Phone Number *',
                      controller: _phoneCtrl,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.p16),
                    AppTextField(
                      label: 'Location *',
                      controller: _locationCtrl,
                      prefixIcon: Icons.location_on_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Location is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.p16),

                    // Role Toggle
                    Text(
                      'Role *',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('CAPTAIN')),
                            selected: _role == 'CAPTAIN',
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: _role == 'CAPTAIN' ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _role = 'CAPTAIN');
                            },
                          ),
                        ),
                        const SizedBox(width: AppSizes.p12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('CREW')),
                            selected: _role == 'CREW',
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: _role == 'CREW' ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _role = 'CREW');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.p16),

                    AppTextField(
                      label: 'Experience (Years)',
                      controller: _expCtrl,
                      prefixIcon: Icons.star_border,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSizes.p16),
                    AppTextField(
                      label: 'Notes',
                      controller: _notesCtrl,
                      prefixIcon: Icons.notes,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.p12),
                  Expanded(
                    child: AppButton(
                      text: isEdit ? 'Update Crew' : 'Save Crew',
                      onPressed: _saveCrew,
                      isLoading: _isSaving,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p32),
            ],
          ),
        ),
      ),
    );
  }
}
