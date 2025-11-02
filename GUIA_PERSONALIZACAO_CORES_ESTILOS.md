# 🎨 Guia de Personalização - Cores e Estilos

## 📋 Objetivo
Personalizar o sistema de custos por hectare com cores e estilos que se integrem ao design do FortSmart Agro, mantendo consistência visual e melhorando a experiência do usuário.

---

## 🎨 Passo 1: Definir Paleta de Cores

### Cores Principais do Sistema
```dart
// Em lib/constants/app_colors.dart
class AppColors {
  // Cores primárias
  static const Color primary = Color(0xFF2E7D32);      // Verde agrícola
  static const Color primaryLight = Color(0xFF4CAF50); // Verde claro
  static const Color primaryDark = Color(0xFF1B5E20);  // Verde escuro
  
  // Cores secundárias
  static const Color secondary = Color(0xFFFF8F00);    // Laranja
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFE65100);
  
  // Cores de fundo
  static const Color background = Color(0xFFFAFAFA);   // Cinza muito claro
  static const Color surface = Color(0xFFFFFFFF);      // Branco
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Cores de texto
  static const Color textPrimary = Color(0xFF212121);  // Preto suave
  static const Color textSecondary = Color(0xFF757575); // Cinza médio
  static const Color textLight = Color(0xFFBDBDBD);    // Cinza claro
  
  // Cores de status
  static const Color success = Color(0xFF4CAF50);      // Verde
  static const Color warning = Color(0xFFFF9800);      // Laranja
  static const Color error = Color(0xFFF44336);        // Vermelho
  static const Color info = Color(0xFF2196F3);         // Azul
  
  // Cores por tipo de operação
  static const Color plantio = Color(0xFF4CAF50);      // Verde
  static const Color adubacao = Color(0xFF2196F3);     // Azul
  static const Color pulverizacao = Color(0xFFFF9800); // Laranja
  static const Color colheita = Color(0xFFFFC107);     // Âmbar
  static const Color solo = Color(0xFF795548);         // Marrom
  static const Color outros = Color(0xFF9E9E9E);       // Cinza
}
```

**Ação:** ✅ Criar arquivo de constantes de cores

---

## 🎨 Passo 2: Criar Tema Personalizado

### Configurar ThemeData
```dart
// Em lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // Cores primárias
      primarySwatch: Colors.green,
      primaryColor: AppColors.primary,
      primaryColorLight: AppColors.primaryLight,
      primaryColorDark: AppColors.primaryDark,
      
      // Cores secundárias
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: Colors.white,
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Cards
      cardTheme: CardTheme(
        color: AppColors.cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Textos
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.error),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
```

**Ação:** ✅ Criar tema personalizado

---

## 🎨 Passo 3: Atualizar Dashboard de Custos

### Aplicar Cores Personalizadas
```dart
// Em lib/screens/custos/custo_por_hectare_dashboard_screen.dart

class _CustoPorHectareDashboardScreenState extends State<CustoPorHectareDashboardScreen> {
  
  // Atualizar cores dos indicadores
  Widget _buildIndicador(String titulo, String valor, IconData icone, Color cor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, color: cor, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            valor,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: cor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Atualizar cores dos filtros
  Widget _buildFiltros() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.textLight.withOpacity(0.3))),
      ),
      child: Column(
        children: [
          // Filtros com cores personalizadas
          Row(
            children: [
              Expanded(
                child: _buildDropdownFiltro(
                  label: 'Talhão',
                  value: _talhaoSelecionado?.name,
                  items: _talhoes.map((t) => t.name).toList(),
                  onChanged: (value) {
                    setState(() {
                      _talhaoSelecionado = _talhoes.firstWhere((t) => t.name == value);
                    });
                    _carregarDados();
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildDatePicker(
                  label: 'Data Início',
                  value: _dataInicio,
                  onChanged: (date) {
                    setState(() {
                      _dataInicio = date;
                    });
                    _carregarDados();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Atualizar cores da tabela
  Widget _buildTabelaCustosPorTalhao() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Custos por Talhão',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Conteúdo da tabela...
        ],
      ),
    );
  }
}
```

**Ação:** ✅ Aplicar cores personalizadas no dashboard

