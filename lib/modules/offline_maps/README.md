# 🗺️ Módulo de Mapas Offline - FortSmart

Este módulo permite o download e armazenamento offline de tiles de mapas para talhões específicos, garantindo funcionamento sem conexão com internet.

## 🚀 Funcionalidades

- **Download automático**: Mapas offline são criados automaticamente quando talhões são criados
- **Gerenciamento inteligente**: Interface para baixar, pausar, retomar e remover mapas offline
- **Integração completa**: Funciona com o sistema de talhões existente do FortSmart
- **Otimização de espaço**: Download apenas dos tiles necessários para cada talhão
- **Progresso em tempo real**: Acompanhamento do progresso de download
- **Múltiplos tipos de mapa**: Suporte a satélite, ruas, outdoors, etc.

## 📁 Estrutura do Módulo

```
lib/modules/offline_maps/
├── models/
│   ├── offline_map_model.dart          # Modelo de dados principal
│   └── offline_map_status.dart         # Enum de status
├── services/
│   ├── offline_map_service.dart        # Serviço principal
│   ├── tile_download_service.dart      # Download de tiles
│   └── talhao_integration_service.dart # Integração com talhões
├── providers/
│   └── offline_map_provider.dart       # Provider para estado
├── screens/
│   └── offline_maps_manager_screen.dart # Tela principal
├── widgets/
│   ├── offline_map_card.dart           # Card de mapa offline
│   └── download_progress_widget.dart  # Widget de progresso
├── utils/
│   ├── offline_map_utils.dart          # Utilitários gerais
│   └── tile_calculator.dart           # Cálculos de tiles
└── index.dart                          # Exportações
```

## 🔧 Como Usar

### 1. Configuração Inicial

```dart
import 'package:fortsmart_agro/modules/offline_maps/index.dart';

// No main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar serviço de mapas offline
  await OfflineMapService().init();
  
  runApp(MyApp());
}
```

### 2. Integração com Talhões

```dart
// No serviço de talhões, após criar um talhão
final talhao = TalhaoModel.criar(
  nome: 'Talhão 1',
  pontos: polygonPoints,
  area: 10.5,
);

// Criar mapa offline automaticamente
final integrationService = TalhaoIntegrationService();
await integrationService.createOfflineMapForTalhao(talhao);
```

### 3. Usar na Interface

```dart
// Adicionar provider no main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => OfflineMapProvider()),
    // outros providers...
  ],
  child: MyApp(),
)

// Usar a tela de gerenciamento
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const OfflineMapsManagerScreen(),
  ),
);
```

## 🗄️ Banco de Dados

O módulo cria automaticamente a tabela `offline_maps` com os seguintes campos:

- `id`: Identificador único
- `talhao_id`: ID do talhão associado
- `talhao_name`: Nome do talhão
- `polygon`: Polígono do talhão (JSON)
- `area`: Área em hectares
- `status`: Status do download
- `zoom_min/zoom_max`: Níveis de zoom
- `total_tiles/downloaded_tiles`: Contadores de tiles
- `local_path`: Caminho local dos tiles
- `metadata`: Dados adicionais (JSON)

## 📱 Interface do Usuário

### Tela Principal
- Lista de todos os mapas offline
- Filtros por status (baixado, baixando, erro, etc.)
- Estatísticas rápidas
- Ações em lote (baixar todos)

### Card de Mapa Offline
- Nome do talhão e fazenda
- Status visual com ícones
- Informações do mapa (área, zoom, tiles)
- Botões de ação (baixar, pausar, retomar, remover)
- Barra de progresso para downloads

## 🔄 Fluxo de Funcionamento

1. **Criação de Talhão**: Quando um talhão é criado, um mapa offline é automaticamente registrado
2. **Download Manual**: Usuário pode baixar mapas através da interface
3. **Uso Offline**: Quando offline, o sistema carrega tiles do armazenamento local
4. **Atualizações**: Mapas podem ser atualizados quando talhões são modificados

## ⚙️ Configurações

### Níveis de Zoom
- **Padrão**: 13-18 (balanceado entre qualidade e tamanho)
- **Alto**: 15-20 (maior qualidade, mais espaço)
- **Econômico**: 12-16 (menor qualidade, menos espaço)

### Tipos de Mapa
- **Satélite**: Imagens de satélite (padrão)
- **Ruas**: Mapa de ruas
- **Outdoors**: Mapa para atividades ao ar livre
- **Híbrido**: Combinação de satélite e ruas

## 📊 Monitoramento

O módulo fornece estatísticas detalhadas:
- Tamanho total dos mapas offline
- Número de arquivos
- Mapas baixados vs pendentes
- Uso de espaço em disco

## 🛠️ Manutenção

### Limpeza Automática
- Remove mapas não baixados há mais de 30 dias
- Limpa tiles corrompidos
- Otimiza espaço em disco

### Backup e Restauração
- Mapas offline são armazenados localmente
- Podem ser exportados/importados
- Sincronização com sistema de backup do FortSmart

## 🔒 Segurança

- Tiles são armazenados localmente no dispositivo
- Não há transmissão de dados sensíveis
- Integração segura com sistema de talhões
- Validação de integridade dos tiles

## 📈 Performance

- Download em lotes para otimizar velocidade
- Cache inteligente de tiles
- Compressão automática quando necessário
- Monitoramento de uso de memória

## 🐛 Troubleshooting

### Problemas Comuns

1. **Download não inicia**
   - Verificar conexão com internet
   - Verificar chave da API MapTiler
   - Verificar espaço em disco

2. **Tiles corrompidos**
   - Limpar cache do aplicativo
   - Rebaixar mapas afetados
   - Verificar integridade do armazenamento

3. **Performance lenta**
   - Reduzir níveis de zoom
   - Limpar mapas antigos
   - Verificar espaço em disco

## 🔮 Futuras Melhorias

- [ ] Suporte a MBTiles
- [ ] Compressão avançada
- [ ] Sincronização em nuvem
- [ ] Mapas personalizados
- [ ] Análise de uso de dados
- [ ] Integração com GPS offline
