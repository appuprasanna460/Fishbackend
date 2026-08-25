import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../providers/fish_provider.dart';

class FishFormScreen extends ConsumerStatefulWidget {
  final String? fishId;
  const FishFormScreen({super.key, this.fishId});

  @override
  ConsumerState<FishFormScreen> createState() => _FishFormScreenState();
}

class _FishFormScreenState extends ConsumerState<FishFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _localNameController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = 'Marine';
  bool _isEdit = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'Freshwater',
    'Marine',
    'Shellfish',
    'Cephalopod',
    'Dried',
    'Frozen'
  ];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.fishId != null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isEdit) {
        setState(() => _isLoading = true);
        await ref.read(fishProvider.notifier).load();
        final list = ref.read(fishProvider).fish;
        final current = list.cast<dynamic>().firstWhere((f) => f.id == widget.fishId, orElse: () => null);
        if (current != null) {
          _nameController.text = current.name;
          _localNameController.text = current.localName ?? '';
          _descController.text = current.description ?? '';
          if (_categories.contains(current.category)) {
            _selectedCategory = current.category!;
          }
        }
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _localNameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text,
      'localName': _localNameController.text,
      'category': _selectedCategory,
      'description': _descController.text,
      'isActive': true,
    };

    setState(() => _isLoading = true);
    bool ok;
    if (_isEdit) {
      ok = await ref.read(fishProvider.notifier).updateFish(widget.fishId!, data);
    } else {
      ok = await ref.read(fishProvider.notifier).createFish(data);
    }
    setState(() => _isLoading = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fish ${_isEdit ? 'updated' : 'added'} successfully')),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operation failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Fish Details' : 'Add New Fish Type'),
      ),
      body: AppLoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fish Master Definition',
                  style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSizes.p16),
                AppTextField(
                  label: 'Common Name (English)',
                  controller: _nameController,
                  prefixIcon: Icons.set_meal,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: AppSizes.p16),
                AppTextField(
                  label: 'Local Name (Regional Language)',
                  controller: _localNameController,
                  prefixIcon: Icons.translate,
                ),
                const SizedBox(height: AppSizes.p16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Classification Category',
                    prefixIcon: const Icon(Icons.category_outlined, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                    ),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: AppSizes.p16),
                AppTextField(
                  label: 'Description / Notes',
                  controller: _descController,
                  maxLines: 3,
                  prefixIcon: Icons.description_outlined,
                ),
                const SizedBox(height: AppSizes.p32),
                AppButton(
                  text: _isEdit ? 'Save Fish Details' : 'Register Fish Variety',
                  onPressed: _onSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
