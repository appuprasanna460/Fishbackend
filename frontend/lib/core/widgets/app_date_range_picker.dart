import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_sizes.dart';

class AppDateRangePicker extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime start, DateTime end) onRangeSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const AppDateRangePicker({
    super.key,
    this.startDate,
    this.endDate,
    required this.onRangeSelected,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<AppDateRangePicker> createState() => _AppDateRangePickerState();
}

class _AppDateRangePickerState extends State<AppDateRangePicker> {
  DateTime? _start;
  DateTime? _end;
  final DateFormat _fmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _start = widget.startDate;
    _end = widget.endDate;
  }

  Future<void> _openPicker() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: widget.firstDate ?? DateTime(2020),
      lastDate: widget.lastDate ?? DateTime.now(),
      initialDateRange: (_start != null && _end != null)
          ? DateTimeRange(start: _start!, end: _end!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _start = result.start;
        _end = result.end;
      });
      widget.onRangeSelected(result.start, result.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRange = _start != null && _end != null;
    return GestureDetector(
      onTap: _openPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSizes.p8),
            Expanded(
              child: Text(
                hasRange
                    ? '${_fmt.format(_start!)}  →  ${_fmt.format(_end!)}'
                    : 'Select date range',
                style: hasRange
                    ? AppTextStyles.bodyMedium
                    : AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
              ),
            ),
            if (hasRange)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _start = null;
                    _end = null;
                  });
                },
                child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
