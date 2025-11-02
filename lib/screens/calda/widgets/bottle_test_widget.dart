import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/calda/product.dart';
import '../../../models/calda/calda_config.dart';
import '../../../models/calda/dose_unit.dart';

class BottleTestWidget extends StatefulWidget {
  final List<Product> products;
  final CaldaConfig config;

  const BottleTestWidget({
    Key? key,
    required this.products,
    required this.config,
  }) : super(key: key);

  @override
  State<BottleTestWidget> createState() => _BottleTestWidgetState();
}

class _BottleTestWidgetState extends State<BottleTestWidget> {
  final _volumeController = TextEditingController(text: '2.5');
  BottleTestResult? _bottleTestResult;

  @override
  void dispose() {
    _volumeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
              'Teste de Garrafa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 20),
            
            // Volume desejado na garrafa
            const Text(
              'Volume desejado na garrafa',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                // Botão menos
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: _decreaseVolume,
                    icon: const Icon(Icons.remove),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Campo de volume
                Expanded(
                  child: TextFormField(
                    controller: _volumeController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (value) => _calculateBottleTest(),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Unidade
                const Text(
                  'litros',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Botão mais
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: _increaseVolume,
                    icon: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Resultado do teste de garrafa
            if (_bottleTestResult != null) ...[
              const Text(
                'Quantidade de produto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              // Quantidade de água
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.water_drop, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Quantidade de água: ${_bottleTestResult!.waterAmount.toStringAsFixed(2)} mL',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Lista de produtos
              ..._bottleTestResult!.products.map((productResult) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        productResult.product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${productResult.displayValue} ${productResult.displayUnit}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              )).toList(),
              
              const SizedBox(height: 20),
              
              // Botão de instruções
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showMixingInstructions,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Instruções para a mistura'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Guia visual de compatibilidade
              _buildCompatibilityGuide(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Guia de Compatibilidade',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            // OK - Compatível
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.yellow[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Incompatibilidade
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 25,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.yellow[300]!,
                              Colors.yellow[600]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 25,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.yellow[600]!,
                              Colors.brown[400]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Incompatibilidade',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'Contraste de cor',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[300]!),
          ),
          child: const Row(
            children: [
              Icon(Icons.access_time, color: Colors.red),
              SizedBox(width: 8),
              Text(
                '3 minutos após agitar a garrafa',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _decreaseVolume() {
    final currentVolume = double.tryParse(_volumeController.text) ?? 2.5;
    if (currentVolume > 0.1) {
      _volumeController.text = (currentVolume - 0.1).toStringAsFixed(1);
      _calculateBottleTest();
    }
  }

  void _increaseVolume() {
    final currentVolume = double.tryParse(_volumeController.text) ?? 2.5;
    _volumeController.text = (currentVolume + 0.1).toStringAsFixed(1);
    _calculateBottleTest();
  }

  void _calculateBottleTest() {
    final volumeText = _volumeController.text;
    if (volumeText.isNotEmpty && widget.products.isNotEmpty) {
      final volume = double.tryParse(volumeText);
      if (volume != null && volume > 0) {
        setState(() {
          _bottleTestResult = _calculateBottleTestResult(volume);
        });
      }
    }
  }

  BottleTestResult _calculateBottleTestResult(double bottleVolume) {
    List<ProductBottleResult> productResults = [];
    double totalProductVolume = 0;

    for (Product product in widget.products) {
      // Calcula a dose proporcional para o volume da garrafa
      double productDose = _calculateProductDoseForBottle(product, bottleVolume);
      
      // Converte para unidade de exibição apropriada
      String displayUnit;
      String displayValue;
      
      if (product.doseUnit.symbol.contains('g') || product.doseUnit.symbol.contains('kg')) {
        if (productDose >= 1000) {
          displayUnit = 'g';
          displayValue = productDose.toStringAsFixed(0);
        } else {
          displayUnit = 'g';
          displayValue = productDose.toStringAsFixed(1);
        }
      } else {
        if (productDose >= 1) {
          displayUnit = 'mL';
          displayValue = (productDose * 1000).toStringAsFixed(0);
        } else {
          displayUnit = 'mL';
          displayValue = (productDose * 1000).toStringAsFixed(1);
        }
      }
      
      productResults.add(ProductBottleResult(
        product: product,
        dose: productDose,
        displayValue: displayValue,
        displayUnit: displayUnit,
      ));
      
      totalProductVolume += productDose;
    }

    // Calcula a quantidade de água (volume total - volume dos produtos)
    double waterAmount = (bottleVolume * 1000) - (totalProductVolume * 1000);

    return BottleTestResult(
      bottleVolume: bottleVolume,
      waterAmount: waterAmount,
      products: productResults,
    );
  }

  double _calculateProductDoseForBottle(Product product, double bottleVolume) {
    // Calcula a proporção baseada no volume da garrafa vs volume por hectare
    double volumePerHectare = widget.config.volumePerHectare;
    double proportion = bottleVolume / volumePerHectare;
    
    // Aplica a proporção à dose do produto
    switch (product.doseUnit) {
      case DoseUnit.l:
        return product.dose * proportion;
      case DoseUnit.lPer100l:
        return (product.dose / 100) * bottleVolume;
      case DoseUnit.ml:
        return (product.dose / 1000) * proportion;
      case DoseUnit.mlPer100l:
        return (product.dose / 100) * bottleVolume / 1000;
      case DoseUnit.g:
        return product.dose * proportion;
      case DoseUnit.gPer100l:
        return (product.dose / 100) * bottleVolume;
      case DoseUnit.kg:
        return (product.dose * 1000) * proportion;
      case DoseUnit.kgPer100l:
        return (product.dose / 100) * bottleVolume * 1000;
      case DoseUnit.percentVv:
        return (product.dose / 100) * bottleVolume;
    }
  }

  void _showMixingInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Instruções para a Mistura'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Adicione água limpa na garrafa (aproximadamente 2/3 do volume final)',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '2. Agite levemente para umedecer as paredes',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '3. Adicione os produtos na ordem sugerida',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '4. Complete com água até o volume desejado',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '5. Tampe a garrafa e agite vigorosamente por 30 segundos',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '6. Aguarde 3 minutos e observe o resultado',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Resultado OK: Líquido homogêneo, sem separação',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              SizedBox(height: 8),
              Text(
                'Incompatibilidade: Separação de cores, precipitação, espuma excessiva',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

/// Resultado do teste de garrafa
class BottleTestResult {
  final double bottleVolume;
  final double waterAmount;
  final List<ProductBottleResult> products;

  BottleTestResult({
    required this.bottleVolume,
    required this.waterAmount,
    required this.products,
  });
}

/// Resultado de produto no teste de garrafa
class ProductBottleResult {
  final Product product;
  final double dose;
  final String displayValue;
  final String displayUnit;

  ProductBottleResult({
    required this.product,
    required this.dose,
    required this.displayValue,
    required this.displayUnit,
  });
}
