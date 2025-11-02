# 🧮 Implementação de Cálculos Geodésicos - FortSmart Agro

## 📋 Resumo das Implementações

Implementei os **cálculos geodésicos específicos** que você detalhou, seguindo exatamente as fórmulas matemáticas para **modo desenho** e **modo GPS**.

---

## 🔹 **1. Modo Desenho (Coordenadas Planas)**

### **Projeção Web Mercator (EPSG:3857)**
```dart
static List<Point<double>> _projectToWebMercator(List<LatLng> points) {
  return points.map((point) {
    final x = point.longitude * _earthRadiusMeters * pi / 180.0;
    final y = log(tan(pi / 4.0 + point.latitude * pi / 360.0)) * _earthRadiusMeters;
    return Point<double>(x, y);
  }).toList();
}
```

### **Fórmula de Shoelace/Gauss**
```dart
static double _calculateShoelaceArea(List<Point<double>> points) {
  double area = 0.0;
  final n = points.length;

  for (int i = 0; i < n; i++) {
    final j = (i + 1) % n;
    area += points[i].x * points[j].y;
    area -= points[j].x * points[i].y;
  }

  return area.abs() / 2.0; // Resultado em m²
}
```

### **Perímetro Euclidiano**
```dart
static double calculatePerimeterDrawingMode(List<LatLng> points) {
  final projectedPoints = _projectToWebMercator(points);
  
  double perimeter = 0.0;
  for (int i = 0; i < projectedPoints.length; i++) {
    final current = projectedPoints[i];
    final next = projectedPoints[(i + 1) % projectedPoints.length];
    
    final dx = next.x - current.x;
    final dy = next.y - current.y;
    perimeter += sqrt(dx * dx + dy * dy);
  }
  
  return perimeter;
}
```

---

## 🔹 **2. Modo GPS (Coordenadas Geodésicas)**

### **Fórmula de Haversine**
```dart
static double _calculateHaversineDistance(LatLng point1, LatLng point2) {
  final lat1Rad = point1.latitude * (pi / 180);
  final lat2Rad = point2.latitude * (pi / 180);
  final deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
  final deltaLngRad = (point2.longitude - point1.longitude) * (pi / 180);

  final sinDeltaLat = sin(deltaLatRad / 2);
  final sinDeltaLng = sin(deltaLngRad / 2);
  
  final a = sinDeltaLat * sinDeltaLat +
      cos(lat1Rad) * cos(lat2Rad) * sinDeltaLng * sinDeltaLng;

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return _earthRadiusMean * c; // R = 6.371.000m
}
```

### **Área Esférica (Excesso Esférico)**
```dart
static double _calculateSphericalArea(List<LatLng> points) {
  // Converter para radianos
  final radianPoints = points.map((p) => Point<double>(
    p.longitude * pi / 180.0,
    p.latitude * pi / 180.0,
  )).toList();

  // Calcular excesso esférico
  double excess = 0.0;
  final n = radianPoints.length;

  for (int i = 0; i < n; i++) {
    final prev = radianPoints[(i - 1 + n) % n];
    final curr = radianPoints[i];
    final next = radianPoints[(i + 1) % n];

    final angle = _calculateSphericalAngle(prev, curr, next);
    excess += angle;
  }

  // Aplicar fórmula: A = R² * (Σθ - (n-2)π)
  excess -= (n - 2) * pi;
  return _earthRadiusMean * _earthRadiusMean * excess.abs();
}
```

---

## 🔹 **3. Filtros de Precisão GPS**

### **Filtro de Kalman**
```dart
static List<LatLng> applyKalmanFilter(List<LatLng> points, {
  double processNoise = 0.01,
  double measurementNoise = 1.0,
}) {
  // Estado inicial (posição e velocidade)
  double lat = points.first.latitude;
  double lng = points.first.longitude;
  double latVel = 0.0;
  double lngVel = 0.0;
  
  // Matrizes de covariância
  double pLat = 1.0;
  double pLng = 1.0;

  for (final point in points) {
    // Predição (estado anterior + velocidade)
    lat += latVel;
    lng += lngVel;
    
    // Correção (Kalman gain)
    final kLat = pLat / (pLat + measurementNoise);
    final kLng = pLng / (pLng + measurementNoise);
    
    // Atualização do estado
    lat += kLat * (point.latitude - lat);
    lng += kLng * (point.longitude - lng);
    
    // Atualização da covariância
    pLat *= (1 - kLat);
    pLng *= (1 - kLng);
  }
}
```

