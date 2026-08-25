import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'notification_list_screen.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class HarbourItem {
  final String id;
  final String name;
  final bool isActive;

  const HarbourItem({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory HarbourItem.fromJson(Map<String, dynamic> json) => HarbourItem(
        id: json['_id'] as String,
        name: json['name'] as String,
        isActive: json['isActive'] as bool? ?? true,
      );
}

// ─── State ────────────────────────────────────────────────────────────────────

class _HarbourState {
  final List<HarbourItem> harbours;
  final bool isLoading;
  final String? error;

  const _HarbourState({
    this.harbours = const [],
    this.isLoading = false,
    this.error,
  });

  _HarbourState copyWith(
          {List<HarbourItem>? harbours,
          bool? isLoading,
          String? error,
          bool clearError = false}) =>
      _HarbourState(
        harbours: harbours ?? this.harbours,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

final _harbourMgmtProvider =
    StateNotifierProvider.autoDispose<_HarbourNotifier, _HarbourState>(
        (ref) => _HarbourNotifier(ref.read(dioClientProvider)));

class _HarbourNotifier extends StateNotifier<_HarbourState> {
  final DioClient _client;
  _HarbourNotifier(this._client) : super(const _HarbourState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _client.dio.get(ApiConstants.harbours);
      final data = res.data['data'] as List? ?? [];
      final list = data
          .map((e) => HarbourItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(harbours: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create(String name) async {
    try {
      await _client.dio.post(ApiConstants.harbours, data: {'name': name});
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> update(String id, String name, bool isActive) async {
    try {
      await _client.dio.put(
        '${ApiConstants.harbours}/$id',
        data: {'name': name, 'isActive': isActive},
      );
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _client.dio.delete('${ApiConstants.harbours}/$id');
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class HarbourManagementScreen extends ConsumerStatefulWidget {
  const HarbourManagementScreen({super.key});

  @override
  ConsumerState<HarbourManagementScreen> createState() =>
      _HarbourManagementScreenState();
}

class _HarbourManagementScreenState
    extends ConsumerState<HarbourManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_harbourMgmtProvider);
    final authState = ref.watch(authProvider);
    final adminName = authState.user?.name ?? 'Admin';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildAppDrawer(context, adminName),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppColors.primary,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Harbour',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Unified Top Header ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p16,
                vertical: AppSizes.p12,
              ),
              child: _buildUnifiedHeader(
                context: context,
                title: 'Harbour Management',
                adminName: adminName,
                scaffoldKey: _scaffoldKey,
                onRefresh: () => ref.read(_harbourMgmtProvider.notifier).load(),
              ),
            ),

            // Subtitle Banner Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.p16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.anchor_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Harbour Operations',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Manage registered harbour ports and locations',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p16),

            // Body content
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: AppColors.danger),
                              const SizedBox(height: 12),
                              Text(state.error!,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => ref
                                    .read(_harbourMgmtProvider.notifier)
                                    .load(),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : state.harbours.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.anchor_rounded,
                                      size: 56, color: AppColors.textSecondary),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No harbours yet',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the Add Harbour button to register your first harbour.',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.p16,
                              ),
                              itemCount: state.harbours.length,
                              itemBuilder: (ctx, i) {
                                final h = state.harbours[i];
                                return _HarbourCard(
                                  harbour: h,
                                  onTap: () => context.push(
                                    '/admin/harbours/${h.id}/users?name=${Uri.encodeComponent(h.name)}',
                                  ),
                                  onEdit: () => _showEditDialog(context, h),
                                  onToggle: () => ref
                                      .read(_harbourMgmtProvider.notifier)
                                      .update(h.id, h.name, !h.isActive),
                                  onDelete: () => _confirmDelete(context, h),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Unified Header Builder Helper ──────────────────────────────────────────

  Widget _buildUnifiedHeader({
    required BuildContext context,
    required String title,
    required String adminName,
    required GlobalKey<ScaffoldState> scaffoldKey,
    required VoidCallback onRefresh,
  }) {
    return Row(
      children: [
        // 3-line hamburger menu button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                scaffoldKey.currentState?.openDrawer();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                context.canPop() ? Icons.arrow_back_rounded : Icons.menu_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Left-aligned Title
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Refresh action
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onRefresh,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Notification Bell
        Consumer(
          builder: (context, ref, child) {
            final notifState = ref.watch(notificationListProvider);
            final count =
                notifState.items.where((i) => !i.isActioned).length;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/admin/notifications'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.border.withOpacity(0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 10),

        // Profile Avatar Button
        GestureDetector(
          onTap: () => context.push('/admin/profile'),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Side Drawer Builder Helper ──────────────────────────────────────────────

  Widget _buildAppDrawer(BuildContext context, String adminName) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              accountName: Text(
                adminName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text('Super Admin • Harbour Pro'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.dashboard_rounded, color: AppColors.primary),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.anchor_rounded),
              title: const Text('Harbours'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/harbours');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_rounded),
              title: const Text('Users'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/users');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_rounded),
              title: const Text('Packages'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/packages');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_rounded),
              title: const Text('Invoice Templates'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/invoice-templates');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_rounded),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/notifications');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _HarbourDialog(
        title: 'Add Harbour',
        controller: ctrl,
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );
    if (confirmed == true && ctrl.text.trim().isNotEmpty) {
      final ok = await ref
          .read(_harbourMgmtProvider.notifier)
          .create(ctrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              ok ? 'Harbour added successfully' : 'Failed to add harbour'),
          backgroundColor: ok ? Colors.green : AppColors.danger,
        ));
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context, HarbourItem h) async {
    final ctrl = TextEditingController(text: h.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _HarbourDialog(
        title: 'Edit Harbour',
        controller: ctrl,
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );
    if (confirmed == true && ctrl.text.trim().isNotEmpty) {
      final ok = await ref
          .read(_harbourMgmtProvider.notifier)
          .update(h.id, ctrl.text.trim(), h.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Harbour updated' : 'Failed to update harbour'),
          backgroundColor: ok ? Colors.green : AppColors.danger,
        ));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, HarbourItem h) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Harbour',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Delete "${h.name}"? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await ref.read(_harbourMgmtProvider.notifier).delete(h.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(ok ? 'Harbour deleted' : 'Failed to delete harbour'),
          backgroundColor: ok ? Colors.green : AppColors.danger,
        ));
      }
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _HarbourCard extends StatelessWidget {
  final HarbourItem harbour;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _HarbourCard({
    required this.harbour,
    this.onTap,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: harbour.isActive
                        ? AppColors.primarySurface
                        : const Color(0xFFF1F5F9),
                  ),
                  child: Icon(
                    Icons.anchor_rounded,
                    color: harbour.isActive ? AppColors.primary : Colors.grey,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        harbour.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: harbour.isActive
                              ? AppColors.successLight
                              : AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          harbour.isActive ? 'Active' : 'Inactive',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: harbour.isActive
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle
                IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    harbour.isActive
                        ? Icons.toggle_on_rounded
                        : Icons.toggle_off_rounded,
                    color: harbour.isActive ? AppColors.primary : Colors.grey,
                    size: 30,
                  ),
                  tooltip: harbour.isActive ? 'Deactivate' : 'Activate',
                ),
                // Edit
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded,
                      color: AppColors.primary, size: 20),
                ),
                // Delete
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_rounded,
                      color: AppColors.danger, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HarbourDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final VoidCallback onConfirm;

  const _HarbourDialog({
    required this.title,
    required this.controller,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Harbour Name',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.anchor_rounded),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text('Save',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
