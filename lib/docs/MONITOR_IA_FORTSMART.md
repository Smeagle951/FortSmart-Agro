# 🤖 Monitor de IA FortSmart - FortSmart Agro

## 📋 Visão Geral

O **Monitor de IA FortSmart** é uma tela elegante e profissional para verificar o status, testar predições e monitorar a performance da IA em tempo real.

---

## 🎯 Funcionalidades

### **✅ Status em Tempo Real**
- Verificação automática da conexão com IA FortSmart
- Indicadores visuais de status (online/offline)
- Informações detalhadas sobre modelos carregados
- Atualização automática a cada 30 segundos

### **✅ Testes da IA FortSmart**
- **Teste Rápido**: Dados de exemplo pré-configurados
- **Teste Customizado**: Dados JSON personalizados
- **Resultados Detalhados**: Predições, probabilidades e recomendações
- **Feedback Visual**: Cores e ícones contextuais

### **✅ Métricas e Performance da IA FortSmart**
- Total de predições realizadas
- Taxa de sucesso da IA FortSmart
- Tempo médio de resposta
- Modelos ativos
- Uptime do sistema

---

## 🚀 Como Acessar

### **1. Navegação Direta**
```dart
Navigator.pushNamed(context, '/ai/monitoring');
```

### **2. Botão Flutuante**
```dart
AIMonitorButton(
  showStatus: true,
  isExtended: true,
)
```

### **3. Card de Status**
```dart
AIStatusCard(
  showDetails: true,
  showMonitorButton: true,
)
```

### **4. Widget de Status**
```dart
AIStatusWidget(
  showDetails: true,
  autoRefresh: true,
  refreshInterval: Duration(seconds: 30),
)
```

---

## 🎨 Componentes Disponíveis

### **1. Tela Principal (`AIMonitoringScreen`)**
- ✅ Verificação de status da IA
- ✅ Testes com dados de exemplo
- ✅ Testes com dados customizados
- ✅ Visualização de resultados
- ✅ Informações detalhadas

### **2. Widget de Status (`AIStatusWidget`)**
- ✅ Indicador visual de status
- ✅ Atualização automática
- ✅ Informações detalhadas
- ✅ Controles de refresh

### **3. Widget de Status Compacto (`AIStatusIndicator`)**
- ✅ Indicador minimalista
- ✅ Cores contextuais
- ✅ Ideal para AppBars

### **4. Widget de Métricas (`AIMetricsWidget`)**
- ✅ Métricas de performance
- ✅ Estatísticas de uso
- ✅ Indicadores de qualidade

---

## 🧪 Como Testar a IA

### **Teste Rápido (Recomendado)**
1. Acesse o Monitor de IA
2. Clique em **"Teste Rápido"**
3. Aguarde o processamento
4. Visualize os resultados

**Dados do Teste Rápido:**
```json
{
  "test_id": "test_001",
  "lote_id": "L001",
  "cultura": "Soja",
  "variedade": "BMX Potência RR",
  "subtestes": [
    {
      "subtest_id": "A",
      "registros": [
        {
          "dia": 3,
          "germinadas": 85,
          "nao_germinadas": 15,
          "manchas": 2,
          "podridao": 1,
          "vigor": "Alto",
          "pureza": 98.5
        }
      ]
    }
  ]
}
```

### **Teste Customizado**
1. Acesse o Monitor de IA
2. Cole seus dados JSON no campo
3. Clique em **"Teste Customizado"**
4. Visualize os resultados

**Exemplo de Dados Customizados:**
```json
{
  "test_id": "meu_teste",
  "lote_id": "L123",
  "cultura": "Milho",
  "variedade": "Híbrido 123",
  "subtestes": [
    {
      "subtest_id": "A",
      "registros": [
        {
          "dia": 5,
          "germinadas": 90,
          "nao_germinadas": 10,
          "manchas": 1,
          "podridao": 0,
          "vigor": "Médio",
          "pureza": 95.0
        }
      ]
    }
  ]
}
```

---

## 📊 Interpretando os Resultados

### **Predição de Regressão**
- **Valor**: Percentual de germinação previsto
- **Exemplo**: `87.5%` - Indica 87.5% de germinação esperada
- **Cor**: Verde (excelente), Azul (boa), Laranja (regular), Vermelho (ruim)

### **Predição de Classificação**
- **Valores**: `Excelente`, `Boa`, `Regular`, `Ruim`
- **Baseado em**: Percentual de germinação e qualidade
- **Uso**: Categorização automática para relatórios

### **Probabilidade**
- **Valor**: Confiança da predição (0.0 a 1.0)
- **Exemplo**: `0.85` - 85% de confiança na predição
- **Uso**: Avaliar confiabilidade dos resultados

