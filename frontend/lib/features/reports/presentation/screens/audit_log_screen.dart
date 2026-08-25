import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../providers/report_provider.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String _selectedAction = 'ALL';
  final _searchCtrl = TextEditingController();

  static const _actions = [
    'ALL', 'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'CHANGE_PASSWORD'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportProvider.notifier).loadAuditLogs();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportProvider);

    // Filter logs locally
    var logs = state.auditLogs;
    if (_selectedAction != 'ALL') {
      logs = logs.where((l) => l.action == _selectedAction).toList();
    }
    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      logs = logs.where((l) =>
          l.userName.toLowerCase().contains(q) ||
          l.resource.toLowerCase().contains(q) ||
          l.action.toLowerCase().contains(q)).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('Audit Logs',
            style: AppTextStyles.h4.copyWith(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(reportProvider.notifier).loadAuditLogs(),
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: state.isLoading,
        child: Column(
          children: [
            // ── Search bar ──────────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(AppSizes.p12),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by user, resource or action…',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textHint),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textSecondary),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p16, vertical: AppSizes.p12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ── Action filter chips ─────────────────────────────────────────
            Container(
              color: AppColors.surface,
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p12, vertical: AppSizes.p4),
                itemCount: _actions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSizes.p6),
                itemBuilder: (_, i) {
                  final action = _actions[i];
                  final isSelected = _selectedAction == action;
                  return FilterChip(
                    label: Text(action,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        )),
                    selected: isSelected,
                    selectedColor: _actionColor(action),
                    backgroundColor: AppColors.surfaceVariant,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onSelected: (_) {
                      setState(() => _selectedAction = action);
                      ref.read(reportProvider.notifier).loadAuditLogs(
                            action: action == 'ALL' ? null : action,
                          );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // ── Count banner ────────────────────────────────────────────────
            Container(
              color: AppColors.surfaceVariant,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p16, vertical: AppSizes.p6),
              child: Row(
                children: [
                  Text('${logs.length} entries',
                      style: AppTextStyles.caption),
                  const Spacer(),
                  Text(
                    'Tap to view details',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            // ── Log list ────────────────────────────────────────────────────
            Expanded(
              child: logs.isEmpty
                  ? _EmptyLogs()
                  : ListView.separated(
                      itemCount: logs.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 72),
                      itemBuilder: (_, i) => _AuditLogTile(log: logs[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _actionColor(String action) {
    return switch (action) {
      'CREATE' => AppColors.success,
      'UPDATE' => AppColors.info,
      'DELETE' => AppColors.error,
      'LOGIN' => AppColors.primary,
      'LOGOUT' => AppColors.secondary,
      'CHANGE_PASSWORD' => AppColors.warning,
      _ => AppColors.textSecondary,
    };
  }
}

// ─── Audit Log Tile ───────────────────────────────────────────────────────────

class _AuditLogTile extends StatelessWidget {
  final AuditLogEntry log;

  const _AuditLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final color = _actionColor(log.action);
    final fmt = DateFormat('d MMM yy, hh:mm a');

    return InkWell(
      onTap: () => _showDetail(context, log),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16, vertical: AppSizes.p12),
        child: Row(
          children: [
            // Action icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppSizes.radius12),
              ),
              child: Icon(_actionIcon(log.action), color: color, size: 20),
            ),
            const SizedBox(width: AppSizes.p12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(log.resource,
                            style: AppTextStyles.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: AppSizes.p8),
                      _ActionBadge(action: log.action, color: color),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${log.userName} • ${fmt.format(log.timestamp)}',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, AuditLogEntry log) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radius20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p16),
            Text('Audit Entry Details',
                style: AppTextStyles.h4),
            const SizedBox(height: AppSizes.p16),
            _DetailRow(label: 'Action', value: log.action),
            _DetailRow(label: 'User', value: log.userName),
            _DetailRow(label: 'Resource', value: log.resource),
            _DetailRow(
                label: 'Timestamp',
                value: DateFormat('d MMM yyyy, hh:mm:ss a')
                    .format(log.timestamp)),
            if (log.ipAddress != null)
              _DetailRow(label: 'IP Address', value: log.ipAddress!),
          ],
        ),
      ),
    );
  }

  Color _actionColor(String action) {
    return switch (action) {
      'CREATE' => AppColors.success,
      'UPDATE' => AppColors.info,
      'DELETE' => AppColors.error,
      'LOGIN' => AppColors.primary,
      'LOGOUT' => AppColors.secondary,
      'CHANGE_PASSWORD' => AppColors.warning,
      _ => AppColors.textSecondary,
    };
  }

  IconData _actionIcon(String action) {
    return switch (action) {
      'CREATE' => Icons.add_circle_outline,
      'UPDATE' => Icons.edit_outlined,
      'DELETE' => Icons.delete_outline,
      'LOGIN' => Icons.login,
      'LOGOUT' => Icons.logout,
      'CHANGE_PASSWORD' => Icons.lock_reset,
      _ => Icons.info_outline,
    };
  }
}

class _ActionBadge extends StatelessWidget {
  final String action;
  final Color color;

  const _ActionBadge({required this.action, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        action,
        style:
            AppTextStyles.overline.copyWith(color: color, letterSpacing: 0.5),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _EmptyLogs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, size: 64, color: AppColors.textHint),
          const SizedBox(height: AppSizes.p12),
          Text('No audit logs found',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSizes.p4),
          Text('Try changing the filter or date range',
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
