import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/haul_entity.dart';
import '../providers/haul_provider.dart';
import '../providers/voyage_provider.dart';

enum _TimelineFilter { all, operations, alerts, system }

class BoatOwnerVoyageLogbook extends ConsumerStatefulWidget {
  final String voyageId;
  final bool startOnTimeline; // true → open Event Timeline tab directly
  const BoatOwnerVoyageLogbook({
    super.key,
    required this.voyageId,
    this.startOnTimeline = false,
  });

  @override
  ConsumerState<BoatOwnerVoyageLogbook> createState() => _BoatOwnerVoyageLogbookState();
}

class _BoatOwnerVoyageLogbookState extends ConsumerState<BoatOwnerVoyageLogbook>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  _TimelineFilter _filter = _TimelineFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.startOnTimeline ? 1 : 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voyageProvider.notifier).loadVoyageById(widget.voyageId);
      ref.read(haulProvider.notifier).fetchHauls(voyageId: widget.voyageId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? "PM" : "AM"}';
  }

  String _fmtDate(DateTime dt) => DateFormat('dd MMM yyyy').format(dt);

  // Build a flat chronological list of events from hauls
  List<_LogEvent> _buildAllEvents(List<HaulEntity> hauls) {
    final events = <_LogEvent>[];
    final sorted = [...hauls]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    for (final h in sorted) {
      events.add(_LogEvent(
        time: h.startedAt,
        title: 'Haul #${h.haulNumber} Started',
        subtitle: '${h.gearType} | Net: ${h.netLength.toStringAsFixed(0)} m | Ground: ${h.fishingGround}',
        type: _TimelineFilter.operations,
      ));
      if (h.endedAt != null) {
        events.add(_LogEvent(
          time: h.endedAt!,
          title: 'Haul #${h.haulNumber} Completed',
          subtitle: 'Duration: ${(h.duration ?? 0)} min',
          type: _TimelineFilter.operations,
        ));
      }
    }
    events.sort((a, b) => a.time.compareTo(b.time));
    return events;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final voyage = ref.watch(voyageProvider).currentVoyage;
    final haulState = ref.watch(haulProvider);
    final allHauls = haulState.hauls;
    final allEvents = _buildAllEvents(allHauls);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Logbook', style: AppTextStyles.titleSmall.copyWith(color: Colors.white)),
            if (voyage != null)
              Text('${voyage.boatName ?? ''} | ${voyage.boatNumber ?? ''}',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/owner/voyages/${widget.voyageId}'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: '📅 Daily Log'),
            Tab(text: '📊 Event Timeline'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyLog(allEvents),
          _buildEventTimeline(allEvents),
        ],
      ),
    );
  }

  // ── Tab 1: Daily Log ───────────────────────────────────────────────────────

  Widget _buildDailyLog(List<_LogEvent> allEvents) {
    final dayEvents = allEvents.where((e) => _isSameDay(e.time, _selectedDate)).toList();

    return Column(
      children: [
        // Date picker row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                _fmtDate(_selectedDate),
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                icon: const Icon(Icons.edit_calendar, size: 16),
                label: const Text('Change'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: dayEvents.isEmpty
              ? _buildEmpty('No events recorded for ${_fmtDate(_selectedDate)}')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 0),
                  itemBuilder: (context, i) => _buildTimelineCard(dayEvents[i], i == dayEvents.length - 1),
                ),
        ),
      ],
    );
  }

  // ── Tab 2: Event Timeline ─────────────────────────────────────────────────

  Widget _buildEventTimeline(List<_LogEvent> allEvents) {
    final filtered = _filter == _TimelineFilter.all
        ? allEvents
        : allEvents.where((e) => e.type == _filter).toList();

    final opCount = allEvents.where((e) => e.type == _TimelineFilter.operations).length;
    final alertCount = allEvents.where((e) => e.type == _TimelineFilter.alerts).length;
    final sysCount = allEvents.where((e) => e.type == _TimelineFilter.system).length;

    return Column(
      children: [
        // Stats row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _filterChip('All', _TimelineFilter.all, allEvents.length),
              const SizedBox(width: 8),
              _filterChip('Ops', _TimelineFilter.operations, opCount),
              const SizedBox(width: 8),
              _filterChip('Alerts', _TimelineFilter.alerts, alertCount),
              const SizedBox(width: 8),
              _filterChip('System', _TimelineFilter.system, sysCount),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty('No events found')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 0),
                  itemBuilder: (context, i) => _buildTimelineCard(filtered[i], i == filtered.length - 1),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, _TimelineFilter f, int count) {
    final selected = _filter == f;
    return GestureDetector(
      onTap: () => setState(() => _filter = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label ($count)',
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineCard(_LogEvent event, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: AppColors.shadowBlue, blurRadius: 4)],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _fmtTime(event.time),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.title,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (event.subtitle != null && event.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.subtitle!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String msg) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_note_outlined,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(msg,
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

class _LogEvent {
  final DateTime time;
  final String title;
  final String? subtitle;
  final _TimelineFilter type;
  const _LogEvent({
    required this.time,
    required this.title,
    this.subtitle,
    this.type = _TimelineFilter.operations,
  });
}
