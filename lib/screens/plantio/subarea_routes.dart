import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'talhao_detalhes_screen.dart';
import 'subarea_detalhes_screen.dart';
import 'criar_subarea_fullscreen_screen.dart';
import 'experimento_melhorado_screen.dart';
import '../../models/experimento_talhao_model.dart';
import '../../models/subarea_experimento_model.dart';
import '../../models/experimento_completo_model.dart';

/// Rotas específicas para o módulo de subáreas
class SubareaRoutes {
  // Constantes das rotas
  static const String talhaoDetalhes = '/talhao/detalhes';
  static const String subareaDetalhes = '/subarea/detalhes';
  static const String criarSubarea = '/subarea/criar';
  static const String exemploSubareas = '/subarea/exemplo';
  static const String experimentoMelhorado = '/experimento/melhorado';

  /// Mapa de rotas do módulo de subáreas
  static final Map<String, WidgetBuilder> routes = {
    talhaoDetalhes: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        return const Scaffold(
          body: Center(
            child: Text('Erro: Argumentos não fornecidos'),
          ),
        );
      }
      final experimento = args['experimento'] as Experimento?;
      if (experimento == null) {
        return const Scaffold(
          body: Center(
            child: Text('Erro: Experimento não encontrado'),
          ),
        );
      }
      return TalhaoDetalhesScreen(experimento: experimento);
    },
    
    subareaDetalhes: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        return const Scaffold(
          body: Center(
            child: Text('Erro: Argumentos não fornecidos'),
          ),
        );
      }
      final subarea = args['subarea'] as Subarea?;
      if (subarea == null) {
        return const Scaffold(
          body: Center(
            child: Text('Erro: Subárea não encontrada'),
          ),
        );
      }
      return SubareaDetalhesScreen(subarea: subarea);
    },
    
    criarSubarea: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        return const Scaffold(
          body: Center(
            child: Text('Erro: Argumentos não fornecidos'),
          ),
        );
      }
      final experimentoId = args['experimentoId'] as String? ?? '';
      final talhaoId = args['talhaoId'] as String? ?? '';
      return CriarSubareaFullscreenScreen(
        experimentoId: experimentoId,
        talhaoId: talhaoId,
      );
    },
    
    exemploSubareas: (context) => const Scaffold(
      body: Center(
        child: Text('Funcionalidade em desenvolvimento'),
      ),
    ),
    
    experimentoMelhorado: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        return const Scaffold(
          body: Center(
            child: Text('Erro: Argumentos não fornecidos'),
          ),
        );
      }
      final experimento = args['experimento'] as ExperimentoCompleto?;
      if (experimento == null) {
        return const Scaffold(
          body: Center(
            child: Text('Erro: Experimento não encontrado'),
          ),
        );
      }
      return ExperimentoMelhoradoScreen(experimento: experimento);
    },
  };

  /// Método para navegar para detalhes do talhão
  static Future<T?> navigateToTalhaoDetalhes<T extends Object?>(
    BuildContext context,
    Experimento experimento,
  ) {
    // Converter Experimento para ExperimentoCompleto e usar a tela melhorada
    final experimentoCompleto = ExperimentoCompleto(
      id: experimento.id,
      nome: experimento.nome,
      talhaoId: experimento.talhaoId,
      talhaoNome: experimento.talhaoNome,
      dataInicio: experimento.dataInicio,
      dataFim: experimento.dataFim ?? experimento.dataInicio.add(Duration(days: 30)),
      status: _convertStringToExperimentoStatus(experimento.status),
      descricao: experimento.observacoes ?? '',
      subareas: experimento.subareas.map((subarea) => SubareaCompleta(
        id: subarea.id?.toString() ?? '',
        experimentoId: experimento.id,
        nome: subarea.nome,
        tipo: subarea.cultura ?? 'N/A',
        cor: subarea.cor,
        pontos: subarea.polygon.vertices.map((v) => LatLng(v.latitude, v.longitude)).toList(),
        area: subarea.areaHa,
        perimetro: subarea.perimetroM,
        dataCriacao: subarea.criadoEm,
        observacoes: subarea.observacoes,
        status: SubareaStatus.ativa,
        dataFinalizacao: null,
      )).toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    return Navigator.pushNamed<T>(
      context,
      experimentoMelhorado,
      arguments: {'experimento': experimentoCompleto},
    );
  }

  /// Método para navegar para detalhes da subárea
  static Future<T?> navigateToSubareaDetalhes<T extends Object?>(
    BuildContext context,
    Subarea subarea,
  ) {
    return Navigator.pushNamed<T>(
      context,
      subareaDetalhes,
      arguments: {'subarea': subarea},
    );
  }

  /// Método para navegar para criar subárea
  static Future<T?> navigateToCriarSubarea<T extends Object?>(
    BuildContext context,
    String experimentoId,
    String talhaoId,
  ) {
    return Navigator.pushNamed<T>(
      context,
      criarSubarea,
      arguments: {
        'experimentoId': experimentoId,
        'talhaoId': talhaoId,
      },
    );
  }

  /// Método para navegar para exemplo de uso
  static Future<T?> navigateToExemploSubareas<T extends Object?>(
    BuildContext context,
  ) {
    return Navigator.pushNamed<T>(
      context,
      exemploSubareas,
    );
  }

  /// Método para navegar para experimento melhorado
  static Future<T?> navigateToExperimentoMelhorado<T extends Object?>(
    BuildContext context,
    ExperimentoCompleto experimento,
  ) {
    return Navigator.pushNamed<T>(
      context,
      experimentoMelhorado,
      arguments: {'experimento': experimento},
    );
  }

  /// Método para verificar se uma rota existe
  static bool hasRoute(String routeName) {
    return routes.containsKey(routeName);
  }

  /// Método para obter uma rota específica
  static WidgetBuilder? getRoute(String routeName) {
    return routes[routeName];
  }
}

/// Converte string para ExperimentoStatus
ExperimentoStatus _convertStringToExperimentoStatus(String status) {
  switch (status.toLowerCase()) {
    case 'ativo':
      return ExperimentoStatus.ativo;
    case 'concluido':
      return ExperimentoStatus.concluido;
    case 'pausado':
      return ExperimentoStatus.pendente;
    case 'cancelado':
      return ExperimentoStatus.cancelado;
    default:
      return ExperimentoStatus.ativo;
  }
}
