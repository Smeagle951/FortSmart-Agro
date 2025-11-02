# 📊 ESTRUTURA DE DADOS - MÓDULO TALHÕES

## 🎯 **MODELOS DE DADOS PRINCIPAIS**

---

## 1. 📋 **TalhaoSafraModel**

### **Propriedades:**
```dart
class TalhaoSafraModel {
  final String id;                    // UUID único
  final String nome;                  // Nome do talhão
  final String culturaId;             // ID da cultura
  final List<LatLng> pontos;          // Pontos do polígono
  final double area;                  // Área em hectares
  final double perimetro;             // Perímetro em metros
  final DateTime dataCriacao;         // Data de criação
  final DateTime? dataAtualizacao;    // Data de atualização
  final bool ativo;                   // Status ativo/inativo
  final String? observacoes;          // Observações do talhão
  final Color corCultura;             // Cor da cultura
  final String? safraId;              // ID da safra
  final String? fazendaId;            // ID da fazenda
}
```

### **Métodos:**
```dart
TalhaoSafraModel copyWith({...})      // Cria cópia com alterações
Map<String, dynamic> toMap()          // Converte para Map
TalhaoSafraModel.fromMap(Map map)     // Cria a partir de Map
String toJson()                       // Converte para JSON
TalhaoSafraModel.fromJson(String json) // Cria a partir de JSON
```

---

## 2. 🌱 **CulturaModel**

### **Propriedades:**
```dart
class CulturaModel {
  final String id;                    // ID único
  final String name;                  // Nome da cultura
  final String description;           // Descrição
  final Color color;                  // Cor da cultura
  final String? iconPath;             // Caminho do ícone
  final bool ativo;                   // Status ativo
  final DateTime dataCriacao;         // Data de criação
}
```

### **Métodos:**
```dart
Widget getIconOrInitial({double size = 24})  // Retorna ícone ou inicial
CulturaModel copyWith({...})                 // Cria cópia com alterações
Map<String, dynamic> toMap()                 // Converte para Map
```

---

## 3. 🗺️ **TalhaoModel** (Legado)

### **Propriedades:**
```dart
class TalhaoModel {
  final String id;                    // ID único
  final String name;                  // Nome do talhão
  final List<LatLng> points;          // Pontos do polígono
  final double area;                  // Área em hectares
  final double perimeter;             // Perímetro em metros
  final String? culturaId;            // ID da cultura
  final Color? color;                 // Cor do talhão
  final DateTime? createdAt;          // Data de criação
  final String? observacoes;          // Observações
}
```

---

## 4. 📐 **PoligonoModel**

### **Propriedades:**
```dart
class PoligonoModel {
  final String id;                    // ID único
  final List<LatLng> pontos;          // Pontos do polígono
  final double area;                  // Área calculada
  final double perimetro;             // Perímetro calculado
  final String metodo;                // Método de criação
  final DateTime dataCriacao;         // Data de criação
  final Map<String, dynamic> metadados; // Metadados adicionais
}
```

---

## 🗄️ **ESTRUTURA DO BANCO DE DADOS**

### **Tabela: talhao_safra**
```sql
CREATE TABLE talhao_safra (
  id TEXT PRIMARY KEY,                -- UUID único
  nome TEXT NOT NULL,                 -- Nome do talhão
  cultura_id TEXT,                    -- ID da cultura
  pontos TEXT NOT NULL,               -- JSON dos pontos
  area REAL NOT NULL,                 -- Área em hectares
  perimetro REAL NOT NULL,            -- Perímetro em metros
  data_criacao TEXT NOT NULL,         -- Data de criação (ISO)
  data_atualizacao TEXT,              -- Data de atualização (ISO)
  ativo INTEGER NOT NULL DEFAULT 1,   -- Status (1=ativo, 0=inativo)
  observacoes TEXT,                   -- Observações
  cor_cultura TEXT,                   -- Cor em hex
  safra_id TEXT,                      -- ID da safra
  fazenda_id TEXT,                    -- ID da fazenda
  created_at TEXT NOT NULL,           -- Timestamp de criação
  updated_at TEXT                     -- Timestamp de atualização
);
```

### **Tabela: culturas**
```sql
CREATE TABLE culturas (
  id TEXT PRIMARY KEY,                -- ID único
  nome TEXT NOT NULL,                 -- Nome da cultura
  descricao TEXT,                     -- Descrição
  cor TEXT NOT NULL,                  -- Cor em hex
  icone TEXT,                         -- Caminho do ícone
  ativo INTEGER NOT NULL DEFAULT 1,   -- Status
  data_criacao TEXT NOT NULL,         -- Data de criação
  created_at TEXT NOT NULL,           -- Timestamp
  updated_at TEXT                     -- Timestamp
);
```

---

## 📊 **ESTRUTURA DE ESTADO DO CONTROLLER**

### **Estado do Mapa:**
```dart
LatLng? _userLocation;                // Localização do usuário
MapController? _mapController;        // Controlador do mapa
bool _showPopup;                      // Mostrar popup
bool _isDrawing;                      // Modo desenho ativo
bool _showActionButtons;              // Mostrar botões de ação
```

### **Estado de Desenho:**
```dart
List<LatLng> _currentPoints;          // Pontos atuais do polígono
List<Map<String, dynamic>> _polygons; // Polígonos desenhados
List<TalhaoModel> _existingTalhoes;   // Talhões existentes
bool _isAdvancedEditing;              // Modo edição avançada
```

