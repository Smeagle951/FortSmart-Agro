# 📊 Módulo de Monitoramento e Mapa de Infestação - FortSmart Agro

## 🎯 **O QUE O MÓDULO DE MONITORAMENTO FAZ**

### **1. Coleta de Dados em Campo**
- **GPS Tracking**: Registra pontos geográficos durante a caminhada no talhão
- **Ocorrências**: Identifica pragas, doenças, plantas daninhas e deficiências
- **Índice de Infestação**: Avalia a severidade de cada ocorrência (0-100%)
- **Fotos e Áudio**: Documenta visualmente as ocorrências encontradas
- **Seções Afetadas**: Especifica quais partes da planta foram afetadas (superior, médio, inferior)

### **2. Processamento de Dados**
- **Cálculo de Severidade**: Analisa a média de infestação de todos os pontos
- **Classificação**: Determina se a infestação é leve, média, grave ou crítica
- **Identificação de Padrões**: Identifica as principais ocorrências por talhão
- **Geração de Alertas**: Cria alertas automáticos para situações críticas

### **3. Integração com Outros Módulos**
- **Mapa de Infestação**: Envia dados para visualização geográfica
- **Histórico**: Armazena dados para análise temporal
- **Relatórios**: Gera relatórios técnicos e gerenciais
- **Alertas**: Notifica sobre situações que requerem atenção

---

## 🗺️ **COMO O MAPA DE INFESTAÇÃO FUNCIONA**

### **1. Visualização Geográfica**
- **Pontos no Mapa**: Cada ponto de monitoramento é marcado no mapa
- **Cores por Severidade**: 
  - 🟢 **Verde**: Baixa infestação (0-25%)
  - 🟡 **Amarelo**: Média infestação (26-50%)
  - 🟠 **Laranja**: Alta infestação (51-75%)
  - 🔴 **Vermelho**: Crítica infestação (76-100%)

### **2. Classificação de Severidade**

#### **Níveis de Severidade (SeveridadeLevel)**
```dart
enum SeveridadeLevel {
  BAIXO,      // 0-25%   - Verde
  MODERADO,   // 26-50%  - Amarelo  
  ALTO,       // 51-75%  - Laranja
  CRITICO     // 76-100% - Vermelho
}
```

#### **Cálculo de Severidade**
```dart
// Base: Índice de infestação (0-100%)
int severidade = occurrence.infestationIndex.round();

// Multiplicadores por tipo de ocorrência:
switch (occurrence.type) {
  case OccurrenceType.pest:
    severidade *= 2;      // Pragas são mais críticas
  case OccurrenceType.disease:
    severidade *= 3;      // Doenças são muito críticas
  case OccurrenceType.weed:
    severidade *= 1;      // Plantas daninhas são menos críticas
  case OccurrenceType.deficiency:
    severidade *= 2;      // Deficiências são críticas
}
```

### **3. Pontos Críticos no Mapa**

#### **O que é considerado "Crítico"**
- **Severidade ≥ 75%**: Infestação crítica (vermelho no mapa)
- **Doenças**: Qualquer doença com índice ≥ 50% é considerada crítica
- **Pragas**: Pragas com índice ≥ 60% são consideradas críticas
- **Múltiplas Ocorrências**: Pontos com várias ocorrências simultâneas

#### **Como são identificados**
```dart
// Verifica se há ocorrências críticas
bool hasCriticalOccurrences = occurrences.any((occ) => 
  occ.infestationIndex >= 75 || 
  (occ.type == OccurrenceType.disease && occ.infestationIndex >= 50) ||
  (occ.type == OccurrenceType.pest && occ.infestationIndex >= 60)
);
```

---

## 🔄 **FLUXO DE DADOS: MONITORAMENTO → MAPA**

### **1. Coleta no Campo**
```
Monitoramento → Pontos GPS → Ocorrências → Índices de Infestação
```

### **2. Processamento**
```
InfestacaoIntegrationService.processMonitoringForInfestation()
├── Calcula severidade média
├── Identifica principais problemas  
├── Atualiza resumo do talhão
└── Gera alertas se necessário
```

### **3. Visualização no Mapa**
```
TalhaoResumoModel → Mapa de Infestação → Cores por Severidade
```

---

## 📊 **DADOS ENVIADOS PELO MONITORAMENTO**

### **Estrutura de Dados**
```dart
class Monitoring {
  String id;
  int plotId;                    // ID do talhão
  String plotName;               // Nome do talhão
  List<MonitoringPoint> points;  // Pontos coletados
  DateTime date;                 // Data do monitoramento
  bool isCompleted;              // Status de conclusão
}

class MonitoringPoint {
  String id;
  double latitude;               // Coordenada GPS
  double longitude;              // Coordenada GPS
  List<Occurrence> occurrences;  // Ocorrências encontradas
  List<String> imagePaths;       // Fotos tiradas
  String? audioPath;             // Áudio gravado
}

class Occurrence {
  OccurrenceType type;           // PEST, DISEASE, WEED, DEFICIENCY
  String name;                   // Nome da ocorrência
  double infestationIndex;       // Índice 0-100%
  List<PlantSection> affectedSections; // Partes afetadas
  String? notes;                 // Observações
}
```

