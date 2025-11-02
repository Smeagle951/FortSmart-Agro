import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget do formulário de calibração de fertilizantes
class CalibracaoFertilizanteForm extends StatelessWidget {
  final TextEditingController nomeController;
  final TextEditingController responsavelController;
  final TextEditingController distanciaController;
  final TextEditingController espacamentoController;
  final TextEditingController faixaEsperadaController;
  final TextEditingController granulometriaController;
  final TextEditingController taxaDesejadaController;
  final TextEditingController diametroPratoController;
  final TextEditingController rpmController;
  final TextEditingController velocidadeController;
  final TextEditingController observacoesController;
  final String tipoPaleta;
  final DateTime dataCalibracao;
  final int numBandejas;
  final List<TextEditingController> pesoControllers;
  final Function(String) onTipoPaletaChanged;
  final Function(DateTime) onDataChanged;
  final Function(int) onNumBandejasChanged;

  const CalibracaoFertilizanteForm({
    Key? key,
    required this.nomeController,
    required this.responsavelController,
    required this.distanciaController,
    required this.espacamentoController,
    required this.faixaEsperadaController,
    required this.granulometriaController,
    required this.taxaDesejadaController,
    required this.diametroPratoController,
    required this.rpmController,
    required this.velocidadeController,
    required this.observacoesController,
    required this.tipoPaleta,
    required this.dataCalibracao,
    required this.numBandejas,
    required this.pesoControllers,
    required this.onTipoPaletaChanged,
    required this.onDataChanged,
    required this.onNumBandejasChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(Icons.science, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Dados da Calibração',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Informações básicas
            _buildSectionTitle('Informações Básicas'),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Calibração *',
                      hintText: 'Ex: Calibração NPK 20-20-20',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Nome é obrigatório';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: responsavelController,
                    decoration: const InputDecoration(
                      labelText: 'Responsável *',
                      hintText: 'Nome do responsável',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Responsável é obrigatório';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: dataCalibracao,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (date != null) {
                        onDataChanged(date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data da Calibração *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${dataCalibracao.day.toString().padLeft(2, '0')}/'
                        '${dataCalibracao.month.toString().padLeft(2, '0')}/'
                        '${dataCalibracao.year}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: tipoPaleta,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Paleta *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pequena', child: Text('Pequena')),
                      DropdownMenuItem(value: 'grande', child: Text('Grande')),
                    ],
                    onChanged: (value) => value != null ? onTipoPaletaChanged(value) : null,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Dados de coleta
            _buildSectionTitle('Dados de Coleta'),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: distanciaController,
                    decoration: const InputDecoration(
                      labelText: 'Distância de Coleta (m) *',
                      hintText: 'Ex: 50.0',
                      border: OutlineInputBorder(),
                      suffixText: 'm',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Distância é obrigatória';
                      }
                      final distancia = double.tryParse(value!);
                      if (distancia == null || distancia <= 0) {
                        return 'Distância deve ser maior que zero';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: espacamentoController,
                    decoration: const InputDecoration(
                      labelText: 'Espaçamento (m) *',
                      hintText: 'Ex: 1.0',
                      border: OutlineInputBorder(),
                      suffixText: 'm',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Espaçamento é obrigatório';
                      }
                      final espacamento = double.tryParse(value!);
                      if (espacamento == null || espacamento <= 0) {
                        return 'Espaçamento deve ser maior que zero';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: faixaEsperadaController,
                    decoration: const InputDecoration(
                      labelText: 'Faixa Esperada (m)',
                      hintText: 'Ex: 36.0',
                      border: OutlineInputBorder(),
                      suffixText: 'm',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: granulometriaController,
                    decoration: const InputDecoration(
                      labelText: 'Granulometria (g/L)',
                      hintText: 'Ex: 1200',
                      border: OutlineInputBorder(),
                      suffixText: 'g/L',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Configuração da máquina
            _buildSectionTitle('Configuração da Máquina'),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: diametroPratoController,
                    decoration: const InputDecoration(
                      labelText: 'Diâmetro do Prato (mm)',
                      hintText: 'Ex: 450',
                      border: OutlineInputBorder(),
                      suffixText: 'mm',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: rpmController,
                    decoration: const InputDecoration(
                      labelText: 'RPM',
                      hintText: 'Ex: 540',
                      border: OutlineInputBorder(),
                      suffixText: 'rpm',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: velocidadeController,
                    decoration: const InputDecoration(
                      labelText: 'Velocidade (km/h)',
                      hintText: 'Ex: 8.0',
                      border: OutlineInputBorder(),
                      suffixText: 'km/h',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: taxaDesejadaController,
                    decoration: const InputDecoration(
                      labelText: 'Taxa Desejada (kg/ha)',
                      hintText: 'Ex: 300',
                      border: OutlineInputBorder(),
                      suffixText: 'kg/ha',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Pesos das bandejas
            _buildSectionTitle('Pesos das Bandejas'),
            const SizedBox(height: 8),
            
            // Controle do número de bandejas
            Row(
              children: [
                const Text('Número de bandejas: '),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: numBandejas > 5 ? () => onNumBandejasChanged(numBandejas - 1) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Reduzir número de bandejas',
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$numBandejas',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: numBandejas < 21 ? () => onNumBandejasChanged(numBandejas + 1) : null,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Aumentar número de bandejas',
                ),
                const Spacer(),
                Text(
                  'Mín: 5 | Máx: 21',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Grid de pesos
            _buildPesosGrid(),
            
            const SizedBox(height: 24),
            
            // Observações
            _buildSectionTitle('Observações'),
            const SizedBox(height: 8),
            
            TextFormField(
              controller: observacoesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Observações adicionais sobre a calibração...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textAlignVertical: TextAlignVertical.top,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildPesosGrid() {
    final crossAxisCount = numBandejas <= 7 ? 5 : 7;
    final rows = (numBandejas / crossAxisCount).ceil();
    
    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: List.generate(crossAxisCount, (colIndex) {
              final index = rowIndex * crossAxisCount + colIndex;
              if (index >= numBandejas) {
                return const Expanded(child: SizedBox());
              }
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: TextFormField(
                    controller: pesoControllers[index],
                    decoration: InputDecoration(
                      labelText: 'B${index + 1}',
                      hintText: '0.0',
                      border: const OutlineInputBorder(),
                      suffixText: 'g',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return null; // Campo opcional
                      }
                      final peso = double.tryParse(value!);
                      if (peso == null || peso < 0) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
