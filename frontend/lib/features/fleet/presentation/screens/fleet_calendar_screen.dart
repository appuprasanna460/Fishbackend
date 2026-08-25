import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../boat_owner/presentation/providers/voyage_provider.dart';

class FleetCalendarScreen extends ConsumerStatefulWidget {
  const FleetCalendarScreen({super.key});

  @override
  ConsumerState<FleetCalendarScreen> createState() => _FleetCalendarScreenState();
}

class _FleetCalendarScreenState extends ConsumerState<FleetCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(boatProvider.notifier).load(ownerId: user.id);
        ref.read(voyageProvider.notifier).loadVoyages();
      }
    });
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysBefore = first.weekday - 1;
    final firstToDisplay = first.subtract(Duration(days: daysBefore));

    return List.generate(42, (index) => firstToDisplay.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final voyageState = ref.watch(voyageProvider);
    final voyages = voyageState.voyages;
    final boatState = ref.watch(boatProvider);
    final boats = boatState.boats;

    final days = _getDaysInMonth(_currentMonth);
    final List<String> weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Filter voyages for selected date
    final selectedVoyages = voyages.where((v) {
      final dep = v.departureDate;
      return dep.year == _selectedDate.year &&
          dep.month == _selectedDate.month &&
          dep.day == _selectedDate.day;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Voyage Calendar'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Calendar Controller Header ──
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                    });
                  },
                ),
                Text(
                  _formatMonthYear(_currentMonth),
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),

          // ── Weekday Labels ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdays.map((w) {
                return SizedBox(
                  width: 32,
                  child: Text(
                    w,
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textHint),
                    textAlign: TextAlign.center,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // ── Calendar Days Grid ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected = day.year == _selectedDate.year &&
                    day.month == _selectedDate.month &&
                    day.day == _selectedDate.day;
                final isCurrentMonth = day.month == _currentMonth.month;

                // Check if this date has any voyages
                final hasVoyages = voyages.any((v) {
                  final dep = v.departureDate;
                  return dep.year == day.year && dep.month == day.month && dep.day == day.day;
                });

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = day;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primary 
                          : (hasVoyages ? AppColors.primary.withOpacity(0.08) : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected 
                          ? Border.all(color: AppColors.primary)
                          : (day.day == DateTime.now().day && day.month == DateTime.now().month && day.year == DateTime.now().year
                              ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5)
                              : null),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : (isCurrentMonth ? AppColors.textPrimary : AppColors.textHint),
                            ),
                          ),
                          if (hasVoyages && !isSelected)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 32),

          // ── Voyages List Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SCHEDULED VOYAGES',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  _formatSelectedDate(_selectedDate),
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Voyage List Cards ──
          Expanded(
            child: selectedVoyages.isEmpty
                ? const Center(child: Text('No voyages scheduled for this date.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                    itemCount: selectedVoyages.length,
                    itemBuilder: (context, index) {
                      final v = selectedVoyages[index];
                      final isPlanned = v.status == 'PLANNED';
                      final isActive = v.status == 'ACTIVE';

                      // Find boat name from boat list using boatId
                      final matchedBoat = boats.where((b) => b.id == v.boatId).toList();
                      final String displayBoatName = matchedBoat.isNotEmpty
                          ? matchedBoat.first.boatName
                          : (v.boatName ?? 'Unknown Boat');

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(AppSizes.p16),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                displayBoatName,
                                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.success.withOpacity(0.1)
                                      : (isPlanned ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  v.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? AppColors.success
                                        : (isPlanned ? Colors.blue : Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.arrow_forward_outlined, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text('${v.departureHarbourName ?? v.departureHarbour} → Deep Sea'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(v.departureTime),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => context.push('/owner/voyages/${v.id}'),
                        ),
                      );
                    },
                  ),
          ),

          // ── Schedule Button ──
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Schedule Voyage',
                leadingIcon: Icons.add,
                onPressed: () => context.push('/owner/voyages/new'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMonthYear(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatSelectedDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}