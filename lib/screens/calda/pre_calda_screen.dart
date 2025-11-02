import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/calda/product.dart';
import '../../models/calda/calda_config.dart';
import '../../services/calda/calda_service.dart';
import '../../services/calda/calda_calculation_service.dart';

class PreCaldaScreen extends StatefulWidget {
  final List<Product> products;
  final CaldaConfig config;

  const PreCaldaScreen({
    Key? key,
    required this.products,
    required this.config,
  }) : super(key: key);

  @override
  State<PreCaldaScreen> createState() => _PreCaldaScreenState();
}

class _PreCaldaScreenState extends State<PreCaldaScreen> {
  final _volumeController = TextEditingController();
  RecipeCalculationResult? _preCaldaResult;
  final CaldaService _caldaService = CaldaService.instance;

  @override
  void dispose() {
    _volumeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de configuração da pré-calda
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuração da Pré-Calda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: _volumeController,
                    decoration: const InputDecoration(
                      labelText: 'Volume da Pré-Calda (L)',
                      hintText: 'Ex: 1200',
                      prefixIcon: Icon(Icons.local_drink),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (value) => _calculatePreCalda(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Informações da receita original
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Receita Original:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Volume: ${widget.config.volumeLiters.toStringAsFixed(0)} L'),
                        Text('Vazão: ${widget.config.flowRate.toStringAsFixed(0)} ${widget.config.isFlowPerHectare ? 'L/ha' : 'L/alqueire'}'),
                        Text('Área: ${widget.config.area.toStringAsFixed(2)} ha'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Resultado da pré-calda
          if (_preCaldaResult != null)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Produtos para Pré-Calda',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Resumo da pré-calda
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF4CAF50)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Volume da Pré-Calda: ${_preCaldaResult!.totalVolume.toStringAsFixed(0)} L',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Área Coberta: ${_preCaldaResult!.hectaresCovered.toStringAsFixed(2)} ha',
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Lista de produtos
                    ..._preCaldaResult!.products.asMap().entries.map((entry) {
                      int index = entry.key;
                      ProductCalculationResult result = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2E7D32),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            result.product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${result.product.manufacturer} • ${result.product.formulation.code}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${result.displayValue} ${result.displayUnit}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Instruções de preparo
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
                      SizedBox(width: 8),
                      Text(
                        'Instruções de Preparo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  const Text(
                    '1. Adicione água limpa no tanque (aproximadamente 1/3 do volume final)\n'
                    '2. Ligue o agitador\n'
                    '3. Adicione os produtos na ordem sugerida\n'
                    '4. Complete com água até o volume desejado\n'
                    '5. Mantenha a agitação por pelo menos 5 minutos\n'
                    '6. Realize o teste de calda antes da aplicação',
                    style: TextStyle(fontSize: 14),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sempre realize o teste de calda (jar-test) antes da aplicação para verificar compatibilidade.',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _calculatePreCalda() {
    final volumeText = _volumeController.text;
    if (volumeText.isNotEmpty) {
      final volume = double.tryParse(volumeText);
      if (volume != null && volume > 0) {
        setState(() {
          _preCaldaResult = _caldaService.calculatePreCalda(
            widget.products,
            widget.config,
            volume,
          );
        });
      }
    }
  }
}
