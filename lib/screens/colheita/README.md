# 🌽 Módulo de Colheita - FortSmart Agro

## 📋 Visão Geral

O módulo de colheita permite calcular e monitorar perdas durante a colheita de milho, fornecendo dados precisos para otimização do processo agrícola.

## 🎯 Funcionalidades Principais

### 1. Cálculo de Perdas na Colheita
- **Objetivo**: Calcular perda de grãos em kg/ha e sacas/ha
- **Método**: Baseado em coleta de resíduos no campo
- **Comparação**: Com limites aceitáveis (ex: 1,0 saca/ha)

### 2. Formatação Brasileira
- **Números**: Vírgula para decimal, ponto para milhares
- **Exemplo**: `1.026.486,76` (em vez de `1,026,486.76`)

## 🧮 Lógica de Cálculo

### Fórmulas Implementadas

```dart
// 1. Converter peso de gramas para kg
double pesoKg = pesoGramas / 1000.0;

// 2. Calcular perda em kg/ha
double perdaKgHa = (pesoKg / areaColeta) * 10000.0;

// 3. Calcular perda em sacas/ha
double perdaScHa = perdaKgHa / pesoSaca; // pesoSaca = 60kg

// 4. Classificar a perda
String classificacao = perdaScHa <= perdaAceitavel
    ? "Aceitável"
    : perdaScHa <= perdaAceitavel * 1.5
        ? "Alerta"
        : "Alta";
```

### Exemplo de Cálculo
- **Peso coletado**: 21 gramas
- **Área da coleta**: 2,00 m²
- **Peso da saca**: 60 kg

**Resultado**:
- Perda estimada: 25,93 kg/ha
- Equivalente: 0,43 sc/ha
- Classificação: ✅ Aceitável

## 🎨 Interface do Usuário

### Seções da Tela

1. **Dados da Coleta**
   - Data da coleta (com seletor de data)
   - Talhão (dropdown integrado com módulo talhões)
   - Cultura (dropdown integrado com módulo culturas)

2. **Método de Cálculo**
   - 🪙 Peso em gramas coletado (ativo por padrão)
   - 📋 PMS do grão (Peso de Mil Sementes)

3. **Campos de Cálculo**
   - Área da coleta (m²) - com formatação brasileira
   - Peso coletado (g) - com formatação brasileira
   - Peso da saca (kg) - padrão 60kg

4. **Resultados Automáticos**
   - Perda em kg/ha (formatado)
   - Perda em sacas/ha (formatado)
   - Classificação com cores e ícones

5. **Complementares**
   - Nome do técnico
   - Localização GPS (automática)
   - Observações

### Cores de Classificação

| Classificação | Cor | Ícone |
|---------------|-----|-------|
| Aceitável | Verde | ✅ |
| Alerta | Laranja | ⚠️ |
| Alta | Vermelho | ❌ |

## 🔧 Arquivos do Módulo

### Modelos
- `colheita_perda_model.dart` - Modelo de dados para perdas na colheita

### Telas
- `colheita_main_screen.dart` - Tela principal do módulo
- `colheita_perda_screen.dart` - Tela de cálculo de perdas

### Widgets
- `brazilian_number_formatter.dart` - Formatação de números brasileiros

## 📱 Como Usar

### 1. Acessar o Módulo
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ColheitaMainScreen(),
  ),
);
```

### 2. Calcular Perdas
1. Selecione a data da coleta
2. Escolha o talhão e cultura
3. Defina o método de cálculo
4. Preencha os dados da coleta
5. Visualize os resultados automáticos
6. Salve os dados

### 3. Formatação de Números
```dart
// Formatar número para exibição
String formatado = BrazilianNumberFormatter.format(1026486.76);
// Resultado: "1.026.486,76"

// Converter string formatada para número
double? numero = BrazilianNumberFormatter.parse("1.026.486,76");
// Resultado: 1026486.76
```

## 🔗 Integrações

### Módulos Utilizados
- **Talhões**: Para seleção de talhões
- **Culturas**: Para seleção de culturas
- **GPS**: Para captura automática de localização

### Serviços
- `TalhaoModuleService` - Gerenciamento de talhões
- `CulturaTalhaoService` - Gerenciamento de culturas
- `Geolocator` - Captura de coordenadas GPS

## 🚀 Próximas Funcionalidades

- [ ] Histórico de coletas
- [ ] Relatórios de perdas
- [ ] Configurações do módulo
- [ ] Exportação de dados
- [ ] Sincronização com servidor
- [ ] Múltiplas culturas (além do milho)

## 📊 Validações

### Dados Obrigatórios
- Talhão selecionado
- Cultura selecionada
- Área da coleta > 0
- Peso coletado > 0
- Nome do técnico

### Validações de Cálculo
- Área da coleta deve ser positiva
- Peso coletado deve ser positivo
- Peso da saca deve ser positivo

## 🎯 Benefícios

1. **Precisão**: Cálculos automáticos e precisos
2. **Facilidade**: Interface intuitiva e responsiva
3. **Padrão Brasileiro**: Formatação adequada para o mercado nacional
4. **Integração**: Conectado com outros módulos do sistema
5. **Rastreabilidade**: Captura automática de localização e data
6. **Classificação**: Avaliação automática da qualidade da colheita

## 🔍 Monitoramento

O módulo registra:
- Data e hora da coleta
- Localização GPS
- Técnico responsável
- Resultados calculados
- Observações adicionais

Todos os dados são salvos localmente e podem ser sincronizados quando necessário. 