### **Score de Vigor**
- **Valor**: Pontuação de vigor das sementes
- **Exemplo**: `8.5` - Vigor alto
- **Uso**: Avaliar qualidade das sementes

### **Recomendações**
- **Lista**: Sugestões baseadas na análise
- **Exemplo**: `["Aumentar temperatura", "Verificar umidade"]`
- **Uso**: Orientações para melhorar resultados

---

## 🔧 Configuração e Personalização

### **Atualização Automática**
```dart
AIStatusWidget(
  autoRefresh: true,
  refreshInterval: Duration(seconds: 30),
)
```

### **Detalhes Visíveis**
```dart
AIStatusWidget(
  showDetails: true,  // Mostrar informações detalhadas
)
```

### **Cores Personalizadas**
```dart
AIStatusCard(
  primaryColor: Colors.blue,
  accentColor: Colors.white,
)
```

### **Controles de Refresh**
```dart
AIStatusWidget(
  onStatusChange: () {
    print('Status da IA alterado');
  },
)
```

---

## 🚨 Solução de Problemas

### **IA Offline**
- ✅ Verifique se o backend Python está rodando
- ✅ Execute: `python germination_prediction_endpoint.py`
- ✅ Verifique a porta 5000
- ✅ Teste a conexão manualmente

### **Erro de Conexão**
- ✅ Verifique a URL: `http://localhost:5000`
- ✅ Confirme que o firewall permite a conexão
- ✅ Teste com `curl http://localhost:5000/health`

### **Teste Falhando**
- ✅ Verifique o formato dos dados JSON
- ✅ Confirme que todos os campos obrigatórios estão presentes
- ✅ Teste com dados de exemplo primeiro

### **Resultados Inconsistentes**
- ✅ Verifique se os modelos estão carregados
- ✅ Confirme que os dados de entrada são válidos
- ✅ Teste com dados conhecidos

---

## 📱 Integração com Outras Telas

### **1. Dashboard Principal**
```dart
// Adicionar status da IA
AIStatusCard(
  showDetails: true,
  showMonitorButton: true,
)
```

### **2. Telas de Plantio**
```dart
// Botão para testar IA
AITestButton(
  onTestComplete: () {
    // Ação após teste
  },
)
```

### **3. AppBar com Status**
```dart
AppBar(
  title: Text('Minha Tela'),
  actions: [
    AIStatusAppBarWidget(),
  ],
)
```

### **4. Lista com Status**
```dart
ListTile(
  title: Text('Item'),
  trailing: AIStatusIndicator(
    isOnline: true,
    onTap: () => Navigator.pushNamed(context, '/ai/monitoring'),
  ),
)
```

---

## 🎯 Casos de Uso Práticos

### **1. Verificação Diária**
- Acesse o monitor pela manhã
- Verifique se a IA está online
- Execute um teste rápido
- Confirme que tudo está funcionando

### **2. Teste de Novos Dados**
- Cole dados de um lote específico
- Execute teste customizado
- Analise os resultados
- Compare com expectativas

### **3. Monitoramento de Performance**
- Verifique métricas de uso
- Analise tempo de resposta
- Identifique possíveis problemas
- Otimize configurações

### **4. Demonstração para Clientes**
- Mostre o status da IA
- Execute teste em tempo real
- Explique os resultados
- Demonstre a confiabilidade

---

## 🚀 Próximos Passos

### **Implementação Imediata**
1. ✅ Adicionar monitor em telas principais
2. ✅ Configurar atualização automática
3. ✅ Testar com dados reais
4. ✅ Ajustar interface conforme necessário

### **Evolução Futura**
1. 📋 Histórico de testes
2. 📋 Gráficos de performance
3. 📋 Alertas automáticos
4. 📋 Integração com notificações

---

## 🎉 Benefícios

### **Para o Usuário**
- ✅ **Visibilidade Total**: Status da IA em tempo real
- ✅ **Testes Fáceis**: Interface intuitiva para testes
- ✅ **Resultados Claros**: Visualização elegante dos resultados
- ✅ **Confiança**: Transparência no funcionamento da IA

### **Para o Sistema**
- ✅ **Monitoramento**: Controle total sobre a IA
- ✅ **Debugging**: Identificação rápida de problemas
- ✅ **Performance**: Métricas de uso e eficiência
- ✅ **Manutenção**: Facilita manutenção e atualizações

### **Para o Negócio**
- ✅ **Confiabilidade**: IA sempre funcionando
- ✅ **Transparência**: Clientes veem o funcionamento
- ✅ **Qualidade**: Testes regulares garantem precisão
- ✅ **Diferencial**: Monitoramento profissional da IA

---

**🎯 RESULTADO: Monitor completo e elegante para a IA Python, com interface profissional e funcionalidades avançadas!**
