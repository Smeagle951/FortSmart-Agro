import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget para entrada de distâncias entre sementes
class DistanceInputWidget extends StatefulWidget {
  final List<double> distancias;
  final Function(List<double>) onDistanciasChanged;

  const DistanceInputWidget({
    Key? key,
    required this.distancias,
    required this.onDistanciasChanged,
  }) : super(key: key);

  @override
  State<DistanceInputWidget> createState() => _DistanceInputWidgetState();
}

class _DistanceInputWidgetState extends State<DistanceInputWidget> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Adiciona uma nova distância à lista
  void _adicionarDistancia() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final valor = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (valor != null && valor > 0) {
      final novasDistancias = List<double>.from(widget.distancias)..add(valor);
      widget.onDistanciasChanged(novasDistancias);
      _controller.clear();
    }
  }

  /// Remove uma distância da lista
  void _removerDistancia(int index) {
    final novasDistancias = List<double>.from(widget.distancias)..removeAt(index);
    widget.onDistanciasChanged(novasDistancias);
  }

  /// Limpa todas as distâncias
  void _limparTodas() {
    widget.onDistanciasChanged([]);
  }

  /// Adiciona distâncias de exemplo
  void _adicionarExemplo() {
    final exemplo = [2.5, 2.8, 2.3, 2.7, 2.4, 2.6, 2.9, 2.2, 2.5, 2.7];
    widget.onDistanciasChanged(exemplo);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Distâncias entre Sementes (cm)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.distancias.isNotEmpty)
                  TextButton.icon(
                    onPressed: _limparTodas,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Limpar'),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Adicione as distâncias medidas entre sementes consecutivas. '
              'Recomenda-se pelo menos 10 medições para um cálculo preciso.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Campo de entrada
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Distância (cm)',
                        hintText: 'Ex: 2,5',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe a distância';
                        }
                        final valor = double.tryParse(value.replaceAll(',', '.'));
                        if (valor == null || valor <= 0) {
                          return 'Valor inválido';
                        }
                        if (valor > 500) {
                          return 'Valor muito alto (máximo 500cm)';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _adicionarDistancia(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _adicionarDistancia,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Adicionar'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botões de ação rápida
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _adicionarExemplo,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Exemplo'),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.distancias.length} medições',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Lista de distâncias
            if (widget.distancias.isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.distancias.length,
                  itemBuilder: (context, index) {
                    final distancia = widget.distancias[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      title: Text('${distancia.toStringAsFixed(1)} cm'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: () => _removerDistancia(index),
                        color: Colors.red,
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Estatísticas básicas
              if (widget.distancias.length >= 2) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatistic(
                        'Média',
                        '${_calcularMedia().toStringAsFixed(1)} cm',
                        Icons.trending_flat,
                      ),
                      _buildStatistic(
                        'Mín',
                        '${widget.distancias.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)} cm',
                        Icons.keyboard_arrow_down,
                      ),
                      _buildStatistic(
                        'Máx',
                        '${widget.distancias.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)} cm',
                        Icons.keyboard_arrow_up,
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma distância adicionada',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Adicione as distâncias entre sementes para calcular o CV%',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Constrói um widget de estatística
  Widget _buildStatistic(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Calcula a média das distâncias
  double _calcularMedia() {
    if (widget.distancias.isEmpty) return 0.0;
    return widget.distancias.reduce((a, b) => a + b) / widget.distancias.length;
  }
}
