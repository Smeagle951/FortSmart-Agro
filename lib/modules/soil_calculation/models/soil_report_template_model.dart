import 'dart:convert';

/// Modelo para templates de relatório customizáveis por fazenda
class SoilReportTemplateModel {
  final int? id;
  final String nomeTemplate;
  final String nomeFazenda;
  final String? logoFazendaPath;
  final String? corPrimaria;
  final String? corSecundaria;
  final String? corAccent;
  final String? fonteTitulo;
  final String? fonteTexto;
  final double? tamanhoTitulo;
  final double? tamanhoSubtitulo;
  final double? tamanhoTexto;
  final bool incluirCapa;
  final bool incluirSumario;
  final bool incluirResumoExecutivo;
  final bool incluirInformacoesPropriedade;
  final bool incluirMetodologia;
  final bool incluirMapaCompactacao;
  final bool incluirTabelaPontos;
  final bool incluirAnalisesEstatisticas;
  final bool incluirDiagnosticos;
  final bool incluirRecomendacoes;
  final bool incluirPlanoAcao;
  final bool incluirAnexos;
  final String? textoRodape;
  final String? assinaturaAgronomo;
  final String? registroAgronomo;
  final String? contatoAgronomo;
  final Map<String, dynamic>? configuracoesExtras;
  final DateTime createdAt;
  final DateTime updatedAt;

