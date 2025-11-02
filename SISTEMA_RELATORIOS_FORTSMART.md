# Sistema de Relatórios FortSmart Agro

## Visão Geral

O sistema de relatórios do FortSmart Agro foi desenvolvido para fornecer análises detalhadas e insights sobre as operações agrícolas, com foco especial em testes de germinação e operações de plantio. O sistema oferece relatórios em múltiplos formatos (PDF, CSV) com análises estatísticas, recomendações técnicas e integração entre módulos.

## Arquitetura do Sistema

### Serviços Principais

#### 1. GerminationReportService
**Localização:** `lib/services/germination_report_service.dart`

**Funcionalidades:**
- Geração de relatórios individuais de teste de germinação
- Relatórios comparativos entre múltiplos testes
- Exportação de dados para CSV
- Análises estatísticas de germinação
- Recomendações baseadas na qualidade das sementes

**Tipos de Relatório:**
- **Individual:** Relatório completo de um teste específico
- **Comparativo:** Análise comparativa entre diferentes lotes/variedades
- **CSV:** Dados brutos para análise externa

#### 2. PlantingReportService
**Localização:** `lib/services/planting_report_service.dart`

**Funcionalidades:**
- Relatórios de operações de plantio
- Análise de densidade de plantio
- Relatórios de calibração
- Análise de produtividade
- Exportação de dados de plantio

**Tipos de Relatório:**
- **Plantio:** Análise completa de operações de plantio
- **Densidade:** Relatório específico de análise de densidade
- **CSV:** Dados de plantio para análise externa

#### 3. IntegratedReportService
**Localização:** `lib/services/integrated_report_service.dart`

**Funcionalidades:**
- Relatórios que combinam dados de germinação e plantio
- Análise de qualidade de sementes
- Análise de tendências integradas
- Recomendações baseadas na integração entre módulos

**Tipos de Relatório:**
- **Integrado:** Análise completa do processo germinação → plantio
- **Qualidade:** Relatório específico de qualidade de sementes

### Telas de Interface

#### 1. GerminationReportScreen
**Localização:** `lib/screens/plantio/submods/germination_test/screens/germination_report_screen.dart`

**Funcionalidades:**
- Interface para geração de relatórios de germinação
- Filtros avançados por data, cultura, variedade, lote
- Opções de conteúdo (gráficos, recomendações)
- Seleção de formato (PDF/CSV)

#### 2. IntegratedReportsDashboard
**Localização:** `lib/screens/reports/integrated_reports_dashboard.dart`

**Funcionalidades:**
- Dashboard central para todos os tipos de relatórios
- Filtros globais aplicáveis a todos os relatórios
- Acesso rápido a diferentes categorias de relatório
- Ações em lote (gerar todos os relatórios)

## Características Técnicas

### Formato de Saída

