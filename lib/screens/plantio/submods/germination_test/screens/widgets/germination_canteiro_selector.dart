/// 🌱 Widget de Seleção de Canteiro
/// 
/// Permite selecionar canteiro para o teste de germinação
/// seguindo padrão visual FortSmart

import 'package:flutter/material.dart';
import '../../../../../../utils/fortsmart_theme.dart';

class GerminationCanteiroSelector extends StatelessWidget {
  final String? selectedCanteiro;
  final ValueChanged<String?> onCanteiroChanged;
  final List<String> availableCanteiros;

  const GerminationCanteiroSelector({
    super.key,
    required this.selectedCanteiro,
    required this.onCanteiroChanged,
    this.availableCanteiros = const [],
    String? canteiroId,
  });

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
              'Seleção de Canteiro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: FortSmartTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCanteiro,
              decoration: InputDecoration(
                labelText: 'Canteiro',
                hintText: 'Selecione um canteiro',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: FortSmartTheme.primaryColor),
                ),
              ),
              items: availableCanteiros.map((canteiro) {
                return DropdownMenuItem<String>(
                  value: canteiro,
                  child: Text(canteiro),
                );
              }).toList(),
              onChanged: onCanteiroChanged,
            ),
            const SizedBox(height: 12),
            Text(
              'Nota: O canteiro será usado para organizar os testes fisicamente.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
