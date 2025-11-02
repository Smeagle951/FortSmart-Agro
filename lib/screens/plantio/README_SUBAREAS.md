# 🌱 Sistema de Subáreas FortSmart

## 📋 Visão Geral

O novo sistema de subáreas foi recriado seguindo o padrão FortSmart para plantio, baseado nas interfaces mostradas nas imagens. O sistema permite gerenciar subáreas dentro de talhões/experimentos, com funcionalidades de visualização em mapa, criação, edição e análise de dados.

## 🏗️ Estrutura de Arquivos

```
lib/
├── models/
│   ├── subarea_experimento_model.dart      # Modelo da subárea
│   └── experimento_talhao_model.dart       # Modelo do experimento/talhão
├── screens/plantio/
│   ├── talhao_detalhes_screen.dart         # Tela principal (Imagem 1)
│   ├── subarea_detalhes_screen.dart        # Detalhes da subárea (Imagens 2 e 3)
│   ├── criar_subarea_screen.dart           # Criação de subáreas
│   └── exemplo_uso_subareas.dart           # Exemplo de uso
├── widgets/
│   ├── subarea_info_item.dart              # Widget para métricas
│   └── subarea_info_chip.dart              # Widget para chips de informação
└── utils/
    └── api_config.dart                     # Configuração do MapTiler
```

## 🎯 Funcionalidades Implementadas

### ✅ Tela Principal do Talhão (Imagem 1)
- **AppBar** com título, ações e tabs (Subáreas, Aplicações, Colheitas)
- **Card do Experimento** com informações básicas e status
- **Cards de Informação** (Início, Fim, Subáreas)
- **Barra de Progresso** com dias restantes
- **Botões de Ação** (Editar, + Subárea)
- **Toggle de Visualização** (Lista/Mapa)
- **Lista de Subáreas** com cards detalhados
- **Visualização no Mapa** com polígonos e marcadores

### ✅ Tela de Detalhes da Subárea (Imagens 2 e 3)
- **Card Principal** com ícone colorido e informações básicas
- **Métricas** (Área, Perímetro, DAE)
- **Toggle de Visualização** (Detalhes/Mapa)
- **Mapa Interativo** com polígono da subárea
- **Seções de Informações**:
  - Informações Técnicas
  - Informações Temporais
  - Estatísticas
  - Observações
- **Floating Action Button** para Nova Aplicação

### ✅ Tela de Criação de Subáreas
- **Formulário Horizontal** com campos organizados
- **Mapa Interativo** para desenho de polígonos
- **Seletor de Cor** com paleta de cores
- **Cálculos Automáticos** de área e perímetro
- **Validação de Dados** completa

## 🎨 Componentes Visuais

### Widgets Auxiliares
- **SubareaInfoItem**: Exibe métricas em cards coloridos
- **SubareaInfoChip**: Chips compactos para informações
- **Cards Elegantes**: Design moderno com sombras e bordas arredondadas
- **Mapa Integrado**: Usando MapTiler API com polígonos e marcadores

### Design System
- **Cores**: Paleta consistente com o FortSmart
- **Tipografia**: Hierarquia clara de textos
- **Espaçamento**: Padding e margins padronizados
- **Bordas**: BorderRadius de 12px para cards
- **Sombras**: BoxShadow sutil para profundidade

## 🔧 Integração com MapTiler

O sistema utiliza a API do MapTiler através do `APIConfig`:

```dart
TileLayer(
  urlTemplate: APIConfig.getMapTilerUrl('satellite'),
  userAgentPackageName: 'com.fortsmart.agro',
  maxZoom: 20,
  minZoom: 10,
)
```

## 📊 Modelos de Dados

### SubareaExperimento
```dart
class SubareaExperimento {
  final String id;
  final String nome;
  final String talhaoId;
  final String? cultura;
  final String? variedade;
  final double areaHa;
  final double perimetroM;
  final int? populacao;
  final Color cor;
  final List<LatLng> vertices;
  final DateTime dataInicio;
  // ... outros campos
}
```

### ExperimentoTalhao
```dart
class ExperimentoTalhao {
  final String id;
  final String nome;
  final String talhaoNome;
  final DateTime startDate;
  final DateTime endDate;
  final List<SubareaExperimento> subareas;
  // ... outros campos
}
```

## 🚀 Como Usar

### 1. Navegação Básica
```dart
// Abrir tela principal
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TalhaoDetalhesScreen(experimento: experimento),
  ),
);
```

### 2. Criar Dados de Exemplo
```dart
final experimento = DadosExemplo.criarExperimentoCompleto();
```

### 3. Acessar Detalhes da Subárea
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SubareaDetalhesScreen(subarea: subarea),
  ),
);
```

## 🎯 Funcionalidades Excluídas

Conforme solicitado, **NÃO** foram implementadas:
- ❌ Módulo de Aplicações
- ❌ Módulo de Colheitas
- ❌ Integração com banco de dados (apenas modelos)
- ❌ Persistência de dados

## 🔄 Próximos Passos

Para completar a integração:

1. **Integrar com Banco de Dados**
   - Criar tabelas para subáreas e experimentos
   - Implementar DAOs e Repositories
   - Adicionar migrações

2. **Conectar com Sistema Existente**
   - Integrar com módulo de plantio
   - Conectar com sistema de talhões
   - Adicionar navegação no menu principal

3. **Funcionalidades Avançadas**
   - Edição de subáreas
   - Exportação de dados
   - Relatórios
   - Sincronização offline

## 📱 Compatibilidade

- ✅ Flutter 3.x+
- ✅ Dart 3.x+
- ✅ flutter_map
- ✅ latlong2
- ✅ MapTiler API

## 🎨 Design Responsivo

O sistema foi desenvolvido com foco em:
- **Layout Horizontal**: Formulários e mapas lado a lado
- **Cards Elegantes**: Design moderno e funcional
- **Navegação Intuitiva**: Fluxo claro entre telas
- **Feedback Visual**: Estados de loading e validação

---

**Desenvolvido seguindo o padrão FortSmart para máxima compatibilidade e integração com o sistema existente.**
