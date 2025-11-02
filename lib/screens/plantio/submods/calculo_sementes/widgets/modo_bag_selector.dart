import 'package:flutter/material.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../models/calculo_sementes_state.dart';

/// Widget para seleção do modo de bag
class ModoBagSelector extends StatelessWidget {
  final ModoBag modoSelecionado;
  final Function(ModoBag) onChanged;

  const ModoBagSelector({
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
              'Modo de Bag',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: FortSmartTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                RadioListTile<ModoBag>(
                  title: const Text('Bag por Sementes'),
                  subtitle: const Text('Informar milhões de sementes no bag'),
                  value: ModoBag.sementesPorBag,
                  groupValue: modoSelecionado,
                  activeColor: FortSmartTheme.primaryColor,
                  onChanged: (value) {
                    if (value != null) onChanged(value);
                  },
                ),
                RadioListTile<ModoBag>(
                  title: const Text('Bag por Peso'),
                  subtitle: const Text('Informar peso do bag em kg'),
                  value: ModoBag.pesoPorBag,
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
