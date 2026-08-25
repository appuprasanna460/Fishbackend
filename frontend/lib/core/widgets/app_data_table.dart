import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_sizes.dart';

class AppDataTable<T> extends StatelessWidget {
  final List<AppDataColumn> columns;
  final List<T> rows;
  final List<DataCell> Function(T item, int index) cellBuilder;
  final void Function(T item)? onRowTap;
  final bool isLoading;
  final int skeletonRowCount;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.cellBuilder,
    this.onRowTap,
    this.isLoading = false,
    this.skeletonRowCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: isLoading
            ? _buildSkeleton()
            : DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.primarySurface),
                headingRowHeight: 52,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 72,
                horizontalMargin: AppSizes.p16,
                columnSpacing: AppSizes.p20,
                dividerThickness: 0.5,
                border: TableBorder(
                  horizontalInside: BorderSide(color: AppColors.divider, width: 0.5),
                ),
                columns: columns
                    .map((col) => DataColumn(
                          label: Text(
                            col.label,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          tooltip: col.tooltip,
                          numeric: col.numeric,
                        ))
                    .toList(),
                rows: List.generate(rows.length, (index) {
                  final item = rows[index];
                  return DataRow(
                    color: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return AppColors.primarySurface.withOpacity(0.5);
                      }
                      return index.isEven ? Colors.white : AppColors.surfaceVariant;
                    }),
                    onSelectChanged: onRowTap != null ? (_) => onRowTap!(item) : null,
                    cells: cellBuilder(item, index),
                  );
                }),
              ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(AppColors.primarySurface),
      headingRowHeight: 52,
      dataRowMinHeight: 56,
      horizontalMargin: AppSizes.p16,
      columnSpacing: AppSizes.p20,
      columns: columns
          .map((col) => DataColumn(
                label: Text(
                  col.label,
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                ),
              ))
          .toList(),
      rows: List.generate(
        skeletonRowCount,
        (i) => DataRow(
          cells: columns
              .map((_) => DataCell(_SkeletonCell(width: 60 + (i % 3) * 20.0)))
              .toList(),
        ),
      ),
    );
  }
}

class AppDataColumn {
  final String label;
  final String? tooltip;
  final bool numeric;

  const AppDataColumn(this.label, {this.tooltip, this.numeric = false});
}

class _SkeletonCell extends StatefulWidget {
  final double width;
  const _SkeletonCell({required this.width});

  @override
  State<_SkeletonCell> createState() => _SkeletonCellState();
}

class _SkeletonCellState extends State<_SkeletonCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.2, end: 0.6).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        width: widget.width,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(_a.value),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
