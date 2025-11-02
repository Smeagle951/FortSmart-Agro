# Guia de Implementação - Sistema de Subáreas FortSmart

## Visão Geral

O sistema de subáreas do FortSmart permite criar divisões geográficas dentro dos talhões existentes, facilitando o gerenciamento de diferentes culturas, variedades e experimentos agrícolas. A implementação segue o padrão arquitetural existente no projeto.

## Arquitetura do Sistema

### 1. Modelos de Dados

O sistema utiliza o modelo `SubareaPlantio` existente:

```dart
class SubareaPlantio {
  final String id;
  final String talhaoId;
  final String safraId;
  final String culturaId;
  final String nome;
  final String? variedadeId;
  final DateTime dataImplantacao;
  final double areaHa;
  final String corRgba;
  final String geojson;
  final String? observacoes;
  final DateTime criadoEm;
  final String usuarioId;
  final bool sincronizado;
}
```

### 2. Serviços

#### SubareaPlantioService
Gerencia a lógica de negócio para subáreas:
- `criarSubarea()`: Cria nova subárea com validações
- `buscarSubareasCompletas()`: Busca subáreas com dados enriquecidos
- `exportarParaGeoJSON()`: Exporta para formato GeoJSON
- `exportarParaKML()`: Exporta para formato KML

#### GeoJSONService (Melhorado)
Fornece funcionalidades geodésicas precisas:
- `calculateAreaHectares()`: Calcula área usando fórmula de Shoelace
- `calculatePerimeterMeters()`: Calcula perímetro usando geodésicas
- `formatArea()`: Formata área no padrão brasileiro
- `formatPerimeter()`: Formata perímetro em metros/quilômetros
- `latLngListToGeoJSONString()`: Converte lista de pontos para GeoJSON

### 3. Repositório e DAO

#### SubareaPlantioRepository
Gerencia operações de persistência:
- `criarSubarea()`: Cria subárea com validações de permissão
- `atualizarSubarea()`: Atualiza subárea existente
- `excluirSubarea()`: Remove subárea
- `buscarPorTalhao()`: Lista subáreas de um talhão

#### SubareaPlantioDao
Acesso direto ao banco de dados:
- `getSubareasByTalhao()`: Busca por talhão
- `getSubareasBySafra()`: Busca por safra
- `getSubareasNaoSincronizadas()`: Busca não sincronizadas
- `marcarComoSincronizada()`: Marca como sincronizada

## Como Usar

### 1. Acessando a Criação de Subáreas

1. Navegue até o módulo de **Plantio**
2. Selecione **Novo Plantio**
3. Escolha um talhão
4. Clique no botão **"Registrar Subáreas"**

### 2. Criando uma Subárea

#### Passo 1: Desenhar o Polígono
1. Clique em **"Iniciar Desenho"**
2. Toque no mapa para adicionar vértices
3. Certifique-se de que todos os pontos estão dentro do talhão
4. Clique em **"Finalizar Polígono"** quando terminar

#### Passo 2: Preencher Informações
1. **Nome da Subárea**: Identificador único
2. **Cultura**: Cultura que será plantada
3. **Variedade** (opcional): Variedade específica
4. **População** (opcional): População de plantas
5. **Cor**: Cor para visualização no mapa
6. **Data de Implantação**: Data de implantação
7. **Observações** (opcional): Notas adicionais

#### Passo 3: Salvar
1. Verifique as informações calculadas (área, perímetro)
2. Clique em **"Salvar Subárea"**

### 3. Validações Implementadas

- **Mínimo de vértices**: Pelo menos 3 vértices
- **Limites do talhão**: Todos os vértices devem estar dentro do polígono pai
- **Nome obrigatório**: Subárea deve ter um nome
- **Cultura obrigatória**: Deve selecionar uma cultura
- **Polígono fechado**: Verificação automática
- **Permissões de usuário**: Verificação de permissões antes de criar

## Algoritmos Utilizados

### 1. Cálculo de Área (Fórmula de Shoelace Melhorada)
```dart
static double calculateAreaHectares(List<LatLng> points) {
  // Calcular latitude média para projeção
  final avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
  
  // Fatores de conversão para metros
  final metersPerDegLat = 111132.954 - 559.822 * cos(2 * avgLat * pi / 180) + 
                         1.175 * cos(4 * avgLat * pi / 180);
  final metersPerDegLng = (pi / 180) * 6378137.0 * cos(avgLat * pi / 180);
  
  // Converter para coordenadas em metros e aplicar Shoelace
  // Retorna área em hectares
}
```

