import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Dropdown customizado para formulários
class CustomDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final String? hint;
  final bool enabled;
  final Widget? prefixIcon;

  const CustomDropdown({
    Key? key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.hint,
    this.enabled = true,
    this.prefixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return DropdownButtonFormField<T>(
              value: value,
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item.value,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth - 32, // Considerando padding e ícone
                    ),
                    child: _extractTextFromWidget(item.child),
                  ),
                );
              }).toList(),
              onChanged: enabled ? onChanged : null,
              validator: validator,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: prefixIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.greyLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.greyLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.danger),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.danger, width: 2),
                ),
                filled: true,
                fillColor: enabled ? Colors.white : AppColors.light,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Extrai o texto de um widget, tratando diferentes tipos
  Widget _extractTextFromWidget(Widget widget) {
    if (widget is Text) {
      return Text(
        widget.data ?? '',
        style: widget.style,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    } else {
      // Para outros tipos de widget, tenta extrair o texto
      return Text(
        widget.toString().replaceAll(RegExp(r'^Text\("|", overflow: ellipsis\)$'), ''),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }
  }
}
