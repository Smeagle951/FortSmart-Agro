# 🗺️ **Módulo de Polígonos - FortSmart Agro**

## 📋 **Visão Geral**

O módulo de polígonos implementa funcionalidades completas para criação, edição e gerenciamento de polígonos geográficos com **precisão < 10 metros** sem uso de filtro Kalman.

## ✨ **Funcionalidades Principais**

### 🎯 **1. Desenho Manual**
- Toque no mapa para adicionar vértices
- Visualização em tempo real da linha e polígono
- Cálculo automático de área e perímetro
- Botão "Finalizar Desenho" para completar o polígono

### 🚶 **2. Gravação GPS (Caminhada)**
- Captura GPS com precisão < 10m
- Filtros de qualidade automáticos
- Pausa/retomada de gravação
- Funcionamento em segundo plano
- Cálculo de distância percorrida

### 📊 **3. Métricas em Tempo Real**
- **Área**: Calculada em hectares
- **Perímetro**: Calculado em metros
- **Distância**: Distância total percorrida (GPS)
- **Pontos**: Quantidade de vértices
- **Precisão**: Precisão atual do GPS

### 💾 **4. Armazenamento**
- Salva polígonos no banco SQLite
- Armazena trilhas GPS completas
- Suporte a múltiplas fazendas
- Integração com culturas e safras

## 🛠️ **Arquitetura Técnica**

### **Serviços Core**
```
lib/services/
├── location_service.dart      # GPS e validação de pontos
├── polygon_service.dart       # Cálculos geométricos
└── storage_service.dart       # Persistência no banco
```

### **Banco de Dados**
```sql
-- Tabela principal de polígonos
CREATE TABLE polygons (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  method TEXT NOT NULL,        -- 'manual', 'caminhada', 'importado'
  coordinates TEXT NOT NULL,   -- GeoJSON
  area_ha REAL NOT NULL,
  perimeter_m REAL NOT NULL,
  distance_m REAL DEFAULT 0,
  created_at TEXT NOT NULL,
  fazenda_id TEXT,
  cultura_id TEXT,
  safra_id TEXT
);

-- Tabela de trilhas GPS
CREATE TABLE tracks (
  id INTEGER PRIMARY KEY,
  polygon_id INTEGER,
  lat REAL NOT NULL,
  lon REAL NOT NULL,
  accuracy REAL,
  speed REAL,
  bearing REAL,
  ts TEXT NOT NULL,
  status TEXT
);
```

## 🎮 **Como Usar**

### **Desenho Manual**
1. Toque no botão **📝** (Desenho Manual)
2. Toque no mapa para adicionar pontos
3. Visualize as métricas em tempo real
4. Toque "Finalizar Desenho" quando concluir
5. Digite o nome e salve

### **Gravação GPS**
1. Toque no botão **🚶** (Gravação GPS)
2. Caminhe pelo perímetro do talhão
3. Monitore a precisão (deve ser < 10m)
4. Use **⏸️** para pausar se necessário
5. Toque "Finalizar GPS" quando concluir
6. Digite o nome e salve

### **Visualização**
- Polígonos salvos aparecem no mapa
- Toque em um polígono para ver detalhes
- Métricas são exibidas em tempo real

## 🔧 **Configuração de Precisão**

### **Critérios de Validação**
```dart
// Gate de qualidade
if (accuracy > 10.0) return false;

// Warm-up (3 primeiros pontos)
if (points.length < 3) return false;

// Salto irreal
if (distance > 20m && time < 2s) return false;

// De-dup (pontos muito próximos)
if (distance < 0.5m) return false;
```

### **Configurações GPS**
```dart
LocationSettings(
  accuracy: LocationAccuracy.best,
  distanceFilter: 1,           // 1 metro
  timeLimit: Duration(seconds: 30),
)
```

## 📱 **Permissões Necessárias**

### **Android**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### **iOS**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Precisamos da sua localização para criar polígonos precisos</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Precisamos da sua localização para gravação GPS em segundo plano</string>
```

## 🧪 **Testes de Precisão**

### **Cenários de Teste**
1. **Céu aberto**: Melhor precisão (2-5m)
2. **Borda de mato**: Precisão moderada (5-10m)
3. **Próximo a construções**: Precisão reduzida (10-15m)

### **Velocidades Recomendadas**
- **A pé**: ~5 km/h (ótimo)
- **Trator**: ~8-12 km/h (bom)
- **Veículo rápido**: >15 km/h (não recomendado)

## 🔍 **Troubleshooting**

### **Problemas Comuns**

**GPS não funciona**
- Verificar permissões
- Ativar GPS nas configurações
- Mover para área com melhor sinal

**Precisão baixa**
- Aguardar warm-up (3 pontos)
- Mover para céu aberto
- Verificar se há obstáculos

**App trava durante gravação**
- Reduzir frequência de amostragem
- Verificar memória disponível
- Reiniciar o app

### **Logs de Debug**
```dart
// Ativar logs detalhados
print('📍 Ponto GPS: ${lat}, ${lng} | Precisão: ${accuracy}m | Válido: $isValid');
print('✅ Polígono salvo com ID: $polygonId');
print('❌ Erro ao salvar: $error');
```

## 🚀 **Próximas Funcionalidades**

### **Fase 2 - Importação/Exportação**
- [ ] Importar KML
- [ ] Importar GeoJSON
- [ ] Importar Shapefile
- [ ] Exportar para múltiplos formatos

### **Fase 3 - Edição Avançada**
- [ ] Editar vértices existentes
- [ ] Adicionar/remover vértices
- [ ] Simplificar polígonos
- [ ] Dividir polígonos

### **Fase 4 - Análise**
- [ ] Sobreposição de polígonos
- [ ] Cálculo de interseções
- [ ] Estatísticas por fazenda
- [ ] Relatórios detalhados

## 📞 **Suporte**

Para dúvidas ou problemas:
1. Verificar logs de debug
2. Testar em diferentes condições
3. Reportar com screenshots e logs
4. Incluir informações do dispositivo

---

**Versão**: 1.0.0  
**Última atualização**: Dezembro 2024  
**Compatibilidade**: Flutter 3.0+ | Android 6+ | iOS 12+
