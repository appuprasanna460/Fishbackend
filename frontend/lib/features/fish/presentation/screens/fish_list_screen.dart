import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class FishListScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const FishListScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<FishListScreen> createState() => _FishListScreenState();
}

class _FishListScreenState extends ConsumerState<FishListScreen> {
  List<Map<String, dynamic>> _fishList = [];
  bool _isLoading = true;
  bool _showAddForm = false;

  // Add form controller
  final _nameCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFish());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
        'pricePerKg': 0,
        'category': 'GENERAL',
      };
      await dio.post(ApiConstants.fish, data: data);
      if (mounted) {
        AppErrorBanner.showSuccess(context, 'Fish added successfully');
        _nameCtrl.clear();
        setState(() => _showAddForm = false);
        await _loadFish();
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        AppErrorBanner.show(context, 'Failed to add fish: $errorMsg');
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
          final errorMsg = e.toString().replaceAll('Exception: ', '');
          AppErrorBanner.show(context, 'Failed to delete: $errorMsg');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authProvider).user;
    final isBuyer = user?.role == 'FISH_BUYER';
    final themeColor = isBuyer ? AppColors.roleBuyer : AppColors.primary;

    final body = Column(
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radius8),
                      ),
                      child: Icon(
                        Icons.set_meal,
                        color: themeColor,
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
              // ✅ REMOVE the extra Center wrapper - AppEmptyState already has Center
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
                      final id = fish['_id'] ?? '';
                      final createdBy = fish['createdBy'];
                      final isOwn =
                          createdBy != null && createdBy['_id'] == user?.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSizes.p8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radius12,
                          ),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.p16,
                            vertical: AppSizes.p8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(AppSizes.p8),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius8,
                              ),
                            ),
                            child: Icon(
                              Icons.set_meal,
                              color: themeColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            name,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: isBuyer && !isOwn
                              ? Text(
                                  'Global Fish',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textHint,
                                  ),
                                )
                              : null,
                          trailing: isBuyer && !isOwn
                              ? null // Can't delete global fish
                              : IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  onPressed: id.isNotEmpty
                                      ? () => _deleteFish(id, name)
                                      : null,
                                ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Scaffold(
        body: body,
        floatingActionButton: FloatingActionButton(
          onPressed: () => setState(() => _showAddForm = !_showAddForm),
          backgroundColor: AppColors.primary,
          child: Icon(_showAddForm ? Icons.close : Icons.add, color: Colors.white),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isBuyer ? 'My Fish List' : 'Fish Master Catalog'),
        actions: [
          IconButton(
            icon: Icon(_showAddForm ? Icons.close : Icons.add),
            onPressed: () => setState(() => _showAddForm = !_showAddForm),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFish),
        ],
      ),
      body: body,
    );
  }
}