  SoilReportTemplateModel({
    this.id,
    required this.nomeTemplate,
    required this.nomeFazenda,
    this.logoFazendaPath,
    this.corPrimaria,
    this.corSecundaria,
    this.corAccent,
    this.fonteTitulo,
    this.fonteTexto,
    this.tamanhoTitulo,
    this.tamanhoSubtitulo,
    this.tamanhoTexto,
    this.incluirCapa = true,
    this.incluirSumario = true,
    this.incluirResumoExecutivo = true,
    this.incluirInformacoesPropriedade = true,
    this.incluirMetodologia = true,
    this.incluirMapaCompactacao = true,
    this.incluirTabelaPontos = true,
    this.incluirAnalisesEstatisticas = true,
    this.incluirDiagnosticos = true,
    this.incluirRecomendacoes = true,
    this.incluirPlanoAcao = true,
    this.incluirAnexos = true,
    this.textoRodape,
    this.assinaturaAgronomo,
    this.registroAgronomo,
    this.contatoAgronomo,
    this.configuracoesExtras,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria template padrão FortSmart
  factory SoilReportTemplateModel.templatePadrao({
    required String nomeFazenda,
    String? logoFazendaPath,
  }) {
    return SoilReportTemplateModel(
      nomeTemplate: 'Padrão FortSmart',
      nomeFazenda: nomeFazenda,
      logoFazendaPath: logoFazendaPath,
      corPrimaria: '#1B5E20', // Verde escuro
      corSecundaria: '#66BB6A', // Verde claro
      corAccent: '#FF9800', // Laranja
      fonteTitulo: 'Inter',
      fonteTexto: 'Inter',
      tamanhoTitulo: 28.0,
      tamanhoSubtitulo: 16.0,
      tamanhoTexto: 12.0,
      textoRodape: 'FortSmart Agro • Relatório Gerado Automaticamente',
      assinaturaAgronomo: 'Agrônomo Responsável',
      registroAgronomo: 'CRBio/CRMV/CRP',
      contatoAgronomo: 'contato@fortsmart.com.br',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Cria template minimalista
  factory SoilReportTemplateModel.templateMinimalista({
    required String nomeFazenda,
    String? logoFazendaPath,
  }) {
    return SoilReportTemplateModel(
      nomeTemplate: 'Minimalista',
      nomeFazenda: nomeFazenda,
      logoFazendaPath: logoFazendaPath,
      corPrimaria: '#2C3E50', // Azul escuro
      corSecundaria: '#34495E', // Cinza escuro
      corAccent: '#E74C3C', // Vermelho
      fonteTitulo: 'Roboto',
      fonteTexto: 'Roboto',
      tamanhoTitulo: 24.0,
      tamanhoSubtitulo: 14.0,
      tamanhoTexto: 11.0,
      incluirCapa: true,
      incluirSumario: false,
      incluirResumoExecutivo: true,
      incluirInformacoesPropriedade: true,
      incluirMetodologia: false,
      incluirMapaCompactacao: true,
      incluirTabelaPontos: true,
      incluirAnalisesEstatisticas: true,
      incluirDiagnosticos: false,
      incluirRecomendacoes: true,
      incluirPlanoAcao: false,
      incluirAnexos: false,
      textoRodape: 'Relatório Técnico - $nomeFazenda',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Cria template executivo
  factory SoilReportTemplateModel.templateExecutivo({
    required String nomeFazenda,
    String? logoFazendaPath,
  }) {
    return SoilReportTemplateModel(
      nomeTemplate: 'Executivo',
      nomeFazenda: nomeFazenda,
      logoFazendaPath: logoFazendaPath,
      corPrimaria: '#8E44AD', // Roxo
      corSecundaria: '#9B59B6', // Roxo claro
      corAccent: '#F39C12', // Amarelo
      fonteTitulo: 'Montserrat',
      fonteTexto: 'Open Sans',
      tamanhoTitulo: 32.0,
      tamanhoSubtitulo: 18.0,
      tamanhoTexto: 13.0,
      incluirCapa: true,
      incluirSumario: true,
      incluirResumoExecutivo: true,
      incluirInformacoesPropriedade: true,
      incluirMetodologia: false,
      incluirMapaCompactacao: true,
      incluirTabelaPontos: false,
      incluirAnalisesEstatisticas: true,
      incluirDiagnosticos: false,
      incluirRecomendacoes: true,
      incluirPlanoAcao: true,
      incluirAnexos: false,
      textoRodape: 'Relatório Executivo - $nomeFazenda',
      assinaturaAgronomo: 'Diretor Técnico',
      registroAgronomo: 'CRBio 12345',
      contatoAgronomo: 'tecnico@$nomeFazenda.com.br',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Cria template técnico completo
  factory SoilReportTemplateModel.templateTecnicoCompleto({
    required String nomeFazenda,
    String? logoFazendaPath,
  }) {
    return SoilReportTemplateModel(
      nomeTemplate: 'Técnico Completo',
      nomeFazenda: nomeFazenda,
      logoFazendaPath: logoFazendaPath,
      corPrimaria: '#1B5E20', // Verde escuro
      corSecundaria: '#66BB6A', // Verde claro
      corAccent: '#FF9800', // Laranja
      fonteTitulo: 'Inter',
      fonteTexto: 'Inter',
      tamanhoTitulo: 28.0,
      tamanhoSubtitulo: 16.0,
      tamanhoTexto: 12.0,
      incluirCapa: true,
      incluirSumario: true,
      incluirResumoExecutivo: true,
      incluirInformacoesPropriedade: true,
      incluirMetodologia: true,
      incluirMapaCompactacao: true,
      incluirTabelaPontos: true,
      incluirAnalisesEstatisticas: true,
      incluirDiagnosticos: true,
      incluirRecomendacoes: true,
      incluirPlanoAcao: true,
      incluirAnexos: true,
      textoRodape: 'Relatório Técnico Completo - $nomeFazenda',
      assinaturaAgronomo: 'Eng. Agrônomo Responsável',
      registroAgronomo: 'CRBio 67890',
      contatoAgronomo: 'agronomo@$nomeFazenda.com.br',
      configuracoesExtras: {
        'incluir_graficos_detalhados': true,
        'incluir_analise_estatistica_avancada': true,
        'incluir_recomendacoes_especificas': true,
        'incluir_cronograma_detalhado': true,
        'incluir_anexos_laboratoriais': true,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome_template': nomeTemplate,
      'nome_fazenda': nomeFazenda,
      'logo_fazenda_path': logoFazendaPath,
      'cor_primaria': corPrimaria,
      'cor_secundaria': corSecundaria,
      'cor_accent': corAccent,
      'fonte_titulo': fonteTitulo,
      'fonte_texto': fonteTexto,
      'tamanho_titulo': tamanhoTitulo,
      'tamanho_subtitulo': tamanhoSubtitulo,
      'tamanho_texto': tamanhoTexto,
      'incluir_capa': incluirCapa ? 1 : 0,
      'incluir_sumario': incluirSumario ? 1 : 0,
      'incluir_resumo_executivo': incluirResumoExecutivo ? 1 : 0,
      'incluir_informacoes_propriedade': incluirInformacoesPropriedade ? 1 : 0,
      'incluir_metodologia': incluirMetodologia ? 1 : 0,
      'incluir_mapa_compactacao': incluirMapaCompactacao ? 1 : 0,
      'incluir_tabela_pontos': incluirTabelaPontos ? 1 : 0,
      'incluir_analises_estatisticas': incluirAnalisesEstatisticas ? 1 : 0,
      'incluir_diagnosticos': incluirDiagnosticos ? 1 : 0,
      'incluir_recomendacoes': incluirRecomendacoes ? 1 : 0,
      'incluir_plano_acao': incluirPlanoAcao ? 1 : 0,
      'incluir_anexos': incluirAnexos ? 1 : 0,
      'texto_rodape': textoRodape,
      'assinatura_agronomo': assinaturaAgronomo,
      'registro_agronomo': registroAgronomo,
      'contato_agronomo': contatoAgronomo,
      'configuracoes_extras': configuracoesExtras != null ? jsonEncode(configuracoesExtras) : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cria a partir de Map
  factory SoilReportTemplateModel.fromMap(Map<String, dynamic> map) {
    return SoilReportTemplateModel(
      id: map['id'],
      nomeTemplate: map['nome_template'],
      nomeFazenda: map['nome_fazenda'],
      logoFazendaPath: map['logo_fazenda_path'],
      corPrimaria: map['cor_primaria'],
      corSecundaria: map['cor_secundaria'],
      corAccent: map['cor_accent'],
      fonteTitulo: map['fonte_titulo'],
      fonteTexto: map['fonte_texto'],
      tamanhoTitulo: map['tamanho_titulo']?.toDouble(),
      tamanhoSubtitulo: map['tamanho_subtitulo']?.toDouble(),
      tamanhoTexto: map['tamanho_texto']?.toDouble(),
      incluirCapa: (map['incluir_capa'] ?? 1) == 1,
      incluirSumario: (map['incluir_sumario'] ?? 1) == 1,
      incluirResumoExecutivo: (map['incluir_resumo_executivo'] ?? 1) == 1,
      incluirInformacoesPropriedade: (map['incluir_informacoes_propriedade'] ?? 1) == 1,
      incluirMetodologia: (map['incluir_metodologia'] ?? 1) == 1,
      incluirMapaCompactacao: (map['incluir_mapa_compactacao'] ?? 1) == 1,
      incluirTabelaPontos: (map['incluir_tabela_pontos'] ?? 1) == 1,
      incluirAnalisesEstatisticas: (map['incluir_analises_estatisticas'] ?? 1) == 1,
      incluirDiagnosticos: (map['incluir_diagnosticos'] ?? 1) == 1,
      incluirRecomendacoes: (map['incluir_recomendacoes'] ?? 1) == 1,
      incluirPlanoAcao: (map['incluir_plano_acao'] ?? 1) == 1,
      incluirAnexos: (map['incluir_anexos'] ?? 1) == 1,
      textoRodape: map['texto_rodape'],
      assinaturaAgronomo: map['assinatura_agronomo'],
      registroAgronomo: map['registro_agronomo'],
      contatoAgronomo: map['contato_agronomo'],
      configuracoesExtras: map['configuracoes_extras'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['configuracoes_extras']))
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  /// Converte para JSON
  String toJson() => jsonEncode(toMap());

  /// Cria a partir de JSON
  factory SoilReportTemplateModel.fromJson(String source) =>
      SoilReportTemplateModel.fromMap(jsonDecode(source));

  /// Cria cópia com alterações
  SoilReportTemplateModel copyWith({
    int? id,
    String? nomeTemplate,
    String? nomeFazenda,
    String? logoFazendaPath,
    String? corPrimaria,
    String? corSecundaria,
    String? corAccent,
    String? fonteTitulo,
    String? fonteTexto,
    double? tamanhoTitulo,
    double? tamanhoSubtitulo,
    double? tamanhoTexto,
    bool? incluirCapa,
    bool? incluirSumario,
    bool? incluirResumoExecutivo,
    bool? incluirInformacoesPropriedade,
    bool? incluirMetodologia,
    bool? incluirMapaCompactacao,
    bool? incluirTabelaPontos,
    bool? incluirAnalisesEstatisticas,
    bool? incluirDiagnosticos,
    bool? incluirRecomendacoes,
    bool? incluirPlanoAcao,
    bool? incluirAnexos,
    String? textoRodape,
    String? assinaturaAgronomo,
    String? registroAgronomo,
    String? contatoAgronomo,
    Map<String, dynamic>? configuracoesExtras,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SoilReportTemplateModel(
      id: id ?? this.id,
      nomeTemplate: nomeTemplate ?? this.nomeTemplate,
      nomeFazenda: nomeFazenda ?? this.nomeFazenda,
      logoFazendaPath: logoFazendaPath ?? this.logoFazendaPath,
      corPrimaria: corPrimaria ?? this.corPrimaria,
      corSecundaria: corSecundaria ?? this.corSecundaria,
      corAccent: corAccent ?? this.corAccent,
      fonteTitulo: fonteTitulo ?? this.fonteTitulo,
      fonteTexto: fonteTexto ?? this.fonteTexto,
      tamanhoTitulo: tamanhoTitulo ?? this.tamanhoTitulo,
      tamanhoSubtitulo: tamanhoSubtitulo ?? this.tamanhoSubtitulo,
      tamanhoTexto: tamanhoTexto ?? this.tamanhoTexto,
      incluirCapa: incluirCapa ?? this.incluirCapa,
      incluirSumario: incluirSumario ?? this.incluirSumario,
      incluirResumoExecutivo: incluirResumoExecutivo ?? this.incluirResumoExecutivo,
      incluirInformacoesPropriedade: incluirInformacoesPropriedade ?? this.incluirInformacoesPropriedade,
      incluirMetodologia: incluirMetodologia ?? this.incluirMetodologia,
      incluirMapaCompactacao: incluirMapaCompactacao ?? this.incluirMapaCompactacao,
      incluirTabelaPontos: incluirTabelaPontos ?? this.incluirTabelaPontos,
      incluirAnalisesEstatisticas: incluirAnalisesEstatisticas ?? this.incluirAnalisesEstatisticas,
      incluirDiagnosticos: incluirDiagnosticos ?? this.incluirDiagnosticos,
      incluirRecomendacoes: incluirRecomendacoes ?? this.incluirRecomendacoes,
      incluirPlanoAcao: incluirPlanoAcao ?? this.incluirPlanoAcao,
      incluirAnexos: incluirAnexos ?? this.incluirAnexos,
      textoRodape: textoRodape ?? this.textoRodape,
      assinaturaAgronomo: assinaturaAgronomo ?? this.assinaturaAgronomo,
      registroAgronomo: registroAgronomo ?? this.registroAgronomo,
      contatoAgronomo: contatoAgronomo ?? this.contatoAgronomo,
      configuracoesExtras: configuracoesExtras ?? this.configuracoesExtras,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SoilReportTemplateModel(id: $id, nomeTemplate: $nomeTemplate, nomeFazenda: $nomeFazenda)';
  }
}
