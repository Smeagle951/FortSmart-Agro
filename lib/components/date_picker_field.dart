import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? initialValue;
  final ValueChanged<DateTime> onChanged;
  final FormFieldValidator<String>? validator;
  final bool readOnly;
  final String? hintText;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerField({
    Key? key,
    required this.label,
    this.initialValue,
    required this.onChanged,
    this.validator,
    this.readOnly = false,
    this.hintText,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: initialValue != null
          ? DateFormat('dd/MM/yyyy').format(initialValue!)
          : '',
    );

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText ?? 'Selecione uma data',
        suffixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
      readOnly: true,
      validator: validator,
      onTap: readOnly
          ? null
          : () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initialValue ?? DateTime.now(),
                firstDate: firstDate ?? DateTime(2000),
                lastDate: lastDate ?? DateTime(2100),
              );
              if (picked != null) {
                controller.text = DateFormat('dd/MM/yyyy').format(picked);
                onChanged(picked);
              }
            },
    );
  }
}
