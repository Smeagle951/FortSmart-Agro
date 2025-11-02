# 🐛 Sistema Integrado de Monitoramento - FortSmart Agro

## 🎯 **VISÃO GERAL**

O Sistema Integrado de Monitoramento conecta automaticamente:
- **Ponto de Monitoramento** → **Catálogo de Organismos** → **Mapa de Infestação**

Permitindo que o técnico informe números (ex: 20 bicudos) e o sistema automaticamente:
1. Identifica o organismo no catálogo
2. Calcula a porcentagem baseada nos limiares
3. Atualiza o mapa de infestação em tempo real
4. Exibe alertas históricos

---

## 🔄 **COMO FUNCIONA**

### **1. Entrada de Dados**
```
Técnico informa: "bicudo" + "20" + "algodao"
↓
Sistema busca no catálogo: "Bicudo do Algodoeiro"
↓
Calcula porcentagem: 20 bicudos = 40% (baseado no limiar)
↓
Determina alerta: "Médio" (laranja)
↓
Atualiza mapa: Mostra ícone 🐛 laranja no talhão
```

### **2. Fluxo Completo**
```
📱 Ponto de Monitoramento
├── Digite organismo: "bicudo"
├── Informe quantidade: "20"
├── Sistema identifica automaticamente
└── Calcula: 20 bicudos = 40% infestação

📚 Catálogo de Organismos
├── Busca por nome: "bicudo"
├── Filtra por cultura: "algodao"
├── Obtém limiares: baixo=5, médio=15, alto=30
└── Calcula porcentagem: (20/30)*100 = 66.7%

🗺️ Mapa de Infestação
├── Recebe dados processados
├── Atualiza visualização térmica
├── Mostra ícone 🐛 com cor laranja
└── Exibe alerta: "Alto nível de infestação"
```

---

## 🛠️ **COMPONENTES IMPLEMENTADOS**

### **1. IntegratedMonitoringService**
```dart
// Serviço principal que integra tudo
final service = IntegratedMonitoringService();

// Processa ocorrência
final result = await service.processOccurrence(
  organismName: "bicudo",
  quantity: 20,
  cropName: "algodao",
  fieldId: "talhao_001",
  notes: "Encontrado nas bordas"
);

// Resultado: ProcessedOccurrence com:
// - organismName: "Bicudo do Algodoeiro"
// - normalizedPercentage: 66.7
// - alertLevel: "alto"
// - alertColor: "#F44336"
// - icon: "🐛"
```

### **2. OccurrenceInputWidget**
```dart
// Widget para entrada de ocorrências
OccurrenceInputWidget(
  cropName: "algodao",
  fieldId: "talhao_001",
  historicalAlerts: alerts,
  onOccurrenceAdded: (occurrence) {
    // Callback quando ocorrência é registrada
  },
)
```

### **3. ThermalInfestationMap**
```dart
// Widget do mapa térmico
ThermalInfestationMap(
  fieldId: "talhao_001",
  fieldPolygon: polygon,
  fieldName: "Talhão 1",
  cropName: "Algodão",
  mapHeight: 300,
  showLegend: true,
  onOrganismTap: (organismId) {
    // Callback quando organismo é clicado
  },
)
```

---

## 🎨 **VISUALIZAÇÃO TÉRMICA**

### **Cores e Significados**
- **🟢 Verde (0-25%)**: Infestação baixa
- **🟡 Laranja (26-50%)**: Infestação média  
- **🔴 Vermelho (51-75%)**: Infestação alta
- **🟣 Roxo (76-100%)**: Infestação crítica

### **Ícones por Tipo**
- **🐛 Pragas**: Lagartas, percevejos, bicudos
- **🦠 Doenças**: Ferrugem, manchas, murchas
- **🌿 Plantas Daninhas**: Buva, capim-amargoso
- **🌱 Deficiências**: Nutricionais, hídricas

### **Mapa Interativo**
- **Marcadores coloridos** com ícones dos organismos
- **Opacidade** baseada na intensidade da infestação
- **Clique** para ver detalhes do organismo
- **Legenda** explicativa das cores

---

## 📊 **EXEMPLO DE USO**

### **Cenário: Monitoramento de Algodão**

#### **1. Técnico encontra bicudo**
```
Entrada: "bicudo" + "20"
↓
Sistema identifica: "Bicudo do Algodoeiro"
↓
Limiares do catálogo: baixo=5, médio=15, alto=30
↓
Cálculo: (20/30)*100 = 66.7%
↓
Classificação: "Alto" (vermelho)
```

