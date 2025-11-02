import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../models/calculo_sementes_state.dart';
import '../services/calculo_sementes_service.dart';

/// Widget para formulário de parâmetros de entrada
class ParametrosEntradaForm extends StatelessWidget {
  final CalculoSementesState state;
  final Function(CalculoSementesState) onStateChanged;

  const ParametrosEntradaForm({
    super.key,
    required this.state,
    required this.onStateChanged,
  });

  /// Formata números para exibição no padrão brasileiro
  String _formatNumber(double value, {bool showDecimals = true}) {
    if (showDecimals) {
      return NumberFormat("#,##0.00", "pt_BR").format(value);
    } else {
      return NumberFormat("#,##0", "pt_BR").format(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📥 Parâmetros de Cálculo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: FortSmartTheme.primaryColor,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            // Espaçamento
            _buildEspacamentoField(),
            const SizedBox(height: 16),
            
            // Campo condicional baseado no modo
            if (state.modoCalculo == ModoCalculo.populacao) ...[
              _buildPopulacaoField(),
            ] else ...[
              _buildSementesPorMetroField(),
            ],
            
            const SizedBox(height: 16),
            
            // Campos do bag
            _buildBagFields(),
            const SizedBox(height: 16),
            
            // PMS Manual
            _buildPMSManualSection(),
            const SizedBox(height: 16),
            
            // Germinação e Vigor
            _buildGerminacaoVigorFields(),
            const SizedBox(height: 16),
            
            // Área desejada
            _buildAreaDesejadaSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEspacamentoField() {
    return TextFormField(
      initialValue: state.espacamento > 0 ? state.espacamento.toString() : '',
      decoration: InputDecoration(
        labelText: 'Espaçamento entre linhas (m)',
        hintText: 'Ex: 0.45',
        helperText: 'Use ponto (.) como separador decimal',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
        ),
        prefixIcon: Icon(Icons.space_bar, color: FortSmartTheme.primaryColor),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Aceita ponto como decimal
      ],
      validator: (value) {
        // Substituir vírgula por ponto antes de validar
        final normalizedValue = value?.replaceAll(',', '.');
        return CalculoSementesService.validarEspacamento(double.tryParse(normalizedValue ?? ''));
      },
      onChanged: (value) {
        print('🔍 DEBUG ESPAÇAMENTO - Input recebido: "$value"');
        // Substituir vírgula por ponto antes de fazer parse
        final normalizedValue = value.replaceAll(',', '.');
        print('🔍 DEBUG ESPAÇAMENTO - Valor normalizado: "$normalizedValue"');
        final newValue = double.tryParse(normalizedValue);
        print('🔍 DEBUG ESPAÇAMENTO - Valor parseado: $newValue');
        if (newValue != null) {
          print('🔍 DEBUG ESPAÇAMENTO - Atualizando estado para: $newValue');
          onStateChanged(state.copyWith(espacamento: newValue));
        } else {
          print('❌ DEBUG ESPAÇAMENTO - Falha no parse, valor não salvo');
        }
      },
    );
  }

  Widget _buildSementesPorMetroField() {
    return TextFormField(
      initialValue: state.sementesPorMetro > 0 ? state.sementesPorMetro.toStringAsFixed(0) : '',
      decoration: InputDecoration(
        labelText: 'Sementes por metro',
        hintText: 'Ex: 14',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
        ),
        prefixIcon: Icon(Icons.grain, color: FortSmartTheme.primaryColor),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // CORREÇÃO: Apenas dígitos para evitar problema com decimal
      ],
      validator: (value) {
        final parsedValue = int.tryParse(value ?? '');
        return CalculoSementesService.validarSementesPorMetro(
          parsedValue?.toDouble() ?? 0.0, 
          state.modoCalculo,
        );
      },
      onChanged: (value) {
        print('🔍 DEBUG SEMENTES/METRO - Input recebido: "$value"');
        final newValue = int.tryParse(value); // CORREÇÃO: Usar int.tryParse
        print('🔍 DEBUG SEMENTES/METRO - Valor parseado: $newValue');
        if (newValue != null) {
          print('🔍 DEBUG SEMENTES/METRO - Atualizando estado para: ${newValue.toDouble()}');
          onStateChanged(state.copyWith(sementesPorMetro: newValue.toDouble()));
        } else {
          print('❌ DEBUG SEMENTES/METRO - Falha no parse, valor não salvo');
        }
      },
    );
  }

  Widget _buildPopulacaoField() {
    return TextFormField(
      initialValue: state.populacaoDesejada > 0 ? _formatNumber(state.populacaoDesejada, showDecimals: false) : '',
      decoration: InputDecoration(
        labelText: 'População desejada (plantas/ha)',
        hintText: 'Ex: 300000',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
        ),
        prefixIcon: Icon(Icons.people, color: FortSmartTheme.primaryColor),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) => CalculoSementesService.validarPopulacaoDesejada(
        double.tryParse(value ?? ''), 
        state.modoCalculo,
      ),
      onChanged: (value) {
        final newValue = double.tryParse(value);
        if (newValue != null) {
          onStateChanged(state.copyWith(populacaoDesejada: newValue));
        }
      },
    );
  }

