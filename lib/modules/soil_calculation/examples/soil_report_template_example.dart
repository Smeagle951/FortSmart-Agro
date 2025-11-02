import '../models/soil_report_template_model.dart';
import '../services/soil_report_generator_service.dart';
import 'package:latlong2/latlong.dart';

/// Exemplo de uso dos templates de relatório
class SoilReportTemplateExample {
  
  /// Exemplo de template padrão FortSmart
  static void exemploTemplatePadrao() {
    print('=== TEMPLATE PADRÃO FORTSMART ===');
    
    final template = SoilReportTemplateModel.templatePadrao(
      nomeFazenda: 'Fazenda Exemplo Ltda',
      logoFazendaPath: '/assets/logo_fazenda.png',
    );
    
    print('Nome: ${template.nomeTemplate}');
    print('Fazenda: ${template.nomeFazenda}');
    print('Cor Primária: ${template.corPrimaria}');
    print('Cor Secundária: ${template.corSecundaria}');
    print('Fonte Título: ${template.fonteTitulo}');
    print('Tamanho Título: ${template.tamanhoTitulo}pt');
    print('Incluir Capa: ${template.incluirCapa}');
    print('Incluir Sumário: ${template.incluirSumario}');
    print('Incluir Mapa: ${template.incluirMapaCompactacao}');
    print('Incluir Gráficos: ${template.incluirAnalisesEstatisticas}');
    print('Texto Rodapé: ${template.textoRodape}');
    print('Assinatura: ${template.assinaturaAgronomo}');
  }

  /// Exemplo de template minimalista
  static void exemploTemplateMinimalista() {
    print('\n=== TEMPLATE MINIMALISTA ===');
    
    final template = SoilReportTemplateModel.templateMinimalista(
      nomeFazenda: 'Fazenda Simples',
      logoFazendaPath: '/assets/logo_simples.png',
    );
    
    print('Nome: ${template.nomeTemplate}');
    print('Fazenda: ${template.nomeFazenda}');
    print('Cor Primária: ${template.corPrimaria}');
    print('Fonte: ${template.fonteTitulo}');
    print('Tamanho Título: ${template.tamanhoTitulo}pt');
    print('Incluir Sumário: ${template.incluirSumario}');
    print('Incluir Metodologia: ${template.incluirMetodologia}');
    print('Incluir Diagnósticos: ${template.incluirDiagnosticos}');
    print('Incluir Plano de Ação: ${template.incluirPlanoAcao}');
  }

  /// Exemplo de template executivo
  static void exemploTemplateExecutivo() {
    print('\n=== TEMPLATE EXECUTIVO ===');
    
    final template = SoilReportTemplateModel.templateExecutivo(
      nomeFazenda: 'Fazenda Executiva S.A.',
      logoFazendaPath: '/assets/logo_executivo.png',
    );
    
    print('Nome: ${template.nomeTemplate}');
    print('Fazenda: ${template.nomeFazenda}');
    print('Cor Primária: ${template.corPrimaria}');
    print('Fonte Título: ${template.fonteTitulo}');
    print('Tamanho Título: ${template.tamanhoTitulo}pt');
    print('Incluir Tabela Pontos: ${template.incluirTabelaPontos}');
    print('Incluir Diagnósticos: ${template.incluirDiagnosticos}');
    print('Incluir Anexos: ${template.incluirAnexos}');
    print('Assinatura: ${template.assinaturaAgronomo}');
    print('Registro: ${template.registroAgronomo}');
  }

  /// Exemplo de template técnico completo
  static void exemploTemplateTecnicoCompleto() {
    print('\n=== TEMPLATE TÉCNICO COMPLETO ===');
    
    final template = SoilReportTemplateModel.templateTecnicoCompleto(
      nomeFazenda: 'Fazenda Técnica Avançada',
      logoFazendaPath: '/assets/logo_tecnico.png',
    );
    
    print('Nome: ${template.nomeTemplate}');
    print('Fazenda: ${template.nomeFazenda}');
    print('Cor Primária: ${template.corPrimaria}');
    print('Fonte: ${template.fonteTitulo}');
    print('Tamanho Título: ${template.tamanhoTitulo}pt');
    print('Incluir Tudo: ${template.incluirCapa && template.incluirSumario && template.incluirResumoExecutivo}');
    print('Configurações Extras: ${template.configuracoesExtras}');
    print('Assinatura: ${template.assinaturaAgronomo}');
    print('Registro: ${template.registroAgronomo}');
  }