#### **2. Mapa é atualizado**
```
- Ícone 🐛 vermelho aparece no talhão
- Opacidade 70% (baseada na porcentagem)
- Lista mostra: "Bicudo do Algodoeiro - 66.7% - ALTO"
```

#### **3. Próximo monitoramento**
```
Sistema mostra alerta histórico:
"⚠️ 3 infestações de Bicudo do Algodoeiro (média: 45.2%)"
```

---

## 🔧 **INTEGRAÇÃO COM CATÁLOGO**

### **Busca Inteligente**
```dart
// Busca por nome exato primeiro
var organisms = await catalogService.searchOrganisms("bicudo");

// Filtra por cultura
organisms = organisms.where((org) => 
  org.cultura.toLowerCase().contains("algodao")
).toList();

// Busca por similaridade se não encontrou
if (organisms.isEmpty) {
  final allOrganisms = await catalogService.getAllOrganisms();
  organisms = allOrganisms.where((org) =>
    org.nome.toLowerCase().contains("bicudo") ||
    "bicudo".contains(org.nome.toLowerCase())
  ).toList();
}
```

### **Cálculo de Porcentagem**
```dart
double calculateNormalizedPercentage(int quantity, OrganismCatalogItem organism) {
  // Usa limiar alto como referência para 100%
  final referenceThreshold = organism.limiarAlto;
  
  if (referenceThreshold <= 0) return 0.0;
  
  double percentage = (quantity / referenceThreshold) * 100;
  return percentage > 100 ? 100.0 : percentage;
}
```

---

## 📱 **TELA INTEGRADA**

### **IntegratedMonitoringScreen**
Combina todos os componentes em uma tela única:

1. **Mapa de Infestação** (topo)
   - Visualização térmica do talhão
   - Marcadores coloridos com ícones
   - Legenda explicativa

2. **Widget de Entrada** (meio)
   - Campo para nome do organismo
   - Campo para quantidade
   - Sugestões automáticas
   - Alertas históricos

3. **Lista de Ocorrências** (baixo)
   - Ocorrências registradas na sessão
   - Porcentagens calculadas
   - Níveis de alerta

---

## 🚀 **COMO IMPLEMENTAR**

### **1. Adicionar à tela existente**
```dart
// No seu ponto de monitoramento
OccurrenceInputWidget(
  cropName: widget.cropName,
  fieldId: widget.fieldId,
  onOccurrenceAdded: (occurrence) {
    // Atualizar UI
    setState(() {
      _occurrences.add(occurrence);
    });
  },
)
```

### **2. Mostrar mapa de infestação**
```dart
ThermalInfestationMap(
  fieldId: widget.fieldId,
  fieldPolygon: widget.fieldPolygon,
  fieldName: widget.fieldName,
  cropName: widget.cropName,
)
```

### **3. Escutar atualizações**
```dart
// Escutar mudanças em tempo real
monitoringService.updateStream.listen((update) {
  if (update.type == 'occurrence_added') {
    // Atualizar lista
  } else if (update.type == 'map_updated') {
    // Atualizar mapa
  }
});
```

---

## 📋 **BENEFÍCIOS**

### **Para o Técnico**
- ✅ **Entrada simples**: Apenas nome + número
- ✅ **Identificação automática**: Sistema encontra no catálogo
- ✅ **Cálculo automático**: Porcentagem calculada automaticamente
- ✅ **Feedback visual**: Mapa atualizado em tempo real
- ✅ **Alertas históricos**: Informações de monitoramentos anteriores

### **Para o Sistema**
- ✅ **Dados consistentes**: Baseado no catálogo oficial
- ✅ **Cálculos precisos**: Usando limiares científicos
- ✅ **Visualização clara**: Mapa térmico informativo
- ✅ **Histórico completo**: Rastreamento de infestações
- ✅ **Integração total**: Conecta todos os módulos

---

## 🎯 **PRÓXIMOS PASSOS**

1. **Integrar com tela existente** de ponto de monitoramento
2. **Adicionar mais organismos** ao catálogo
3. **Implementar filtros** por data, cultura, tipo
4. **Adicionar relatórios** de infestação
5. **Implementar notificações** para infestações críticas

---

## 📞 **SUPORTE**

Para dúvidas ou problemas:
- Verifique se o catálogo de organismos está carregado
- Confirme se os limiares estão configurados
- Verifique a conexão com o banco de dados
- Consulte os logs para erros específicos

**Sistema pronto para uso! 🚀**
