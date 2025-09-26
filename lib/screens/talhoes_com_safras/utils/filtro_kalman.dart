import 'package:latlong2/latlong.dart';

/// Implementação de Filtro Kalman para suavização de coordenadas GPS
/// Reduz ruído e imprecisões nas coordenadas coletadas durante caminhada GPS
class FiltroKalman {
  /// Aplica o filtro Kalman a uma lista de pontos GPS
  /// Retorna uma nova lista com pontos suavizados
  static List<LatLng> aplicar(List<LatLng> pontosOriginais) {
    if (pontosOriginais.length < 3) return pontosOriginais;
    
    List<LatLng> pontosFiltrados = [pontosOriginais.first];
    
    // Parâmetros do filtro
    const double pesoAnterior = 0.25;
    const double pesoAtual = 0.5;
    const double pesoProximo = 0.25;
    
    // Aplicar filtro para cada ponto (exceto primeiro e último)
    for (int i = 1; i < pontosOriginais.length - 1; i++) {
      final anterior = pontosOriginais[i - 1];
      final atual = pontosOriginais[i];
      final proximo = pontosOriginais[i + 1];
      
      // Aplicar média ponderada para suavização
      final latFiltrada = (anterior.latitude * pesoAnterior) + 
                         (atual.latitude * pesoAtual) + 
                         (proximo.latitude * pesoProximo);
      
      final lngFiltrada = (anterior.longitude * pesoAnterior) + 
                         (atual.longitude * pesoAtual) + 
                         (proximo.longitude * pesoProximo);
      
      pontosFiltrados.add(LatLng(latFiltrada, lngFiltrada));
    }
    
    // Adicionar o último ponto original
    pontosFiltrados.add(pontosOriginais.last);
    return pontosFiltrados;
  }
  
  /// Aplica filtro Kalman avançado com detecção de outliers
  /// Útil para GPS com baixa precisão ou em áreas com sinal fraco
  static List<LatLng> aplicarAvancado(List<LatLng> pontosOriginais, {
    double distanciaMaxima = 10.0, // metros
    int janelaDeslizante = 5,
  }) {
    if (pontosOriginais.length < janelaDeslizante) return aplicar(pontosOriginais);
    
    List<LatLng> pontosFiltrados = [];
    final Distance calculadorDistancia = const Distance();
    
    // Primeiro, remover outliers (pontos muito distantes)
    List<LatLng> pontosSemOutliers = [pontosOriginais.first];
    
    for (int i = 1; i < pontosOriginais.length; i++) {
      final pontoAnterior = pontosSemOutliers.last;
      final pontoAtual = pontosOriginais[i];
      
      final distancia = calculadorDistancia.as(
        LengthUnit.Meter,
        pontoAnterior,
        pontoAtual
      );
      
      // Se a distância for razoável, adicionar o ponto
      if (distancia <= distanciaMaxima) {
        pontosSemOutliers.add(pontoAtual);
      } else {
        // Caso contrário, interpolar um ponto intermediário
        final latMedia = (pontoAnterior.latitude + pontoAtual.latitude) / 2;
        final lngMedia = (pontoAnterior.longitude + pontoAtual.longitude) / 2;
        pontosSemOutliers.add(LatLng(latMedia, lngMedia));
      }
    }
    
    // Aplicar janela deslizante para suavização
    pontosFiltrados.add(pontosSemOutliers.first);
    
    for (int i = 1; i < pontosSemOutliers.length - 1; i++) {
      // Determinar tamanho da janela (menor entre o configurado e o disponível)
      final inicioJanela = (i - janelaDeslizante ~/ 2).clamp(0, pontosSemOutliers.length - 1);
      final fimJanela = (i + janelaDeslizante ~/ 2).clamp(0, pontosSemOutliers.length - 1);
      
      double somaLat = 0;
      double somaLng = 0;
      int contadorPontos = 0;
      
      // Calcular média ponderada na janela
      for (int j = inicioJanela; j <= fimJanela; j++) {
        // Peso maior para pontos mais próximos do centro da janela
        final peso = 1.0 - (j - i).abs() / janelaDeslizante;
        somaLat += pontosSemOutliers[j].latitude * peso;
        somaLng += pontosSemOutliers[j].longitude * peso;
        contadorPontos += 1;
      }
      
      // Adicionar ponto suavizado
      if (contadorPontos > 0) {
        pontosFiltrados.add(LatLng(
          somaLat / contadorPontos,
          somaLng / contadorPontos
        ));
      }
    }
    
    pontosFiltrados.add(pontosSemOutliers.last);
    return pontosFiltrados;
  }
}
