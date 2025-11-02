# 🗺️ Módulo Mapa de Infestação - FortSmart Agro

## 📋 Visão Geral

O módulo de Mapa de Infestação é uma solução completa para visualização, análise e gestão de dados de infestação agrícola. Ele integra-se com o sistema de monitoramento existente para fornecer insights georreferenciados sobre pragas, doenças e plantas daninhas.

## ✨ Funcionalidades Principais

### 🗺️ Visualização de Mapas
- **Mapa Interativo**: Visualização georreferenciada de talhões e pontos de infestação
- **Camadas Múltiplas**: Polígonos de talhões, marcadores de pontos e heatmaps
- **Modo Satélite**: Alternância entre visualização de mapa e satélite
- **Zoom e Navegação**: Controles intuitivos de navegação

### 📊 Análise de Dados
- **Cálculos Inteligentes**: Algoritmos ponderados por precisão GPS e tempo
- **Níveis de Infestação**: Classificação automática (Baixo, Moderado, Alto, Crítico)
- **Estatísticas Agregadas**: Resumos por talhão, organismo e período
- **Heatmaps Hexagonais**: ✅ **IMPLEMENTADO** - Visualização de densidade de infestação com algoritmo de hexbin otimizado

### 🚨 Sistema de Alertas ✅ **IMPLEMENTADO**
- **Alertas Automáticos**: ✅ Geração baseada em resumos de infestação com score de prioridade
- **Priorização**: ✅ Classificação por nível de risco (crítico > alto > médio > baixo)
- **Reconhecimento**: ✅ Sistema de confirmação de alertas (ativo → reconhecido → resolvido)
- **Histórico e Status**: ✅ Rastreamento completo do ciclo de vida dos alertas
- **Score de Prioridade**: ✅ Cálculo inteligente baseado em nível, tendência, severidade e recência
- **Stream em Tempo Real**: ✅ Atualizações automáticas da interface
- **Estatísticas Completas**: ✅ Métricas de resolução, tempo médio e distribuição por risco
- **Interface Avançada**: ✅ Painel com abas, busca, filtros e ações de gestão

### 🔍 Filtros Avançados
- **Período**: Seleção de janelas de tempo
- **Níveis**: Filtro por severidade de infestação
- **Organismos**: Seleção específica de pragas/doenças
- **Talhões**: Filtro por área específica
- **Alertas**: Filtros por status e tipo

## 🏗️ Arquitetura

### Estrutura de Pastas
```
lib/modules/infestation_map/
├── models/           # Modelos de dados
├── services/         # Lógica de negócio
├── screens/          # Telas da interface
├── widgets/          # Componentes reutilizáveis
├── utils/            # Utilitários e helpers
└── README.md         # Esta documentação
```

### Componentes Principais

#### Models
- **InfestationSummary**: Resumo de infestação por talhão/organismo
- **InfestationAlert**: Alertas de infestação
- **InfestationLevel**: Enum de níveis de severidade
- **InfestationFilters**: Filtros de consulta

#### Services
- **InfestationCalculationService**: ✅ **IMPLEMENTADO** - Cálculos e algoritmos ponderados
- **InfestacaoIntegrationService**: ✅ **IMPLEMENTADO** - Pipeline de processamento completo
- **HexbinService**: ✅ **IMPLEMENTADO** - Geração de dados hexagonais para heatmaps
- **AlertService**: ✅ **IMPLEMENTADO** - Sistema completo de alertas com priorização e gestão de ciclo de vida

#### Repositories
- **InfestationRepository**: ✅ **IMPLEMENTADO** - Persistência completa e métodos de consulta

#### Services de Integração
- **TalhaoIntegrationService**: ✅ **IMPLEMENTADO** - Coordenadas reais dos talhões
- **OrganismCatalogIntegrationService**: ✅ **IMPLEMENTADO** - Thresholds reais do catálogo

#### Sistema de Cache ✅ **IMPLEMENTADO**
- **InfestationCacheService**: Cache inteligente com expiração automática
- **Cache de Coordenadas**: Talhões com expiração de 6 horas
- **Cache de Thresholds**: Organismos com expiração de 12 horas
- **Cache de Estatísticas**: Infestação com expiração de 1 hora
- **Cache de Heatmap**: Dados de visualização com expiração de 1 hora
- **Invalidação Inteligente**: Por talhão, organismo ou completa
- **Monitoramento**: Estatísticas de uso e tamanho do cache

