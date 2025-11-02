import 'package:flutter/material.dart';
import '../../models/dashboard/dashboard_data.dart';

/// Card de dados climáticos
class WeatherCard extends StatelessWidget {
  final WeatherData weatherData;
  final VoidCallback? onTap;

  const WeatherCard({
    Key? key,
    required this.weatherData,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[400]!,
                Colors.blue[600]!,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        weatherData.localizacao,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${weatherData.temperatura.toStringAsFixed(0)}°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            weatherData.condicao,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildWeatherIcon(weatherData.condicao),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildWeatherDetail(
                        Icons.water_drop,
                        'Umidade',
                        '${weatherData.umidade.toStringAsFixed(0)}%',
                      ),
                    ),
                    Expanded(
                      child: _buildWeatherDetail(
                        Icons.air,
                        'Vento',
                        '${weatherData.vento.toStringAsFixed(0)} km/h',
                      ),
                    ),
                    Expanded(
                      child: _buildWeatherDetail(
                        Icons.cloud,
                        'Chuva',
                        '${weatherData.probabilidadeChuva.toStringAsFixed(0)}%',
                      ),
                    ),
                  ],
                ),
                if (weatherData.previsao3Dias.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white30),
                  const SizedBox(height: 12),
                  Text(
                    'Previsão 3 dias',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...weatherData.previsao3Dias.map((previsao) => _buildForecastItem(previsao)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherIcon(String condition) {
    IconData icon;
    switch (condition.toLowerCase()) {
      case 'ensolarado':
        icon = Icons.wb_sunny;
        break;
      case 'parcialmente nublado':
        icon = Icons.wb_cloudy;
        break;
      case 'nublado':
        icon = Icons.cloud;
        break;
      case 'chuvoso':
        icon = Icons.grain;
        break;
      default:
        icon = Icons.wb_sunny;
    }

    return Icon(
      icon,
      color: Colors.white,
      size: 48,
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastItem(PrevisaoTempo previsao) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(previsao.data),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildWeatherIcon(previsao.condicao),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${previsao.temperaturaMax.toStringAsFixed(0)}°/${previsao.temperaturaMin.toStringAsFixed(0)}°',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${previsao.probabilidadeChuva.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'Hoje';
    if (difference == 1) return 'Amanhã';
    
    const weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return weekdays[date.weekday % 7];
  }
}

/// Card de indicadores rápidos
class IndicadoresRapidosCard extends StatelessWidget {
  final IndicadoresRapidos indicadores;
  final VoidCallback? onTap;

  const IndicadoresRapidosCard({
    Key? key,
    required this.indicadores,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: Colors.indigo,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Indicadores Rápidos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Resumo Geral',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildIndicator(
                      'Área Plantada',
                      '${indicadores.areaPlantada.toStringAsFixed(1)} ha',
                      Icons.eco,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildIndicator(
                      'Produtividade',
                      '${indicadores.produtividadeEstimada.toStringAsFixed(1)} sc/ha',
                      Icons.trending_up,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildIndicator(
                      'Hectares Infestados',
                      '${indicadores.hectaresInfestados.toStringAsFixed(1)} ha',
                      Icons.warning,
                      Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildIndicator(
                      'Custos Acumulados',
                      'R\$ ${_formatCurrency(indicadores.custosAcumulados)}',
                      Icons.attach_money,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}