#### PDF
- **Biblioteca:** `pdf` package
- **Fontes:** Poppins (Regular, Bold, SemiBold)
- **Cores:** Tema FortSmart (Verde #2A4F3D, Verde claro #468750, Amarelo #F3C20F)
- **Estrutura:** Cabeçalho, conteúdo multi-página, rodapé
- **Elementos:** Tabelas, gráficos, caixas de informação, ícones

#### CSV
- **Codificação:** UTF-8
- **Separador:** Vírgula (formato brasileiro com ponto como decimal)
- **Cabeçalhos:** Descrição clara das colunas
- **Dados:** Valores numéricos formatados no padrão brasileiro

### Análises Implementadas

#### Análise de Germinação
- **Taxa de Germinação:** Percentual de sementes germinadas
- **Qualidade:** Classificação (Excelente >95%, Muito Boa 90-95%, Boa 80-90%, Regular 70-80%, Baixa <70%)
- **Doenças:** Percentual de sementes doentes
- **Velocidade:** Análise temporal da germinação
- **Uniformidade:** Distribuição da germinação ao longo do tempo

#### Análise de Plantio
- **Densidade:** Plantas por hectare
- **Espaçamento:** Distância entre plantas
- **Profundidade:** Profundidade de plantio
- **Calibração:** Status de calibração das máquinas
- **Produtividade:** Análise por cultura e variedade

#### Análise Integrada
- **Correlação:** Relação entre qualidade de germinação e densidade de plantio
- **Alertas:** Notificações automáticas para ajustes necessários
- **Tendências:** Análise temporal de qualidade
- **Recomendações:** Sugestões baseadas nos dados integrados

### Recomendações Automáticas

#### Baseadas em Germinação
- **< 80%:** Aumentar densidade de plantio
- **< 70%:** Revisar armazenamento e tratamento
- **> 95%:** Manter padrões atuais
- **Doenças > 5%:** Implementar tratamento químico

#### Baseadas em Plantio
- **Densidade baixa:** Aumentar população de plantas
- **Densidade alta:** Reduzir para evitar competição
- **Espaçamento inadequado:** Ajustar configuração da máquina
- **Profundidade excessiva:** Verificar emergência

## Integração com o Sistema

### Dados Utilizados
- **Germinação:** `GerminationTest`, `GerminationDailyRecord`
- **Plantio:** `Planting`, `Plot`, `Farm`
- **Integração:** `GerminationPlantingIntegrationService`
- **Alertas:** `DensityAlert`, `SeedLotApproval`

### Banco de Dados
- **Acesso:** Através dos DAOs específicos
- **Filtros:** Por data, cultura, variedade, status
- **Performance:** Consultas otimizadas com índices apropriados

## Funcionalidades Avançadas

### Filtros Inteligentes
- **Por Período:** Data inicial e final
- **Por Cultura:** Filtro específico por tipo de cultura
- **Por Variedade:** Análise por variedade específica
- **Por Lote:** Análise por lote de sementes
- **Por Status:** Testes concluídos, em andamento, pendentes

### Exportação e Compartilhamento
- **PDF:** Geração local com opção de compartilhamento
- **CSV:** Dados brutos para análise externa
- **Compartilhamento:** Via sistema nativo do dispositivo
- **Armazenamento:** Diretório de documentos do aplicativo

### Personalização
- **Conteúdo:** Opções para incluir/excluir seções
- **Visualização:** Gráficos e análises visuais
- **Recomendações:** Sugestões técnicas personalizadas
- **Formato:** Escolha entre PDF e CSV

## Casos de Uso

### 1. Análise de Qualidade de Lote
**Cenário:** Produtor quer avaliar a qualidade de um lote específico de sementes.

**Solução:**
1. Acessar relatório individual de germinação
2. Selecionar o lote desejado
3. Gerar relatório com análises estatísticas
4. Receber recomendações de densidade de plantio

### 2. Comparação Entre Safras
**Cenário:** Comparar a qualidade das sementes entre diferentes safras.

**Solução:**
1. Usar relatório comparativo de germinação
2. Selecionar testes de diferentes períodos
3. Analisar tendências de qualidade
4. Identificar melhorias ou problemas

### 3. Planejamento de Plantio
**Cenário:** Planejar a densidade de plantio baseada na qualidade das sementes.

**Solução:**
1. Gerar relatório integrado
2. Analisar alertas de densidade
3. Ajustar densidade conforme recomendações
4. Documentar decisões para futuras referências

### 4. Controle de Qualidade
**Cenário:** Monitorar continuamente a qualidade das sementes.

**Solução:**
1. Configurar relatórios automáticos
2. Usar filtros por período
3. Analisar tendências de qualidade
4. Implementar melhorias baseadas nos dados

## Configuração e Personalização

### Cores e Tema
```dart
// Cores do tema FortSmart
static const PdfColor primaryColor = PdfColor(0.16, 0.31, 0.24); // #2A4F3D
static const PdfColor secondaryColor = PdfColor(0.27, 0.53, 0.31); // #468750
static const PdfColor accentColor = PdfColor(0.95, 0.76, 0.06); // #F3C20F
```

### Fontes
- **Títulos:** Poppins Bold
- **Cabeçalhos:** Poppins SemiBold
- **Texto:** Poppins Regular
- **Fallback:** Fontes do sistema

### Formatação Numérica
- **Decimal:** Vírgula (padrão brasileiro)
- **Milhares:** Ponto
- **Percentuais:** Formato brasileiro (ex: 85,5%)

## Manutenção e Extensibilidade

### Adicionando Novos Tipos de Relatório
1. Criar novo serviço baseado nos existentes
2. Implementar métodos de geração de PDF/CSV
3. Adicionar interface na dashboard
4. Integrar com sistema de filtros

### Personalizando Análises
1. Modificar métodos de cálculo estatístico
2. Ajustar thresholds de qualidade
3. Adicionar novos tipos de recomendação
4. Implementar novos gráficos

### Integrando Novos Módulos
1. Estender `IntegratedReportService`
2. Adicionar novos tipos de dados
3. Implementar análises específicas
4. Atualizar dashboard principal

## Considerações de Performance

### Otimizações Implementadas
- **Cache de fontes:** Carregamento único por sessão
- **Consultas otimizadas:** Filtros aplicados no banco
- **Geração assíncrona:** Não bloqueia a interface
- **Arquivos temporários:** Limpeza automática

### Limitações Conhecidas
- **PDFs grandes:** Pode demorar para gerar
- **Muitos dados:** Consultas podem ser lentas
- **Memória:** Arquivos grandes consomem RAM
- **Armazenamento:** Espaço em disco para relatórios

## Troubleshooting

### Problemas Comuns

#### Relatório não gera
- Verificar dados disponíveis no período
- Confirmar filtros aplicados
- Verificar permissões de arquivo
- Consultar logs de erro

#### PDF corrompido
- Verificar fontes carregadas
- Confirmar estrutura de dados
- Testar com dados menores
- Verificar memória disponível

#### Dados incorretos
- Verificar filtros de data
- Confirmar seleção de testes
- Validar dados no banco
- Verificar cálculos estatísticos

### Logs e Debug
- **Logger:** Sistema integrado de logs
- **Debug:** Modo desenvolvimento ativo
- **Erros:** Captura e exibição de exceções
- **Performance:** Medição de tempos de geração

## Conclusão

O sistema de relatórios FortSmart Agro oferece uma solução completa e integrada para análise de dados agrícolas, com foco especial em germinação e plantio. A arquitetura modular permite fácil extensão e personalização, enquanto as análises automatizadas fornecem insights valiosos para tomada de decisão.

O sistema está preparado para crescer com as necessidades da fazenda, oferecendo relatórios cada vez mais sofisticados e análises mais profundas dos dados agrícolas.