  Widget _buildBagFields() {
    return Column(
      children: [
        // Campo principal baseado no modo
        TextFormField(
          initialValue: state.modoBag == ModoBag.sementesPorBag 
              ? (state.sementesPorBag > 0 ? _formatNumber(state.sementesPorBag, showDecimals: false) : '')
              : (state.pesoBag > 0 ? _formatNumber(state.pesoBag, showDecimals: false) : ''),
          decoration: InputDecoration(
            labelText: state.modoBag == ModoBag.sementesPorBag 
                ? 'Sementes por bag (milhões)' 
                : 'Peso do bag (kg)',
            hintText: state.modoBag == ModoBag.sementesPorBag 
                ? 'Ex: 5000000' 
                : 'Ex: 1000',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
            ),
            prefixIcon: Icon(
              state.modoBag == ModoBag.sementesPorBag 
                  ? Icons.grain 
                  : Icons.scale,
              color: FortSmartTheme.primaryColor,
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) => state.modoBag == ModoBag.sementesPorBag
              ? CalculoSementesService.validarSementesPorBag(double.tryParse(value ?? ''), state.modoBag)
              : CalculoSementesService.validarPesoBag(double.tryParse(value ?? '')),
          onChanged: (value) {
            final newValue = double.tryParse(value);
            if (newValue != null) {
              if (state.modoBag == ModoBag.sementesPorBag) {
                onStateChanged(state.copyWith(sementesPorBag: newValue));
              } else {
                onStateChanged(state.copyWith(pesoBag: newValue));
              }
            }
          },
        ),
        const SizedBox(height: 16),
        
        // Campo de número de bags
        TextFormField(
          initialValue: state.numeroBags > 0 ? _formatNumber(state.numeroBags.toDouble(), showDecimals: false) : '',
          decoration: InputDecoration(
            labelText: 'Número de Bags',
            hintText: 'Ex: 1',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
            ),
            prefixIcon: Icon(Icons.inventory, color: FortSmartTheme.primaryColor),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) => CalculoSementesService.validarNumeroBags(int.tryParse(value ?? '')),
          onChanged: (value) {
            final newValue = int.tryParse(value);
            if (newValue != null) {
              onStateChanged(state.copyWith(numeroBags: newValue));
            }
          },
        ),
        
        // Campo de peso do bag - SEMPRE visível quando modo é "sementes por bag"
        if (state.modoBag == ModoBag.sementesPorBag) ...[
          const SizedBox(height: 16),
          TextFormField(
            initialValue: state.pesoBag > 0 ? _formatNumber(state.pesoBag, showDecimals: false) : '',
            decoration: InputDecoration(
              labelText: 'Peso do bag (kg) - Necessário para PMS',
              hintText: 'Ex: 1000',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
              ),
              prefixIcon: Icon(Icons.scale, color: FortSmartTheme.primaryColor),
              helperText: 'Informe o peso do bag para calcular o PMS (Peso de Mil Sementes)',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) => CalculoSementesService.validarPesoBag(double.tryParse(value ?? '')),
            onChanged: (value) {
              final newValue = double.tryParse(value);
              if (newValue != null) {
                onStateChanged(state.copyWith(pesoBag: newValue));
              }
            },
          ),
        ],
        
        // Campo de sementes por bag (sempre necessário para calcular PMS quando modo é peso)
        if (state.modoBag == ModoBag.pesoPorBag) ...[
          const SizedBox(height: 16),
          TextFormField(
            initialValue: state.sementesPorBag > 0 ? _formatNumber(state.sementesPorBag, showDecimals: false) : '',
            decoration: InputDecoration(
              labelText: 'Sementes por bag (milhões) - Necessário para PMS',
              hintText: 'Ex: 5000000',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
              ),
              prefixIcon: Icon(Icons.grain, color: FortSmartTheme.primaryColor),
              helperText: 'Informe o número de sementes por bag para calcular o PMS',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) => CalculoSementesService.validarSementesPorBag(double.tryParse(value ?? ''), state.modoBag),
            onChanged: (value) {
              final newValue = double.tryParse(value);
              if (newValue != null) {
                onStateChanged(state.copyWith(sementesPorBag: newValue));
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPMSManualSection() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Inserir PMS manualmente'),
          subtitle: const Text('Peso de Mil Sementes em g/1000'),
          value: state.usarPMSManual,
          activeColor: FortSmartTheme.primaryColor,
          onChanged: (value) {
            onStateChanged(state.copyWith(usarPMSManual: value ?? false));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        
        if (state.usarPMSManual) ...[
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'PMS (g/1000 sementes)',
              hintText: 'Ex: 180',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
              ),
              prefixIcon: Icon(Icons.scale, color: FortSmartTheme.primaryColor),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) => CalculoSementesService.validarPMSManual(
              double.tryParse(value ?? ''), 
              state.usarPMSManual,
            ),
            onChanged: (value) {
              final newValue = double.tryParse(value);
              onStateChanged(state.copyWith(pmsManual: newValue));
            },
          ),
        ],
      ],
    );
  }

  Widget _buildGerminacaoVigorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⚠️ Aviso: Campos informativos
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ℹ️ Germinação e Vigor são APENAS informativos (não afetam o cálculo)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: state.germinacao > 0 ? _formatNumber(state.germinacao, showDecimals: false) : '',
                decoration: InputDecoration(
                  labelText: 'Germinação (%) - Informativo',
                  hintText: 'Ex: 90',
                  helperText: 'Não afeta o cálculo',
                  helperStyle: TextStyle(color: Colors.blue.shade600, fontSize: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
                  ),
                  prefixIcon: Icon(Icons.eco, color: Colors.blue.shade400),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) => CalculoSementesService.validarGerminacao(double.tryParse(value ?? '')),
                onChanged: (value) {
                  final newValue = double.tryParse(value);
                  if (newValue != null) {
                    onStateChanged(state.copyWith(germinacao: newValue));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: state.vigor > 0 ? _formatNumber(state.vigor, showDecimals: false) : '',
                decoration: InputDecoration(
                  labelText: 'Vigor (%) - Informativo',
                  hintText: 'Ex: 95',
                  helperText: 'Não afeta o cálculo',
                  helperStyle: TextStyle(color: Colors.blue.shade600, fontSize: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
                  ),
                  prefixIcon: Icon(Icons.health_and_safety, color: Colors.blue.shade400),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) => CalculoSementesService.validarVigor(double.tryParse(value ?? '')),
                onChanged: (value) {
                  final newValue = double.tryParse(value);
                  if (newValue != null) {
                    onStateChanged(state.copyWith(vigor: newValue));
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAreaDesejadaSection() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Calcular para área específica'),
          subtitle: const Text('Informar área em hectares para calcular necessidade'),
          value: state.usarAreaDesejada,
          activeColor: FortSmartTheme.primaryColor,
          onChanged: (value) {
            onStateChanged(state.copyWith(usarAreaDesejada: value ?? false));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        
        if (state.usarAreaDesejada) ...[
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Área desejada (hectares)',
              hintText: 'Ex: 100',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
              ),
              prefixIcon: Icon(Icons.area_chart, color: FortSmartTheme.primaryColor),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) => CalculoSementesService.validarAreaDesejada(
              double.tryParse(value ?? ''), 
              state.usarAreaDesejada,
            ),
            onChanged: (value) {
              final newValue = double.tryParse(value);
              if (newValue != null) {
                onStateChanged(state.copyWith(areaDesejada: newValue));
              }
            },
          ),
        ],
      ],
    );
  }
}