#### Sistema de Heatmap/Hexbin ✅ **IMPLEMENTADO**
- **HexbinService**: Geração de dados hexagonais para visualização de densidade
- **Algoritmo Otimizado**: Tamanho de hexágonos ajustado automaticamente baseado na densidade de pontos
- **GeoJSON**: Exportação em formato padrão para integração com sistemas de mapas
- **Filtros por Organismo**: Geração de heatmaps específicos por praga/doença
- **Cálculo de Infestação**: Valores médios por hexágono com classificação de níveis
- **Integração com Talhões**: Polígonos reais dos talhões como base para geração

#### Screens
- **InfestationMapScreen**: Tela principal do mapa

#### Widgets
- **InfestationLegendWidget**: Legenda de níveis
- **InfestationFiltersPanel**: Painel de filtros
- **InfestationStatsCard**: Card de estatísticas
- **AlertsPanel**: ✅ **IMPLEMENTADO** - Painel completo de gestão de alertas com abas, busca e ações

## 🔧 Instalação e Configuração

### Dependências
```yaml
dependencies:
  flutter_map: ^5.0.0
  latlong2: ^0.9.0
  uuid: ^3.0.7
```

### Pré-requisitos
**IMPORTANTE**: Este módulo requer que os seguintes módulos estejam funcionando:
- ✅ **Módulo de Monitoramento**: Para dados de infestação
- ✅ **Módulo de Talhões**: Para informações geográficas
- ✅ **Módulo Catálogo de Organismos**: Para thresholds e pesos de risco

### Configuração
1. **Verifique** se os módulos dependentes estão funcionando
2. **Configure** as dependências no `pubspec.yaml`
3. **Importe** o módulo no seu projeto
4. **Inicialize** o módulo na inicialização do app
5. **Conecte** com os dados reais dos módulos existentes

```dart
import 'package:fortsmart_agro/modules/infestation_map/infestation_map_module.dart';

// Na inicialização do app
await InfestationMapModule.initialize();
```

## 📱 Uso

### Navegação
```dart
Navigator.pushNamed(context, '/infestation_map');
```

### Integração com Dados Reais
```dart
import 'package:fortsmart_agro/modules/infestation_map/repositories/repositories.dart';
import 'package:fortsmart_agro/modules/infestation_map/services/services.dart';

// 1. Repositório de Infestação
final repository = InfestationRepository();
final summaries = await repository.getInfestationSummariesByTalhao('TALHAO_001');

// 2. Serviço de Integração com Talhões
final talhaoService = TalhaoIntegrationService();
final coordinates = await talhaoService.getTalhaoCenter('TALHAO_001');
final polygon = await talhaoService.getTalhaoPolygon('TALHAO_001');

// 3. Serviço de Integração com Catálogo de Organismos
final organismService = OrganismCatalogIntegrationService();
final thresholds = await organismService.getOrganismThresholds('ORGANISMO_001');
final riskWeights = await organismService.getRiskWeights();

// 4. Sistema de Cache (Automático)
final cacheService = InfestationCacheService();
final cacheStats = await cacheService.getCacheStats();
final cacheSizeMB = await cacheService.getCacheSizeMB();
```

### Exemplo de Uso com Dados Reais
```dart
// 1. Obter dados de monitoramento do módulo existente
final monitoringData = await monitoringService.getRecentMonitoring(talhaoId);

// 2. Obter thresholds do catálogo de organismos
final organismThresholds = await organismCatalogService.getThresholds();

// 3. Processar para infestação
await infestationService.processRealData(
  monitoringData: monitoringData,
  thresholds: organismThresholds,
);

// 4. Exibir no mapa com dados reais
final infestationMap = InfestationMapScreen(
  talhaoId: talhaoId,
  useRealData: true, // Sempre true - não há dados de exemplo
);
```

## 🎨 Personalização

### Cores e Temas
O módulo usa as cores padrão do FortSmart Agro:
- **Primária**: `#2A4F3D` (Verde escuro)
- **Secundária**: `#3BAA57` (Verde claro)
- **Níveis de Infestação**: Verde, Amarelo, Laranja, Vermelho

### Configurações
- Thresholds de níveis configuráveis
- Tamanho de hexágonos ajustável
- Fatores de peso para cálculos
- Configurações de alertas

## 🔌 Integração