### **Estado de GPS:**
```dart
bool _isAdvancedGpsTracking;          // GPS walk mode ativo
bool _isAdvancedGpsPaused;            // GPS pausado
double _advancedGpsDistance;          // Distância percorrida
double _advancedGpsAccuracy;          // Precisão do GPS
String _advancedGpsStatus;            // Status do GPS
DateTime? _trackingStartTime;         // Hora de início
DateTime? _lastGpsUpdate;             // Última atualização
```

### **Estado de Cálculos:**
```dart
double _currentAreaHa;                // Área atual em hectares
double _currentPerimeterM;            // Perímetro atual em metros
double _currentSpeedKmh;              // Velocidade atual
Duration _elapsedTime;                // Tempo decorrido
double _currentArea;                  // Área calculada
double _currentPerimeter;             // Perímetro calculado
double _currentDistance;              // Distância calculada
```

### **Estado de Culturas:**
```dart
List<CulturaModel> _culturas;         // Lista de culturas
CulturaModel? _selectedCultura;       // Cultura selecionada
bool _isLoadingCulturas;              // Carregando culturas
```

### **Estado de Salvamento:**
```dart
bool _isSaving;                       // Salvando talhão
String _polygonName;                  // Nome do polígono
```

---

## 🔄 **ESTRUTURA DE CALLBACKS E LISTENERS**

### **Callbacks do GPS Walk Service:**
```dart
onPointsChanged: (List<LatLng> points) => void
onAreaChanged: (double area) => void
onPerimeterChanged: (double perimeter) => void
onDistanceChanged: (double distance) => void
onSpeedChanged: (double speed) => void
onAccuracyChanged: (double accuracy) => void
onStatusChanged: (String status) => void
onTrackingStateChanged: (bool isTracking) => void
```

### **Callbacks do Editor Avançado:**
```dart
onPointsChanged: (List<LatLng> points) => void
onMetricsChanged: (double area, double perimeter) => void
```

### **Callbacks do Card Informativo:**
```dart
onEdit: () => void
onDelete: () => void
onViewDetails: () => void
onClose: () => void
```

---

## 📋 **ESTRUTURA DE CONFIGURAÇÕES**

### **Configurações de GPS:**
```dart
static const Duration _timeoutGps = Duration(seconds: 10);
static const double _zoomDefault = 15.0;
static const double _minDistance = 2.0;        // Distância mínima entre pontos
static const double _maxAccuracy = 10.0;       // Precisão máxima aceita
```

### **Configurações de Cálculo:**
```dart
static const double _earthRadius = 6371000.0;  // Raio da Terra em metros
static const double _hectareConversion = 10000.0; // Conversão m² para ha
```

### **Configurações de Interface:**
```dart
static const double _cardWidth = 320.0;        // Largura do card
static const double _markerSize = 30.0;        // Tamanho dos marcadores
static const Duration _animationDuration = Duration(milliseconds: 300);
```

---

## 🎯 **ESTRUTURA DE VALIDAÇÃO**

### **Validação de Polígono:**
```dart
bool isValidPolygon(List<LatLng> points) {
  return points.length >= 3 &&           // Mínimo 3 pontos
         !_isSelfIntersecting(points) && // Não auto-intersecta
         _hasValidCoordinates(points);   // Coordenadas válidas
}
```

### **Validação de Talhão:**
```dart
bool isValidTalhao(TalhaoSafraModel talhao) {
  return talhao.nome.isNotEmpty &&       // Nome obrigatório
         talhao.pontos.length >= 3 &&    // Mínimo 3 pontos
         talhao.area > 0 &&              // Área positiva
         talhao.perimetro > 0;           // Perímetro positivo
}
```

### **Validação de Cultura:**
```dart
bool isValidCultura(CulturaModel cultura) {
  return cultura.name.isNotEmpty &&      // Nome obrigatório
         cultura.color != null &&        // Cor obrigatória
         cultura.ativo;                  // Deve estar ativa
}
```

---

## 📊 **ESTRUTURA DE MÉTRICAS**

### **Métricas de Performance:**
```dart
class PerformanceMetrics {
  final Duration initializationTime;    // Tempo de inicialização
  final Duration gpsStartTime;          // Tempo para iniciar GPS
  final Duration calculationTime;       // Tempo de cálculo
  final Duration saveTime;              // Tempo de salvamento
  final int pointsCount;                // Número de pontos
  final double accuracy;                // Precisão média
}
```

### **Métricas de Qualidade:**
```dart
class QualityMetrics {
  final double areaAccuracy;            // Precisão da área
  final double perimeterAccuracy;       // Precisão do perímetro
  final double gpsAccuracy;             // Precisão do GPS
  final int validPoints;                // Pontos válidos
  final int totalPoints;                // Total de pontos
}
```

---

## 🎉 **RESUMO DA ESTRUTURA**

### **📋 Modelos Principais:**
- **TalhaoSafraModel** - Modelo principal do talhão
- **CulturaModel** - Modelo da cultura
- **PoligonoModel** - Modelo do polígono

### **🗄️ Banco de Dados:**
- **talhao_safra** - Tabela principal de talhões
- **culturas** - Tabela de culturas

### **📊 Estado:**
- **Mapa** - Localização e controle
- **Desenho** - Pontos e polígonos
- **GPS** - Rastreamento e métricas
- **Cálculos** - Área, perímetro, distância
- **Culturas** - Lista e seleção
- **Salvamento** - Estado de persistência

### **🔄 Callbacks:**
- **GPS** - Atualizações em tempo real
- **Editor** - Mudanças de pontos
- **Card** - Ações do usuário

**🎯 Esta estrutura fornece a base completa de dados para recriar o módulo de talhões!**