### **Tipos de Ocorrências**
- **PEST**: Pragas (lagartas, percevejos, etc.)
- **DISEASE**: Doenças (ferrugem, manchas, etc.)
- **WEED**: Plantas daninhas
- **DEFICIENCY**: Deficiências nutricionais
- **OTHER**: Outras ocorrências

---

## 🎨 **REPRESENTAÇÃO VISUAL NO MAPA**

### **Cores e Significados**
- **🟢 Verde (0-25%)**: Infestação baixa, situação controlada
- **🟡 Amarelo (26-50%)**: Infestação moderada, atenção necessária
- **🟠 Laranja (51-75%)**: Infestação alta, ação imediata recomendada
- **🔴 Vermelho (76-100%)**: Infestação crítica, ação urgente necessária

### **Marcadores no Mapa**
- **Tamanho**: Pontos maiores = maior severidade
- **Cor**: Baseada no nível de severidade
- **Ícone**: Diferente para cada tipo de ocorrência
- **Tooltip**: Mostra detalhes ao clicar

### **Filtros Disponíveis**
- **Por Severidade**: Baixa, Média, Alta, Crítica
- **Por Tipo**: Pragas, Doenças, Plantas Daninhas
- **Por Data**: Período específico
- **Por Talhão**: Talhão específico

---

## ⚠️ **SISTEMA DE ALERTAS**

### **Alertas Automáticos**
- **Crítico**: Severidade ≥ 75% → Notificação urgente
- **Alto**: Severidade ≥ 50% → Aviso de atenção
- **Múltiplas Ocorrências**: Várias pragas/doenças simultâneas
- **Tendência Crescente**: Aumento de severidade ao longo do tempo

### **Notificações**
- **Push Notification**: Alertas em tempo real
- **Email**: Relatórios diários/semanais
- **Dashboard**: Indicadores visuais
- **Relatórios**: Documentação técnica

---

## 🔧 **CONFIGURAÇÕES E PERSONALIZAÇÃO**

### **Limites Configuráveis**
```dart
// Limites de severidade (configuráveis)
const double CRITICAL_THRESHOLD = 75.0;  // Crítico
const double HIGH_THRESHOLD = 50.0;      // Alto
const double MODERATE_THRESHOLD = 25.0;  // Moderado
```

### **Multiplicadores por Cultura**
- **Soja**: Doenças mais críticas (×3)
- **Milho**: Pragas mais críticas (×2.5)
- **Algodão**: Pragas e doenças equilibradas (×2)

### **Ajustes Sazonais**
- **Período Chuvoso**: Doenças mais críticas
- **Período Seco**: Pragas mais críticas
- **Floração**: Pragas de grãos mais críticas

---

## 📈 **ANÁLISE E RELATÓRIOS**

### **Métricas Calculadas**
- **Severidade Média**: Média ponderada de todas as ocorrências
- **Principais Problemas**: Top 3 ocorrências mais frequentes
- **Tendência Temporal**: Evolução da infestação ao longo do tempo
- **Distribuição Espacial**: Concentração de problemas por região

### **Relatórios Gerados**
- **Relatório Técnico**: Dados detalhados para agrônomos
- **Relatório Gerencial**: Resumo executivo para gestores
- **Relatório de Campo**: Dados para aplicação de produtos
- **Relatório Histórico**: Evolução temporal da infestação

---

## ✅ **VERIFICAÇÃO DE INTEGRIDADE**

### **Dados Enviados Corretamente**
- ✅ **Coordenadas GPS**: Latitude e longitude precisas
- ✅ **Índices de Infestação**: Valores entre 0-100%
- ✅ **Tipos de Ocorrência**: Classificação correta
- ✅ **Datas**: Timestamps precisos
- ✅ **Fotos**: Imagens associadas aos pontos

### **Processamento no Mapa**
- ✅ **Cálculo de Severidade**: Algoritmo correto
- ✅ **Classificação**: Níveis bem definidos
- ✅ **Cores**: Representação visual adequada
- ✅ **Alertas**: Geração automática funcionando

---

## 🚀 **PRÓXIMOS PASSOS**

### **Melhorias Planejadas**
1. **IA para Identificação**: Reconhecimento automático de pragas/doenças
2. **Predição**: Antecipação de surtos baseada em dados históricos
3. **Integração Climática**: Correlação com dados meteorológicos
4. **Alertas Inteligentes**: Notificações baseadas em padrões

### **Funcionalidades Adicionais**
- **Heatmap**: Visualização de densidade de infestação
- **Análise 3D**: Visualização tridimensional dos talhões
- **Comparação Temporal**: Evolução da infestação
- **Recomendações Automáticas**: Sugestões de tratamento

---

## 📞 **SUPORTE E MANUTENÇÃO**

### **Logs e Debug**
- **Logs Detalhados**: Rastreamento completo do fluxo de dados
- **Validação**: Verificação de integridade dos dados
- **Correção Automática**: Reparo de dados corrompidos
- **Backup**: Preservação de dados históricos

### **Monitoramento de Performance**
- **Tempo de Processamento**: Otimização de algoritmos
- **Uso de Memória**: Gestão eficiente de recursos
- **Sincronização**: Coordenação entre módulos
- **Escalabilidade**: Suporte a grandes volumes de dados