  /// Exemplo de customização de template
  static void exemploCustomizacaoTemplate() {
    print('\n=== CUSTOMIZAÇÃO DE TEMPLATE ===');
    
    // Cria template base
    final templateBase = SoilReportTemplateModel.templatePadrao(
      nomeFazenda: 'Fazenda Customizada',
    );
    
    // Customiza cores e fontes
    final templateCustomizado = templateBase.copyWith(
      corPrimaria: '#8E44AD', // Roxo
      corSecundaria: '#9B59B6', // Roxo claro
      corAccent: '#F39C12', // Amarelo
      fonteTitulo: 'Montserrat',
      fonteTexto: 'Open Sans',
      tamanhoTitulo: 32.0,
      tamanhoSubtitulo: 18.0,
      tamanhoTexto: 13.0,
      incluirSumario: false,
      incluirMetodologia: false,
      incluirDiagnosticos: false,
      incluirAnexos: false,
      textoRodape: 'Relatório Customizado - Fazenda Customizada',
      assinaturaAgronomo: 'Eng. Agrônomo Especialista',
      registroAgronomo: 'CRBio 12345',
      contatoAgronomo: 'especialista@fazendacustomizada.com.br',
    );
    
    print('Template Customizado:');
    print('  Nome: ${templateCustomizado.nomeTemplate}');
    print('  Cor Primária: ${templateCustomizado.corPrimaria}');
    print('  Fonte: ${templateCustomizado.fonteTitulo}');
    print('  Tamanho Título: ${templateCustomizado.tamanhoTitulo}pt');
    print('  Incluir Sumário: ${templateCustomizado.incluirSumario}');
    print('  Incluir Metodologia: ${templateCustomizado.incluirMetodologia}');
    print('  Incluir Diagnósticos: ${templateCustomizado.incluirDiagnosticos}');
    print('  Incluir Anexos: ${templateCustomizado.incluirAnexos}');
    print('  Texto Rodapé: ${templateCustomizado.textoRodape}');
    print('  Assinatura: ${templateCustomizado.assinaturaAgronomo}');
  }

  /// Exemplo de geração de relatório com template
  static Future<void> exemploGeracaoRelatorioComTemplate() async {
    print('\n=== GERAÇÃO DE RELATÓRIO COM TEMPLATE ===');
    
    try {
      // Cria template personalizado
      final template = SoilReportTemplateModel.templateExecutivo(
        nomeFazenda: 'Fazenda Exemplo',
        logoFazendaPath: '/assets/logo_exemplo.png',
      );
      
      // Dados simulados
      final pontos = [
        // Pontos simulados aqui
      ];
      
      final polygonCoordinates = [
        LatLng(-23.5505, -46.6333),
        LatLng(-23.5510, -46.6340),
        LatLng(-23.5500, -46.6325),
        LatLng(-23.5505, -46.6333),
      ];
      
      // Gera relatório com template
      final filePath = await SoilReportGeneratorService.gerarRelatorioPremium(
        talhaoId: 1,
        nomeTalhao: 'Talhão A',
        nomeFazenda: 'Fazenda Exemplo',
        nomeResponsavel: 'João Silva',
        areaHectares: 25.5,
        centroTalhao: LatLng(-23.5505, -46.6333),
        safraId: 2025,
        dataColeta: DateTime.now(),
        operador: 'Maria Santos',
        pontos: pontos,
        polygonCoordinates: polygonCoordinates,
        logoFazendaPath: '/assets/logo_exemplo.png',
        template: template, // Usa template personalizado
      );
      
      print('Relatório gerado com sucesso!');
      print('Arquivo: $filePath');
      print('Template usado: ${template.nomeTemplate}');
      print('Cores: ${template.corPrimaria} / ${template.corSecundaria}');
      print('Fonte: ${template.fonteTitulo}');
      
    } catch (e) {
      print('Erro ao gerar relatório: $e');
    }
  }

  /// Exemplo de serialização/deserialização
  static void exemploSerializacao() {
    print('\n=== SERIALIZAÇÃO/DESERIALIZAÇÃO ===');
    
    // Cria template
    final template = SoilReportTemplateModel.templatePadrao(
      nomeFazenda: 'Fazenda Serialização',
    );
    
    // Converte para Map
    final map = template.toMap();
    print('Template convertido para Map:');
    print('  ID: ${map['id']}');
    print('  Nome: ${map['nome_template']}');
    print('  Fazenda: ${map['nome_fazenda']}');
    print('  Cor Primária: ${map['cor_primaria']}');
    print('  Incluir Capa: ${map['incluir_capa']}');
    
    // Converte para JSON
    final json = template.toJson();
    print('\nTemplate convertido para JSON:');
    print('Tamanho: ${json.length} caracteres');
    print('Primeiros 100 caracteres: ${json.substring(0, 100)}...');
    
    // Reconstrói a partir do Map
    final templateReconstruido = SoilReportTemplateModel.fromMap(map);
    print('\nTemplate reconstruído:');
    print('  Nome: ${templateReconstruido.nomeTemplate}');
    print('  Fazenda: ${templateReconstruido.nomeFazenda}');
    print('  Cor Primária: ${templateReconstruido.corPrimaria}');
    print('  Incluir Capa: ${templateReconstruido.incluirCapa}');
    
    // Verifica se são iguais
    print('\nTemplates são iguais: ${template.nomeTemplate == templateReconstruido.nomeTemplate}');
  }

  /// Executa todos os exemplos
  static Future<void> executarTodosExemplos() async {
    print('📄 EXEMPLOS DE TEMPLATES DE RELATÓRIO - FORTSMART AGRO\n');
    
    exemploTemplatePadrao();
    exemploTemplateMinimalista();
    exemploTemplateExecutivo();
    exemploTemplateTecnicoCompleto();
    exemploCustomizacaoTemplate();
    exemploSerializacao();
    
    print('\n' + '='*50 + '\n');
    
    await exemploGeracaoRelatorioComTemplate();
    
    print('\n✅ Todos os exemplos executados com sucesso!');
  }
}
