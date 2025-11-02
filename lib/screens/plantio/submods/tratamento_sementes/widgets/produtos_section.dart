import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../../../../../modules/tratamento_sementes/models/produto_ts_model.dart';
import '../models/tratamento_sementes_state.dart';
import '../services/tratamento_sementes_service.dart';

/// Widget para seção de produtos
class ProdutosSection extends StatelessWidget {
  final TratamentoSementesState state;
  final Function(TratamentoSementesState) onStateChanged;

  const ProdutosSection({
    Key? key,
    required this.state,
    required this.onStateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (state.doseSelecionada == null || state.produtosDose.isEmpty) {
      return const SizedBox.shrink();
    }

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
            Row(
              children: [
                Text(
                  '📦 Produtos e Doses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: FortSmartTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                if (state.isCalculando)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            ...state.produtosDose.map((produto) => _buildProdutoCard(produto)),
          ],
        ),
      ),
    );
  }

  Widget _buildProdutoCard(ProdutoTS produto) {
    final numberFormat = NumberFormat("#,##0.00", "pt_BR");
    
    // Calcular quantidade baseada no tipo de cálculo
    final quantidade = TratamentoSementesService.calcularQuantidadeProduto(produto, state);
    
    // Calcular custo total
    final custoTotal = TratamentoSementesService.calcularCustoProduto(produto, state);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FortSmartTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.science, color: FortSmartTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produto.nomeProduto,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        produto.tipoCalculoDescricao,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dose: ${numberFormat.format(produto.valor)} ${produto.unidade}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Total: ${numberFormat.format(quantidade)} ${produto.unidade}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: FortSmartTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                if (produto.valorUnitario != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'R\$ ${numberFormat.format(produto.valorUnitario!)}/${produto.unidade}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'R\$ ${numberFormat.format(custoTotal)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