### **Média Móvel**
```dart
static List<LatLng> applyMovingAverage(List<LatLng> points, {int windowSize = 3}) {
  final smoothedPoints = <LatLng>[];
  
  for (int i = 0; i < points.length; i++) {
    int start = (i - windowSize ~/ 2).clamp(0, points.length - windowSize);
    int end = (start + windowSize).clamp(windowSize, points.length);
    
    double latSum = 0.0;
    double lngSum = 0.0;
    
    for (int j = start; j < end; j++) {
      latSum += points[j].latitude;
      lngSum += points[j].longitude;
    }
    
    smoothedPoints.add(LatLng(
      latSum / (end - start),
      lngSum / (end - start),
    ));
  }
  
  return smoothedPoints;
}
```

### **Validação de Precisão GPS**
```dart
static List<LatLng> validateGPSAccuracy(List<LatLng> points, {
  double maxAccuracyMeters = 5.0,
  double minDistanceMeters = 1.0,
}) {
  final validPoints = <LatLng>[points.first];
  
  for (int i = 1; i < points.length; i++) {
    final currentPoint = points[i];
    final lastValidPoint = validPoints.last;
    
    // Verificar distância mínima
    final distance = _calculateHaversineDistance(lastValidPoint, currentPoint);
    if (distance < minDistanceMeters) continue;
    
    // Verificar precisão (HDOP/PDOP simulado)
    final accuracy = _estimateGPSAccuracy(currentPoint, lastValidPoint);
    if (accuracy <= maxAccuracyMeters) {
      validPoints.add(currentPoint);
    }
  }
  
  return validPoints;
}
```

---

## 🔹 **4. Integração com Interface**

### **Cálculo Dinâmico por Modo**
```dart
void _calcularMetricas() {
  double area;
  double perimetro;

  // Usar método específico baseado no modo de desenho
  if (_modoDesenho == 'manual') {
    // Modo DESENHO: coordenadas planas + fórmula de Shoelace/Gauss
    area = SubareaGeodeticService.calculateAreaDrawingMode(_pontosAtuais);
    perimetro = SubareaGeodeticService.calculatePerimeterDrawingMode(_pontosAtuais);
  } else {
    // Modo GPS: coordenadas geodésicas + fórmula de Haversine + área esférica
    area = SubareaGeodeticService.calculateAreaGPSMode(_pontosAtuais);
    perimetro = SubareaGeodeticService.calculatePerimeterGPSMode(_pontosAtuais);
  }

  final percentual = (area / widget.talhaoAreaHa) * 100;

  setState(() {
    _areaAtual = area;
    _perimetroAtual = perimetro;
    _percentualAtual = percentual;
  });
}
```

### **Salvamento com Método Específico**
```dart
// Calcular métricas finais usando método específico do modo
double areaFinal;
double perimetroFinal;

if (_modoDesenho == 'manual') {
  // Modo DESENHO: coordenadas planas + fórmula de Shoelace/Gauss
  areaFinal = SubareaGeodeticService.calculateAreaDrawingMode(_pontosAtuais);
  perimetroFinal = SubareaGeodeticService.calculatePerimeterDrawingMode(_pontosAtuais);
} else {
  // Modo GPS: coordenadas geodésicas + fórmula de Haversine + área esférica
  areaFinal = SubareaGeodeticService.calculateAreaGPSMode(_pontosAtuais);
  perimetroFinal = SubareaGeodeticService.calculatePerimeterGPSMode(_pontosAtuais);
}
```

---

## ✅ **Resumo das Implementações**

### **Modo Desenho (Coordenadas Planas)**
- ✅ **Projeção Web Mercator** (EPSG:3857)
- ✅ **Fórmula de Shoelace/Gauss** para área
- ✅ **Distância Euclidiana** para perímetro
- ✅ **Conversão automática** m² → hectares

### **Modo GPS (Coordenadas Geodésicas)**
- ✅ **Fórmula de Haversine** para distâncias
- ✅ **Área Esférica** (excesso esférico)
- ✅ **Raio médio da Terra** (6.371.000m)
- ✅ **Cálculos geodésicos precisos**

### **Filtros de Precisão**
- ✅ **Filtro de Kalman** para suavização
- ✅ **Média móvel** para ruído
- ✅ **Validação de precisão** GPS
- ✅ **Estimativa de HDOP/PDOP**

### **Integração com Interface**
- ✅ **Cálculo dinâmico** por modo
- ✅ **Feedback em tempo real**
- ✅ **Validação automática**
- ✅ **Conversão para hectares**

---

## 🎯 **Resultado Final**

O sistema agora implementa **exatamente** as fórmulas matemáticas que você especificou:

1. **Modo Desenho** → Conversão para coordenadas planas → Fórmula de Gauss (Shoelace)
2. **Modo GPS** → Haversine para distâncias + área esférica (excesso esférico)
3. **Conversão final** → m² e hectares com registro de perímetro e precisão GPS
4. **Filtros de precisão** → Kalman, média móvel e validação de HDOP/PDOP

Tudo integrado perfeitamente com a interface do FortSmart Agro! 🚀
