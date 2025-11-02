import 'package:flutter/material.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../models/calculo_sementes_state.dart';

/// Widget para seleção do modo de cálculo
class ModoCalculoSelector extends StatelessWidget {
  final ModoCalculo modoSelecionado;
  final Function(ModoCalculo) onChanged;

  const ModoCalculoSelector({
    Key? key,
    required this.modoSelecionado,
    required this.onChanged,
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
              'Modo de Cálculo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: FortSmartTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                RadioListTile<ModoCalculo>(
                  title: const Text('Sementes por Metro'),
                  subtitle: const Text('Calcular baseado no número de sementes por metro linear'),
                  value: ModoCalculo.sementesPorMetro,
                  groupValue: modoSelecionado,
                  activeColor: FortSmartTheme.primaryColor,
                  onChanged: (value) {
                    if (value != null) onChanged(value);
                  },
                ),
                RadioListTile<ModoCalculo>(
                  title: const Text('População'),
                  subtitle: const Text('Calcular baseado na população desejada por hectare'),
                  value: ModoCalculo.populacao,
                  groupValue: modoSelecionado,
                  activeColor: FortSmartTheme.primaryColor,
                  onChanged: (value) {
                    if (value != null) onChanged(value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
