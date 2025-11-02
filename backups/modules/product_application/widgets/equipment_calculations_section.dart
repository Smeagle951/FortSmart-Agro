import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/app_colors.dart';

class EquipmentCalculationsSection extends StatelessWidget {
  final TextEditingController syrupVolumePerHectareController;
  final TextEditingController equipmentCapacityController;
  final TextEditingController nozzleTypeController;
  final double area;
  final double totalSyrupVolume;
  final int numberOfTanks;
  final Function(double) onSyrupVolumePerHectareChanged;
  final Function(double) onEquipmentCapacityChanged;
  final Function(String) onNozzleTypeChanged;
  
  const EquipmentCalculationsSection({
    Key? key,
    required this.syrupVolumePerHectareController,
    required this.equipmentCapacityController,
    required this.nozzleTypeController,
    required this.area,
    required this.totalSyrupVolume,
    required this.numberOfTanks,
    required this.onSyrupVolumePerHectareChanged,
    required this.onEquipmentCapacityChanged,
    required this.onNozzleTypeChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Equipamento e Cálculos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Volume de calda por hectare
            TextFormField(
              controller: syrupVolumePerHectareController,
              decoration: const InputDecoration(
                labelText: 'Volume de calda por hectare (L/ha)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.water_drop),
                suffixText: 'L/ha',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o volume de calda por hectare';
                }
                final volume = double.tryParse(value);
                if (volume == null || volume <= 0) {
                  return 'Volume deve ser maior que zero';
                }
                return null;
              },
              onChanged: (value) {
                final volume = double.tryParse(value) ?? 0;
                onSyrupVolumePerHectareChanged(volume);
              },
            ),
            const SizedBox(height: 16),
            
            // Capacidade do equipamento
            TextFormField(
              controller: equipmentCapacityController,
              decoration: const InputDecoration(
                labelText: 'Capacidade do tanque (L)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.agriculture),
                suffixText: 'L',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe a capacidade do tanque';
                }
                final capacity = double.tryParse(value);
                if (capacity == null || capacity <= 0) {
                  return 'Capacidade deve ser maior que zero';
                }
                return null;
              },
              onChanged: (value) {
                final capacity = double.tryParse(value) ?? 0;
                onEquipmentCapacityChanged(capacity);
              },
            ),
            const SizedBox(height: 16),
            
            // Tipo de bico
            TextFormField(
              controller: nozzleTypeController,
              decoration: const InputDecoration(
                labelText: 'Tipo de bico/ponta',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o tipo de bico/ponta';
                }
                return null;
              },
              onChanged: onNozzleTypeChanged,
            ),
            const SizedBox(height: 24),
            
            // Resultados dos cálculos
            if (area > 0 && totalSyrupVolume > 0) ...[
              const Divider(),
              const SizedBox(height: 16),
              
              const Text(
                'Resultados dos Cálculos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Área total
              _buildCalculationRow(
                label: 'Área total:',
                value: '${area.toStringAsFixed(2)} ha',
                icon: Icons.landscape,
              ),
              const SizedBox(height: 8),
              
              // Volume total de calda
              _buildCalculationRow(
                label: 'Volume total de calda:',
                value: '${totalSyrupVolume.toStringAsFixed(2)} L',
                icon: Icons.water_drop,
              ),
              const SizedBox(height: 8),
              
              // Número de tanques
              _buildCalculationRow(
                label: 'Número de tanques:',
                value: '$numberOfTanks',
                icon: Icons.repeat,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildCalculationRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
