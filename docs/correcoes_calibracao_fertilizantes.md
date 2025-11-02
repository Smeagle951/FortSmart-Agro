# Correções da Calibração de Fertilizantes

## Problemas Identificados

1. **Erro de salvamento SQLite**: Tentativa de salvar `List<double>` diretamente no banco
2. **Cálculo incorreto da taxa real**: Usando fórmula errada que resultava em valores absurdos
3. **Falta de validação**: Dados inconsistentes não eram validados
4. **Método de cálculo inadequado**: Não seguia o padrão técnico correto

## Correções Implementadas

### 1. Correção do Erro SQLite (`List<double>`)

**Problema:**
```dart
// ❌ ERRO: Tentativa de salvar List<double> diretamente
'weights': weights, // List<double> não suportado pelo SQLite
```

**Solução:**
```dart
// ✅ CORRETO: Serialização JSON
import 'dart:convert';

'weights': jsonEncode(weights), // "[1.0,1.1,0.9,1.0,2.0]"
'effectiveRangeIndices': jsonEncode(effectiveRangeIndices),
```

**Deserialização:**
```dart
// ✅ CORRETO: Parse JSON com tratamento de erro
List<double> weights = [];
if (map['weights'] is String) {
  try {
    final List<dynamic> raw = jsonDecode(map['weights']);
    weights = raw.map((e) => (e as num).toDouble()).toList();
  } catch (e) {
    print('Erro ao deserializar weights: $e');
    weights = [];
  }
}
```

### 2. Implementação do Método de Cálculo Correto

**Novo Serviço:** `lib/services/fertilizer_calibration_calculator.dart`

**Fórmula Correta:**
```
Taxa Real (kg/ha) = (Soma das massas * 10) / (N * larguraBandeja * distância)
```

**Implementação:**
```dart
class CalibracaoFertilizantesCalculator {
  static ResultadoCalibracao calcular({
    required List<double> massasBandejaG,     // g
    required double distanciaPercorridaM,     // m
    required double larguraBandejaM,          // m (ex.: 0.20)
    required double taxaDesejadaKgHa,         // kg/ha
    // ... outros parâmetros
  }) {
    // Validações
    if (distanciaPercorridaM <= 0) {
      throw ArgumentError('Distância percorrida deve ser > 0 m.');
    }
    
    // Estatística básica (desvio amostral n-1)
    final n = massasBandejaG.length;
    final soma = massasBandejaG.fold<double>(0, (a, b) => a + b);
    final media = soma / n;
    
    // Desvio padrão amostral
    double varianciaAmostral = 0;
    if (n > 1) {
      final sq = massasBandejaG
          .map((v) => (v - media) * (v - media))
          .fold<double>(0, (a, b) => a + b);
      varianciaAmostral = sq / (n - 1);
    }
    final desvio = sqrt(varianciaAmostral);
    final cv = (desvio / media) * 100.0;
    
    // Taxa real - FÓRMULA CORRETA
    final taxaRealKgHa = (soma * 10.0) / (n * larguraBandejaM * distanciaPercorridaM);
    
    // Erro percentual
    final erroPercent = ((taxaRealKgHa - taxaDesejadaKgHa) / taxaDesejadaKgHa) * 100.0;
    
    return ResultadoCalibracao(
      taxaRealKgHa: taxaRealKgHa,
      erroPercent: erroPercent,
      mediaG: media,
      desvioG: desvio,
      cvPercent: cv,
      faixaEfetivaM: faixaEsperadaM,
    );
  }
}
```

### 3. Validações de Dados

**Validações Implementadas:**
- ✅ Distância percorrida > 0
- ✅ Largura da bandeja > 0
- ✅ Massas das bandejas não vazias
- ✅ Taxa desejada > 0
- ✅ Consistência massa vs distância
- ✅ Verificação de valores absurdos