---

## 🎨 Passo 4: Atualizar Histórico de Custos

### Personalizar Cards de Registro
```dart
// Em lib/screens/historico/historico_custos_talhao_screen.dart

class _HistoricoCustosTalhaoScreenState extends State<HistoricoCustosTalhaoScreen> {
  
  // Atualizar cores dos tipos de registro
  final Map<String, Map<String, dynamic>> _tiposRegistro = {
    'plantio': {
      'nome': 'Plantio',
      'icone': Icons.eco,
      'cor': AppColors.plantio,
      'emoji': '🌱',
    },
    'adubacao': {
      'nome': 'Adubação',
      'icone': Icons.water_drop,
      'cor': AppColors.adubacao,
      'emoji': '💧',
    },
    'pulverizacao': {
      'nome': 'Pulverização',
      'icone': Icons.science,
      'cor': AppColors.pulverizacao,
      'emoji': '🧴',
    },
    'colheita': {
      'nome': 'Colheita',
      'icone': Icons.agriculture,
      'cor': AppColors.colheita,
      'emoji': '🌾',
    },
    'solo': {
      'nome': 'Solo',
      'icone': Icons.terrain,
      'cor': AppColors.solo,
      'emoji': '🌍',
    },
    'outros': {
      'nome': 'Outros',
      'icone': Icons.settings,
      'cor': AppColors.outros,
      'emoji': '⚙️',
    },
  };

  // Atualizar design dos cards
  Widget _buildListaRegistros() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _registros.length,
      itemBuilder: (context, index) {
        final registro = _registros[index];
        final tipo = registro['tipo'] as String;
        final dadosTipo = _tiposRegistro[tipo]!;
        
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Cabeçalho do card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dadosTipo['cor'].withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: dadosTipo['cor'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        dadosTipo['icone'],
                        color: dadosTipo['cor'],
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            registro['titulo'],
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: dadosTipo['cor'],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateUtils.formatDate(registro['data']),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
                      onSelected: (action) => _executarAcao(action, registro),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'duplicar',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 16, color: AppColors.secondary),
                              SizedBox(width: 8),
                              Text('Duplicar'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remover',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Remover'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Conteúdo do card
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Talhão: ${registro['talhao']} / ${registro['safra']}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Área: ${registro['area'].toStringAsFixed(1)} ha',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Produto(s): ${registro['produtos']}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'R\$ ${registro['custo_total'].toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: dadosTipo['cor'],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'R\$ ${registro['custo_ha'].toStringAsFixed(2)}/ha',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

**Ação:** ✅ Personalizar design do histórico

---

## 🎨 Passo 5: Atualizar Filtros e Chips

### Personalizar FilterChips
```dart
// Em lib/screens/historico/historico_custos_talhao_screen.dart

