/// 🌱 Widget de Configuração de Subtestes
/// 
/// Permite configurar subtestes A, B, C com design elegante
/// seguindo padrão visual FortSmart

import 'package:flutter/material.dart';
import '../../../../../../utils/fortsmart_theme.dart';

class GerminationSubtestConfigWidget extends StatefulWidget {
  final List<String> subtestNames;
  final ValueChanged<List<String>> onSubtestNamesChanged;
  final int subtestSeedCount;
  final ValueChanged<int> onSubtestSeedCountChanged;

  const GerminationSubtestConfigWidget({
    super.key,
    required this.subtestNames,
    required this.onSubtestNamesChanged,
    required this.subtestSeedCount,
    required this.onSubtestSeedCountChanged,
  });

  @override
  State<GerminationSubtestConfigWidget> createState() => _GerminationSubtestConfigWidgetState();
}

class _GerminationSubtestConfigWidgetState extends State<GerminationSubtestConfigWidget> {
  late TextEditingController _seedCountController;

  @override
  void initState() {
    super.initState();
    _seedCountController = TextEditingController(); // Campo vazio para entrada livre
  }

  @override
  void dispose() {
    _seedCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuração de Subtestes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: FortSmartTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Campo para definir sementes por subteste
            TextField(
              controller: _seedCountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Sementes por Subteste',
                hintText: 'Digite a quantidade desejada',
                helperText: 'Quantidade de sementes que cada subteste receberá',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: FortSmartTheme.primaryColor),
                ),
                prefixIcon: const Icon(Icons.grass),
              ),
              onChanged: (value) {
                final seedCount = int.tryParse(value) ?? 100;
                widget.onSubtestSeedCountChanged(seedCount);
              },
            ),
            const SizedBox(height: 16),
            
            Text(
              'Nomes dos Subtestes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: FortSmartTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(3, (index) {
              final labels = ['A', 'B', 'C'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Subteste ${labels[index]}',
                    hintText: 'Ex: Controle, Tratamento 1, Tratamento 2',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: FortSmartTheme.primaryColor),
                    ),
                  ),
                  onChanged: (value) {
                    final newNames = List<String>.from(widget.subtestNames);
                    if (newNames.length <= index) {
                      newNames.addAll(List.filled(index + 1 - newNames.length, ''));
                    }
                    newNames[index] = value;
                    widget.onSubtestNamesChanged(newNames);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