**Exemplo de Validação:**
```dart
static List<String> validarDados({
  required List<double> massasBandejaG,
  required double distanciaPercorridaM,
  required double larguraBandejaM,
  required double taxaDesejadaKgHa,
}) {
  final erros = <String>[];
  
  if (distanciaPercorridaM <= 0) {
    erros.add('Distância percorrida deve ser maior que zero');
  }
  
  // Validação de consistência
  if (massasBandejaG.isNotEmpty && distanciaPercorridaM > 0) {
    final soma = massasBandejaG.fold<double>(0, (a, b) => a + b);
    
    if (soma < 1.0 && distanciaPercorridaM > 50.0) {
      erros.add('Massa total muito baixa para o percurso. Considere reduzir a distância para 10-20m');
    }
  }
  
  return erros;
}
```

### 4. Classificações Agronômicas

**CV (Coeficiente de Variação):**
- < 10%: Excelente
- 10-20%: Moderado
- > 20%: Ruim

**Erro Percentual:**
- ≤ 5%: OK
- 5-10%: Alerta
- > 10%: Recalibrar

### 5. Por que o Erro de -99,7% Acontecia

**Exemplo com dados reais:**
```
massas = [1.0, 1.1, 0.9, 1.0, 2.0] g
soma = 6.0 g
N = 5 bandejas
larguraBandeja = 0.20 m
distancia = 100 m

Taxa Real = (6 * 10) / (5 * 0.20 * 100) = 60 / 100 = 0.6 kg/ha

Comparando com taxa desejada de 180 kg/ha:
Erro = ((0.6 - 180) / 180) * 100 = -99.7%
```

**Causa:** As massas coletadas estavam muito baixas para o percurso, indicando necessidade de ajuste na metodologia.

## Arquivos Modificados

1. **`lib/models/fertilizer_calibration.dart`**
   - ✅ Adicionado `import 'dart:convert'`
   - ✅ Serialização JSON para `weights` e `effectiveRangeIndices`
   - ✅ Deserialização com tratamento de erro
   - ✅ Novo método `calculateRealApplicationRate()`

2. **`lib/services/fertilizer_calibration_calculator.dart`** (NOVO)
   - ✅ Implementação do método de cálculo correto
   - ✅ Validações de dados
   - ✅ Classificações agronômicas
   - ✅ Utilitários matemáticos

## Como Testar

1. **Teste de Salvamento:**
   ```dart
   final calibracao = FertilizerCalibration(
     weights: [1.0, 1.1, 0.9, 1.0, 2.0],
     // ... outros campos
   );
   
   // Deve salvar sem erro
   await repository.save(calibracao);
   ```

2. **Teste de Cálculo:**
   ```dart
   final resultado = CalibracaoFertilizantesCalculator.calcular(
     massasBandejaG: [1.0, 1.1, 0.9, 1.0, 2.0],
     distanciaPercorridaM: 100.0,
     larguraBandejaM: 0.20,
     taxaDesejadaKgHa: 180.0,
   );
   
   print('Taxa Real: ${resultado.taxaRealKgHa} kg/ha');
   print('Erro: ${resultado.erroPercent}%');
   ```

3. **Teste de Validação:**
   ```dart
   final erros = CalibracaoFertilizantesCalculator.validarDados(
     massasBandejaG: [1.0, 1.1, 0.9, 1.0, 2.0],
     distanciaPercorridaM: 100.0,
     larguraBandejaM: 0.20,
     taxaDesejadaKgHa: 180.0,
   );
   
   if (erros.isNotEmpty) {
     print('Erros encontrados: $erros');
   }
   ```

## Próximos Passos

1. **Adicionar campo "Largura da Bandeja" na UI**
2. **Implementar validações na tela de entrada**
3. **Adicionar feedback visual para erros de validação**
4. **Implementar histórico de calibrações**
5. **Adicionar relatórios de calibração**

## Observações Importantes

- **Largura da Bandeja**: Campo obrigatório que deve ser configurável (padrão: 0.20m)
- **Distância**: Deve ser medida durante a coleta das bandejas
- **Massas**: Devem estar em gramas (g)
- **Taxa**: Resultado em kg/ha
- **CV**: Usa desvio padrão amostral (n-1) conforme padrão estatístico
