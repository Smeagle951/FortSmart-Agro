# 🌱 Submódulo: Evolução Fenológica

## 📋 Visão Geral

O submódulo **Evolução Fenológica** é um sistema inteligente de acompanhamento do desenvolvimento vegetativo das culturas agrícolas. Ele transforma dados brutos de campo em diagnósticos agronômicos precisos, gráficos de evolução e alertas inteligentes.

## 🎯 Funcionalidades Principais

### 1️⃣ Registro Quinzenal Inteligente
- ✅ Coleta simplificada de dados de campo (altura, estande, vagens, sanidade, etc.)
- ✅ Captura de fotos para documentação visual
- ✅ Geolocalização automática do ponto de coleta
- ✅ Validação automática de dados inconsistentes

### 2️⃣ Classificação Automática de Estágios Fenológicos
- ✅ Identificação automática do estágio BBCH baseado em:
  - Altura média das plantas
  - Número de folhas expandidas
  - Presença de estruturas reprodutivas (vagens, espigas, etc.)
  - Dias após emergência (DAE)
- ✅ Suporte para múltiplas culturas:
  - 🌾 Soja → V1, V2, V4, R1, R3, R5, R7, R8, R9
  - 🌽 Milho → V4, V6, VT, R1, R3, R6
  - 🌿 Feijão → V2, V3, R5, R6, R8, R9
  - ➕ Extensível para outras culturas

### 3️⃣ Curvas de Crescimento e Gráficos Evolutivos
- 📊 **Gráfico de Altura x Dias**: Visualize a evolução do crescimento vegetativo
- 📊 **Gráfico de Vagens/Espigas x Dias**: Acompanhe o desenvolvimento reprodutivo
- 📊 **Gráfico de Estande x Tempo**: Monitore a mortalidade de plantas
- 📊 **Gráfico de Sanidade x Dias**: Identifique problemas fitossanitários precocemente

### 4️⃣ Comparação com Padrões de Referência
- ✅ Banco de dados de referência por cultura
- ✅ Comparação automática: "Altura média 10% abaixo do esperado para 25 DAE"
- ✅ Indicadores visuais de status (dentro, acima, abaixo do padrão)

### 5️⃣ Alertas Inteligentes
- 🚨 **Alertas de Crescimento**: Detecção de crescimento abaixo do esperado
- 🚨 **Alertas de Estande**: Mortalidade acima de limites aceitáveis
- 🚨 **Alertas de Sanidade**: Problemas fitossanitários identificados
- 🚨 **Alertas Nutricionais**: Sintomas de deficiência nutricional

### 6️⃣ Dashboard Dinâmico em Tempo Real
- 📈 Indicadores-chave por talhão:
  - Altura média atual
  - Estágio fenológico atual
  - Estande real (%)
  - Vagens/planta (culturas leguminosas)
  - Sanidade (% plantas sadias)
  - Desvio em relação ao padrão esperado

### 7️⃣ Previsão de Produtividade
- 🎯 Estimativa dinâmica baseada em:
  - Estande real
  - Vagens/planta (ou espigas/planta)
  - Sementes/vagem (ou grãos/espiga)
  - Peso médio de grão
- 🎯 Atualização automática a cada novo registro

## 📁 Estrutura do Submódulo

```
phenological_evolution/
├── models/                              # Modelos de dados
│   ├── phenological_record_model.dart   # Registro quinzenal
│   ├── phenological_stage_model.dart    # Estágios BBCH
│   ├── growth_curve_model.dart          # Curvas de crescimento
│   └── phenological_alert_model.dart    # Alertas gerados
│
├── database/                            # Persistência de dados
│   ├── daos/
│   │   ├── phenological_record_dao.dart
│   │   ├── phenological_stage_dao.dart
│   │   └── reference_data_dao.dart
│   └── phenological_database.dart
│
├── providers/                           # Gerenciamento de estado
│   └── phenological_provider.dart
│
├── services/                            # Lógica de negócio
│   ├── phenological_classification_service.dart  # Classificação BBCH
│   ├── growth_analysis_service.dart              # Análise de crescimento
│   ├── productivity_estimation_service.dart      # Estimativa de produtividade
│   └── phenological_alert_service.dart           # Sistema de alertas
│
├── screens/                             # Telas do módulo
│   ├── phenological_main_screen.dart             # Dashboard principal
│   ├── phenological_record_screen.dart           # Registro quinzenal
│   ├── phenological_history_screen.dart          # Histórico e evolução
│   ├── phenological_comparison_screen.dart       # Comparação com padrões
│   └── widgets/
│       ├── phenological_dashboard_widget.dart
│       ├── growth_chart_widget.dart
│       ├── stage_indicator_widget.dart
│       └── record_form_widget.dart
│
└── widgets/                             # Widgets reutilizáveis
    ├── phenological_card_widget.dart
    ├── alert_banner_widget.dart
    └── productivity_estimate_widget.dart
```