### 2. Cálculo de Perímetro (Geodésicas)
```dart
static double calculatePerimeterMeters(List<LatLng> points) {
  double perimeter = 0.0;
  for (int i = 0; i < points.length - 1; i++) {
    final p1 = points[i];
    final p2 = points[i + 1];
    perimeter += _calculateGeodesicDistance(p1, p2);
  }
  return perimeter;
}
```

### 3. Algoritmo Ray Casting para Verificação de Ponto em Polígono
```dart
bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
  bool inside = false;
  int j = polygon.length - 1;
  
  for (int i = 0; i < polygon.length; i++) {
    if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
        (point.longitude < (polygon[j].longitude - polygon[i].longitude) * 
         (point.latitude - polygon[i].latitude) / 
         (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
      inside = !inside;
    }
    j = i;
  }
  
  return inside;
}
```

## Cores Disponíveis

O sistema oferece 8 cores predefinidas para subáreas:
- Azul (#2196F3)
- Verde (#4CAF50)
- Laranja (#FF9800)
- Roxo (#9C27B0)
- Vermelho (#F44336)
- Ciano (#00BCD4)
- Marrom (#795548)
- Azul acinzentado (#607D8B)

## Formatação Brasileira

O sistema utiliza formatação brasileira para números:
- Área: "1,25 ha" ou "1.250,5 m²"
- Perímetro: "150,5 m" ou "1,25 km"
- Separador decimal: vírgula (,)

## Melhorias Implementadas

### 1. Integração com Sistema Existente
- ✅ Usa `SubareaPlantio` existente
- ✅ Usa `SubareaPlantioService` existente
- ✅ Usa `SubareaPlantioRepository` existente
- ✅ Usa `SubareaPlantioDao` existente
- ✅ Mantém compatibilidade com banco de dados

### 2. Cálculos Geodésicos Precisos
- ✅ Fórmula de Shoelace melhorada com projeção local
- ✅ Cálculo de perímetro usando geodésicas
- ✅ Formatação brasileira de números
- ✅ Validação de pontos dentro de polígonos

### 3. Interface de Usuário
- ✅ Mapa interativo com Flutter Map
- ✅ Desenho de polígonos por toque
- ✅ Validação visual em tempo real
- ✅ Cálculo automático de área e perímetro
- ✅ Seleção de cores para subáreas

### 4. Validações e Segurança
- ✅ Verificação de permissões de usuário
- ✅ Validação de limites do talhão
- ✅ Validação de dados obrigatórios
- ✅ Tratamento de erros robusto

## Próximos Passos

### Funcionalidades Planejadas
1. **Edição de subáreas**: Modificar subáreas existentes
2. **Exclusão de subáreas**: Remover subáreas
3. **Visualização em lista**: Listar todas as subáreas
4. **Filtros avançados**: Filtrar por cultura, data, etc.
5. **Relatórios**: Relatórios de área por cultura
6. **Sincronização**: Sincronizar com servidor remoto

### Melhorias Técnicas
1. **GPS contínuo**: Rastreamento GPS em tempo real
2. **Simplificação automática**: Redução de ruído GPS
3. **Validação de sobreposição**: Evitar subáreas sobrepostas
4. **Cache de mapas**: Melhorar performance
5. **Exportação**: Exportar para KML, Shapefile

## Troubleshooting

### Problemas Comuns

1. **"Ponto deve estar dentro do talhão"**
   - Verifique se está clicando dentro dos limites do talhão
   - O talhão é exibido em azul no mapa

2. **"Polígono deve ter pelo menos 3 pontos"**
   - Adicione mais pontos clicando no mapa
   - Certifique-se de que o polígono está fechado

3. **Erro ao calcular área**
   - Verifique se o GPS está ativo
   - Tente redesenhar o polígono

4. **Subárea não salva**
   - Verifique se preencheu todos os campos obrigatórios
   - Certifique-se de que há conexão com o banco de dados

### Logs de Debug

O sistema gera logs detalhados para debug:
```
🏗️ Iniciando criação no repositório...
🔍 Verificando permissões...
✅ Permissões verificadas
🔍 Obtendo usuário atual...
✅ Usuário obtido: João Silva
🔍 Gerando ID único...
✅ ID gerado: subarea_123456
🔍 Gerando cor única...
✅ Cor gerada: 255, 99, 132, 0.7
🔍 Salvando no DAO...
✅ Subárea salva com sucesso no DAO
```

## Suporte

Para dúvidas ou problemas:
1. Verifique os logs de debug
2. Consulte a documentação técnica
3. Entre em contato com a equipe de desenvolvimento

## Compatibilidade

O sistema é totalmente compatível com:
- ✅ Banco de dados SQLite existente
- ✅ Modelos de dados existentes
- ✅ Serviços existentes
- ✅ Repositórios existentes
- ✅ Sistema de permissões existente
- ✅ Sistema de sincronização existente
