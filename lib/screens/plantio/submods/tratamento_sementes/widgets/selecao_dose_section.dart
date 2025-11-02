import 'package:flutter/material.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../../../../../modules/tratamento_sementes/models/dose_ts_model.dart';
import '../models/tratamento_sementes_state.dart';

/// Widget para seção de seleção de dose
class SelecaoDoseSection extends StatelessWidget {
  final TratamentoSementesState state;
  final Function(TratamentoSementesState) onStateChanged;

  const SelecaoDoseSection({
    Key? key,
    required this.state,
    required this.onStateChanged,
  }) : super(key: key);

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
              '🧪 Seleção de Dose',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: FortSmartTheme.primaryColor,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<DoseTS>(
                value: state.doseSelecionada,
                decoration: InputDecoration(
                  labelText: 'Dose de tratamento',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.science, color: FortSmartTheme.primaryColor),
                ),
                items: state.dosesDisponiveis.map((dose) {
                  return DropdownMenuItem<DoseTS>(
                    value: dose,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dose.nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Cultura: ${dose.nomeCultura} • v${dose.versao}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (dose) {
                  onStateChanged(state.copyWith(doseSelecionada: dose));
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecione uma dose';
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }
}
