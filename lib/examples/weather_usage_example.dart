import 'package:flutter/material.dart';
import '../widgets/weather_card_widget.dart';
import '../screens/weather_forecast_screen.dart';
import '../constants/app_colors.dart';

/// Exemplo de como usar o widget de clima em diferentes telas
class WeatherUsageExample extends StatelessWidget {
  const WeatherUsageExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplos de Uso - Widget de Clima'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Card de Clima Simples'),
            const SizedBox(height: 16),
            const WeatherCardWidget(
              showDetails: false,
              margin: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Card de Clima com Detalhes'),
            const SizedBox(height: 16),
            const WeatherCardWidget(
              showDetails: true,
              margin: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Card de Clima com Navegação'),
            const SizedBox(height: 16),
            WeatherCardWidget(
              showDetails: true,
              margin: EdgeInsets.zero,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WeatherForecastScreen(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Card de Clima para Localização Específica'),
            const SizedBox(height: 16),
            const WeatherCardWidget(
              cityName: 'Cuiabá, MT',
              latitude: -15.6014,
              longitude: -56.0979,
              showDetails: true,
              margin: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Botão para Tela Completa'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeatherForecastScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.wb_sunny),
                label: const Text('Ver Previsão Completa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

/// Exemplo de como integrar o widget de clima em uma tela existente
class DashboardWithWeatherExample extends StatelessWidget {
  const DashboardWithWeatherExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard com Clima'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Card de clima no topo
            const WeatherCardWidget(
              showDetails: true,
              onTap: null, // Navegação será tratada no onTap do card
            ),
            
            // Conteúdo do dashboard
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo da Fazenda',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Cards de estatísticas
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Talhões',
                          '12',
                          Icons.agriculture,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Culturas',
                          '3',
                          Icons.eco,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Área Total',
                          '1.250 ha',
                          Icons.landscape,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Safra Atual',
                          '2024/25',
                          Icons.calendar_today,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Exemplo de como usar o widget de clima em uma lista
class WeatherListExample extends StatelessWidget {
  const WeatherListExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista com Clima'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Card de clima
          const WeatherCardWidget(
            showDetails: false,
            margin: EdgeInsets.all(16),
          ),
          
          // Lista de itens
          ...List.generate(10, (index) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text('${index + 1}'),
                ),
                title: Text('Item ${index + 1}'),
                subtitle: Text('Descrição do item ${index + 1}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Ação do item
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
