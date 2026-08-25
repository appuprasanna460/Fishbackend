import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../providers/voyage_provider.dart';
import '../providers/crew_provider.dart';

enum _CheckStatus { incomplete, pending, complete }

class _CheckItem {
  final String emoji;
  final String title;
  final String valueLabel; // e.g. "0 / 8" or "Pending"
  _CheckStatus status;

  _CheckItem({
    required this.emoji,
    required this.title,
    required this.valueLabel,
    this.status = _CheckStatus.incomplete,
  });
}

class BoatOwnerVoyageDepartureChecklist extends ConsumerStatefulWidget {
  final String voyageId;
  const BoatOwnerVoyageDepartureChecklist({super.key, required this.voyageId});

  @override
  ConsumerState<BoatOwnerVoyageDepartureChecklist> createState() =>
      _BoatOwnerVoyageDepartureChecklistState();
}

class _BoatOwnerVoyageDepartureChecklistState
    extends ConsumerState<BoatOwnerVoyageDepartureChecklist> {
  late List<_CheckItem> _items;
  bool _initialized = false;
  bool _loading = false;

  static const Map<String, String> _itemKeys = {
    'Crew On Board': 'crew',
    'Fuel Filled': 'fuel',
    'Ice Loaded': 'ice',
    'Fresh Water': 'water',
    'Rations & Supplies': 'rations',
    'Fishing Gear & Nets': 'gear',
    'Documents & Licenses': 'documents',
    'Safety Equipment': 'safety',
    'Communication Check': 'communication',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voyageProvider.notifier).loadVoyageById(widget.voyageId);
    });
  }

  void _buildItems() {
    final voyage = ref.read(voyageProvider).currentVoyage;
    if (voyage == null || _initialized) return;
    _initialized = true;

    final crewCount = voyage.crewMembers.length + 1; // crew + captain
    final totalCrew = crewCount; // all assigned
    final fuelReq = voyage.supplies.fuelRequired.toStringAsFixed(0);
    final iceReq = voyage.supplies.iceRequired.toStringAsFixed(0);
    final waterReq = voyage.supplies.water.toStringAsFixed(0);

    final savedChecklist = voyage.checklist ?? {};

    _CheckStatus getStatus(String title, _CheckStatus defaultStatus) {
      final key = _itemKeys[title];
      if (key != null && savedChecklist.containsKey(key)) {
        final statusStr = savedChecklist[key];
        if (statusStr == 'complete') return _CheckStatus.complete;
        if (statusStr == 'pending') return _CheckStatus.pending;
        if (statusStr == 'incomplete') return _CheckStatus.incomplete;
      }
      return defaultStatus;
    }

    _items = [
      _CheckItem(
        emoji: '👥',
        title: 'Crew On Board',
        valueLabel: '0 / $totalCrew',
        status: getStatus('Crew On Board', _CheckStatus.incomplete),
      ),
      _CheckItem(
        emoji: '⛽',
        title: 'Fuel Filled',
        valueLabel: '0 / $fuelReq Ltrs',
        status: getStatus('Fuel Filled', _CheckStatus.incomplete),
      ),
      _CheckItem(
        emoji: '🧊',
        title: 'Ice Loaded',
        valueLabel: '0 / $iceReq Kg',
        status: getStatus('Ice Loaded', _CheckStatus.incomplete),
      ),
      _CheckItem(
        emoji: '💧',
        title: 'Fresh Water',
        valueLabel: '0 / $waterReq Ltrs',
        status: getStatus('Fresh Water', _CheckStatus.incomplete),
      ),
      _CheckItem(
        emoji: '🍱',
        title: 'Rations & Supplies',
        valueLabel: 'Pending',
        status: getStatus('Rations & Supplies', _CheckStatus.pending),
      ),
      _CheckItem(
        emoji: '🎣',
        title: 'Fishing Gear & Nets',
        valueLabel: 'Pending',
        status: getStatus('Fishing Gear & Nets', _CheckStatus.pending),
      ),
      _CheckItem(
        emoji: '📄',
        title: 'Documents & Licenses',
        valueLabel: '0 / 5',
        status: getStatus('Documents & Licenses', _CheckStatus.incomplete),
      ),
      _CheckItem(
        emoji: '🛟',
        title: 'Safety Equipment',
        valueLabel: '0 / 6',
        status: getStatus('Safety Equipment', _CheckStatus.incomplete),
      ),
      _CheckItem(
        emoji: '📡',
        title: 'Communication Check',
        valueLabel: 'Pending',
        status: getStatus('Communication Check', _CheckStatus.pending),
      ),
    ];
  }

  void _toggleItem(int index) {
    setState(() {
      final current = _items[index].status;
      _items[index].status = current == _CheckStatus.complete
          ? _CheckStatus.incomplete
          : _CheckStatus.complete;
    });
  }

  void _markAllCompleted() {
    setState(() {
      for (final item in _items) {
        item.status = _CheckStatus.complete;
      }
    });
  }

  Future<void> _saveDraft() async {
    final voyage = ref.read(voyageProvider).currentVoyage;
    if (voyage == null) return;

    final Map<String, String> checklistMap = {};
    for (final item in _items) {
      final key = _itemKeys[item.title];
      if (key != null) {
        String statusStr = 'incomplete';
        if (item.status == _CheckStatus.complete) statusStr = 'complete';
        if (item.status == _CheckStatus.pending) statusStr = 'pending';
        checklistMap[key] = statusStr;
      }
    }

    setState(() => _loading = true);
    try {
      final api = ref.read(boatOwnerApiProvider);
      await api.saveChecklistDetails(widget.voyageId, {
        'boatId': voyage.boatId,
        'checklist': checklistMap,
      });
      
      // Reload voyage data to update provider state
      await ref.read(voyageProvider.notifier).loadVoyageById(widget.voyageId);

      if (mounted) {
        AppErrorBanner.showSuccess(context, 'Checklist draft saved successfully');
      }
    } catch (e) {
      if (mounted) {
        AppErrorBanner.show(context, 'Failed to save checklist draft: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final voyageState = ref.watch(voyageProvider);
    final voyage = voyageState.currentVoyage;

    if (voyageState.isLoading && voyage == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (voyage != null && !_initialized) {
      _buildItems();
    }

    final completed =
        _initialized ? _items.where((i) => i.status == _CheckStatus.complete).length : 0;
    final total = _initialized ? _items.length : 9;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Departure Checklist'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/owner/voyages/${widget.voyageId}'),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
         
          // ── Progress bar ──────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completed / $total Completed',
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${total > 0 ? ((completed / total) * 100).toInt() : 0}%',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? completed / total : 0,
                    backgroundColor: AppColors.border,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.success),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Checklist items ───────────────────────────────────────────────
          Expanded(
            child: _initialized
                ? ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 20, endIndent: 20),
                    itemBuilder: (context, i) => _buildCheckRow(i),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),

          // ── Action buttons ────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saveDraft,
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Save Draft'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Mark All Done',
                          onPressed: _markAllCompleted,
                          backgroundColor: AppColors.success,
                          leadingIcon: Icons.check_circle_outline,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckRow(int index) {
    final item = _items[index];
    Color dotColor;
    IconData dotIcon;
    switch (item.status) {
      case _CheckStatus.complete:
        dotColor = AppColors.success;
        dotIcon = Icons.check_circle;
        break;
      case _CheckStatus.pending:
        dotColor = AppColors.warning;
        dotIcon = Icons.radio_button_checked;
        break;
      case _CheckStatus.incomplete:
        dotColor = AppColors.error;
        dotIcon = Icons.cancel;
        break;
    }

    return InkWell(
      onTap: () => _toggleItem(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.valueLabel,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(dotIcon, color: dotColor, size: 22),
          ],
        ),
      ),
    );
  }
}
