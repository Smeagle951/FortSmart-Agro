import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../models/tratamento_sementes_state.dart';
import '../services/tratamento_sementes_service.dart';

/// Widget para seção de dados básicos
class DadosBasicosSection extends StatelessWidget {
  final TratamentoSementesState state;
  final Function(TratamentoSementesState) onStateChanged;

  const DadosBasicosSection({
    Key? key,
    required this.state,
    required this.onStateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat("#,##0.00", "pt_BR");
    
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
              '📊 Dados Básicos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: FortSmartTheme.primaryColor,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            // Campos editáveis
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: state.pesoBagEditavel.toString(),
                    decoration: InputDecoration(
                      labelText: 'Peso do bag (kg)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
                      ),
                      prefixIcon: Icon(Icons.scale, color: FortSmartTheme.primaryColor),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) => TratamentoSementesService.validarPesoBag(double.tryParse(value ?? '')),
                    onChanged: (value) {
                      final newValue = double.tryParse(value);
                      if (newValue != null) {
                        onStateChanged(state.copyWith(pesoBagEditavel: newValue));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: state.numeroBagsEditavel.toString(),
                    decoration: InputDecoration(
                      labelText: 'Número de bags',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
                      ),
                      prefixIcon: Icon(Icons.inventory, color: FortSmartTheme.primaryColor),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => TratamentoSementesService.validarNumeroBags(int.tryParse(value ?? '')),
                    onChanged: (value) {
                      final newValue = int.tryParse(value);
                      if (newValue != null) {
                        onStateChanged(state.copyWith(numeroBagsEditavel: newValue));
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              initialValue: state.descricao,
              decoration: InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
                ),
                prefixIcon: Icon(Icons.description, color: FortSmartTheme.primaryColor),
              ),
              maxLines: 2,
              onChanged: (value) {
                onStateChanged(state.copyWith(descricao: value));
              },
            ),
            
            const SizedBox(height: 16),
            
            // Valores calculados
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FortSmartTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FortSmartTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Valores Calculados',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: FortSmartTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCalculoItem('Peso total das sementes', '${numberFormat.format(state.pesoTotalSementes)} kg'),
                  _buildCalculoItem('Hectares cobertos', '${numberFormat.format(state.hectaresCobertos)} ha'),
                  _buildCalculoItem('Kg por hectare', '${numberFormat.format(state.kgPorHectare)} kg/ha'),
                  _buildCalculoItem('Sementes por bag', '${numberFormat.format(state.sementesPorBag)} milhões'),
                  _buildCalculoItem('Germinação', '${state.germinacao.toStringAsFixed(1)}%'),
                  _buildCalculoItem('Vigor', '${state.vigor.toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCalculoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: FortSmartTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
