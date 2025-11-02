import 'package:flutter/material.dart';

class SelecaoDatasWidget extends StatelessWidget {
  final TextEditingController dataEmergenciaController;
  final TextEditingController dataAvaliacaoController;
  final Function(String) onDataEmergenciaSelecionada;
  final Function(String) onDataAvaliacaoSelecionada;
  final Function()? calcularDiasAposEmergencia;
  final int? diasAposEmergencia;

  const SelecaoDatasWidget({
    Key? key,
    required this.dataEmergenciaController,
    required this.dataAvaliacaoController,
    required this.onDataEmergenciaSelecionada,
    required this.onDataAvaliacaoSelecionada,
    this.calcularDiasAposEmergencia,
    required this.diasAposEmergencia,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: dataEmergenciaController,
              decoration: const InputDecoration(
                labelText: 'Data de Emergência',
                hintText: 'dd/mm/aaaa',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  final formattedDate = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                  onDataEmergenciaSelecionada(formattedDate);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe a data de emergência';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: dataAvaliacaoController,
              decoration: const InputDecoration(
                labelText: 'Data de Avaliação',
                hintText: 'dd/mm/aaaa',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  final formattedDate = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                  onDataAvaliacaoSelecionada(formattedDate);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe a data de avaliação';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dias Após Emergência (DAE): ${diasAposEmergencia ?? "Calcule para ver"}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
