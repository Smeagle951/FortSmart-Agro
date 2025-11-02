import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_application_model.dart';
import '../../../utils/app_colors.dart';

class GeneralInfoSection extends StatelessWidget {
  final ApplicationType applicationType;
  final DateTime applicationDate;
  final TextEditingController responsibleNameController;
  final TextEditingController equipmentTypeController;
  final Function(ApplicationType) onApplicationTypeChanged;
  final Function(DateTime) onApplicationDateChanged;
  
  // Removido 'const' do construtor para resolver o erro de compilação
  GeneralInfoSection({
    Key? key,
    required this.applicationType,
    required this.applicationDate,
    required this.responsibleNameController,
    required this.equipmentTypeController,
    required this.onApplicationTypeChanged,
    required this.onApplicationDateChanged,
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
              'Informações Gerais',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tipo de aplicação (terrestre/aérea)
            const Text(
              'Tipo de Aplicação',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<ApplicationType>(
                    title: const Text('Terrestre'),
                    value: ApplicationType.terrestrial,
                    groupValue: applicationType,
                    onChanged: (value) {
                      if (value != null) {
                        onApplicationTypeChanged(value);
                      }
                    },
                    activeColor: AppColors.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<ApplicationType>(
                    title: const Text('Aérea'),
                    value: ApplicationType.aerial,
                    groupValue: applicationType,
                    onChanged: (value) {
                      if (value != null) {
                        onApplicationTypeChanged(value);
                      }
                    },
                    activeColor: AppColors.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Data de aplicação
            InkWell(
              onTap: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: applicationDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                
                if (selectedDate != null) {
                  onApplicationDateChanged(selectedDate);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data de Aplicação',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(applicationDate),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Responsável
            TextFormField(
              controller: responsibleNameController,
              decoration: const InputDecoration(
                labelText: 'Responsável',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o responsável pela aplicação';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Tipo de equipamento
            TextFormField(
              controller: equipmentTypeController,
              decoration: const InputDecoration(
                labelText: 'Equipamento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.agriculture),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o tipo de equipamento utilizado';
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
