/// Enum para tipos de análise de integração de plantio
enum IntegrationAnalysis {
  excelencia,
  compensacaoGerminacao,
  germinacaoBaixa,
  plantioIrregular,
  dadosIncompletos,
}

/// Extensão para facilitar conversões
extension IntegrationAnalysisExtension on IntegrationAnalysis {
  /// Converte para string legível
  String get displayName {
    switch (this) {
      case IntegrationAnalysis.excelencia:
        return 'Excelência';
      case IntegrationAnalysis.compensacaoGerminacao:
        return 'Compensação de Germinação';
      case IntegrationAnalysis.germinacaoBaixa:
        return 'Germinação Baixa';
      case IntegrationAnalysis.plantioIrregular:
        return 'Plantio Irregular';
      case IntegrationAnalysis.dadosIncompletos:
        return 'Dados Incompletos';
    }
  }

  /// Converte para string técnica
  String get technicalName {
    switch (this) {
      case IntegrationAnalysis.excelencia:
        return 'excelencia';
      case IntegrationAnalysis.compensacaoGerminacao:
        return 'compensacao_germinacao';
      case IntegrationAnalysis.germinacaoBaixa:
        return 'germinacao_baixa';
      case IntegrationAnalysis.plantioIrregular:
        return 'plantio_irregular';
      case IntegrationAnalysis.dadosIncompletos:
        return 'dados_incompletos';
    }
  }

  /// Converte para cor do indicador
  String get color {
    switch (this) {
      case IntegrationAnalysis.excelencia:
        return '#4CAF50'; // Verde
      case IntegrationAnalysis.compensacaoGerminacao:
        return '#8BC34A'; // Verde claro
      case IntegrationAnalysis.germinacaoBaixa:
        return '#FFC107'; // Amarelo
      case IntegrationAnalysis.plantioIrregular:
        return '#FF9800'; // Laranja
      case IntegrationAnalysis.dadosIncompletos:
        return '#F44336'; // Vermelho
    }
  }

  /// Converte para ícone
  String get icon {
    switch (this) {
      case IntegrationAnalysis.excelencia:
        return '✅';
      case IntegrationAnalysis.compensacaoGerminacao:
        return '🔄';
      case IntegrationAnalysis.germinacaoBaixa:
        return '⚠️';
      case IntegrationAnalysis.plantioIrregular:
        return '📊';
      case IntegrationAnalysis.dadosIncompletos:
        return '❌';
    }
  }
}
