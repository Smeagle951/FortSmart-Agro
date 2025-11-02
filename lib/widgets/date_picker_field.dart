import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatelessWidget {
  final String labelText;
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected;
  final bool allowNull;
  final String? Function(DateTime?)? validator;

  const DatePickerField({
    Key? key,
    required this.labelText,
    this.initialDate,
    required this.onDateSelected,
    this.allowNull = false,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final displayText = initialDate != null ? dateFormat.format(initialDate!) : 'Selecione uma data';

    return FormField<DateTime>(
      initialValue: initialDate,
      validator: validator,
      builder: (FormFieldState<DateTime> state) {
        return InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: initialDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            
            if (picked != null) {
              state.didChange(picked);
              onDateSelected(picked);
            } else if (allowNull && initialDate != null) {
              state.didChange(null);
              onDateSelected(DateTime(0));
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: labelText,
              errorText: state.hasError ? state.errorText : null,
              border: OutlineInputBorder(),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayText,
                  style: TextStyle(
                    color: initialDate == null ? Colors.grey[600] : Colors.black,
                  ),
                ),
                Icon(Icons.calendar_today),
              ],
            ),
          ),
        );
      },
    );
  }
}
