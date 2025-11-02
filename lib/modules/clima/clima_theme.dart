// lib/modules/clima/clima_theme.dart
import 'package:flutter/material.dart';
import 'clima_constants.dart';

class ClimaTheme {
  // Gradientes baseados nas condições climáticas
  static LinearGradient gradientFor(String weatherIcon) {
    final isDayTime = ClimaConstants.isDayTime(weatherIcon);
    
    switch (weatherIcon.substring(0, 2)) {
      case '01': // Céu limpo
        return isDayTime 
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF87CEEB), Color(0xFFE0F6FF)],
              stops: [0.0, 1.0],
            )
          : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              stops: [0.0, 0.5, 1.0],
            );
            
      case '02': // Parcialmente nublado
        return isDayTime
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF8FB6C8), Color(0xFFD9EEFA)],
              stops: [0.0, 1.0],
            )
          : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF232526), Color(0xFF414345)],
              stops: [0.0, 1.0],
            );
            
      case '03': // Nublado
      case '04':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6B8FB8), Color(0xFF9BB5D1)],
          stops: [0.0, 1.0],
        );
        
      case '09': // Chuva leve
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4B79A1), Color(0xFF283E51)],
          stops: [0.0, 1.0],
        );
        
      case '10': // Chuva pesada
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6B8FB8), Color(0xFF36454F)],
          stops: [0.0, 1.0],
        );
        
      case '11': // Tempestade
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C3E50), Color(0xFF34495E), Color(0xFF1A252F)],
          stops: [0.0, 0.6, 1.0],
        );
        
      case '13': // Neve
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE6F0FA), Color(0xFFBFD8F1)],
          stops: [0.0, 1.0],
        );
        
      case '50': // Névoa/Neblina
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF95A5A6), Color(0xFFBDC3C7)],
          stops: [0.0, 1.0],
        );
        
      default:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8FB6C8), Color(0xFFD9EEFA)],
          stops: [0.0, 1.0],
        );
    }
  }

  // Cores para cards baseadas na temperatura
  static Color getTemperatureColor(double temperature) {
    if (temperature >= 35) return Colors.red.shade700;
    if (temperature >= 28) return Colors.orange.shade600;
    if (temperature >= 20) return Colors.green.shade600;
    if (temperature >= 10) return Colors.blue.shade600;
    if (temperature >= 0) return Colors.lightBlue.shade700;
    return Colors.purple.shade700; // Abaixo de zero
  }

  // Cores para indicadores de umidade
  static Color getHumidityColor(double humidity) {
    if (humidity >= 80) return Colors.blue.shade700;
    if (humidity >= 60) return Colors.green.shade600;
    if (humidity >= 40) return Colors.yellow.shade700;
    if (humidity >= 20) return Colors.orange.shade600;
    return Colors.red.shade700;
  }

  // Cores para indicadores de vento
  static Color getWindColor(double windSpeed) {
    if (windSpeed >= 30) return Colors.red.shade700;
    if (windSpeed >= 20) return Colors.orange.shade600;
    if (windSpeed >= 10) return Colors.yellow.shade700;
    if (windSpeed >= 5) return Colors.green.shade600;
    return Colors.blue.shade600;
  }

  // Cores para alertas
  static Color getAlertColor(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'storm':
      case 'tornado':
        return Colors.red.shade700;
      case 'heavy_rain':
      case 'flood':
        return Colors.blue.shade700;
      case 'frost':
      case 'freeze':
        return Colors.purple.shade700;
      case 'high_wind':
        return Colors.orange.shade600;
      case 'extreme_heat':
        return Colors.red.shade600;
      case 'drought':
        return Colors.brown.shade600;
      default:
        return Colors.amber.shade600;
    }
  }

  // Estilos de texto para o módulo clima
  static const TextStyle titleLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(
        offset: Offset(1, 1),
        blurRadius: 3,
        color: Colors.black26,
      ),
    ],
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    shadows: [
      Shadow(
        offset: Offset(1, 1),
        blurRadius: 2,
        color: Colors.black26,
      ),
    ],
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    shadows: [
      Shadow(
        offset: Offset(0.5, 0.5),
        blurRadius: 1,
        color: Colors.black26,
      ),
    ],
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white60,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white70,
    letterSpacing: 0.5,
  );

  // Estilos para métricas
  static const TextStyle metricValue = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle metricLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
    letterSpacing: 0.3,
  );

  // Tema do card principal
  static BoxDecoration getCardDecoration({
    required LinearGradient gradient,
    double borderRadius = 16,
    bool hasShadow = true,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: hasShadow ? [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          offset: const Offset(0, 2),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ] : null,
    );
  }

  // Decoração para cards de métricas
  static BoxDecoration getMetricCardDecoration({
    Color? backgroundColor,
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          offset: const Offset(0, 2),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ],
    );
  }

  // Decoração para alertas
  static BoxDecoration getAlertDecoration({
    required Color alertColor,
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      color: alertColor.withOpacity(0.9),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: alertColor,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: alertColor.withOpacity(0.3),
          offset: const Offset(0, 2),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ],
    );
  }

  // Cores para gráficos
  static const List<Color> chartColors = [
    Color(0xFF3498DB), // Azul
    Color(0xFF2ECC71), // Verde
    Color(0xFFF39C12), // Laranja
    Color(0xFFE74C3C), // Vermelho
    Color(0xFF9B59B6), // Roxo
    Color(0xFF1ABC9C), // Turquesa
    Color(0xFFF1C40F), // Amarelo
    Color(0xFF34495E), // Cinza escuro
  ];

  // Método para obter cor do gráfico por índice
  static Color getChartColor(int index) {
    return chartColors[index % chartColors.length];
  }

  // Tema para botões
  static ButtonStyle getPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withOpacity(0.2),
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
    );
  }

  static ButtonStyle getSecondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(
        color: Colors.white.withOpacity(0.5),
        width: 1.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  // Animações e transições
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  static const Curve defaultAnimationCurve = Curves.easeInOut;
  static const Curve fastAnimationCurve = Curves.easeOut;
  static const Curve slowAnimationCurve = Curves.easeInOutCubic;
}
