import 'package:flutter/material.dart';

/// Tela de teste simples para verificar se as telas de germinação estão funcionando
class TestSimpleGerminationScreens extends StatelessWidget {
  const TestSimpleGerminationScreens({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Simples - Telas de Germinação'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teste das Telas de Germinação',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Teste as telas de registro diário para verificar se estão funcionando',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            
            // Botão para teste individual
            _buildTestButton(
              context,
              title: 'Teste Individual',
              subtitle: 'Para testes com uma única amostra',
              icon: Icons.eco,
              color: Colors.green,
              onTap: () => _navigateToIndividualTest(context),
            ),
            
            const SizedBox(height: 16),
            
            // Botão para teste com subtestes
            _buildTestButton(
              context,
              title: 'Teste com Subtestes',
              subtitle: 'Para testes com múltiplos canteiros (A, B, C)',
              icon: Icons.science,
              color: Colors.blue,
              onTap: () => _navigateToSubtestsTest(context),
            ),
            
            const SizedBox(height: 32),
            
            // Informações sobre o problema
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Problema Identificado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'As telas de registro diário estavam ficando brancas porque as rotas não estavam registradas no arquivo principal de rotas.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '✅ Correção aplicada: Rotas adicionadas ao routes.dart',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
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

  Widget _buildTestButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToIndividualTest(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/germination/daily-record-individual-optimized',
      arguments: {
        'testId': 'teste_individual_demo',
        'day': 1,
      },
    );
  }

  void _navigateToSubtestsTest(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/germination/daily-record-subtests-optimized',
      arguments: {
        'testId': 'teste_subtestes_demo',
        'day': 1,
      },
    );
  }
}
