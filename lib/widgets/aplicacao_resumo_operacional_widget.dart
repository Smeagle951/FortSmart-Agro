import 'package:flutter/material.dart';
import '../services/aplicacao_calculo_service.dart';
import '../utils/app_colors.dart';

/// Widget para exibir resumo operacional de aplicação agrícola
class AplicacaoResumoOperacionalWidget extends StatelessWidget {
  final Map<String, dynamic> resumoOperacional;
  final VoidCallback? onEditar;

  const AplicacaoResumoOperacionalWidget({
    super.key,
    required this.resumoOperacional,
    this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildResumoOperacional(context),
            const SizedBox(height: 16),
            _buildResumoProdutos(context),
            const SizedBox(height: 16),
            _buildResumoFinanceiro(context),
            if (onEditar != null) ...[
              const SizedBox(height: 16),
              _buildBotaoEditar(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.analytics,
          color: AppColors.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Resumo Operacional',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getCorTipoMaquina(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            resumoOperacional['tipoMaquina'] ?? 'N/A',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumoOperacional(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuração da Máquina',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Área Total',
                  '${resumoOperacional['areaTotal']?.toStringAsFixed(2)} ha',
                  Icons.area_chart,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Vazão',
                  '${resumoOperacional['vazaoPorHectare']?.toStringAsFixed(0)} L/ha',
                  Icons.water_drop,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Capacidade',
                  '${resumoOperacional['capacidadeTanque']?.toStringAsFixed(0)} L',
                  Icons.storage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Ha por Tanque',
                  '${resumoOperacional['hectaresPorTanque']?.toStringAsFixed(1)} ha',
                  Icons.agriculture,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Tanques',
                  '${resumoOperacional['numeroTanques']}',
                  Icons.local_shipping,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Eficiência',
                  '${resumoOperacional['eficiencia']?.toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          if (resumoOperacional['volumeResidual'] != null &&
              resumoOperacional['volumeResidual'] > 0) ...[
            const SizedBox(height: 8),
            _buildInfoItem(
              'Volume Residual',
              '${resumoOperacional['volumeResidual']?.toStringAsFixed(1)} L',
              Icons.warning,
              cor: Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResumoProdutos(BuildContext context) {
    final produtos = resumoOperacional['produtos'] as List<dynamic>? ?? [];
    
    if (produtos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Nenhum produto selecionado',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo por Produto',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ...produtos.map((produto) => _buildProdutoCard(produto)).toList(),
      ],
    );
  }

  Widget _buildProdutoCard(Map<String, dynamic> produto) {
    final estoqueSuficiente = produto['estoqueSuficiente'] ?? true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: estoqueSuficiente ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  estoqueSuficiente ? Icons.check_circle : Icons.warning,
                  color: estoqueSuficiente ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    produto['nome'] ?? 'Produto',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!estoqueSuficiente)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Estoque Insuficiente',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildProdutoInfo(
                    'Dose',
                    '${produto['dosePorHectare']?.toStringAsFixed(2)} ${produto['unidade']}/ha',
                  ),
                ),
                Expanded(
                  child: _buildProdutoInfo(
                    'Por Tanque',
                    '${produto['quantidadePorTanque']?.toStringAsFixed(2)} ${produto['unidade']}',
                  ),
                ),
                Expanded(
                  child: _buildProdutoInfo(
                    'Total',
                    '${produto['quantidadeTotal']?.toStringAsFixed(2)} ${produto['unidade']}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _buildProdutoInfo(
                    'Estoque',
                    '${produto['estoqueDisponivel']?.toStringAsFixed(2)} ${produto['unidade']}',
                  ),
                ),
                Expanded(
                  child: _buildProdutoInfo(
                    'Custo',
                    'R\$ ${produto['custoTotal']?.toStringAsFixed(2)}',
                    cor: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoFinanceiro(BuildContext context) {
    final custoTotal = resumoOperacional['custoTotal'] ?? 0.0;
    final custoPorHectare = resumoOperacional['custoPorHectare'] ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo Financeiro',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Custo por Ha',
                  'R\$ ${custoPorHectare.toStringAsFixed(2)}',
                  Icons.attach_money,
                  cor: Colors.green.shade700,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Custo Total',
                  'R\$ ${custoTotal.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  cor: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoEditar(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onEditar,
        icon: const Icon(Icons.edit),
        label: const Text('Editar Configurações'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {Color? cor}) {
    return Column(
      children: [
        Icon(icon, color: cor ?? Colors.grey.shade600, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: cor ?? Colors.grey.shade800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProdutoInfo(String label, String value, {Color? cor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: cor ?? Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Color _getCorTipoMaquina() {
    final tipo = resumoOperacional['tipoMaquina'] ?? '';
    switch (tipo) {
      case 'Terrestre':
        return Colors.blue;
      case 'Aérea':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
