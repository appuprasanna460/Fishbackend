import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FishBuyerFishListScreen extends ConsumerStatefulWidget {
  const FishBuyerFishListScreen({super.key});

  @override
  ConsumerState<FishBuyerFishListScreen> createState() =>
      _FishBuyerFishListScreenState();
}

class _FishBuyerFishListScreenState
    extends ConsumerState<FishBuyerFishListScreen> {
  List<Map<String, dynamic>> _fishList = [];
  bool _isLoading = true;
  bool _showAddForm = false;

  // Add form controllers
  final _nameCtrl = TextEditingController();
  final _localNameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFish());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _localNameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFish() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(ApiConstants.fish);
      final list = res.data['data'] ?? res.data ?? [];
      setState(() {
        _fishList = list is List
            ? list.map((e) => e as Map<String, dynamic>).toList()
            : [];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading fish: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addFish() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppErrorBanner.show(context, 'Fish name is required');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final data = {
        'name': _nameCtrl.text.trim(),
        if (_localNameCtrl.text.isNotEmpty)
          'localName': _localNameCtrl.text.trim(),
        if (_categoryCtrl.text.isNotEmpty)
          'category': _categoryCtrl.text.trim(),
        'pricePerKg': double.tryParse(_priceCtrl.text) ?? 0,
      };
      await dio.post(ApiConstants.fish, data: data);
      if (mounted) {
        AppErrorBanner.showSuccess(context, 'Fish added successfully');
        _nameCtrl.clear();
        _localNameCtrl.clear();
        _categoryCtrl.clear();
        _priceCtrl.clear();
        setState(() => _showAddForm = false);
        await _loadFish();
      }
    } catch (e) {
      if (mounted) {
        AppErrorBanner.show(context, 'Failed to add fish: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteFish(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Fish'),
        content: Text('Delete "$name" from your fish list?'),
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
    if (confirm == true) {
      try {
        final dio = ref.read(dioClientProvider).dio;
        await dio.delete('${ApiConstants.fish}/$id');
        if (mounted) {
          AppErrorBanner.showSuccess(context, 'Fish deleted');
          await _loadFish();
        }
      } catch (e) {
        if (mounted) {
          AppErrorBanner.show(context, 'Failed to delete');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Fish List'),
        actions: [
          IconButton(
            icon: Icon(_showAddForm ? Icons.close : Icons.add),
            onPressed: () => setState(() => _showAddForm = !_showAddForm),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFish),
        ],
      ),
      body: Column(
        children: [
          // Add Fish Form
          if (_showAddForm)
            Container(
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.roleBuyer.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radius8),
                        ),
                        child: Icon(
                          Icons.set_meal,
                          color: AppColors.roleBuyer,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSizes.p8),
                      Text(
                        'Add New Fish',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p12),
                  AppTextField(
                    label: 'Fish Name *',
                    controller: _nameCtrl,
                    prefixIcon: Icons.set_meal,
                  ),
                  const SizedBox(height: AppSizes.p8),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Local Name',
                          controller: _localNameCtrl,
                          prefixIcon: Icons.translate,
                        ),
                      ),
                      const SizedBox(width: AppSizes.p8),
                      Expanded(
                        child: AppTextField(
                          label: 'Category',
                          controller: _categoryCtrl,
                          prefixIcon: Icons.category,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p8),
                  AppTextField(
                    label: 'Price per KG (₹)',
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.currency_rupee,
                  ),
                  const SizedBox(height: AppSizes.p12),
                  AppButton(
                    text: 'Add Fish',
                    onPressed: _addFish,
                    isLoading: _isSubmitting,
                    leadingIcon: Icons.check,
                  ),
                ],
              ),
            ),

          // Fish List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _fishList.isEmpty
                ? const AppEmptyState(
                    title: 'No Fish Added',
                    subtitle:
                        'Add fish varieties to create your own fish list.',
                    icon: Icons.set_meal_outlined,
                  )
                : RefreshIndicator(
                    onRefresh: _loadFish,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.p16),
                      itemCount: _fishList.length,
                      itemBuilder: (_, i) {
                        final fish = _fishList[i];
                        final name = fish['name'] ?? '';
                        final localName = fish['localName'] as String?;
                        final category = fish['category'] as String?;
                        final price = (fish['pricePerKg'] ?? 0).toDouble();

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSizes.p12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radius12,
                            ),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.roleBuyer.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(AppSizes.p12),
                            leading: Container(
                              padding: const EdgeInsets.all(AppSizes.p10),
                              decoration: BoxDecoration(
                                color: AppColors.roleBuyer.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radius12,
                                ),
                              ),
                              child: const Icon(
                                Icons.set_meal,
                                color: AppColors.roleBuyer,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              name,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (localName != null && localName.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Local: $localName',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                if (category != null && category.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 1),
                                    child: Text(
                                      'Category: $category',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                if (price > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '₹${price.toStringAsFixed(2)}/KG',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.roleBuyer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                              ),
                              onPressed: () =>
                                  _deleteFish(fish['_id'] ?? '', name),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
