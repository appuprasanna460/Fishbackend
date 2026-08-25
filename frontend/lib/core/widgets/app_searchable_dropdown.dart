import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_sizes.dart';

class AppSearchableDropdown<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final bool isLoading;
  final String? hint;
  final IconData? prefixIcon;

  const AppSearchableDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.validator,
    this.isLoading = false,
    this.hint,
    this.prefixIcon,
  });

  @override
  State<AppSearchableDropdown<T>> createState() =>
      _AppSearchableDropdownState<T>();
}

class _AppSearchableDropdownState<T> extends State<AppSearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  List<T> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
      setState(() {});
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            shadowColor: AppColors.shadow,
            borderRadius: BorderRadius.circular(AppSizes.radius12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radius12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.p8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (q) {
                        setState(() {
                          _filtered = widget.items
                              .where((i) => widget
                                  .itemLabel(i)
                                  .toLowerCase()
                                  .contains(q.toLowerCase()))
                              .toList();
                        });
                        _overlayEntry?.markNeedsBuild();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p12,
                          vertical: AppSizes.p8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius8),
                          borderSide: BorderSide.none,
                        ),
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                      ),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final item = _filtered[i];
                        final isSelected = widget.value == item;
                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          selectedTileColor: AppColors.primarySurface,
                          title: Text(
                            widget.itemLabel(item),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check, size: 16, color: AppColors.primary)
                              : null,
                          onTap: () {
                            widget.onChanged(item);
                            _searchController.clear();
                            _filtered = widget.items;
                            _removeOverlay();
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: FormField<T>(
        validator: widget.validator,
        initialValue: widget.value,
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.isLoading ? null : _toggleDropdown,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p16,
                  vertical: AppSizes.p16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                  border: Border.all(
                    color: field.hasError
                        ? AppColors.error
                        : _isOpen
                            ? AppColors.primary
                            : AppColors.border,
                    width: _isOpen ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (widget.prefixIcon != null) ...[
                      Icon(widget.prefixIcon, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: AppSizes.p8),
                    ],
                    Expanded(
                      child: widget.isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.value != null
                                  ? widget.itemLabel(widget.value as T)
                                  : (widget.hint ?? widget.label),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: widget.value != null
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                              ),
                            ),
                    ),
                    AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(left: AppSizes.p12, top: AppSizes.p4),
                child: Text(
                  field.errorText!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
