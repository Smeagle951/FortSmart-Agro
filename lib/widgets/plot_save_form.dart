import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/plot.dart';
import '../utils/area_calculator.dart';

class PlotSaveForm extends StatefulWidget {
  final List<LatLng> points;
  final double area;
  final Function(String name, String? description) onSave;
  final String farmId;
  final String propertyId;
  final String? farmName;

  const PlotSaveForm({
    Key? key,
    required this.points,
    required this.area,
    required this.onSave,
    required this.farmId,
    required this.propertyId,
    this.farmName,
  }) : super(key: key);

  @override
  _PlotSaveFormState createState() => _PlotSaveFormState();
}

class _PlotSaveFormState extends State<PlotSaveForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Text(
              'Salvar Talhão',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Informações do talhão
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome da Fazenda (carregado automaticamente)
                  Row(
                    children: [
                      const Icon(Icons.home_work, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'Fazenda:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.farmId.isNotEmpty ? 'Fazenda ${widget.farmId}' : 'Não especificada',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Área calculada
                  Row(
                    children: [
                      const Icon(Icons.area_chart, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'Área:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.area.toStringAsFixed(2)} ha',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Número de pontos
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'Pontos:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.points.length}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Campo de nome
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Talhão *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.crop_square),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe um nome para o talhão';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Campo de descrição
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Cancelar', style: TextStyle(fontSize: 16)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onSave(
                          _nameController.text,
                          _descriptionController.text.isEmpty ? null : _descriptionController.text,
                        );
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Confirmar', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: const Color(0xFF4CAF50), // backgroundColor não é suportado em flutter_map 5.0.0
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
