import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../models/calculo_sementes_state.dart';
import '../services/calculo_sementes_service.dart';

/// Widget para seção de área de plantio
class AreaPlantioSection extends StatelessWidget {
  final CalculoSementesState state;
  final Function(CalculoSementesState) onStateChanged;

  const AreaPlantioSection({
    Key? key,
    required this.state,
    required this.onStateChanged,
  }) : super(key: key);

  /// Formata números para exibição no padrão brasileiro
  String _formatNumber(double value, {bool showDecimals = true}) {
    if (showDecimals) {
      return NumberFormat("#,##0.00", "pt_BR").format(value);
    } else {
      return NumberFormat("#,##0", "pt_BR").format(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Área de Plantio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: FortSmartTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Usar área manual'),
                    value: state.usarAreaManual,
                    activeColor: FortSmartTheme.primaryColor,
                    onChanged: (value) {
                      onStateChanged(state.copyWith(usarAreaManual: value ?? false));
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _formatNumber(state.areaManual),
              decoration: InputDecoration(
                labelText: 'Área (hectares)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
                ),
                prefixIcon: Icon(Icons.area_chart, color: FortSmartTheme.primaryColor),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) => CalculoSementesService.validarAreaManual(double.tryParse(value ?? '')),
              onChanged: (value) {
                final newValue = double.tryParse(value);
                if (newValue != null) {
                  onStateChanged(state.copyWith(areaManual: newValue));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
