// lib/modules/clima/widgets/clima_card_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/clima_model.dart';
import '../clima_theme.dart';
import 'clima_lottie_widget.dart';

class ClimaCardWidget extends StatelessWidget {
  final ClimaModel clima;
  final VoidCallback? onTap;
  final bool showDetails;
  final bool showMetrics;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const ClimaCardWidget({
    Key? key,
    required this.clima,
    this.onTap,
    this.showDetails = true,
    this.showMetrics = true,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradient = ClimaTheme.gradientFor(clima.icone);
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: padding ?? const EdgeInsets.all(20),
        decoration: ClimaTheme.getCardDecoration(gradient: gradient),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com localização e data
            _buildHeader(context, dateFormat),
            
            const SizedBox(height: 16),
            
            // Corpo principal com animação e temperatura
            _buildMainContent(context),
            
            if (showDetails) ...[
              const SizedBox(height: 20),
              _buildDetails(context),
            ],
            
            if (showMetrics) ...[
              const SizedBox(height: 16),
              _buildMetrics(context, timeFormat),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DateFormat dateFormat) {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          color: Colors.white.withOpacity(0.9),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clima.cidade,
                style: ClimaTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                dateFormat.format(clima.dataHora),
                style: ClimaTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (clima.ultimaAtualizacao != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.refresh,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
              Text(
                'Atualizado',
                style: ClimaTheme.bodySmall.copyWith(fontSize: 10),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Row(
      children: [
        // Animação Lottie
        ClimaLottieWidget(
          iconCode: clima.icone,
          size: 120,
        ),
        
        const SizedBox(width: 20),
        
        // Temperatura e descrição
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${clima.temperatura.toStringAsFixed(0)}°C',
                style: ClimaTheme.titleLarge.copyWith(fontSize: 42),
              ),
              Text(
                clima.descricao.toUpperCase(),
                style: ClimaTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sensação ${clima.sensacaoTermica.toStringAsFixed(0)}°C',
                style: ClimaTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ClimaTheme.getMetricCardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _buildDetailItem(
                'Mín/Máx',
                '${clima.temperaturaMinima.toStringAsFixed(0)}° / ${clima.temperaturaMaxima.toStringAsFixed(0)}°',
                Icons.thermostat,
              ),
              const SizedBox(width: 20),
              _buildDetailItem(
                'Precipitação',
                clima.precipitacao1h != null 
                  ? '${clima.precipitacao1h!.toStringAsFixed(1)}mm'
                  : '0mm',
                Icons.water_drop,
              ),
            ],
          ),
          if (clima.hasHighWindAlert || clima.hasFrostRisk || clima.hasHeatAlert) ...[
            const SizedBox(height: 12),
            _buildAlertSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ClimaTheme.labelLarge,
              ),
              Text(
                value,
                style: ClimaTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSection() {
    final alerts = <String>[];
    
    if (clima.hasHighWindAlert) {
      alerts.add('Vento forte');
    }
    if (clima.hasFrostRisk) {
      alerts.add('Risco de geada');
    }
    if (clima.hasHeatAlert) {
      alerts.add('Calor extremo');
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: Colors.orange.shade200,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alerts.join(' • '),
              style: ClimaTheme.bodySmall.copyWith(
                color: Colors.orange.shade100,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(BuildContext context, DateFormat timeFormat) {
    return Row(
      children: [
        _buildMetricCard(
          'Umidade',
          '${clima.umidade}%',
          Icons.water_percent,
          ClimaTheme.getHumidityColor(clima.umidade.toDouble()),
        ),
        const SizedBox(width: 12),
        _buildMetricCard(
          'Vento',
          '${clima.velocidadeVento.toStringAsFixed(0)} km/h',
          Icons.air,
          ClimaTheme.getWindColor(clima.velocidadeVento),
        ),
        const SizedBox(width: 12),
        _buildMetricCard(
          'Pressão',
          '${clima.pressao.toStringAsFixed(0)} hPa',
          Icons.speed,
          Colors.blue.shade300,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: ClimaTheme.getMetricCardDecoration(
          backgroundColor: color.withOpacity(0.15),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: ClimaTheme.metricValue.copyWith(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: ClimaTheme.metricLabel.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget compacto para listas
class ClimaCardCompactWidget extends StatelessWidget {
  final ClimaModel clima;
  final VoidCallback? onTap;
  final bool showDate;

  const ClimaCardCompactWidget({
    Key? key,
    required this.clima,
    this.onTap,
    this.showDate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradient = ClimaTheme.gradientFor(clima.icone);
    final timeFormat = showDate ? DateFormat('dd/MM HH:mm') : DateFormat('HH:mm');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: ClimaTheme.getCardDecoration(
          gradient: gradient,
          borderRadius: 12,
        ),
        child: Row(
          children: [
            ClimaIconeWidget(
              iconCode: clima.icone,
              size: 50,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${clima.temperatura.toStringAsFixed(0)}°C',
                    style: ClimaTheme.titleMedium.copyWith(fontSize: 20),
                  ),
                  Text(
                    clima.descricao,
                    style: ClimaTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeFormat.format(clima.dataHora),
                  style: ClimaTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_percent,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${clima.umidade}%',
                      style: ClimaTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
