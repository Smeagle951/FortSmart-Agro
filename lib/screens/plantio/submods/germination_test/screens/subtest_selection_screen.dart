/// 🧪 Tela de Seleção de Subteste
/// 
/// Permite escolher entre teste individual ou subtestes A, B, C
/// Design elegante seguindo padrão FortSmart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../../../../../widgets/app_bar_widget.dart';
import '../providers/germination_test_provider.dart';
import '../models/germination_test_model.dart';
import 'germination_daily_record_screen.dart';

class SubtestSelectionScreen extends StatelessWidget {
  final GerminationTest test;
  
  const SubtestSelectionScreen({
    Key? key,
    required this.test,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: FortSmartTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Selecionar Subteste',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTestInfoCard(),
            const SizedBox(height: 24),
            _buildTestTypeInfo(),
            const SizedBox(height: 24),
            _buildSubtestOptions(context),
            const SizedBox(height: 100), // Espaço para FAB
          ],
        ),
      ),
    );
  }

  /// 📋 Card de informações do teste
  Widget _buildTestInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: FortSmartTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Informações do Teste',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Cultura:', test.culture),
            _buildInfoRow('Variedade:', test.variety),
            _buildInfoRow('Total de Sementes:', '${test.totalSeeds}'),
            _buildInfoRow('Tipo:', test.useSubtests ? 'Com Subtestes' : 'Individual'),
          ],
        ),
      ),
    );
  }

  /// 📝 Informações sobre o tipo de teste
  Widget _buildTestTypeInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Tipo de Teste',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              test.useSubtests 
                  ? 'Este teste possui 3 subtestes (A, B, C) que devem ser registrados separadamente. Cada subteste terá 100 sementes.'
                  : 'Este é um teste individual com todas as sementes em um único registro.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🧪 Opções de subtestes
  Widget _buildSubtestOptions(BuildContext context) {
    if (!test.useSubtests) {
      return _buildIndividualTestOption(context);
    } else {
      return _buildSubtestOptionsList(context);
    }
  }

  /// 🎯 Opção para teste individual
  Widget _buildIndividualTestOption(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToRecord(context, null),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FortSmartTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.science,
                      color: FortSmartTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Teste Individual',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Registrar todas as ${test.totalSeeds} sementes',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🧪 Opções para subtests A, B, C
  Widget _buildSubtestOptionsList(BuildContext context) {
    final subtests = ['A', 'B', 'C'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecionar Subteste',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        ...subtests.map((subtest) => _buildSubtestCard(context, subtest)).toList(),
      ],
    );
  }

  /// 🎯 Card de subteste individual
  Widget _buildSubtestCard(BuildContext context, String subtestName) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToRecord(context, subtestName),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getSubtestColor(subtestName),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    subtestName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subteste $subtestName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '100 sementes - Registros separados',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 Cores para cada subteste
  Color _getSubtestColor(String subtest) {
    switch (subtest) {
      case 'A':
        return Colors.blue;
      case 'B':
        return Colors.green;
      case 'C':
        return Colors.orange;
      default:
        return FortSmartTheme.primaryColor;
    }
  }

  /// 🧭 Navegação para registro
  void _navigateToRecord(BuildContext context, String? subtestName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GerminationDailyRecordScreen(
          test: test,
          subtestName: subtestName,
        ),
      ),
    );
  }

  /// 📝 Linha de informação
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
