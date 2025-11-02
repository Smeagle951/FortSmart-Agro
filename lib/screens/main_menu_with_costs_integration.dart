import 'package:flutter/material.dart';
import 'custos/custo_por_hectare_dashboard_screen.dart';
import 'historico/historico_custos_talhao_screen.dart';
import 'gestao_custos_screen.dart';

/// Exemplo de integração do sistema de custos no menu principal
/// Este arquivo demonstra como adicionar as novas funcionalidades
/// ao menu de navegação da aplicação
class MainMenuWithCostsIntegration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FortSmart Agro - Menu Principal'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🌾 FortSmart Agro',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sistema de Gestão Agrícola Inteligente',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            
            // Seção de Custos e Análises
            _buildSectionHeader('💰 Custos e Análises', Icons.analytics),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Dashboard de Custos',
                    'Visualize custos por hectare e análises',
                    Icons.dashboard,
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustoPorHectareDashboardScreen(),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Histórico de Custos',
                    'Histórico completo por talhão',
                    Icons.history,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoricoCustosTalhaoScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Gestão de Custos',
                    'Controle de estoque e custos',
                    Icons.inventory,
                    Colors.teal,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GestaoCustosScreen(),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Simulador de Custos',
                    'Calcule custos futuros',
                    Icons.calculate,
                    Colors.orange,
                    () => _showSimulatorDialog(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Relatórios',
                    'Gere relatórios detalhados',
                    Icons.assessment,
                    Colors.purple,
                    () => _showReportsDialog(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            
            // Seção de Gestão de Campo
            _buildSectionHeader('🌱 Gestão de Campo', Icons.agriculture),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Talhões',
                    'Gerencie seus talhões',
                    Icons.map,
                    Colors.brown,
                    () => _showComingSoon(context, 'Gestão de Talhões'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Prescrições Premium',
                    'Cálculos de produtos com dose e integração de custos',
                    Icons.science,
                    Colors.teal,
                    () => Navigator.pushNamed(context, '/prescricao/premium'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Monitoramento',
                    'Acompanhe o desenvolvimento',
                    Icons.trending_up,
                    Colors.indigo,
                    () => _showComingSoon(context, 'Monitoramento'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Colheita',
                    'Registre dados de colheita',
                    Icons.agriculture,
                    Colors.amber,
                    () => _showComingSoon(context, 'Registro de Colheita'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            
            // Seção de Gestão de Recursos
            _buildSectionHeader('📦 Gestão de Recursos', Icons.inventory),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Estoque',
                    'Controle de produtos',
                    Icons.inventory_2,
                    Colors.red,
                    () => _showComingSoon(context, 'Gestão de Estoque'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Equipamentos',
                    'Gerencie equipamentos',
                    Icons.build,
                    Colors.grey,
                    () => _showComingSoon(context, 'Gestão de Equipamentos'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Funcionários',
                    'Gestão de equipe',
                    Icons.people,
                    Colors.cyan,
                    () => _showComingSoon(context, 'Gestão de Funcionários'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Fornecedores',
                    'Cadastro de fornecedores',
                    Icons.business,
                    Colors.deepOrange,
                    () => _showComingSoon(context, 'Gestão de Fornecedores'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            
            // Seção de Configurações
            _buildSectionHeader('⚙️ Configurações', Icons.settings),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Perfil da Fazenda',
                    'Configure dados da fazenda',
                    Icons.agriculture,
                    Colors.lightGreen,
                    () => _showComingSoon(context, 'Perfil da Fazenda'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Preferências',
                    'Configurações do sistema',
                    Icons.tune,
                    Colors.deepPurple,
                    () => _showComingSoon(context, 'Preferências'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            
            // Seção de Suporte
            _buildSectionHeader('📞 Suporte', Icons.help),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Ajuda',
                    'Central de ajuda',
                    Icons.help_center,
                    Colors.blue,
                    () => _showComingSoon(context, 'Central de Ajuda'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMenuCard(
                    context,
                    'Sobre',
                    'Informações do sistema',
                    Icons.info,
                    Colors.grey,
                    () => _showAboutDialog(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSimulatorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.calculate, color: Colors.orange),
            SizedBox(width: 8),
            Text('Simulador de Custos'),
          ],
        ),
        content: Text(
          'O simulador de custos permite calcular custos futuros de aplicações '
          'baseado em produtos selecionados e área definida. '
          'Acesse através do Dashboard de Custos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustoPorHectareDashboardScreen(),
                ),
              );
            },
            child: Text('Abrir Dashboard'),
          ),
        ],
      ),
    );
  }

  void _showReportsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.assessment, color: Colors.purple),
            SizedBox(width: 8),
            Text('Relatórios'),
          ],
        ),
        content: Text(
          'Gere relatórios detalhados de custos por período, talhão ou safra. '
          'Os relatórios podem ser exportados em diferentes formatos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoricoCustosTalhaoScreen(),
                ),
              );
            },
            child: Text('Abrir Histórico'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.construction, color: Colors.orange),
            SizedBox(width: 8),
            Text('Em Desenvolvimento'),
          ],
        ),
        content: Text(
          'A funcionalidade "$feature" está sendo desenvolvida e estará '
          'disponível em breve. Fique atento às atualizações!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('Sobre o Sistema'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FortSmart Agro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Versão: 2.0.0'),
            Text('Sistema de Gestão Agrícola Inteligente'),
            SizedBox(height: 16),
            Text(
              'Funcionalidades Principais:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Gestão de Custos por Hectare'),
            Text('• Controle de Estoque'),
            Text('• Histórico de Aplicações'),
            Text('• Simulador de Custos'),
            Text('• Relatórios Detalhados'),
            SizedBox(height: 16),
            Text(
              '© 2024 FortSmart Agro. Todos os direitos reservados.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
