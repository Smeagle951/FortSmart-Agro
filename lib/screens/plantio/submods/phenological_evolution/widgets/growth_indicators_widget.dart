/// 📊 Widget: Indicadores de Crescimento
/// 
/// Widget para exibir indicadores calculados de crescimento
/// e desenvolvimento (espaçamento nós, eficiência reprodutiva, etc.)
/// 
/// Autor: FortSmart Agro
/// Data: Outubro 2025

import 'package:flutter/material.dart';
import '../models/phenological_record_model.dart';
import '../services/growth_analysis_service.dart';

class GrowthIndicatorsWidget extends StatelessWidget {
  final PhenologicalRecordModel registro;
  final String cultura;
  final List<PhenologicalRecordModel>? historico;

  const GrowthIndicatorsWidget({
    Key? key,
    required this.registro,
    required this.cultura,
    this.historico,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Indicadores Calculados',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Crescimento médio diário
            if (historico != null && historico!.length >= 2)
              _buildIndicadorCrescimentoDiario(),
            
            // Espaçamento entre nós
            if (registro.numeroNos != null && registro.alturaCm != null)
              _buildIndicadorEspacamentoNos(),
            
            // Relação vagens/nó
            if (registro.vagensPlanta != null && registro.numeroNos != null)
              _buildIndicadorRelacaoVagensNo(),
            
            // Eficiência reprodutiva (algodão)
            if (registro.numeroRamosVegetativos != null && 
                registro.numeroRamosReprodutivos != null)
              _buildIndicadorEficienciaReprodutiva(),
            
            // Mensagem se não houver indicadores
            if (!_temIndicadores())
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'ℹ️ Complete mais campos para ver indicadores calculados',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _temIndicadores() {
    return (historico != null && historico!.length >= 2) ||
           (registro.numeroNos != null && registro.alturaCm != null) ||
           (registro.vagensPlanta != null && registro.numeroNos != null) ||
           (registro.numeroRamosVegetativos != null && registro.numeroRamosReprodutivos != null);
  }

  Widget _buildIndicadorCrescimentoDiario() {
    final crescimento = GrowthAnalysisService.calcularCrescimentoMedioDiario(historico!);
    
    if (crescimento == null) return const SizedBox.shrink();
    
    return _buildIndicadorCard(
      icone: Icons.trending_up,
      cor: Colors.green,
      titulo: 'Crescimento Médio Diário',
      valor: '${crescimento.toStringAsFixed(2)} cm/dia',
      status: _getStatusCrescimento(crescimento),
    );
  }

  Widget _buildIndicadorEspacamentoNos() {
    final espacamento = GrowthAnalysisService.calcularEspacamentoEntreNos(
      alturaCm: registro.alturaCm,
      numeroNos: registro.numeroNos,
    );
    
    if (espacamento == null) return const SizedBox.shrink();
    
    final analise = GrowthAnalysisService.analisarEstiolamento(
      espacamentoEntreNosCm: espacamento,
      cultura: cultura,
    );
    
    return _buildIndicadorCard(
      icone: Icons.height,
      cor: _getCorEstiolamento(analise),
      titulo: 'Espaçamento Entre Nós',
      valor: '${espacamento.toStringAsFixed(1)} cm/nó',
      status: analise,
    );
  }

  Widget _buildIndicadorRelacaoVagensNo() {
    final relacao = GrowthAnalysisService.calcularRelacaoVagensNo(
      vagensPlanta: registro.vagensPlanta,
      numeroNos: registro.numeroNos,
    );
    
    if (relacao == null) return const SizedBox.shrink();
    
    return _buildIndicadorCard(
      icone: Icons.analytics_outlined,
      cor: Colors.purple,
      titulo: 'Eficiência Reprodutiva',
      valor: '${relacao.toStringAsFixed(2)} vagens/nó',
      status: _getStatusEficiencia(relacao),
    );
  }

  Widget _buildIndicadorEficienciaReprodutiva() {
    final analise = GrowthAnalysisService.analisarEficienciaReprodutiva(
      ramosVegetativos: registro.numeroRamosVegetativos,
      ramosReprodutivos: registro.numeroRamosReprodutivos,
    );
    
    final relacao = (registro.numeroRamosReprodutivos! / 
                     registro.numeroRamosVegetativos!);
    
    return _buildIndicadorCard(
      icone: Icons.park,
      cor: _getCorEficienciaAlgodao(analise),
      titulo: 'Relação Ramos (Algodão)',
      valor: '${relacao.toStringAsFixed(2)}:1',
      status: analise,
    );
  }

  Widget _buildIndicadorCard({
    required IconData icone,
    required Color cor,
    required String titulo,
    required String valor,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusCrescimento(double crescimento) {
    if (crescimento > 4) {
      return '📈 Crescimento acelerado';
    } else if (crescimento > 2) {
      return '✅ Crescimento normal';
    } else if (crescimento > 0) {
      return '⚠️ Crescimento lento';
    } else {
      return '🚨 Crescimento estagnado';
    }
  }

  Color _getCorEstiolamento(String analise) {
    if (analise.contains('✅')) {
      return Colors.green;
    } else if (analise.contains('⚠️')) {
      return Colors.orange;
    } else if (analise.contains('🚨')) {
      return Colors.red;
    }
    return Colors.blue;
  }

  String _getStatusEficiencia(double relacao) {
    if (relacao > 2.5) {
      return '✅ Excelente';
    } else if (relacao > 2.0) {
      return '✅ Boa';
    } else if (relacao > 1.5) {
      return '⚠️ Moderada';
    } else {
      return '🚨 Baixa';
    }
  }

  Color _getCorEficienciaAlgodao(String analise) {
    if (analise.contains('Excelente')) {
      return Colors.green;
    } else if (analise.contains('Boa')) {
      return Colors.lightGreen;
    } else if (analise.contains('Moderada')) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

