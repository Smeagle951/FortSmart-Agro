import 'package:flutter/material.dart';
import '../../../../models/agricultural_product.dart';
import '../../../../models/talhao_model_new.dart';
import '../../../../services/cultura_icon_service.dart';

class SelecaoTalhaoCulturaWidget extends StatefulWidget {
  final TalhaoModel? talhaoSelecionado;
  final AgriculturalProduct? culturaSelecionada;
  final VoidCallback onSelecionarTalhao;
  final VoidCallback onSelecionarCultura;
  final Function(String)? onCulturaManualChanged;

  const SelecaoTalhaoCulturaWidget({
    Key? key,
    required this.talhaoSelecionado,
    required this.culturaSelecionada,
    required this.onSelecionarTalhao,
    required this.onSelecionarCultura,
    this.onCulturaManualChanged,
  }) : super(key: key);

  @override
  State<SelecaoTalhaoCulturaWidget> createState() => _SelecaoTalhaoCulturaWidgetState();
}

class _SelecaoTalhaoCulturaWidgetState extends State<SelecaoTalhaoCulturaWidget> {
  final TextEditingController _culturaController = TextEditingController();
  bool _usarEntradaManual = true; // Por padrão, usar entrada manual

  @override
  void initState() {
    super.initState();
    // Inicializar com o nome da cultura selecionada se existir
    if (widget.culturaSelecionada?.name != null) {
      _culturaController.text = widget.culturaSelecionada!.name!;
    }
  }

  @override
  void dispose() {
    _culturaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Talhão e Cultura',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Talhão'),
              subtitle: Text(
                widget.talhaoSelecionado?.nomeTalhao ?? 
                widget.talhaoSelecionado?.name ?? 
                'Selecione um talhão'
              ),
              leading: CircleAvatar(
                backgroundColor: widget.talhaoSelecionado?.cor ?? Colors.grey,
                child: const Icon(Icons.landscape, color: Colors.white),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.talhaoSelecionado == null)
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
              onTap: widget.onSelecionarTalhao,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: widget.talhaoSelecionado == null 
                      ? Colors.orange.shade300 
                      : Colors.grey.shade300,
                  width: widget.talhaoSelecionado == null ? 2 : 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Toggle entre entrada manual e seleção
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Entrada Manual'),
                    value: true,
                    groupValue: _usarEntradaManual,
                    onChanged: (value) {
                      setState(() {
                        _usarEntradaManual = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Selecionar'),
                    value: false,
                    groupValue: _usarEntradaManual,
                    onChanged: (value) {
                      setState(() {
                        _usarEntradaManual = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Campo de entrada manual ou seleção
            if (_usarEntradaManual) ...[
              TextFormField(
                controller: _culturaController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Cultura',
                  hintText: 'Ex: Soja, Milho, Algodão...',
                  prefixIcon: Icon(Icons.grass),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  widget.onCulturaManualChanged?.call(value);
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da cultura';
                  }
                  return null;
                },
              ),
            ] else ...[
              ListTile(
                title: const Text('Cultura'),
                subtitle: Text(widget.culturaSelecionada?.name ?? 'Selecione uma cultura'),
                leading: widget.culturaSelecionada != null
                    ? CulturaIconService.getCulturaIcon(
                        culturaNome: widget.culturaSelecionada!.name,
                        size: 40,
                        backgroundColor: widget.culturaSelecionada!.colorValue != null
                            ? Color(int.parse('0xFF${widget.culturaSelecionada!.colorValue!.replaceAll('#', '')}'))
                            : Colors.grey,
                      )
                    : CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: const Icon(Icons.grass, color: Colors.white),
                      ),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: widget.onSelecionarCultura,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ],
            
            // Indicador de status dos dados
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.talhaoSelecionado == null 
                    ? Colors.orange.shade50 
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.talhaoSelecionado == null 
                      ? Colors.orange.shade200 
                      : Colors.blue.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.talhaoSelecionado == null 
                        ? Icons.warning_amber 
                        : Icons.info_outline, 
                    color: widget.talhaoSelecionado == null 
                        ? Colors.orange.shade600 
                        : Colors.blue.shade600, 
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.talhaoSelecionado == null
                          ? '⚠️ Nenhum talhão selecionado. Clique para selecionar um talhão do módulo Talhões.'
                          : _usarEntradaManual 
                              ? 'Digite o nome da cultura manualmente'
                              : 'Selecione uma cultura da lista (pode não estar disponível)',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.talhaoSelecionado == null 
                            ? Colors.orange.shade700 
                            : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
