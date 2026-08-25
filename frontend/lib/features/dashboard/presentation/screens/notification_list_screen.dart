import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../subscription_plan/presentation/providers/subscription_provider.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class RegistrationNotification {
  final String id;
  final String message;
  final bool isRead;
  final bool isActioned;
  final DateTime createdAt;
  final _NotifUser? user;

  const RegistrationNotification({
    required this.id,
    required this.message,
    required this.isRead,
    required this.isActioned,
    required this.createdAt,
    this.user,
  });

  factory RegistrationNotification.fromJson(Map<String, dynamic> json) {
    final rawUser = json['userId'];
    _NotifUser? user;
    if (rawUser is Map<String, dynamic>) {
      user = _NotifUser.fromJson(rawUser);
    }
    return RegistrationNotification(
      id: json['_id'] as String,
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      isActioned: json['isActioned'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      user: user,
    );
  }
}

class _NotifUser {
  final String? name;
  final String? email;
  final String? phone;
  final String? companyName;
  final String? referenceBy;
  final String? subscriptionPlan;
  final String? role;
  final String? harbourName;
  // Populated plan details from subscriptionPlanId (new dynamic plans)
  final String? planName;
  final int? planDurationDays;
  final double? planPrice;

  const _NotifUser({
    this.name,
    this.email,
    this.phone,
    this.companyName,
    this.referenceBy,
    this.subscriptionPlan,
    this.role,
    this.harbourName,
    this.planName,
    this.planDurationDays,
    this.planPrice,
  });

  factory _NotifUser.fromJson(Map<String, dynamic> json) {
    String? harbourName;
    final h = json['harbourId'];
    if (h is Map<String, dynamic>) {
      harbourName = h['name'] as String?;
    }

    // Populated subscriptionPlanId object (new dynamic plan reference)
    String? planName;
    int? planDurationDays;
    double? planPrice;
    final p = json['subscriptionPlanId'];
    if (p is Map<String, dynamic>) {
      planName = p['name']?.toString();
      planDurationDays = p['durationDays'] is num
          ? (p['durationDays'] as num).toInt()
          : null;
      planPrice = p['price'] is num ? (p['price'] as num).toDouble() : null;
    }

    return _NotifUser(
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      companyName: json['companyName'] as String?,
      referenceBy: json['referenceBy'] as String?,
      subscriptionPlan: json['subscriptionPlan'] as String?,
      role: json['role'] as String?,
      harbourName: harbourName,
      planName: planName,
      planDurationDays: planDurationDays,
      planPrice: planPrice,
    );
  }
}

// ─── State ────────────────────────────────────────────────────────────────────

class _NotifState {
  final List<RegistrationNotification> items;
  final bool isLoading;
  final String? error;

  const _NotifState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  _NotifState copyWith(
          {List<RegistrationNotification>? items,
          bool? isLoading,
          String? error,
          bool clearError = false}) =>
      _NotifState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

final notificationListProvider =
    StateNotifierProvider.autoDispose<_NotifNotifier, _NotifState>(
        (ref) => _NotifNotifier(ref.read(dioClientProvider)));

class _NotifNotifier extends StateNotifier<_NotifState> {
  final DioClient _client;
  _NotifNotifier(this._client) : super(const _NotifState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _client.dio.get(ApiConstants.notifications);
      final data = res.data['data'] as List? ?? [];
      final list = data
          .map((e) =>
              RegistrationNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(items: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> approve(String notifId) async {
    try {
      await _client.dio.post(
          ApiConstants.approveRegistration.replaceAll('{id}', notifId));
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reject(String notifId) async {
    try {
      await _client.dio.post(
          ApiConstants.rejectRegistration.replaceAll('{id}', notifId));
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load renewal requests on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionProvider.notifier).loadRenewalRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListProvider);
    final subState = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Admin Notifications',
          style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              ref.read(notificationListProvider.notifier).load();
              ref.read(subscriptionProvider.notifier).loadRenewalRequests();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Registrations',
                      style: GoogleFonts.inter(fontSize: 13)),
                  if (state.items.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.items.length}',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Renewals', style: GoogleFonts.inter(fontSize: 13)),
                  if (subState.renewalRequests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${subState.renewalRequests.length}',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 0: Registrations ──────────────────────────────────────
          _buildRegistrationsTab(context, state),
          // ── Tab 1: Renewals ───────────────────────────────────────────
          _buildRenewalsTab(context, subState),
        ],
      ),
    );
  }

  Widget _buildRegistrationsTab(BuildContext context, _NotifState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text('Error loading notifications',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(notificationListProvider.notifier).load(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_rounded,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('No pending registrations',
                style: GoogleFonts.inter(
                    fontSize: 16, color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length,
      itemBuilder: (ctx, i) {
        final n = state.items[i];
        return _NotifCard(
          notification: n,
          onApprove: () async {
            final ok = await ref
                .read(notificationListProvider.notifier)
                .approve(n.id);
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(
                    ok ? '✅ User approved successfully' : '❌ Failed to approve'),
                backgroundColor: ok ? Colors.green : AppColors.danger,
              ));
            }
          },
          onReject: () async {
            final confirmed = await showDialog<bool>(
              context: ctx,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text('Reject Registration',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                content: Text(
                  'This will delete the user account permanently. Are you sure?',
                  style: GoogleFonts.inter(),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Reject',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              final ok = await ref
                  .read(notificationListProvider.notifier)
                  .reject(n.id);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'Registration rejected'
                      : '❌ Failed to reject'),
                  backgroundColor:
                      ok ? Colors.orange : AppColors.danger,
                ));
              }
            }
          },
        );
      },
    );
  }

  Widget _buildRenewalsTab(BuildContext context, SubscriptionState subState) {
    if (subState.isLoading && subState.renewalRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (subState.renewalRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh_rounded,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('No pending renewal requests',
                style: GoogleFonts.inter(
                    fontSize: 16, color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subState.renewalRequests.length,
      itemBuilder: (ctx, i) {
        final r = subState.renewalRequests[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
            border: Border.all(
              color: r.isPending
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.card_membership_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.userName ?? 'Unknown User',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: r.isPending
                          ? Colors.orange.shade50
                          : r.isApproved
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: r.isPending
                            ? Colors.orange
                            : r.isApproved
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),
                    child: Text(
                      r.status,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: r.isPending
                            ? Colors.orange.shade700
                            : r.isApproved
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (r.userEmail != null)
                _RenewalInfoRow(Icons.email_outlined, r.userEmail!),
              _RenewalInfoRow(
                Icons.card_membership_rounded,
                '${r.requestedPlanName} — ${r.requestedDurationDays} days',
              ),
              _RenewalInfoRow(
                Icons.calendar_today_outlined,
                'Requested: ${_fmtDate(r.requestedAt)}',
              ),
              if (r.isPending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final ok = await ref
                              .read(subscriptionProvider.notifier)
                              .approveRenewal(r.id);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text(ok
                                  ? '✅ Renewal approved!'
                                  : '❌ Failed to approve'),
                              backgroundColor:
                                  ok ? Colors.green : Colors.red,
                            ));
                          }
                        },
                        icon: const Icon(Icons.check_circle_rounded,
                            size: 16),
                        label: Text('Approve',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          side: BorderSide(
                              color: Colors.green.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final reasonCtrl = TextEditingController();
                          final confirmed = await showDialog<bool>(
                            context: ctx,
                            builder: (_) => AlertDialog(
                              title: Text('Reject Renewal',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold)),
                              content: TextField(
                                controller: reasonCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Reason (optional)',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Reject',
                                        style: TextStyle(
                                            color: Colors.white))),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            final ok = await ref
                                .read(subscriptionProvider.notifier)
                                .rejectRenewal(r.id,
                                    reason: reasonCtrl.text.trim());
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? 'Renewal rejected'
                                      : '❌ Failed to reject'),
                                  backgroundColor: ok
                                      ? Colors.orange
                                      : Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.cancel_rounded, size: 16),
                        label: Text('Reject',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(
                              color: Colors.red.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _RenewalInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RenewalInfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}


// ─── Notification Card ────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final RegistrationNotification notification;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _NotifCard({
    required this.notification,
    required this.onApprove,
    required this.onReject,
  });

  String _planLabel(_NotifUser? u) {
    // New dynamic plan (populated from subscriptionPlanId)
    if (u?.planName != null) {
      final days = u!.planDurationDays;
      final price = u.planPrice;
      final parts = <String>[u.planName!];
      if (days != null) parts.add('$days days');
      if (price != null) parts.add('₹${price.toStringAsFixed(0)}');
      return parts.join(' • ');
    }
    // Legacy enum plan
    switch (u?.subscriptionPlan) {
      case 'QUARTERLY':
        return 'Quarterly (₹300)';
      case 'HALF_YEARLY':
        return 'Half-Yearly (₹500)';
      case 'YEARLY':
        return 'Yearly (₹1000)';
      default:
        return u?.subscriptionPlan ?? 'None';
    }
  }

  String _roleLabel(String? role) {
    if (role == null) return 'Unknown';
    return role
        .split('_')
        .map((w) => w.isNotEmpty
            ? w[0].toUpperCase() + w.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final u = notification.user;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.08),
                  AppColors.primary.withOpacity(0.02),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      (u?.name?.isNotEmpty == true)
                          ? u!.name![0].toUpperCase()
                          : '?',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u?.name ?? 'Unknown User',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        u?.email ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'PENDING',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _InfoRow(
                    icon: Icons.business_outlined,
                    label: 'Company',
                    value: u?.companyName ?? '-'),
                _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: u?.phone ?? '-'),
                _InfoRow(
                    icon: Icons.shield_outlined,
                    label: 'Role',
                    value: _roleLabel(u?.role)),
                _InfoRow(
                    icon: Icons.anchor_rounded,
                    label: 'Harbour',
                    value: u?.harbourName ?? '-'),
                _InfoRow(
                    icon: Icons.credit_card_rounded,
                    label: 'Plan',
                    value: _planLabel(u)),
                if (u?.referenceBy?.isNotEmpty == true)
                  _InfoRow(
                      icon: Icons.people_outline_rounded,
                      label: 'Referred By',
                      value: u!.referenceBy!),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text('Reject',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16),
                    label: Text('Approve',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
