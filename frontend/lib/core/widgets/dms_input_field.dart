// lib/core/widgets/dms_input_field.dart
import 'package:flutter/material.dart';
import '../utils/dms_utils.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DmsInputField extends StatefulWidget {
  final String label;
  final String? initialValue;
  final bool isLatitude;
  final ValueChanged<double> onChanged;
  final ValueChanged<String>? onRawTextChanged;
  final String? errorText;
  final bool enabled;

  const DmsInputField({
    super.key,
    required this.label,
    this.initialValue,
    required this.isLatitude,
    required this.onChanged,
    this.onRawTextChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<DmsInputField> createState() => _DmsInputFieldState();
}

class _DmsInputFieldState extends State<DmsInputField> {
  final TextEditingController _controller = TextEditingController();
  bool _isValid = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
      _validateInput(widget.initialValue!);
    }
  }

  @override
  void didUpdateWidget(DmsInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != null) {
      _controller.text = widget.initialValue!;
      _validateInput(widget.initialValue!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateInput(String text) {
    if (text.isEmpty) {
      setState(() {
        _isValid = true;
        _errorText = null;
      });
      widget.onRawTextChanged?.call(text);
      return;
    }

    final isValid = DmsUtils.isValidDms(text, widget.isLatitude);
    setState(() {
      _isValid = isValid;
      _errorText = isValid ? null : 'Invalid format. Use: 12 56 45.64 N';
    });

    if (isValid) {
      try {
        final decimal = DmsUtils.dmsToDecimal(text);
        widget.onChanged(decimal);
      } catch (e) {
        // Ignore
      }
    }
    widget.onRawTextChanged?.call(text);
  }

  void _onFieldSubmitted(String text) {
    if (text.isNotEmpty && DmsUtils.isValidDms(text, widget.isLatitude)) {
      // Format the DMS for display
      final formatted = DmsUtils.formatDmsDisplay(text);
      _controller.text = formatted;
      _validateInput(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.labelMedium.copyWith(
            color: widget.enabled ? AppColors.textPrimary : AppColors.textHint,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _controller,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.isLatitude
                ? '12° 56\' 45.64" N'
                : '78° 52\' 25.57" E',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            errorText: widget.errorText ?? _errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _controller.clear();
                      _validateInput('');
                    },
                  )
                : null,
          ),
          onChanged: _validateInput,
          onFieldSubmitted: _onFieldSubmitted,
          style: AppTextStyles.bodyMedium,
        ),
        // Show decimal conversion preview
        if (_controller.text.isNotEmpty && _isValid)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Decimal: ${DmsUtils.dmsToDecimal(_controller.text).toStringAsFixed(6)}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint,
                fontSize: 11,
              ),
            ),
          ),
        // Show format hint
        if (_controller.text.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Format: Degrees Minutes Seconds Direction',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}