## 🔧 Arquitetura e Padrões

### Clean Architecture
- **Models**: Entidades puras de domínio
- **DAOs**: Camada de acesso a dados
- **Services**: Lógica de negócio isolada
- **Providers**: Gerenciamento de estado com ChangeNotifier
- **Screens**: Camada de apresentação

### Padrões Utilizados
- ✅ Repository Pattern (DAOs)
- ✅ Provider Pattern (Estado)
- ✅ Service Pattern (Lógica de negócio)
- ✅ Factory Pattern (Criação de modelos)
- ✅ Strategy Pattern (Diferentes cálculos por cultura)

## 🚀 Como Usar

### 1. Registro Quinzenal
```dart
// Navegar para tela de registro
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PhenologicalRecordScreen(
      talhaoId: talhaoId,
      culturaId: culturaId,
    ),
  ),
);
```

### 2. Visualizar Dashboard
```dart
// Dashboard integrado com gráficos e alertas
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PhenologicalMainScreen(
      talhaoId: talhaoId,
    ),
  ),
);
```

### 3. Integração com Estande de Plantas
```dart
// Botão na tela de Estande de Plantas
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhenologicalMainScreen(
          talhaoId: _talhaoSelecionado.id,
          culturaId: _culturaSelecionada.id,
        ),
      ),
    );
  },
  icon: Icon(Icons.timeline),
  label: Text('📈 Evolução Fenológica'),
)
```

## 📊 Fórmulas e Cálculos

### Classificação de Estágio Fenológico (Soja)
```dart
if (numFolhasTrifolioladas >= 1) {
  estagio = 'V${numFolhasTrifolioladas}';
} else if (presencaFlores) {
  estagio = 'R1';
} else if (presencaVagens && comprimentoVagem < 1.5) {
  estagio = 'R3';
} else if (comprimentoVagem >= 1.5 && comprimentoVagem < 2.0) {
  estagio = 'R5';
}
// ... e assim por diante
```

### Estimativa de Produtividade
```dart
Produtividade (kg/ha) = (
  Estande Real (plantas/ha) × 
  Vagens por Planta × 
  Sementes por Vagem × 
  Peso Médio de Grão (g)
) ÷ 1000
```

### Desvio em Relação ao Padrão
```dart
Desvio (%) = ((Valor Real - Valor Esperado) / Valor Esperado) × 100
```

## 🎨 Paleta de Cores (Status)

- 🟢 **Verde** (#4CAF50): Dentro do esperado (desvio < 10%)
- 🟠 **Laranja** (#FF9800): Atenção (desvio entre 10-20%)
- 🔴 **Vermelho** (#F44336): Crítico (desvio > 20%)
- 🔵 **Azul** (#2196F3): Acima do esperado (positivo)

## 🔄 Integração com Outros Módulos

### Estande de Plantas
- ✅ Usa dados de estande para cálculo de produtividade
- ✅ Compartilha informações de talhão e cultura

### Monitoramento
- ✅ Pode receber dados de sanidade do monitoramento
- ✅ Não deve referenciar organismos (conforme memória 8743822)

### Colheita (Futuro)
- ✅ Fornece estimativa de produtividade para planejamento
- ✅ Compara produtividade estimada vs real

## 📝 Notas de Desenvolvimento

### ⚠️ IMPORTANTE: Rotas NÃO Conectadas
- As rotas deste submódulo **NÃO** estão conectadas ao sistema de rotas principal
- Isso evita erros de compilação durante o desenvolvimento
- Para ativar: descomentar as rotas no arquivo `lib/routes.dart`

### 🔗 Como Conectar as Rotas (Futuro)
1. Abrir `lib/routes.dart`
2. Adicionar as rotas do submódulo:
```dart
// Evolução Fenológica
'/phenological/main': (context) => PhenologicalMainScreen(),
'/phenological/record': (context) => PhenologicalRecordScreen(),
'/phenological/history': (context) => PhenologicalHistoryScreen(),
```

## 🧪 Testes

### Testes Unitários
- ✅ Testes de classificação BBCH por cultura
- ✅ Testes de cálculo de produtividade
- ✅ Testes de geração de alertas

### Testes de Integração
- ✅ Integração com banco de dados
- ✅ Integração com módulo de Estande

## 📈 Próximas Evoluções

- [ ] Integração com sensoriamento remoto (NDVI)
- [ ] Machine Learning para previsão de estágios
- [ ] Exportação de relatórios PDF
- [ ] Comparação entre talhões
- [ ] Benchmark com safras anteriores

## 👨‍💻 Desenvolvido com ❤️

Este submódulo foi desenvolvido seguindo as melhores práticas de desenvolvimento Flutter/Dart, com foco em:
- Código limpo e bem documentado
- Arquitetura escalável
- Performance otimizada
- UX intuitiva e moderna

---

**Versão:** 1.0.0  
**Data:** Outubro 2025  
**Projeto:** FortSmart Agro

