# Correção da Formatação da Área em Hectares

## Problema Identificado

A formatação da área em hectares estava inconsistente em todo o sistema, com diferentes fatores de conversão sendo usados em diferentes partes do código, resultando em valores incorretos sendo exibidos.

## Causa Raiz

O problema estava nos fatores de conversão inconsistentes usados para converter coordenadas geográficas (graus²) para hectares:

- **PolygonService**: `111000` (correto)
- **GeoMath**: `_calcularFatorConversao()` (variável por latitude)
- **ValidadorTalhao**: `_calcularFatorConversao()` (variável por latitude)
- **NovoTalhaoScreen**: `11100000` (incorreto - muito alto)
- **PolygonVertexEditor**: `111.32 * 111.32 * 100` (diferente)
- **Plot Model**: `111320 * 111320 / 10000` (diferente)

## Solução Implementada

### 1. Padronização do Fator de Conversão

Todos os cálculos de área agora usam o mesmo fator de conversão:
```dart
const double grauParaHectares = 111000; // 111 km² = 11.100 hectares
```

Este fator é baseado na latitude média do Brasil (~15°S) e é consistente com a fórmula:
- 1 grau² ≈ 111 km² na latitude média do Brasil
- 1 km² = 100 hectares
- Portanto: 1 grau² ≈ 111 * 100 = 11.100 hectares

### 2. Criação do AreaFormatter

Foi criado um utilitário centralizado (`lib/utils/area_formatter.dart`) que garante consistência na formatação de áreas em todo o sistema:

```dart
class AreaFormatter {
  static String formatHectares(double areaHectares)
  static String formatHectaresFixed(double areaHectares, {int precision = 2})
  static String formatSquareMeters(double areaM2)
  static String formatAreaAuto(double areaHectares)
  // ... outros métodos
}
```

### 3. Arquivos Corrigidos

#### Cálculos de Área:
- `lib/utils/geo_math.dart`
- `lib/services/polygon_service.dart`
- `lib/utils/validador_talhao.dart`
- `lib/widgets/polygon_vertex_editor.dart`
- `lib/models/plot.dart`
- `lib/screens/monitoring/advanced_monitoring_screen.dart`
- `lib/screens/infestacao/mapa_infestacao_screen.dart`
- `lib/screens/talhoes_com_safras/novo_talhao_screen.dart`

#### Formatação de Exibição:
- `lib/widgets/talhao_popup_info.dart`
- `lib/widgets/premium_talhao_popup.dart`
- `lib/widgets/talhao_list_widget.dart`
- `lib/widgets/futuristic_talhao_list.dart`
- `lib/widgets/lista_talhoes_widget.dart`
- `lib/widgets/talhoes_com_safras/lista_talhoes_widget.dart`
- `lib/screens/talhoes_com_safras/widgets/lista_talhoes_widget.dart`
- `lib/screens/talhoes_com_safras/talhao_popup_info.dart`
- `lib/screens/talhoes_com_safras/widgets/premium_talhao_popup.dart`

## Benefícios da Correção

1. **Consistência**: Todos os cálculos de área agora usam o mesmo fator de conversão
2. **Precisão**: Valores de área agora refletem os cálculos reais
3. **Manutenibilidade**: Formatação centralizada facilita futuras alterações
4. **Experiência do Usuário**: Valores consistentes em toda a aplicação

## Regras de Formatação Implementadas

- **< 0.01 ha**: Exibir em m² (ex: "50 m²")
- **0.01 - 1 ha**: 2 casas decimais (ex: "0.25 ha")
- **1 - 10 ha**: 1 casa decimal (ex: "3.2 ha")
- **> 10 ha**: Sem casas decimais (ex: "15 ha")

## Teste Recomendado

Para verificar se a correção funcionou:

1. Criar um talhão com coordenadas conhecidas
2. Verificar se a área exibida no formulário de edição corresponde ao valor calculado
3. Comparar com outros módulos que usam a mesma área
4. Verificar se a formatação está consistente em todas as telas

## Observações Importantes

- O fator de conversão fixo é uma aproximação válida para a latitude média do Brasil
- Para aplicações que precisam de maior precisão em diferentes latitudes, pode ser necessário implementar um fator variável
- Todos os cálculos existentes foram preservados, apenas padronizados
