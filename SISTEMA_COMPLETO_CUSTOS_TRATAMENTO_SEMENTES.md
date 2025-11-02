# Sistema Completo de Custos - Tratamento de Sementes

## Visão Geral

O sistema de custos para Tratamento de Sementes foi completamente implementado, permitindo o controle detalhado de custos por dose, integração com o módulo de gestão de custos e relatórios avançados.

## Funcionalidades Implementadas

### 1. **Modelos de Dados**

#### `CustoDoseTS` - Modelo Principal
- **Campos**:
  - `id`: Identificador único
  - `nomeDose`: Nome da dose criada
  - `nomeCultura`: Nome da cultura (campo livre)
  - `sementesKg`: Peso das sementes em kg
  - `hectares`: Área em hectares (opcional)
  - `custoTotalProdutos`: Custo total dos produtos TS
  - `custoTotalInoculantes`: Custo total dos inoculantes
  - `custoTotalAgua`: Custo total da água/calda
  - `custoTotalGeral`: Custo total geral
  - `dataCriacao`: Data de criação
  - `observacoes`: Observações adicionais

#### `DetalheProdutoDoseTS` - Detalhes dos Produtos
- **Campos**:
  - `id`: Identificador único
  - `custoDoseId`: Referência à dose
  - `tipoProduto`: Tipo (produtoTS, inoculante, agua)
  - `nomeProduto`: Nome do produto
  - `unidade`: Unidade de medida
  - `quantidade`: Quantidade utilizada
  - `valorUnitario`: Valor unitário
  - `custoTotal`: Custo total do item
  - `observacoes`: Observações

### 2. **Repositório de Dados**

#### `CustoDoseTSRepository`
- **Funcionalidades**:
  - Criação automática de tabelas SQLite
  - Salvamento completo de doses com detalhes
  - Busca por cultura, data, etc.
  - Cálculo automático de custos
  - Estatísticas e relatórios

### 3. **Interface do Usuário**

#### Tela de Nova Dose (`TSDoseEditorScreen`)
- **Campos**:
  - Nome da dose (obrigatório)
  - Cultura (campo livre - obrigatório)
  - Peso das sementes (kg)
  - Área (hectares - opcional)
  - Descrição/observações

#### Widgets de Seleção
- **Produtos TS**: Com opção de produtos pré-definidos ou personalizados
- **Inoculantes**: Com opção de inoculantes pré-definidos ou personalizados
- **Água/Calda**: Configuração de volume
- **Compatibilidade**: Verificação automática
- **Custos**: Resumo em tempo real

### 4. **Sistema de Custos**

#### Cálculo Automático
- **Produtos TS**: Baseado em quantidade × valor unitário
- **Inoculantes**: Baseado em doses × valor unitário
- **Água/Calda**: R$ 0,50 por litro
- **Total**: Soma de todos os componentes

#### Integração com Gestão de Custos
- Salvamento automático no banco de dados
- Dados estruturados para relatórios
- Histórico completo de custos

### 5. **Relatórios e Estatísticas**

#### Histórico de Custos (`HistoricoCustosDosesWidget`)
- Lista todas as doses criadas
- Filtro por cultura
- Detalhes completos de cada dose
- Visualização de custos por categoria

#### Relatórios Avançados (`RelatoriosCustosTSWidget`)
- **Estatísticas Gerais**:
  - Total de doses
  - Custo total e médio
  - Custos por categoria
  - Distribuição por cultura

- **Relatório por Cultura**:
  - Análise detalhada por cultura
  - Custos médios
  - Quantidades utilizadas
  - Comparativo entre culturas

- **Projeções** (preparado para implementação futura):
  - Cálculo de custos estimados
  - Baseado em dados históricos
  - Para planejamento de safras

### 6. **Serviços de Integração**

#### `GestaoCustosIntegrationService`
- Exportação de dados para módulo de gestão
- Geração de relatórios
- Cálculo de projeções
- Estatísticas avançadas

## Como Usar

### 1. **Criar Nova Dose**
1. Acesse "Tratamento de Sementes" → "Nova Dose"
2. Preencha as informações básicas:
   - Nome da dose
   - Cultura (ex: Soja, Milho, Algodão)
   - Peso das sementes
   - Área (opcional)
3. Adicione produtos TS (pré-definidos ou personalizados)
4. Configure inoculantes (pré-definidos ou personalizados)
5. Configure água/calda
6. Verifique compatibilidade
7. Revise o resumo de custos
8. Salve a dose

### 2. **Visualizar Histórico**
1. Acesse "Histórico de Custos"
2. Use o filtro por cultura se necessário
3. Clique em uma dose para ver detalhes completos

### 3. **Gerar Relatórios**
1. Acesse "Relatórios de Custos"
2. Navegue pelas abas:
   - **Estatísticas**: Visão geral
   - **Por Cultura**: Análise detalhada
   - **Projeções**: Cálculos futuros

## Estrutura de Arquivos

```
lib/modules/tratamento_sementes/
├── models/
│   ├── custo_dose_ts_model.dart
│   ├── detalhe_produto_dose_ts_model.dart
│   ├── produto_ts_model.dart (atualizado)
│   └── inoculante_ts_model.dart (atualizado)
├── repositories/
│   └── custo_dose_ts_repository.dart
├── services/
│   └── gestao_custos_integration_service.dart
├── widgets/
│   ├── historico_custos_doses_widget.dart
│   ├── relatorios_custos_ts_widget.dart
│   ├── produto_ts_selection_widget.dart (atualizado)
│   ├── inoculante_ts_selection_widget.dart (atualizado)
│   └── custo_ts_widget.dart
└── screens/
    └── ts_dose_editor_screen.dart (atualizado)
```

## Banco de Dados

### Tabelas Criadas
1. **`custos_doses_ts`**: Dados principais das doses
2. **`detalhes_produtos_doses_ts`**: Detalhes dos produtos utilizados

### Índices
- Nome da dose
- Nome da cultura
- Data de criação
- Relacionamento entre tabelas

## Benefícios

### 1. **Controle Total de Custos**
- Rastreamento detalhado de cada componente
- Cálculo automático e preciso
- Histórico completo

### 2. **Flexibilidade**
- Produtos e inoculantes personalizados
- Cultura livre (não limitada a opções pré-definidas)
- Valores unitários editáveis

### 3. **Integração**
- Dados estruturados para módulo de gestão
- Relatórios avançados
- Estatísticas em tempo real

### 4. **Usabilidade**
- Interface intuitiva
- Validações automáticas
- Feedback visual em tempo real

## Próximos Passos

### 1. **Integração com Módulo de Gestão**
- Conectar com sistema principal de custos
- Sincronização automática
- Dashboard unificado

### 2. **Funcionalidades Avançadas**
- Calculadora de projeções
- Comparativo entre safras
- Análise de tendências

### 3. **Exportação**
- Relatórios em PDF
- Exportação para Excel
- Integração com sistemas externos

## Conclusão

O sistema de custos para Tratamento de Sementes está completamente funcional e integrado, oferecendo:

- ✅ Controle total de custos por dose
- ✅ Produtos e inoculantes personalizáveis
- ✅ Cultura livre (campo manual)
- ✅ Cálculo automático de custos
- ✅ Histórico completo
- ✅ Relatórios avançados
- ✅ Integração com gestão de custos
- ✅ Interface intuitiva e responsiva

O sistema está pronto para uso em produção e pode ser facilmente expandido com novas funcionalidades conforme necessário.