Widget _buildFiltros() {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.background,
      border: Border(bottom: BorderSide(color: AppColors.textLight.withOpacity(0.3))),
    ),
    child: Column(
      children: [
        // Filtros de dropdown
        Row(
          children: [
            Expanded(
              child: _buildDropdownFiltro(
                label: 'Talhão',
                value: _talhaoSelecionado?.name,
                items: _talhoes.map((t) => t.name).toList(),
                onChanged: (value) {
                  setState(() {
                    _talhaoSelecionado = _talhoes.firstWhere((t) => t.name == value);
                  });
                  _carregarRegistros();
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDropdownFiltro(
                label: 'Safra',
                value: _safraSelecionada,
                items: _safras,
                onChanged: (value) {
                  setState(() {
                    _safraSelecionada = value;
                  });
                  _carregarRegistros();
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        
        // Filtros de data
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                label: 'Data Início',
                value: _dataInicio,
                onChanged: (date) {
                  setState(() {
                    _dataInicio = date;
                  });
                  _carregarRegistros();
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDatePicker(
                label: 'Data Fim',
                value: _dataFim,
                onChanged: (date) {
                  setState(() {
                    _dataFim = date;
                  });
                  _carregarRegistros();
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        
        // Tipos de registro
        Text(
          'Tipos de Registro',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _tiposRegistro.entries.map((entry) {
            final tipo = entry.key;
            final dados = entry.value;
            final isSelected = _tiposRegistroSelecionados.contains(tipo);
            
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(dados['emoji']),
                  SizedBox(width: 4),
                  Text(dados['nome']),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _tiposRegistroSelecionados.add(tipo);
                  } else {
                    _tiposRegistroSelecionados.remove(tipo);
                  }
                });
                _carregarRegistros();
              },
              backgroundColor: AppColors.surface,
              selectedColor: dados['cor'].withOpacity(0.2),
              checkmarkColor: dados['cor'],
              labelStyle: TextStyle(
                color: isSelected ? dados['cor'] : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? dados['cor'] : AppColors.textLight,
                  width: isSelected ? 2 : 1,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}
```

**Ação:** ✅ Personalizar filtros e chips

---

## 🎨 Passo 6: Atualizar Resumo de Custos

### Personalizar Footer Fixo
```dart
// Em lib/screens/historico/historico_custos_talhao_screen.dart

Widget _buildResumoCustos() {
  final resumo = _resumoCustos!;
  final custosPorTipo = resumo['custos_por_tipo'] as Map<String, double>;
  final custoTotal = resumo['custo_total'] as double;
  final custoMedioPorHa = resumo['custo_medio_por_ha'] as double;
  final totalRegistros = resumo['total_registros'] as int;

  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.textLight.withOpacity(0.3))),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: Offset(0, -2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              '📊 Resumo Custos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${totalRegistros} registros',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        
        // Custos por tipo
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: custosPorTipo.entries.map((entry) {
            final tipo = entry.key;
            final custo = entry.value;
            final dadosTipo = _tiposRegistro[tipo]!;
            final areaTotal = resumo['area_total'] as double;
            final custoPorHa = areaTotal > 0 ? custo / areaTotal : 0.0;
            
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: dadosTipo['cor'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: dadosTipo['cor'].withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(dadosTipo['emoji']),
                      SizedBox(width: 4),
                      Text(
                        dadosTipo['nome'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dadosTipo['cor'],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'R\$ ${custo.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: dadosTipo['cor'],
                    ),
                  ),
                  Text(
                    'R\$ ${custoPorHa.toStringAsFixed(2)}/ha',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        
        SizedBox(height: 12),
        Divider(color: AppColors.textLight.withOpacity(0.3)),
        
        // Total
        Row(
          children: [
            Text(
              'TOTAL:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${custoTotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'R\$ ${custoMedioPorHa.toStringAsFixed(2)}/ha',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
```

**Ação:** ✅ Personalizar resumo de custos

---

## 🎨 Passo 7: Aplicar Tema no main.dart

### Configurar Tema Global
```dart
// Em lib/main.dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FortSmart Agro',
      theme: AppTheme.lightTheme,
      home: MainMenuWithCostsIntegration(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

**Ação:** ✅ Aplicar tema global

---

## ✅ Checklist de Personalização

### Cores e Tema
- [ ] Paleta de cores definida
- [ ] Tema personalizado criado
- [ ] Tema aplicado no main.dart
- [ ] Cores consistentes em todo o app

### Componentes Personalizados
- [ ] Dashboard com cores personalizadas
- [ ] Histórico com design moderno
- [ ] Cards com sombras e bordas arredondadas
- [ ] Filtros com design consistente

### Tipografia
- [ ] Textos com hierarquia clara
- [ ] Cores de texto apropriadas
- [ ] Tamanhos de fonte consistentes
- [ ] Pesos de fonte adequados

### Interatividade
- [ ] Estados hover e pressed
- [ ] Feedback visual adequado
- [ ] Animações suaves
- [ ] Transições fluidas

---

## 🎯 Status da Personalização

**Progresso:** 0% → 100%

**Próximo Passo:** Após completar a personalização, prosseguir para:
1. 🧪 Validação completa das funcionalidades

---

## 📞 Suporte Durante Personalização

Se encontrar problemas durante a personalização:

1. **Verificar imports:** Confirmar se AppColors está importado
2. **Testar em diferentes dispositivos:** Verificar responsividade
3. **Verificar acessibilidade:** Contraste de cores adequado
4. **Testar modo escuro:** Se aplicável

**Status:** ✅ Pronto para iniciar personalização