### Módulos Dependentes
- **Monitoramento**: Fonte de dados de infestação (pontos de monitoramento, coordenadas GPS)
- **Talhões**: Informações geográficas (polígonos, coordenadas, área)
- **Catálogo de Organismos**: Dados de pragas/doenças (thresholds, pesos de risco)

### Integração com Dados Reais
O módulo **NÃO usa dados de exemplo**. Todos os dados são coletados dos módulos existentes:

#### Monitoramento
- Pontos de infestação com coordenadas GPS reais
- Dados de precisão e timestamp
- Histórico de monitoramento por talhão

#### Catálogo de Organismos
- Thresholds reais para classificação de níveis
- Pesos de risco específicos por organismo
- Informações taxonômicas e agronômicas

#### Talhões
- Coordenadas geográficas reais dos polígonos
- Área e limites precisos
- Informações de cultura e safra

### APIs
- **Processamento**: Integração automática com monitoramento
- **Consulta**: Filtros e estatísticas baseados em dados reais
- **Alertas**: Sistema de notificações com dados reais

## 🧪 Testes

### Testes Unitários
```bash
flutter test test/modules/infestation_map/
```

### Testes de Integração
```bash
flutter test integration_test/
```

### Testes de Integração em Tempo Real ✅ **IMPLEMENTADO**
O módulo inclui um sistema completo de testes de integração que pode ser executado diretamente na interface:

#### InfestationTestRunner
```dart
import 'package:fortsmart_agro/modules/infestation_map/utils/utils.dart';

final testRunner = InfestationTestRunner();
final results = await testRunner.runAllTests();
```

#### Testes Disponíveis
1. **Conexão com Banco de Dados**: Verifica conectividade e inicialização
2. **Repositório de Infestação**: Testa busca de resumos, alertas e estatísticas
3. **Integração com Talhões**: Verifica busca de coordenadas e polígonos
4. **Integração com Catálogo**: Testa thresholds e pesos de risco
5. **Cálculos de Infestação**: Verifica processamento de dados
6. **Geração de Heatmap**: Testa renderização de mapas térmicos

#### Execução via Interface
- Clique no botão 🐛 na AppBar da tela de mapa
- Aguarde a execução dos testes
- Visualize o relatório detalhado de resultados
- Verifique logs para detalhes de falhas

#### Relatório de Resultados
```
📊 RELATÓRIO DE TESTES - MÓDULO DE INFESTAÇÃO
==================================================
✅ Testes passaram: 5/6 (83.3%)

database_connection: ✅ PASSOU
infestation_repository: ✅ PASSOU
talhao_integration: ✅ PASSOU
organism_catalog_integration: ✅ PASSOU
infestation_calculations: ✅ PASSOU
heatmap_generation: ❌ FALHOU

⚠️ Alguns testes falharam. Verifique os logs para detalhes.
```

## 📈 Roadmap

### Versão 1.1
- [ ] Cache de heatmaps
- [ ] Exportação de relatórios
- [ ] Notificações push

### Versão 1.2
- [ ] Análise de tendências
- [ ] Recomendações automáticas
- [ ] Integração com prescrição

### Versão 2.0
- [ ] Machine Learning para predição
- [ ] Análise de imagens
- [ ] Integração com drones

## 🐛 Solução de Problemas

### Problemas Comuns

#### Mapa não carrega
- Verificar permissões de localização
- Confirmar conectividade com internet
- Verificar configuração de tiles

#### Dados não aparecem
- **Verificar módulos dependentes**: Monitoramento, Talhões e Catálogo de Organismos
- **Confirmar dados reais**: Verificar se há dados de monitoramento nos módulos
- **Verificar integração**: Confirmar se a conexão entre módulos está funcionando
- **Confirmar filtros aplicados**: Verificar se os filtros não estão muito restritivos
- **Verificar permissões de usuário**: Confirmar acesso aos módulos dependentes

#### Performance lenta
- Reduzir tamanho de hexágonos
- Limitar período de dados
- Usar cache de heatmaps

## 📞 Suporte

Para suporte técnico ou dúvidas sobre o módulo:
- **Email**: suporte@fortsmart.agro
- **Documentação**: [docs.fortsmart.agro](https://docs.fortsmart.agro)
- **Issues**: [GitHub Issues](https://github.com/fortsmart/agro/issues)

## 📄 Licença

Este módulo é parte do FortSmart Agro e está sob a mesma licença do projeto principal.

---

**Desenvolvido com ❤️ pela equipe FortSmart Agro**
