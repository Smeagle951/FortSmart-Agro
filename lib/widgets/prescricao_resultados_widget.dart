import 'package:flutter/material.dart';
import '../models/prescricao_model.dart';

import '../utils/app_colors.dart';

/// Widget para exibição de resultados e KPIs da prescrição
/// Mostra cálculos finais, tempo estimado, custos e produtividade
class PrescricaoResultadosWidget extends StatelessWidget {
  final PrescricaoModel prescricao;
  final CalibracaoModel? calibracao;
  final List<PrescricaoProdutoModel> produtos;
  final ResultadosCalculoModel? resultados;
  final TotaisPrescricaoModel? totais;

  const PrescricaoResultadosWidget({
    super.key,
    required this.prescricao,
    this.calibracao,
    required this.produtos,
    this.resultados,
    this.totais,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        _buildSectionTitle('Resultados do Cálculo'),
        
        const SizedBox(height: 16),

        // KPIs principais
        _buildKpisPrincipais(),
        
        const SizedBox(height: 16),

        // Detalhes de tempo e produtividade
        _buildTempoProdutividade(),
        
        const SizedBox(height: 16),

        // Custos detalhados
        _buildCustosDetalhados(),
        
        const SizedBox(height: 16),

        // Resumo por tanque
        _buildResumoTanque(),
        
        const SizedBox(height: 16),

        // Alertas e validações
        _buildAlertasValidacoes(),
      ],
    );
  }

  /// Constrói o título da seção
  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói KPIs principais
  Widget _buildKpisPrincipais() {
    final haPorTanque = _calcularHaPorTanque();
    final numTanques = _calcularNumTanques();
    final tempoTotal = _calcularTempoTotal();
    final custoTotal = _calcularCustoTotal();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KPIs Principais',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    'ha/tanque',
                    haPorTanque.toStringAsFixed(1),
                    'Hectares por tanque',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    'Tanques',
                    numTanques.toString(),
                    'Número de cargas',
                    Icons.repeat,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    'Tempo Total',
                    '${tempoTotal.toStringAsFixed(1)}h',
                    'Horas estimadas',
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    'Custo Total',
                    'R\$ ${custoTotal.toStringAsFixed(2)}',
                    'Custo da aplicação',
                    Icons.attach_money,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói card de KPI
  Widget _buildKpiCard(String label, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Constrói detalhes de tempo e produtividade
  Widget _buildTempoProdutividade() {
    final tempoPorTanque = _calcularTempoPorTanque();
    final capacidadeCampo = _calcularCapacidadeCampo();
    final vazaoTotal = calibracao?.vazaoTotalCalculadaLMin ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tempo e Produtividade',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Vazão Total', '${vazaoTotal.toStringAsFixed(1)} L/min'),
            _buildInfoRow('Tempo por Tanque', '${tempoPorTanque.toStringAsFixed(1)} min'),
            _buildInfoRow('Capacidade de Campo', '${capacidadeCampo.toStringAsFixed(1)} ha/h'),
            _buildInfoRow('Eficiência', '${((calibracao?.eficienciaCampo ?? 0.85) * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
    );
  }

  /// Constrói custos detalhados
  Widget _buildCustosDetalhados() {
    final custoPorHa = _calcularCustoPorHa();
    final custoTotal = _calcularCustoTotal();
    final custoProdutos = _calcularCustoProdutos();
    final custoOperacional = custoTotal - custoProdutos;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custos Detalhados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Custo por Hectare', 'R\$ ${custoPorHa.toStringAsFixed(2)}'),
            _buildInfoRow('Custo dos Produtos', 'R\$ ${custoProdutos.toStringAsFixed(2)}'),
            _buildInfoRow('Custo Operacional', 'R\$ ${custoOperacional.toStringAsFixed(2)}'),
            const Divider(),
            _buildInfoRow(
              'Custo Total',
              'R\$ ${custoTotal.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói resumo por tanque
  Widget _buildResumoTanque() {
    final haPorTanque = _calcularHaPorTanque();
    final volumePorTanque = prescricao.volumeLHa * haPorTanque;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo por Tanque',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Área por Tanque', '${haPorTanque.toStringAsFixed(2)} ha'),
            _buildInfoRow('Volume por Tanque', '${volumePorTanque.toStringAsFixed(1)} L'),
            _buildInfoRow('Capacidade Efetiva', '${prescricao.capacidadeEfetivaL.toStringAsFixed(1)} L'),
            _buildInfoRow('Volume de Segurança', '${prescricao.volumeSegurancaL.toStringAsFixed(1)} L'),
            
            const SizedBox(height: 12),
            
            // Lista de produtos por tanque
            if (produtos.isNotEmpty) ...[
              const Divider(),
              Text(
                'Produtos por Tanque:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ...produtos.map((produto) {
                final quantidadePorTanque = _calcularQuantidadePorTanque(produto);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child:                          Text(
                           produto.produtoNome,
                           style: const TextStyle(fontSize: 12),
                         ),
                      ),
                      Text(
                        '${quantidadePorTanque.toStringAsFixed(2)} ${produto.unidade}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  /// Constrói alertas e validações
  Widget _buildAlertasValidacoes() {
    final alertas = <Widget>[];

    // Verificar estoque
    for (final produto in produtos) {
      if (!_verificarEstoque(produto)) {
        alertas.add(_buildAlerta(
          'Estoque Insuficiente',
          '${produto.produtoNome}: necessário ${_calcularQuantidadeTotal(produto).toStringAsFixed(2)}, disponível ${produto.estoqueDisponivel?.toStringAsFixed(2) ?? "N/A"}',
          Colors.orange,
          Icons.warning,
        ));
      }
    }

    // Verificar calibração
    if (calibracao == null) {
      alertas.add(_buildAlerta(
        'Calibração Necessária',
        'Configure os parâmetros de calibração para obter resultados precisos',
        Colors.blue,
        Icons.info,
      ));
    }

    // Verificar produtos
    if (produtos.isEmpty) {
      alertas.add(_buildAlerta(
        'Produtos Necessários',
        'Adicione pelo menos um produto para gerar a prescrição',
        Colors.red,
        Icons.error,
      ));
    }

    if (alertas.isEmpty) {
      alertas.add(_buildAlerta(
        'Tudo Pronto!',
        'A prescrição está completa e pronta para execução',
        Colors.green,
        Icons.check_circle,
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status e Validações',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            ...alertas,
          ],
        ),
      ),
    );
  }

  /// Constrói alerta
  Widget _buildAlerta(String titulo, String mensagem, Color cor, IconData icone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
                Text(
                  mensagem,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói linha de informação
  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppColors.primary : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppColors.primary : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // Métodos de cálculo

  /// Calcula hectares por tanque
  double _calcularHaPorTanque() {
    if (prescricao.volumeLHa <= 0) return 0;
    return prescricao.capacidadeEfetivaL / prescricao.volumeLHa;
  }

  /// Calcula número de tanques
  int _calcularNumTanques() {
    final haPorTanque = _calcularHaPorTanque();
    if (haPorTanque <= 0) return 0;
    return (prescricao.areaTrabalhoHa / haPorTanque).ceil();
  }

  /// Calcula tempo por tanque
  double _calcularTempoPorTanque() {
    final vazaoTotal = calibracao?.vazaoTotalCalculadaLMin ?? 0;
    if (vazaoTotal <= 0) return 0;
          return prescricao.capacidadeEfetivaL / vazaoTotal;
  }

  /// Calcula tempo total
  double _calcularTempoTotal() {
    final numTanques = _calcularNumTanques();
    final tempoPorTanque = _calcularTempoPorTanque();
    return (numTanques * tempoPorTanque) / 60; // Converter para horas
  }

  /// Calcula capacidade de campo
  double _calcularCapacidadeCampo() {
    final velocidade = calibracao?.velocidadeKmh ?? 0;
    final largura = calibracao?.larguraM ?? 0;
    final eficiencia = calibracao?.eficienciaCampo ?? 0.85;
    
    if (velocidade <= 0 || largura <= 0) return 0;
    return (velocidade * largura) / 10 * eficiencia;
  }

  /// Calcula custo por hectare
  double _calcularCustoPorHa() {
    if (prescricao.areaTrabalhoHa <= 0) return 0;
    return _calcularCustoTotal() / prescricao.areaTrabalhoHa;
  }

  /// Calcula custo total
  double _calcularCustoTotal() {
    return produtos.fold<double>(
      0, (sum, produto) => sum + _calcularCustoProduto(produto)
    );
  }

  /// Calcula custo dos produtos
  double _calcularCustoProdutos() {
    return produtos.fold<double>(
      0, (sum, produto) => sum + _calcularCustoProduto(produto)
    );
  }

  /// Calcula custo de um produto
  double _calcularCustoProduto(PrescricaoProdutoModel produto) {
    final quantidadeTotal = _calcularQuantidadeTotal(produto);
    return quantidadeTotal * (produto.custoUnitario ?? 0);
  }

  /// Calcula quantidade total de um produto
  double _calcularQuantidadeTotal(PrescricaoProdutoModel produto) {
    return produto.dosePorHa * prescricao.areaTrabalhoHa;
  }

  /// Calcula quantidade por tanque de um produto
  double _calcularQuantidadePorTanque(PrescricaoProdutoModel produto) {
    if (prescricao.volumeLHa <= 0) return 0;
    final haPorTanque = prescricao.capacidadeEfetivaL / prescricao.volumeLHa;
    if (produto.percentualVv != null && produto.percentualVv! > 0) {
      final volumePorTanque = haPorTanque * prescricao.volumeLHa;
      return (produto.percentualVv! / 100) * volumePorTanque;
    }
    return produto.dosePorHa * haPorTanque;
  }

  /// Verifica se há estoque suficiente
  bool _verificarEstoque(PrescricaoProdutoModel produto) {
    if (produto.estoqueDisponivel == null) return true;
    final quantidadeTotal = _calcularQuantidadeTotal(produto);
    return produto.estoqueDisponivel! >= quantidadeTotal;
  }
}
